# Post-Installation Role

This role handles the core logic for the Griffin automation suite. It is designed to be cross-platform (Linux/macOS) and modular.

## Variables

The role uses a split variable structure:
- `vars/debian.yaml`: Linux-specific paths and settings.
- `vars/darwin.yaml`: macOS-specific paths and settings.
- `defaults/main.yaml`: Common default settings and feature flags.

### Feature Flags

You can enable specific features by passing variables or using tags (see below).

| Variable | Default | Description |
|----------|---------|-------------|
| `gui` | `false` | Installs general GUI applications (browsers, chat apps, etc.) |
| `dev_tools_gui` | `false` | Installs GUI development tools (IDEs, DB clients) |
| `docker` | `false` | Installs Docker and Docker Compose |
| `rust` | `false` | Installs Rust toolchain |
| `golang` | `false` | Installs Go toolchain |
| `java` | `false` | Installs Java (SDKMan) |
| `fonts` | `false` | Installs Nerd Fonts |
| `vpn` | `false` | Installs VPN clients |
| `all` | `false` | Enables ALL features |

## Tags

Tags allow you to run specific parts of the playbook. Using a tag automatically enables the corresponding feature flag.

| Tag | Description | Implied Variable |
|-----|-------------|------------------|
| `system` | System preparation (apt update, basic packages) | - |
| `core` | Core tools (curl, git, zsh, etc.) | - |
| `shell` | Shell configuration (Oh My Zsh, Powerlevel10k) | - |
| `dev` | Development foundation (git config, neovim) | - |
| `languages` | Programming languages | - |
| `rust` | Rust installation | `rust=true` |
| `golang` | Go installation | `golang=true` |
| `java` | Java installation | `java=true` |
| `dev-tools` | Development tools | `dev_tools_gui=true` |
| `docker` | Docker installation | `docker=true` |
| `ddev` | DDEV installation | - |
| `fonts` | Fonts installation | `fonts=true` |
| `vpn` | VPN installation | `vpn=true` |
| `gui` | GUI applications | `gui=true` |
| `cleanup` | Final cleanup tasks | - |

### Example Usage

Run only shell configuration:
```bash
ansible-playbook playbook.yaml -K -e username=$(whoami) --tags "shell"
```

Install only Rust and Go:
```bash
ansible-playbook playbook.yaml -K -e username=$(whoami) --tags "rust,golang"
```

## Directory Structure

- `tasks/`: Main task definitions
  - `debian/`: Linux-specific tasks
  - `darwin/`: macOS-specific tasks
  - `shared/`: Cross-platform tasks
- `vars/`: OS-specific variable definitions
- `defaults/`: Default variable values
- `handlers/`: Event handlers (e.g., cache updates)
