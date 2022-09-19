# Command for generating static plugins file
# run from ~
# ping -c 1 google.com && rm -rf ~/.cache/antibody && antibody bundle < ~/.zsh_plugins_antibody.pl > ~/.zsh_plugins_antibody.sh

# Theme
romkatv/powerlevel10k

# Bundles from the default repo (robbyrussell's oh-my-zsh).
robbyrussell/oh-my-zsh
robbyrussell/oh-my-zsh path:plugins/command-not-found
robbyrussell/oh-my-zsh path:plugins/git
robbyrussell/oh-my-zsh path:plugins/history

# Bundles from ohmyzsh
ohmyzsh/ohmyzsh path:lib/directories.zsh
ohmyzsh/ohmyzsh path:lib/completion.zsh
ohmyzsh/ohmyzsh path:lib/history.zsh
ohmyzsh/ohmyzsh path:lib/key-bindings.zsh
ohmyzsh/ohmyzsh path:lib/theme-and-appearance.zsh

# Node Version Manager
lukechilds/zsh-nvm

# Additional completion definitions for Zsh.
zsh-users/zsh-autosuggestions
zsh-users/zsh-completions
zdharma-continuum/fast-syntax-highlighting

ael-code/zsh-colored-man-pages
changyuheng/fz
rupa/z
