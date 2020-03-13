# Description

- Ansible playbook used for installing and configuring software after a system installation
- The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

- OS: Ubuntu 18.04 based distro - Linux Mint 19.3
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
- code
- curl
- dbeaver-ce
- docker
- git
- gitkraken
- htop
- httpstat
- make
- nodejs 12
- postman
- python-pip
- redshift
- redshift-gtk
- terminator
- vim
---
### General use software
- bleachbit
- firefox
- flameshot
- libinput-gestures
- mailspring
- onlyoffice-desktopeditors
- papirus-icons-theme
- rescuetime
- skype
- thefuck
- tixati
- unified remote
- unzip
- variety
- viber
- vlc
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


### Scripts
In the `post-installation/defaults/scripts` directory there is a `theme-by-time.sh` bash script which will change the Cinnamon theme and icons based on time of the day.
- 06:00 - 17:00
    - Theme - Adapta
    - Icons - Papirus-Adapta
- 17:00 - 06:00
    - Theme - Adapta-Nokto
    - Icons - Papirus-Adapta-Nokto

You must install these two theme manually. Ansible will copy the script to `~/.local/bin/theme-by-time.sh`.

> Set up autostart to point to this file

## Vagrant
In here you will vind a `Vagrantfile` and a `playbook_vagrant.yml` files. These two are set up for working with Vagrant and testing the configuration.
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
> Box name `ubuntu/bionic64` - https://app.vagrantup.com/ubuntu/boxes/bionic64/
>
> Box version - 20200130.1.0
>
> Box link - https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20200130.1.0
