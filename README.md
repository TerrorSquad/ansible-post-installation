# Description

* Ansible playbook used for installing and configuring software after a system installation
* The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

* OS: Ubuntu 18.04 based distro
* Software: `ansible` 

If you do not have ansible installed you can do so by running this piece of code:

``` bash
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

Check if the instalation was correct by running

``` bash
ansible --version
```

## How to run

``` bash
ansible-playbook ./playbook.yml -K -e USERNAME=$(whoami)
```

* USERNAME - defined in `defaults/main.yaml` - can be overriden
* `-K` - flag used to ask for root password

## TODO:

* Install and run undervolt
