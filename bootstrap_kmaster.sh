#!/bin/bash

echo "[TASK 11] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

echo "[TASK 12] Initialize Kubernetes Cluster"
kubeadm init --apiserver-advertise-address=172.16.16.100 --pod-network-cidr=192.168.0.0/16 >> /root/kubeinit.log 2>/dev/null

echo "[TASK 13] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[TASK 14] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

echo "[TASK 15] Install nfs-kernel-server, configure and start nfs-kernel-server"
apt install -qq -y nfs-kernel-server >/dev/null 2>&1

echo "[TASK 16] creating /srv/kubernetes/volume for K8's pv"
mkdir -p /srv/kubernetes/volume

echo "[TASK 17] Changing the ownership of /srv/kubernetes/volume to nobody"
chown -R nobody:nogroup /srv/kubernetes/

echo "[TASK 18] Granting write permissions to /srv/kubernetes"
chmod -R 777 /srv/kubernetes/

echo "[TASK 19] Update /etc/exports file"
cat >>/etc/exports<<EOF
/srv/kubernetes/ 172.16.16.0/24(rw,no_root_squash,no_subtree_check,insecure)
EOF

echo "[TASK 20] Strating nfs-kernel-server"
exportfs -ar
systemctl enable nfs-kernel-server
systemctl start nfs-kernel-server