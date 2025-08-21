update-antidote() {
    IS_ONLINE=$(ping -c 1 google.com)
    if [ $? -eq 0 ]; then
        echo "Updating antidote plugins"
        if [ $IS_MAC ]; then
            rm -rf ~/Library/Caches/antidote
        elif [ $IS_LINUX ]; then
            rm -rf ~/.cache/antidote
        fi
        antidote update
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

if [[ $(uname -a) != *"Darwin"* ]]; then
    phpstorm() {
        nohup $HOME/.local/bin/phpstorm "$@" &>/dev/null &
        disown
    }
fi

sudohx() {
    sudo $(which hx) "$@"
}

sudonvim() {
    sudo $(which nvim) "$@"
}

sudosd() {
    sudo $(which sd) "$@"
}

restartPlasma() {
    kquitapp6 plasmashell || kstart plasmashell
}
