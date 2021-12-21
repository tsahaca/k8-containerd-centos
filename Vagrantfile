# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"

  # Kubernetes Master Server
  config.vm.define "kmaster-cnd" do |node|
    node.vm.box = "centos/7"
    node.vm.hostname = "kmaster-cnd.example.com"
    node.vm.network "private_network", ip: "172.26.26.100"
    node.vm.provider "virtualbox" do |v|
      v.name = "kmaster-cnd"
      v.memory = 4096
      v.cpus = 2
    end
    node.vm.provision "shell", path: "bootstrap_kmaster.sh"
  end

  NodeCount = 2

  # Kubernetes Worker Nodes
  (1..NodeCount).each do |i|
    config.vm.define "kworker-cnd-#{i}" do |workernode|
      workernode.vm.box = "centos/7"
      workernode.vm.hostname = "kworker-cnd-#{i}.example.com"
      workernode.vm.network "private_network", ip: "172.26.26.10#{i}"
      workernode.vm.provider "virtualbox" do |v|
        v.name = "kworker-cnd-#{i}"
        v.memory = 2048
        v.cpus = 1
      end
      workernode.vm.provision "shell", path: "bootstrap_kworker.sh"
    end
  end

end
