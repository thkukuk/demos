# Elastic Inference on Raspberry Pi with openSUSE Kubic

## Pre-Requires
* Cluster of 4 Raspberry Pi 4 with 4GB of RAM
* One Pi 4 acts as gateway and has:
  * 2 NICs
  * 4x20 LCD display via i2c interface
  * RTC via i2c interface
* Intel Neural Compute Stick 2 (NCS2)
* Naming:
  * Nodes: rpi4-1.demo, rpi4-2.demo, rpi4-3.demo, rpi4-4.demo
  * Loadbalancer for metallb: rpi4-lb1.demo - rpi4-lb9.demo
  * Additional nodes: rpi4-d1.demo - rpi4-d40.demo
* IP addreses: the internal network uses 172.27.0.x, the external interface uses dhcp, but can be configured/changed during first boot with ignition

## Images
The Gateway will be intalled with the
openSUSE-MicroOS.aarch64-16.0.0-ContainerHost-RaspberryPi.raw image, the other
three nodes will be installed with
openSUSE-MicroOS.aarch64-16.0.0-Kubic-kubeadm-RaspberryPi.raw image.

Download from: https://download.opensuse.org/repositories/home:/kukuk:/raspi:/images/openSUSE_Factory_ARM/

## Configuration

### Edge Gateway
Use ignition/rpi4-lb-gateway.yaml, convert to config.ign and use that as
source to configure:
* eth0 - internal network
* eth1 - external network
* ssh key
* root password
* LCD display

#### Configuration files
Copy the directory structure and files from *srv* to */srv* on *rpi4-1.demo*.
Copy the *registries.conf* file to */srv/salt* on *rpi4-1.demo*

#### NTP server
Configure chronyd to become a ntp server and add to */etc/chrony.conf*:

    local stratum 8
    allow 172.27.0.0/24

and restart chrony: ``systemctl restart chronyd``

#### Install missing packages

```
  # transactional-update pkg install container-registry-systemd containers-systemd apache2-utils mirror-registry reg salt-master kubicd
  # systemctl reboot
```

#### Setup local container registry

At first, we need a password for the registry (blowfish hash).
``htpasswd -nB admin`` creates such a hash, which needs to be inserted in the
configuration file: ``nano /etc/registry/auth_config.yml``

We re-create the certificates, as we need to add the hostnames of the external
interface. The hostnames in the ``create-container-registry-certs`` line needs
to be adjusted.

```
  # echo "172.27.0.1 rpi4-1.demo rpi4-1" >> /etc/hosts
  # setup-container-registry
  # create-container-registry-certs -f -a rpi4-1 rpi4-1.demo localhost e106 e106.suse.de
  # systemctl start container-registry
  # systemctl start registry-auth_server
```

We need to mirror the kubic and opensuse namespace of registry.opensuse.org to
deploy kubernetes on the local cluster without internet connection.

```
  # mirror-registry --out kubic-small.yaml --minimize registry.opensuse.org "(^kubic|^opensuse/([^/]+)$)"
  # skopeo sync --scoped --src yaml --dest docker --dest-creds admin:password kubic-small.yaml localhost
```

#### Setup bind, dhcp and salt-master

Start local name server:

```
  # echo "include \"/etc/named.d/demo.conf\";" >> /srv/bind/etc/named.conf
  # systemctl enable --now container-bind
```

Adjust DNS configuration of rpi4-1.demo to use local nameserver, too:

```
  # nano /etc/sysconfig/network/config
  NETCONFIG_DNS_STATIC_SEARCHLIST="demo"
  NETCONFIG_DNS_STATIC_SERVERS="127.0.0.1"
```

Adjust DHCP Interface in */etc/sysconfig/container-dhcp-server* and start the
dhcp-server and salt-master:

```
  # systemctl enable --now container-dhcp-server
  # systemctl enable --now salt-master
```

### Setup remaining Nodes

Now you can boot rpi4-2, rpi4-3 and rpi4-4.

Accept all salt minions: ``salt-keys -A``

#### Distribute CA key

Distribute CA key for container registry to all nodes. The
update-ca-certificates call should not be necessary, it's only to be on the
safe side.

```
  # cp /etc/registry/certs/ContainerRegistryCA.crt /srv/salt
  # salt '*' cp.get_file salt://ContainerRegistryCA.crt /etc/pki/trust/anchors/ContainerRegistryCA.pem
  # salt '*' cmd.run update-ca-certificates
```

#### Setup cri-o to use local registry

```
  # salt '*' cp.get_file salt://registries.conf /etc/containers/registries.conf
  # salt '*' service.restart crio
```

#### Setup kubic-control

```
  # systemctl enable --now kubicd-init.service
  # systemctl enable --now kubicd.service
```

#### Deploy kubernetes

Start haproxy and use kubic-control to setup the kubernetes cluster and deploy
hello-kubic to verify everything is working.

```
  # systemctl enable --now container-haproxy
  # kubicctl init --salt rpi4-2.demo
  # kubicctl node add rpi4-[34].demo
  # kubicctl deploy metallb 172.27.0.21-172.27.0.29
  # kubicctl deploy hello-kubic -i kubic-lb1.demo -t LoadBalancer
```

## Demos

### Prepare Node with NCS2

Plug-in the NCS2 and install the driver on node rpi4-4:

```
# transactional-update pkg install dldt-udev dldt-firmware myriadctl
# systemctl reboot
# systemctl enable --now myriadctl
```

Add the NCS2 as resource for rpi4-4

```
# kubectl proxy
# scripts/advertise-ncs2 rpi4-4
```

### OpenVINO classification service

Deploy openvino classification service:
``kustomize build classification/myriad | kubectl apply -f -``

To verify it's working:

```
  # cd scripts
  # ./classify-image e106.suse.de car.png
  # cd ..
```

### Elastic Inference Demo

Install the yaml/kustomize files to deploy the elastic inference demo

```
  # zypper ar -f https://download.opensuse.org/repositories/devel:/kubic:/ei-demo/openSUSE_Factory_ARM ei-demo
  # transactional-update pkg install elastic-inference-demo-k8s-yaml
  # systemctl reboot
```

We need to mirror the containers for elastic inference demo, as the cluster
cannot access the internet:

```
  # mirror-registry --out kubic-ei-demo.yaml --minimize registry.opensuse.org "^devel/kubic/ei-demo"
  # skopeo sync --scoped --src yaml --dest docker --dest-creds admin:password kubic-ei-demo.yaml localhost
```
