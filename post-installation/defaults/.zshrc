# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Antidote
IS_MAC=$(uname -a | grep -i darwin)
IS_LINUX=$(uname -a | grep -i linux)
if [ $IS_MAC ]; then
    ZDOTDIR=$(brew --prefix)/opt/antidote/share/antidote
    autoload -Uz compinit
    compinit
elif [ $IS_LINUX ]; then
    ZDOTDIR=~/.antidote
    alias bat="batcat"
fi

# Load the antidote plugin manager
source ${ZDOTDIR:-~}/antidote.zsh

# Check if the plugins file is older than the sh file and regenerate it if needed
zsh_plugins=~/.zsh_plugins
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.sh ]]; then
  antidote bundle <${zsh_plugins}.sh >${zsh_plugins}.zsh
fi

# Load the plugins
source ${zsh_plugins}.zsh

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

alias gbc="git branch --show-current"

if [ -s $HOME/ZscalerRootCA.crt ]; then
    export NODE_EXTRA_CA_CERTS="$HOME/ZscalerRootCA.crt"
fi

# Functions

update-antidote() {
    IS_ONLINE=$(ping -c 1 google.com)
    if [ $? -eq 0 ]; then
        echo "Updating antidote plugins"
        if [ $IS_MAC ]; then
            rm -rf ~/Library/Caches/antidote
        elif [ $IS_LINUX ]; then
            rm -rf ~/.cache/antidote
        fi
        antidote bundle <~/.zsh_plugins.sh >~/.zsh_plugins.zsh
    else
        echo "No internet connection"
    fi
}

getJiraTicketNumber() {
    local branchName=$(git branch --show-current)
    echo $branchName | grep -o -E '[A-Z]+-[0-9]+'
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

if [[ -d ~/flutter/bin ]]; then
  PATH=$PATH:~/flutter/bin
fi

if [[ -d ~/.bun/bin ]]; then
  PATH=$PATH:~/.bun/bin
fi

if [[ -d ~/go/bin ]]; then
  PATH=$PATH:~/go/bin
fi

export FZF_TMUX_HEIGHT=50

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# bun completions
[ -s ~/.bun/_bun ] && source ~/.bun/_bun

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
