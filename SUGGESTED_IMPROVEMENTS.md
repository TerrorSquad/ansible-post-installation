# Suggested Improvements

## 1. Idempotency & Task Safety

- **`shell` and `command` modules**: Several tasks use `shell` or `command` without `changed_when` or `creates` parameters. This makes it hard to determine if a change actually occurred and breaks idempotency.
    - *Example*: `post-installation/tasks/shared/zsh.yaml` (Antidote installation)
    - *Recommendation*: Use `creates` to check for existing files or `changed_when` to parse output.
    - **Status**: ✅ Added `changed_when` and `creates` to all `shell` and `command` tasks.
- **`apt` retries**: As noted in recent fixes, `retries` on `apt` tasks don't work without an `until` loop.
    - *Recommendation*: Implement a standard retry loop pattern for all network-dependent tasks (apt, get_url, git, etc.) or use a custom block/rescue strategy.
    - **Status**: ✅ Implemented standard retry loop pattern with `register` and `until` across all tasks.

## 2. Variable Management

- **`defaults/main.yaml` bloat**: This file is getting large.
    - *Recommendation*: Split variables into platform-specific files (e.g., `defaults/debian.yaml`, `defaults/darwin.yaml`) and load them conditionally, or use `vars/` for static data and keep `defaults/` for user-overridable settings.
    - **Status**: ✅ Split variables into `vars/debian.yaml` and `vars/darwin.yaml` and loaded them in `tasks/main.yaml`.
- **Hardcoded Paths**: There are still some hardcoded paths or assumptions about user home directories in scripts.
    - *Recommendation*: consistently use `{{ user_home }}` and other variables.
    - **Status**: ✅ Replaced hardcoded paths (`/bin/bash`, `/usr/bin/bash`, `/usr/local/bin`, etc.) with variables (`bash_executable`, `system_bin`) defined in platform-specific vars files.

## 3. Testing & CI

- **Molecule**: Consider adding Molecule for local testing of roles. This allows for more granular testing than the current "run the whole playbook" approach.
- **Linting**: Add `ansible-lint` to the CI pipeline to catch issues early. The current `reviewdog` setup is good, but a strict local linting step (pre-commit hook) would be better.
    - **Status**: ✅ Added `.ansible-lint` config and `.github/workflows/lint.yaml` for strict CI linting.

## 4. Documentation

- **Role Documentation**: The `post-installation` role could have its own `README.md` detailing input variables and example usage.
- **Developer Guide**: A guide on how to add new tools (similar to what was added to `copilot-instructions.md`) would be beneficial for contributors.

## 5. Code Structure

- **Handlers**: Use handlers for service restarts (if any) or cache updates instead of running them as tasks.
    - **Status**: ✅ Moved `fc-cache` update to a handler in `post-installation/handlers/main.yaml`.
- **Tags**: Ensure all tasks have appropriate tags. This allows users to run specific parts of the setup (e.g., `ansible-playbook ... --tags "dotfiles,zsh"`).
    - **Status**: ✅ Added high-level tags (`system`, `core`, `shell`, `dev`, `languages`, `gui`, `cleanup`) to `post-installation/tasks/main.yaml`.
    - **Status**: ✅ Implemented "Tags imply Variables" logic so running `--tags gui` automatically enables `gui=true`.
- **Block/Rescue**: Use `block` and `rescue` for critical sections that might fail, providing better error messages or fallback mechanisms.

## 6. Specific Task Improvements

- **`zsh.yaml`**: The Antidote installation logic is complex. It could be moved to a dedicated script or a custom module if it grows further.
- **`fonts.yaml`**: The URL parsing for Nerd Fonts is fragile. If the release asset naming scheme changes, it will break.
    - *Recommendation*: Use a more robust method to find the correct asset URL, perhaps by querying the GitHub API more specifically or using a dedicated Ansible collection for fonts if available.
