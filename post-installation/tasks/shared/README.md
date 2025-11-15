# Shared Cross-Platform Tasks

This directory contains Ansible tasks that work across both Linux and macOS platforms, with conditional logic for platform-specific implementations.

## Organization:

### Environment Configuration:
- `shell_environment.yaml` - Shell and terminal setup coordinator
- `development_foundation.yaml` - Version control, editors, CLI tools coordinator

### Programming Languages:
- `programming_languages.yaml` - Programming language environments coordinator

### Development Tools:
- `development_tools.yaml` - Development tools and containerization coordinator

### Cleanup:
- `finalization.yaml` - Cleanup and finalization coordinator

## Individual Components:

### Shell and Environment:
- `zsh.yaml` - Zsh shell configuration
- `general_use_software_cli.yaml` - General CLI applications

### Development Foundation:
- `git.yaml` - Git installation and configuration
- `nvim.yaml` - Neovim editor installation
- `dev_tools_cli.yaml` - Command-line development tools

### Programming Languages:
- `rust.yaml` - Rust programming language installation
- `golang.yaml` - Go programming language installation
- `java.yaml` - Java development kit installation

### Development Tools:
- `docker.yaml` - Docker installation with platform detection
- `ddev.yaml` - DDEV local development environment
- `fonts.yaml` - Font installation across platforms
- `vpn.yaml` - VPN client software

### Utilities:
- `delete_downloaded_files.yaml` - Cleanup of temporary download files

## Utility Directory:
- `utils/` - Reusable utility tasks for common installation patterns
  - `install_github_asset.yaml` - GitHub release asset installer
  - `install_remote_deb.yaml` - Remote .deb package installer

## Platform Detection:
All shared tasks use `ansible_os_family` variable:
- `'Darwin'` for macOS
- `'Debian'` for Linux (Ubuntu, Debian, Linux Mint)

## Usage Pattern:
These tasks contain conditional blocks that execute different logic based on the detected operating system, providing unified installation interfaces across platforms.
