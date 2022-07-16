#!/bin/bash

# echo "[TASK# 14] Pull required containers"
# kubeadm config images pull >/dev/null 2>&1


# Initialize Kubernetes
echo "[TASK# 15] Initialize Kubernetes Cluster calico=192.168.0.0/16 flannel=10.244.0.0/16"
kubeadm init --apiserver-advertise-address=172.19.245.219 --pod-network-cidr=192.168.0.0/16  >> /root/kubeinit.log 2>/dev/null

# Copy Kube admin config
echo "[TASK# 16] Copy kube admin config to Vagrant user .kube directory"
mkdir /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube

# Deploy calico network
echo "[TASK# 17] Deploy Calico network"
## su - vagrant -c "kubectl create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/manifests/calico.yaml >/dev/null 2>&1
#kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/tsahaca/k8-containerd-centos/fedora/kube-flannel.yml >/dev/null 2>&1


# Generate Cluster join command
echo "[TASK# 18] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

# Configuring NFS Server
# yum install nfs-utils -y

echo "[TASK# 19] Creating folder /srv/kubernetes/volume for nfs-server"
mkdir -p /srv/kubernetes/volume
chmod -R 755 /srv/kubernetes
chown -R nfsnobody:nfsnobody /srv/kubernetes

echo "[TASK 20] Update /etc/exports file"
cat >>/etc/exports<<EOF
/srv/kubernetes/volume 172.16.16.0/24(rw,sync,no_root_squash,no_subtree_check)
EOF

echo "[TASK 21] Exporting the NFS Share"
exportfs -ar

echo "[TASK# 22] Starting for nfs-server"
systemctl restart nfs-server
systemctl enable nfs-server
