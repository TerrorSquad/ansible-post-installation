# Shell startup time benchmark oneliner
# hyperfine 'zsh -i -c exit'

# Command for generating static plugins file
# run from ~
# ping -c 1 google.com && rm -rf ~/.cache/antibody && antibody bundle < ~/.zsh_plugins_antibody.pl > ~/.zsh_plugins_antibody.sh

# Set vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

# Disable double rm -rf verification
setopt rm_star_silent

# Env variables required for plugins
export NVM_LAZY_LOAD=true
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim' 'nvim' 'code' 'java' 'phpstorm' 'intellij-idea-ultimate' 'intellij-idea-community' 'webstorm' 'git' 'gitkraken')

# Sourcing antibody plugins
source ~/.zsh_plugins_antibody.sh

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

alias ls="exa --icons"
alias l="ls -la"
alias ll="ls -lh --git"
alias lt="ls -lT --git"

export BAT_PAGER="less -RF"

# Functions

restartCinnamon() {
    (nohup cinnamon --replace >/dev/null 2>&1) &
}

getProgramPids() {
    PROGRAM=$1
    local result=$(ps aux | grep ${PROGRAM} | grep -v grep | tr -s ' ' | cut -d ' ' -f 2)
    echo $result
}

killByPid() {
    PROGRAM=$1
    local PIDS=$(getProgramPids ${PROGRAM})
    if [ $PIDS ]; then
        return kill ${PIDS}
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
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
