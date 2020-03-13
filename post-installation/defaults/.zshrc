source /home/$(whoami)/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle command-not-found
# antigen bundle common-aliases     # Common aliases like ll and la
antigen bundle git
# antigen bundle history            # aliases: h for history, hsi for grepping history
# antigen bundle npm                # support for NodeJS package manager
antigen bundle thefuck

# Additional completion definitions for Zsh.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-history-substring-search
antigen bundle alexrochas/zsh-git-semantic-commits
antigen bundle alexrochas/zsh-path-environment-explorer
antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle arialdomartini/oh-my-git
antigen bundle lukechilds/zsh-nvm
# antigen bundle lukechilds/zsh-better-npm-completion
# antigen bundle voronkovich/gitignore.plugin.zsh
# antigen bundle jessarcher/zsh-artisan

# Load the theme.
antigen theme bhilburn/powerlevel9k powerlevel9k

# Font
POWERLEVEL9K_MODE="nerdfont-complete"
# POWERLEVEL9K_DISABLE_RPROMPT=true

# Prompt customization
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="▶ "
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""

OS_ICON="\uF304"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon context dir rbenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)

HYPHEN_INSENSITIVE="true"

DISABLE_UNTRACKED_FILES_DIRTY="true"

# Aliases
alias c="clear"
alias cjs="npm run compile:js"
alias ccss="npm run compile:scss"
alias nrb="npm run build"
alias tnrb="time npm run build"
alias gs="gss"
alias pestle="bin/cli php pestle.phar"
# phpstormAlias() {
# 	cd /home/$(whoami)/opt;
# 	PHP_DIRECTORY_NAME=$(ls . | grep PhpStorm*);
# 	cd $PHP_DIRECTORY_NAME/bin;
# 	alias phpstorm=$(pwd)/phpstorm.sh
# 	cd
# }
# phpstormAlias

man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}

# Tell Antigen that you're done.
antigen apply
