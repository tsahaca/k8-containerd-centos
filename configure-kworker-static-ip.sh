#!/bin/sh

echo 'Setting static IP address for kworker Hyper-V...'

cat << EOF > /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0
BOOTPROTO=none
ONBOOT=yes
PREFIX=24
IPADDR=$1
GATEWAY=172.16.16.99
DNS1=8.8.8.8
EOF

# Be sure NOT to execute "systemctl restart network" here, so the changes take
# effect on reboot instead of immediately, which would disconnect the provisioner.