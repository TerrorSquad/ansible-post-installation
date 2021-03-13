# Shell startup time benchmark oneliner
# hyperfine 'zsh -i -c exit'

# Set vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

# Env variables required for plugins
export NVM_LAZY_LOAD=true
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim' 'nvim' 'code' 'java' 'phpstorm' 'intellij-idea-ultimate' 'intellij-idea-community' 'webstorm' 'git')

# Sourcing antibody plugins
source ~/.zsh_plugins_antibody.sh

# Aliases
alias c="clear"
alias cjs="npm run compile:js"
alias ccss="npm run compile:scss"
alias nrb="npm run build"
alias tnrb="time npm run build"
alias gs="gss"
alias fd="fdfind"
alias bat="batcat"
alias code="code --goto"
alias hsi="history | rg -i"
alias bm="bin/magento"
alias bxe="bin/xdebug enable"
alias bxd="bin/xdebug disable"
alias open="xdg-open"

# alias ls="exa"
# alias l="exa -la"
# alias ll="exa -lh --git"
# alias lt="exa -lT --git"

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

update_vsf_config() {
    VSF_GIT_CONFIG=~/improved-potato

    VSF_PROJECT=~/Projects/paperchase/vsf
    VSF_API_PROJECT=~/Projects/paperchase/vsf-api
    # Copy config files
    cp $VSF_PROJECT/config/local.json $VSF_GIT_CONFIG/vsf.local.json
    cp $VSF_API_PROJECT/config/local.json $VSF_GIT_CONFIG/vsf-api.local.json

    # Git add, commit and push
    cd $VSF_GIT_CONFIG
    git add $VSF_GIT_CONFIG/vsf.local.json
    git add $VSF_GIT_CONFIG/vsf-api.local.json
    git commit -m "config: update config files"
    git push
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
