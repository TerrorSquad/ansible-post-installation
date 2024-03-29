# Load the antidote plugin manager
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# Check if the plugins file is older than the txt file and regenerate it if needed
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
fi
# Load the plugins
source ${zsh_plugins}.zsh

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Set nvim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

# Disable double rm -rf verification.
# What it does exactly is that it removes the prompt that asks you to confirm the deletion of files and directories.
setopt rm_star_silent

# Aliases
alias c="clear"
alias cjs="npm run compile:js"
alias ccss="npm run compile:scss"
alias nrb="npm run build"
alias tnrb="time npm run build"
alias gs="gss"
alias bat="batcat"
alias code="code --goto"
alias hsi="history | rg -i"
alias bm="bin/magento"
alias bdm="bin/debug-magento"
alias bxe="bin/xdebug enable"
alias bxd="bin/xdebug disable"
alias open="xdg-open"
alias sail="./vendor/bin/sail"
alias dps="docker ps --format \"table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\""

export BAT_PAGER="less --mouse -RF"
export LESS="--mouse -RF"
alias jt=getJiraTicketNumber

alias gbc="git branch --show-current"

# Functions

update-antidote() {
    ping -c 1 google.com && rm -rf ~/.cache/antidote && antidote bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.zsh
}

bench() {
    hyperfine 'zsh -i -c exit' --warmup 3
}


getProgramPids() {
    PROGRAM=$1
    local result=$(ps aux | grep ${PROGRAM} | grep -v grep | tr -s ' ' | cut -d ' ' -f 2)
    echo $result
}

kill_by_name() {
    PROGRAM=$1
    local PIDS=$(getProgramPids ${PROGRAM})
    if [ $PIDS ]; then
        echo ${PIDS} | xargs kill -9
        return $?
    else
        echo "PROGRAM IS STOPPED"
        return 1
    fi
}

kill_port() {
    if [ $# -eq 0 ]; then
        echo "No arguments provided"
        echo "provide port of service you wish to kill"
        exit 1
    fi
    fuser -k $1/tcp
}


PATH=$PATH:~/.local/bin

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export FZF_TMUX_HEIGHT=50

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
# export SDKMAN_DIR="$HOME/.sdkman"
# [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "/home/gninkovic/.bun/_bun" ] && source "/home/gninkovic/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
