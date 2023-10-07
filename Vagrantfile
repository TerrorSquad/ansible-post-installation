# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.3.2"
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
