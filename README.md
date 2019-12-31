# Description

- Ansible playbook used for installing and configuring software after a system installation
- The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

- OS: Ubuntu 18.04 based distro
- Software: `ansible`

If you do not have ansible installed you can do so by running this piece of code:

```bash
sudo apt update
sudo apt install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

Check if the installation was correct by running

```bash
ansible --version
```

## How to run

```bash
ansible-playbook ./playbook.yml -K -e USERNAME=$(whoami)
```

- USERNAME - defined in `defaults/main.yaml` - can be overridden
- `-K` - flag used to ask for root password

## What's installed
### ZSH and antigen with sane defaults
### Development software
- curl
- git
- vim 
- terminator
- redshift
- redshift-gtk
- nodejs 12
- code
- gitkraken
- postman
- python-pip
---
### General use software
- variety
- flameshot
- bleachbit
- skype
- firefox
- mailspring
- vlc
- rescuetime
- viber
- tixati
- unified remote
- libinput-gestures
---
### Thermal optimization software
- undervolt
- tlp
> It's going to undevolt the core, cache and gpu to `-130mv`, create a service file and start the service, which will undervolt the cpu on boot after a 2 minute delay
> 130mv works on Dell XPS 15 9570 - it may not work on another system

> Look into your specific CPU and laptop model to see how much undervolting your cpu can support. You can also edit the _undervolt.timer_ file to specify exactll when do you want undervolting to take place (default is 2 minutes after boot)
 ---
### Fonts
- hack
- hack nerd font
- roboto
