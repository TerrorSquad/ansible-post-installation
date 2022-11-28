# Shell startup time benchmark oneliner
# hyperfine 'zsh -i -c exit'

# Command for generating static plugins file
# run from ~
# ping -c 1 google.com && antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.zsh

# Set vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

# Disable double rm -rf verification
setopt rm_star_silent

# Env variables required for plugins
export NVM_LAZY_LOAD=true
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim' 'nvim' 'code' 'java' 'phpstorm' 'intellij-idea-ultimate' 'intellij-idea-community' 'webstorm' 'git' 'gitkraken')

# source antidote
source ${ZDOTDIR:-~}/.antidote/antidote.zsh

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
source ~/.zsh_plugins.zsh

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
alias bxe="bin/xdebug enable"
alias bxd="bin/xdebug disable"
alias open="xdg-open"
alias sail="./vendor/bin/sail"

export BAT_PAGER="less -RF"
alias jt=getJiraTicketNumber

alias gbc="git branch --show-current"

alias jump="ssh g.ninkovic@jump.youweagency.com"

# Functions

getJiraTicketNumber() {
    local branchName=$(git branch --show-current)
    echo $branchName | grep -o -E '[A-Z]+-[0-9]+'
}

restartCinnamon() {
    (nohup cinnamon --replace >/dev/null 2>&1) &
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export FZF_TMUX_HEIGHT=50

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
