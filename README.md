# Description

[![Build Status](https://travis-ci.com/TerrorSquad/ansible-post-installation.svg?branch=master)](https://travis-ci.com/TerrorSquad/ansible-post-installation)

- Ansible playbook used for installing and configuring software after a system installation
- The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

- OS: Ubuntu 20.04 based distro - Linux Mint 20
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
ansible-playbook ./playbook.yml -K -e USERNAME=$(whoami) -e=GIT_SET_USER_DATA=true -e GIT_USER_EMAIL="your@email.com" -e GIT_USER_NAME="Your Name"
```

> Note: You can also pass UNDERVOLT variable. That will call the undervolt.yml role.

```bash
ansible-playbook ./playbook.yml -K -e USERNAME=$(whoami) -e UNDERVOLT=true
```

- USERNAME - defined in `defaults/main.yaml` - can be overridden
- `-K` - flag used to ask for root password

## What's installed

### ZSH and antibody with sane defaults

### Development software

- alacritty
- code
- curl
- dbeaver-ce
- docker
- git
- gitkraken
- graphviz
- htop
- httpstat
- kcachegrind
- make
- nvm with latest nodejs
- postman
- python3-pip
- redshift
- redshift-gtk
- sublime-text
- terminator

---

### General use software

- ag
- bleachbit
- brightnessctl
- dmenu
- exa
- fd-find
- firefox
- flameshot
- google chrome
- i3
- libinput-gestures
- mailspring
- nvim
- onlyoffice-desktopeditors
- openconnect
- papirus-icons-theme
- peco
- rescuetime
- skype
- thefuck
- tixati
- unified remote
- unzip
- variety
- viber
- vim
- vlc
- zoom

---

### Thermal optimization software

- undervolt
- tlp
  > It's going to undevolt the core, cache and gpu to `-130mv`, create a service file and start the service, which will undervolt the cpu on boot after a 2 minute delay
  > 130mv works on Dell XPS 15 9570 - it may not work on another system

> Look into your specific CPU and laptop model to see how much undervolting your cpu can support. You can also edit the _undervolt.timer_ file to specify exactly when do you want undervolting to take place (default is 2 minutes after boot)

---

### Fonts

- hack
- hack nerd font
- roboto

### Scripts

In the `post-installation/defaults/scripts` directory there is a `theme-by-time.sh` bash script which will change the Cinnamon theme and icons based on time of the day.

- Icons - Papirus

- 06:00 - 17:00
  - Theme - Adapta
- 17:00 - 06:00
  - Theme - Adapta-Nokto

You must install these two theme manually. Ansible will copy the script to `~/.local/bin/theme-by-time.sh`.

> Set up autostart to point to this file

## Vagrant

In here you will find a `Vagrantfile` and a `playbook_vagrant.yml` files. These two are set up for working with Vagrant and testing the configuration.

- Install Vagrant

  ```bash
  sudo apt install -y vagrant virtualbox
  ```

- Create a Vagrant box and provision it

  ```bash
  vagrant up --provision
  ```

- Force destroy and recreate the box

  ```bash
  vagrant destroy --force && vagrant up --provision
  ```

> Vagrantfile will use `playbook_vagrant.yml` file as the `Ansible` entrypoint.
>
> Box name `generic/ubuntu2004` - <https://app.vagrantup.com/generic/boxes/ubuntu2004>
>
> Box version - 3.0.34
>
> Box link - <https://app.vagrantup.com/generic/boxes/ubuntu2004/versions/3.0.34>
