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

echo "[TASK 3] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.100   kmaster.example.com    kmaster
172.16.16.101   kworker1.example.com   kworker1
172.16.16.102   kworker2.example.com   kworker2
EOF

 
## Disable firewall starting from Kubernetes v1.19 onwards to avoid any issues. Kubernetes uses IPTables to handle inbound and outbound traffic.
echo "[TASK# 4] Disable firewall"
systemctl disable firewalld
systemctl stop firewalld


## Swap needs to be disabled. Kubeadm will check to make sure that swap is disabled. Turn swap off and disable for future reboots.
echo "[TASK# 5] Disable Swap"
swapoff -a
sed -i.bak '/swap/d' /etc/fstab

## We need to disable SELinux or set it to permissive mode if it’s enabled. I’m setting to Permissive mode.
echo "[TASK# 6] Disable SELinux"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
 
## Setup necessary steps to use containerd as CRI runtime
# Configure persistent loading of modules
echo "[TASK# 7] Setup necessary steps to use containerd as CRI runtime"
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
modprobe overlay
modprobe br_netfilter

# Ensure sysctl params are set
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload configs
sysctl --system

# Install required packages
yum install -y yum-utils device-mapper-persistent-data lvm2

# Add Docker repo
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Install containerd
echo "[TASK# 8] Installing containerd"
yum update -y && yum install -y containerd.io

# Configure containerd and start service
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# restart containerd
echo "[TASK# 9] Restarting and Enabling containerd"
systemctl restart containerd
systemctl enable containerd

 
###
## configuring Kubernetes repositories
echo "[TASK# 10] Configuring Kubernetes repositories"
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

echo "[TASK# 11] Pull required containers"
kubeadm config images pull >/dev/null 2>&1

# Start and Enable kubelet service
echo "[TASK 12] Enable and start kubelet service"
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