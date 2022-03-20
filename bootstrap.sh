#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2004 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#

##Update the OS
yum update -y
 
## Install yum-utils, bash completion, git, and more
#yum install yum-utils nfs-utils bash-completion git wget -y
echo "[TASK# 2] Installing wget"
yum install wget -y

 
## Disable firewall starting from Kubernetes v1.19 onwards to avoid any issues. Kubernetes uses IPTables to handle inbound and outbound traffic.
echo "[TASK# 1] Disable firewall"
systemctl disable firewalld
systemctl stop firewalld


## Swap needs to be disabled. Kubeadm will check to make sure that swap is disabled. Turn swap off and disable for future reboots.
echo "[TASK# 2] Disable Swap"
swapoff -a
sed -i.bak '/swap/d' /etc/fstab

## We need to disable SELinux or set it to permissive mode if it’s enabled. I’m setting to Permissive mode.
echo "[TASK# 3] Disable SELinux"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 
## Setup necessary steps to use containerd as CRI runtime
echo "[TASK# 4] Install and configure prerequisites for containerd runtime"
cat <<EOF | tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sysctl --system  
 
## Install Containerd with Release Tarball
echo "[TASK# 5] Install Containerd with Release Tarball"
yum install wget -y
wget https://storage.googleapis.com/cri-containerd-release/cri-containerd-1.3.4.linux-amd64.tar.gz
tar --no-overwrite-dir -C / -xzf cri-containerd-1.3.4.linux-amd64.tar.gz
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
systemctl enable containerd
systemctl start containerd

 
###
## configuring Kubernetes repositories
echo "[TASK# 6] Configuring Kubernetes repositories"
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
 
 
##Install Kubernetes, specify Version as CRI-O
yum install -y kubelet-1.22.4-0 kubeadm-1.22.4-0 kubectl-1.22.4-0 >/dev/null 2>&1

echo "[TASK# 14] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 10] Enable and start kubelet service"
systemctl daemon-reload
systemctl enable kubelet 
#--now

# cat >>/etc/systemd/system/kubelet.service.d/0-containerd.conf<<EOF
# [Service]                                                 
# Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
# EOF

# systemctl daemon-reload
# systemctl restart kubelet



# Enable ssh password authentication
echo "[TASK 11] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl reload sshd

# Set Root password
echo "[TASK 12] Set root password"
echo "kubeadmin" | passwd --stdin root >/dev/null 2>&1

# Update vagrant user's bashrc file
echo "export TERM=xterm" >> /etc/bashrc


echo "[TASK 13] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.100   kmaster.example.com    kmaster
172.16.16.101   kworker1.example.com   kworker1
172.16.16.102   kworker2.example.com   kworker2
EOF