# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu1804"
  config.vm.box_version = "2.0.6"
  ENV['LC_ALL']="en_US.UTF-8"

  #
  # Run Ansible from the Vagrant Host
  #
  config.vm.provision "ansible" do |ansible|
    ansible.groups = {
      'vagrant' => ['default']
    }

    ansible.playbook = "playbook_vagrant.yml"
    ansible.verbose = "vv"
  end
end
