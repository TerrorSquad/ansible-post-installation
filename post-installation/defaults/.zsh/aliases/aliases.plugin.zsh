alias vim=nvim
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
# Check if we are in WSL via uname
if [[ $(uname -a) == *"WSL"* ]]; then
  alias open="explorer.exe"
fi
# Check if we are in macOS via uname
if [[ $(uname -a) == *"Darwin"* ]]; then
  alias open="open"
fi
alias sail="./vendor/bin/sail"
alias dps="docker ps --format \"table {{.ID}}\t{{.Names}}\t{{.RunningFor}}\t{{.Status}}\""
alias ls="eza --icons=always"
alias gbc="git branch --show-current"
