# Debian-Based System Tasks

This directory contains Ansible tasks that are specific to Debian-based systems (Ubuntu, Linux Mint, Debian).

## Organization:

### Core System Files:
- `system_setup.yaml` - Initial system preparation and basic packages
- `core_tools.yaml` - Package managers and essential tools

### GUI and Applications:
- `gui_applications.yaml` - GUI applications coordinator
- `dev_tools_gui.yaml` - GUI development tools
- `general_use_software_gui.yaml` - General GUI applications

### System Customization:
- `libinput_gestures.yaml` - Touchpad gesture configuration
- `themes.yaml` - Theme configuration (Linux Mint)
- `dconf.yaml` - Desktop configuration (Linux Mint)

### Infrastructure:
- `basic_packages.yaml` - Essential system packages via APT
- `homebrew.yaml` - Homebrew installation for Linux
- `i3.yaml` - i3 window manager configuration
- `update_apt_cache_and_prepare_download_dir.yaml` - APT setup
- `clean_apt.yaml` - APT cache cleanup

## Platform Requirements:
- Debian-based Linux distributions (Ubuntu, Linux Mint, Debian)
- APT package manager
- Systemd init system
