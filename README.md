# Description

[![Build status](https://github.com/TerrorSquad/ansible-post-installation/actions/workflows/build.yml/badge.svg)](https://github.com/TerrorSquad/ansible-post-installation/actions/workflows/build.yml)

- Ansible playbook used for installing and configuring software after a system installation
- The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

- OS: Ubuntu 23.04. (tested with Kubuntu 23.04)
- Software: `ansible`

1. Install ansible
  `sudo apt install ansible`
2. Check if the installation was correct by running
  `ansible --version`

It should print out something similar to this this:

```bash
ansible [core 2.11.3]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/gninkovic/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
  ansible python module location = /home/gninkovic/.local/lib/python3.8/site-packages/ansible
  ansible collection location = /home/gninkovic/.ansible/collections:/usr/share/ansible/collections
  executable location = /home/gninkovic/.local/bin/ansible
  python version = 3.8.10 (default, Sep 28 2021, 16:10:42) [GCC 9.3.0]
  jinja version = 3.0.1
  libyaml = True
```

## How to run

### Clone this repo, enter the directory and run the following command

```bash
cd ~/Downloads \
&& wget https://github.com/TerrorSquad/ansible-post-installation/archive/refs/heads/master.zip \
&& unzip master.zip \
&& cd ansible-post-installation-master
```

### Install all software

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=all=true -e=git_set_user_data=true -e "git_user_email='your@email.com'" -e "git_user_name='Your Name'"
```

#### If you want to only install CLI tools, run the following command

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=cli=true -e=dev_tools_cli=true -e=git_set_user_data=true -e "git_user_email='your@email.com'" -e "git_user_name='Your Name'"
```

#### If you want to only install GUI tools, run the following command

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=gui=true -e=dev_tools_gui=true -e=git_set_user_data=true -e "git_user_email='your@email.com'" -e "git_user_name='Your Name'"
```

### Flags

- `-e all=true` - Installs everything.
- `-e dev_tools_cli=true` - Installs developer tools from `dev_tools_cli.yaml`.
- `-e dev_tools_gui=true` - Installs developer tools from `dev_tools_gui.yaml`.
- `-e cli=true` - Installs general tools from `general_use_software_cli.yaml`.
- `-e gui=true` - Installs general tools from `general_use_software_gui.yaml`.
- `-e gestures=true` - Installs general tools from `libinput_gestures.yaml`.
- `-e docker=true` - Installs and configures docker.
- `-e git_set_user_data=true` - Used to enable updating git user data.
- `-e git_user_email="your@email.com` - Sets git user.email config value. Must be used with `-e git_set_user_data=true`
- `-e git_user_name="Your Name` - Sets git user.name config value. Must be used with `-e git_set_user_data=true`
- `username` - defined in `defaults/main.yaml` - can be overridden. Sets the username of the user for who the configuration should happen.
- `-K` - flag used to ask for root password. Required mostly for installing apt packages and updating apt repositories.

## What's installed

### ZSH and antidote with sane defaults

### Development software

- JetBrains Toolbox
- bat
- bottom
- broot
- btop
- code (Visual Studio Code)
- curl
- curlie
- dbeaver-ce
- delta
- docker
- docker-compose
- duf
- dust
- eza
- fd
- gh
- git
- git-quick-stats
- gitkraken
- gping
- graphviz
- guake
- htop
- httpstat
- hyperfine
- jq
- kcachegrind
- lazydocker
- libutempter0
- lnav
- make
- oha
- postman
- python3-pip
- redshift
- redshift-gtk
- rg
- ripgrep
- sd
- sdkman
- shellcheck
- sublime-text
- terminator
- tokei
- volta with latest nodejs
- xh

---

### General use software

- bleachbit
- fd
- flameshot
- fzf
- google chrome
- httpie
- libinput-gestures
- mailspring
- ncdu
- nvim
- onlyoffice-desktopeditors
- openconnect
- papirus-icon-theme
- peco
- rescuetime
- skype
- slack
- thefuck
- tixati
- unified remote
- unzip
- variety
- viber
- vim
- vlc
- zip
- zoom

### Additional window manager - i3

---

### Fonts

- Hack Mono Nerd Font
- Fira Code Nerd Font
- Fira Mono Nerd Font
- Roboto

## Testing - Vagrant

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
> Box name `generic/ubuntu2204` - <https://app.vagrantup.com/generic/boxes/ubuntu2204>
>
> Box version - 4.3.2
>
> Box link - <https://app.vagrantup.com/generic/boxes/ubuntu2204/versions/4.3.2>
