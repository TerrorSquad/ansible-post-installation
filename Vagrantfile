# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "aaronvonawesome/linux-mint-20-cinnamon"
  config.vm.box_version = "2.1.0"
  ENV['LC_ALL']="en_US.UTF-8"

  #
  # Run Ansible from the Vagrant Host
  #
  config.vm.provision "ansible" do |ansible|
    ansible.groups = {
      'vagrant' => ['default']
    }

    ansible.playbook = "playbook_vagrant.yml"
  end
end
