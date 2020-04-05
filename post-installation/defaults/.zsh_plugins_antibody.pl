# Command for generating static plugins file
# antibody bundle < ~/.zsh_plugins_antibody.pl > ~/.zsh_plugins_antibody.sh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
robbyrussell/oh-my-zsh path:plugins/command-not-found
robbyrussell/oh-my-zsh path:plugins/git
robbyrussell/oh-my-zsh path:plugins/history
robbyrussell/oh-my-zsh path:plugins/colored-man-pages

# Bundles from ohmyzsh
ohmyzsh/ohmyzsh path:lib/key-bindings.zsh
ohmyzsh/ohmyzsh path:lib/history.zsh

# Node Version Manager
lukechilds/zsh-nvm

# Additional completion definitions for Zsh.
zdharma/fast-syntax-highlighting
zsh-users/zsh-completions
zsh-users/zsh-autosuggestions

# Other plugins
zsh-users/zsh-history-substring-search
alexrochas/zsh-path-environment-explorer
unixorn/autoupdate-antigen.zshplugin

# Theme powerlevel10k
romkatv/powerlevel10k
