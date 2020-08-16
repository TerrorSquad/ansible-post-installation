# Shell startup time benchmark oneliner
# for i in $(seq 1 10); do /usr/bin/time --format=%e zsh -i -c exit; done

# Set vim as default editor
export VISUAL=nvim
export EDITOR="$VISUAL"

alias vim=nvim

restartCinnamon() {
    (nohup cinnamon --replace >/dev/null 2>&1) &
}

# Env variables required for plugins
export NVM_LAZY_LOAD=true
export NVM_LAZY_LOAD_EXTRA_COMMANDS=('vim' 'nvim' 'code' 'java' 'phpstorm' 'webstorm')

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
alias cat="bat --paging=never --style=plain"
alias code="code --goto"
alias hsi="history | rg -i"
alias bm="bin/magento"
alias bxe="bin/xdebug enable"
alias bxd="bin/xdebug disable"

# alias ls="exa"
# alias l="exa -la"
# alias ll="exa -lh --git"
# alias lt="exa -lT --git"

export BAT_PAGER="less -RF"

# Functions
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
