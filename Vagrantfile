# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"
  config.vm.box_version = "3.6.8"
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
