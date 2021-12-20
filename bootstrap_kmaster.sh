#!/bin/bash

echo "[TASK# 14] Pull required containers"
kubeadm config images pull >/dev/null 2>&1


# Initialize Kubernetes
echo "[TASK# 15] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=192.168.58.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK# 16] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy calico network
echo "[TASK# 17] Deploy Calico network"
## su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1


# Generate Cluster join command
echo "[TASK# 18] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null
