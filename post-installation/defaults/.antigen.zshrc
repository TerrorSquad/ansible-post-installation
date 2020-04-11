source /home/$(whoami)/.antigen.zsh

alias vim=nvim

# Set neovim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

restartCinnamon() {
    (nohup cinnamon --replace >/dev/null 2>&1) &
}
# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle command-not-found
antigen bundle git
antigen bundle history # aliases: h for history, hsi for grepping history

# Enable lazy loading of nvm
export NVM_LAZY_LOAD=true
antigen bundle lukechilds/zsh-nvm

# Additional completion definitions for Zsh.
antigen bundle zdharma/fast-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle greymd/docker-zsh-completion

# Theme
source ~/powerlevel10k/powerlevel10k.zsh-theme

# Font
POWERLEVEL9K_MODE="nerdfont-complete"

# Prompt customization
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="▶ "
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""

OS_ICON="\uF304"

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon root_indicator dir ssh dir_writable vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time status background_jobs history time ram)

HYPHEN_INSENSITIVE="true"

DISABLE_UNTRACKED_FILES_DIRTY="true"

# Aliases
alias c="clear"
alias cjs="npm run compile:js"
alias ccss="npm run compile:scss"
alias nrb="npm run build"
alias tnrb="time npm run build"
alias gs="gss"

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
