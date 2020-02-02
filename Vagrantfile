# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.box_version = "20200130.1.0"

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
