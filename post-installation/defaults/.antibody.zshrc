# Shell startup time benchmark oneliner
# for i in $(seq 1 10); do /usr/bin/time --format=%e zsh -i -c exit; done

# Set vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

restartCinnamon() {
    (nohup cinnamon --replace &) && rm nohup.out
}

# Env variables required for plugins
export NVM_LAZY_LOAD=true

# Sourcing antibody plugins
source ~/.zsh_plugins_antibody.sh

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
