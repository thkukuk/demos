# SUSECon 19

## openSUSE Kubic Presentation demo

1. Create three images (kubic-1, kubic-2, kubic-3) according to
   the howto and use the libvirt definitions to run them with
   virt-manager/KVM
2. Copy the demo-magic.sh, kubic-1.sh files and manifests directory
   to root home directory on kubic-1
3. Login to kubic-1 and run ./kubic-1.sh
   - Enter -> Command Shown -> Enter -> Command Executed
   - kubeadm init is called, salt master/minion are setup,
     kubeadm join is called via salt on all worker nodes,
     metalllb is installed, hello-kubernetes is deployed
   - go to a webbrowser, lb1.demo will show the hello world output

## openSUSE Kubic Kiosk

1. Use the setup from the presentation
2. Install kubernetes dashboard according to howto.txt
   - lb2.demo will have the dashboard
3. Install ingress controller
4. Install prometheus and grafana, prometheus.demo and grafana.demo
   will show the tools via ingress controller
5. Install openSUSE MicroOS for transactional-update demo
