# Description

[![Build status](https://github.com/TerrorSquad/ansible-post-installation/actions/workflows/build.yml/badge.svg)](https://github.com/TerrorSquad/ansible-post-installation/actions/workflows/build.yml)

- Ansible playbook used for installing and configuring software after a system installation
- The playbook should be run as root user (-K flag) and the user name of the non-root user should be passed as an extra argument or defined in defaults/main.yaml.

## Requirements

- OS: Ubuntu 23.04. (tested with Kubuntu 23.04)
- Software: `ansible`

If you do not have ansible installed you can do so by running this piece of code:

```bash
sudo apt install ansible
```

Check if the installation was correct by running

```bash
ansible --version
```

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

Clone this repo, enter the directory and run the following command:

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=all=true -e=git_set_user_data=true -e git_user_email="your@email.com" -e git_user_name="Your Name"
```

If you want to only install CLI tools, run the following command:

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=cli=true -e=dev_tools_cli=true -e=git_set_user_data=true -e git_user_email="gninkovic@euronetworldwide.com" -e git_user_name="Goran Ninkovic"
```

If you want to only install GUI tools, run the following command:

```bash
ansible-playbook ./playbook.yml -K -e username=$(whoami) -e=gui=true -e=dev_tools_gui=true -e=git_set_user_data=true -e git_user_email="your@email.com" -e git_user_name="Your Name"
```

### Flags
- `-e all=true` - Installs everything.
- `-e dev_tools_cli=true` - Installs developer tools from `dev_tools_cli.yaml`.
- `-e dev_tools_gui=true` - Installs developer tools from `dev_tools_gui.yaml`.
- `-e cli=true` - Installs general tools from `general_use_software_cli.yaml`.
- `-e gui=true` - Installs general tools from `general_use_software_gui.yaml`.
- `-e gaming=true` - Installs general tools from `gaming_software_gui.yaml`.
- `-e gestures=true` - Installs general tools from `libinput_gestures.yaml`.
- `-e docker=true` - Installs and configures docker.
- `-e git_set_user_data=true` - Used to enable updating git user data.
- `-e git_user_email="your@email.com` - Sets git user.email config value. Must be used with `-e git_set_user_data=true`
- `-e git_user_name="Your Name` - Sets git user.name config value. Must be used with `-e git_set_user_data=true`
- `-e undervolt=true` - Calls the `undervolt.yml` role.
- `-e use_snap=true` - Enables snap and snapd. No snap packages will be installed.
- `username` - defined in `defaults/main.yaml` - can be overridden. Sets the username of the user for who the configuration should happen.
- `-K` - flag used to ask for root password. Required mostly for installing apt packages and updating apt repositories.

## What's installed

### ZSH and antidote with sane defaults

### Development software

- JetBrains Toolbox
- bat
- code (Visual Studio Code)
- ctop
- curl
- dbeaver-ce
- delta
- dust
- duf
- bottom
- curlie
- albert
- docker
- docker-compose
- git
- gitkraken
- graphviz
- guake
- htop
- httpstat
- hyperfine
- jq
- kcachegrind
- lazydocker
- libutempter0
- make
- nvm with latest nodejs
- postman
- python3-pip
- redshift
- redshift-gtk
- rg
- sdkman
- shellcheck
- sublime-text
- terminator

---

### General use software

- bleachbit
- exa
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
- papirus-icons-theme
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

In the `post-installation/defaults/scripts` directory there is a `theme_changer.sh` bash script which will change the Cinnamon theme and icons based on time of the day.

- Icons - Papirus

- 06:00 - 17:00
  - Theme - Arc
- 17:00 - 06:00
  - Theme - Arc-Dark

> This script will autostart after the next system restart.

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
