# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_CACHE_DIR=$HOME/.zsh

# Load default zsh completions
if [ -d "$HOME/.zsh/completions" ]; then
  fpath=(~/.zsh/completions $fpath)
fi

# Antidote
IS_MAC=$(uname -a | grep -i darwin)
IS_LINUX=$(uname -a | grep -i linux)
if [ $IS_MAC ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    ZDOTDIR=${HOMEBREW_PREFIX}/opt/antidote/share/antidote
elif [ $IS_LINUX ]; then
    ZDOTDIR=~/.antidote
    alias bat="batcat"
    HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

# Load Homebrew's zsh-completions
if [ -d "${HOMEBREW_PREFIX}/share/zsh/site-functions" ]; then
  fpath=(${HOMEBREW_PREFIX}/share/zsh/site-functions $fpath)
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

# Disable double rm -rf verification.
# What it does exactly is that it removes the prompt that asks you to confirm the deletion of files and directories.
setopt rm_star_silent

export BAT_PAGER="less --mouse -RF"
export LESS="--mouse -RF"

if [ -s $HOME/.ZscalerRootCA.crt ]; then
    export NODE_EXTRA_CA_CERTS="$HOME/.ZscalerRootCA.crt"
fi

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

if [[ -d /home/linuxbrew/.linuxbrew/bin ]]; then
  PATH=$PATH:/home/linuxbrew/.linuxbrew/bin
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
