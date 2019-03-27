#!/bin/bash

########################
# include the magic
########################
. ./demo-magic.sh


########################
# Configure the options
########################

#
# speed at which to simulate typing. bigger num = faster
#
# TYPE_SPEED=20

#
# custom prompt
#
# see http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html for escape sequences
#
#DEMO_PROMPT="${GREEN}➜ ${CYAN}\W "
DEMO_PROMPT="${RED}\h:\w # "
DEMO_CMD_COLOR=$BLACK

# hide the evidence
clear

pe "kubeadm init --cri-socket=/var/run/crio/crio.sock --pod-network-cidr=10.244.0.0/16 --kubernetes-version=1.13.5"
pe "mkdir -p ~/.kube && cp /etc/kubernetes/admin.conf ~/.kube/config"
pe "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"
pe "kubectl apply -f /usr/share/kured/kured-1.1.0.yaml"

pe "systemctl enable --now salt-master"
#pe "echo \"master: localhost\" > /etc/salt/minion.d/master.conf"
pe "systemctl enable --now salt-minion"

# Make sure kubic-2 and kubic-3 are running
sleep 20 # Give salt minions time to connect
pe "salt-key -L"
pe "salt-key -A"

# run kubeadm join
KUBEADM_JOIN=`kubeadm token create --print-join-command`
pe "salt -G 'roles:kube-worker' cmd.run \"${KUBEADM_JOIN} --cri-socket=/var/run/crio/crio.sock\""
pe "kubectl get nodes"

# Show how many updates are missing
pe "salt '*' cmd.run update-checker"
pe "salt '*' cmd.run \"echo REBOOT_METHOD=kured > /etc/transactional-update.conf\""
#pe "kubectl get pods -n kube-system -o wide --selector=name=kured"


# Install metallb to run hello-kubernetes
pe "kubectl apply -f manifests/metallb.yaml"
pe "cat manifests/metallb-layer2-config.yaml"
pe "kubectl apply -f manifests/metallb-layer2-config.yaml"
pe "kubectl apply -f manifests/hello-kubernetes.yaml"
pe "kubectl get pods -o wide --watch"
# show a prompt so as not to reveal our true nature after
# the demo has concluded
p ""
