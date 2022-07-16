# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV['VAGRANT_NO_PARALLEL'] = 'yes'

ENV['VAGRANT_DEFAULT_PROVIDER'] = 'hyperv'


Vagrant.configure(2) do |config|

  config.vm.provision "shell", path: "bootstrap.sh"

  # Kubernetes Master Server
  config.vm.define "kmaster" do |node|
  
    node.vm.box               = "centos/7"
    node.vm.box_check_update  = false
    node.vm.hostname          = "kmaster.example.com"

    node.vm.network "private_network", ip: "172.16.16.100"
  
    
    node.vm.provider :hyperv do |v|
      v.memory  = 4096
      v.cpus    = 2
    end
  
    node.vm.provision "shell", path: "bootstrap_kmaster.sh"
  
  end


  # Kubernetes Worker Nodes
  NodeCount = 2

  (1..NodeCount).each do |i|

    config.vm.define "kworker#{i}" do |node|

      node.vm.box               = "centos/7"
      node.vm.box_check_update  = false
      node.vm.hostname          = "kworker#{i}.example.com"

      node.vm.network "private_network", ip: "172.16.16.10#{i}"
    
      node.vm.provider :hyperv do |v|
        v.memory  = 8192
        v.cpus    = 2
      end

      node.vm.provision "shell", path: "bootstrap_kworker.sh"

    end

  end

end