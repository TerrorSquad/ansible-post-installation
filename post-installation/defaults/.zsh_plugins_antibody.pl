# Command for generating static plugins file
# antibody bundle < ~/.zsh_plugins_antibody.pl > ~/.zsh_plugins_antibody.sh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
robbyrussell/oh-my-zsh path:plugins/command-not-found
robbyrussell/oh-my-zsh path:plugins/git
robbyrussell/oh-my-zsh path:plugins/history
robbyrussell/oh-my-zsh path:plugins/colored-man-pages

# Bundles from ohmyzsh
ohmyzsh/ohmyzsh path:lib/grep.zsh
ohmyzsh/ohmyzsh path:lib/history.zsh
ohmyzsh/ohmyzsh path:lib/key-bindings.zsh
ohmyzsh/ohmyzsh path:lib/theme-and-appearance.zsh
ohmyzsh/ohmyzsh path:plugins/common-aliases

# Node Version Manager
lukechilds/zsh-nvm

# Additional completion definitions for Zsh.
zdharma/fast-syntax-highlighting
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions

# Other plugins
alexrochas/zsh-path-environment-explorer
unixorn/autoupdate-antigen.zshplugin
zsh-users/zsh-history-substring-search

# Theme powerlevel10k
romkatv/powerlevel10k
