# -*- mode: ruby -*-

require 'berkshelf/vagrant'

Vagrant.configure("2") do |config|

  config.berkshelf.enabled = true

  config.vm.hostname = "mapserver-dev"

  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.network "private_network", ip: "192.168.33.2"

  config.vm.network "forwarded_port", guest: 80, host: 8002
  config.vm.network "forwarded_port",  guest: 22, host: 2202

  config.vm.synced_folder "~", "/vagrant_data"

  config.vm.provider "virtualbox" do |v|
    v.name = "mapserver-dev"
    v.customize ["modifyvm", :id, "--cpus", 2]
    v.memory = 1500
  end

  config.vm.provision :chef_solo do |chef|
    chef.run_list = [
      "recipe[mapserver-dev::default]"
    ]
  end

end
