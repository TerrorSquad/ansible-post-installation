# Theme
romkatv/powerlevel10k

~/.zsh/functions/compinit.plugin.zsh kind:defer

# Jump around in your shell
changyuheng/fz kind:defer
rupa/z kind:defer

# Additional completion definitions for Zsh.
zsh-users/zsh-completions kind:defer

# Open a file or repository in the web by using the `git open` command
paulirish/git-open kind:defer

# A collection of oh-my-zsh libraries

# History must not be deferred
ohmyzsh/ohmyzsh path:lib/history.zsh

ohmyzsh/ohmyzsh path:lib/theme-and-appearance.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/git.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/grep.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/key-bindings.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/completion.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/functions.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/misc.zsh kind:defer
ohmyzsh/ohmyzsh path:lib/correction.zsh kind:defer

# A collection of oh-my-zsh plugins

ohmyzsh/ohmyzsh path:plugins/command-not-found kind:defer
ohmyzsh/ohmyzsh path:plugins/git kind:defer
ohmyzsh/ohmyzsh path:plugins/history kind:defer
ohmyzsh/ohmyzsh path:plugins/bun kind:defer
ohmyzsh/ohmyzsh path:plugins/colored-man-pages kind:defer
ohmyzsh/ohmyzsh path:plugins/rust kind:defer
ohmyzsh/ohmyzsh path:plugins/fzf kind:defer

# Provides suggestions as you type
zsh-users/zsh-autosuggestions kind:defer

# Provides syntax highlighting for the shell
zdharma-continuum/fast-syntax-highlighting kind:defer

# Provides a tab completion system for the shell with fzf
Aloxaf/fzf-tab kind:defer

~/.zsh/aliases/aliases.plugin.zsh kind:defer
~/.zsh/aliases/directories.plugin.zsh kind:defer
~/.zsh/functions/functions.plugin.zsh kind:defer

# This adds the zsh-bench function to benchmark the shell startup time.
# romkatv/zsh-bench kind:path

wintermi/zsh-mise kind:defer
