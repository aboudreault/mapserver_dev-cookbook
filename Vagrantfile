# -*- mode: ruby -*-

require 'berkshelf/vagrant'

Vagrant::Config.run do |config|

  config.vm.host_name = "mapserver-dev"

  config.vm.box = "precise32"
  config.vm.box_url = "http://files.vagrantup.com/precise32.box"

  config.vm.network :hostonly, "192.168.33.2"

  config.vm.forward_port  80, 8002
  config.vm.forward_port  22, 2202
  
  config.vm.share_folder "v-data", "/vagrant_data", "~"

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  config.vm.customize ["modifyvm", :id, "--cpus", 2]
  config.vm.customize ["modifyvm", :id, "--memory", 1024]
  
  config.vm.provision :chef_solo do |chef|
    chef.run_list = [
      "recipe[mapserver-dev::default]"
    ]
  end

end
