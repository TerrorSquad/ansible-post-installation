# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

ZSH_CACHE_DIR=$HOME/.zsh

fpath=(~/.zsh/completions $fpath)

alias bat="batcat"
ZDOTDIR=~/.antidote
HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"

# Antidote
IS_MAC=$(uname -a | grep -i darwin)
if [ $IS_MAC ]; then
    HOMEBREW_PREFIX="/opt/homebrew"
    ZDOTDIR=${HOMEBREW_PREFIX}/opt/antidote/share/antidote
    unalias bat
fi

export PATH=$HOMEBREW_PREFIX/bin:$PATH
fpath=(${HOMEBREW_PREFIX}/share/zsh/site-functions $fpath)

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

export PATH=$PATH:$HOME/.local/bin

if [[ -d "$HOME/go/bin" ]]; then
  PATH=$PATH:~/go/bin
fi

export FZF_TMUX_HEIGHT=50

# volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
