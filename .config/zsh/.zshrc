# --------------------------------------------------
# Paths base
# --------------------------------------------------

export ZDOTDIR="$HOME/.config/zsh"
export ZSH="$ZDOTDIR/plugins/ohmyzsh"

# --------------------------------------------------
# Powerlevel10k instant prompt
# --------------------------------------------------

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --------------------------------------------------
# Oh My Zsh
# --------------------------------------------------

ZSH_THEME=""

plugins=(
  git
)

source "$ZSH/oh-my-zsh.sh"

# --------------------------------------------------
# Completions externas
# --------------------------------------------------

fpath=("$ZDOTDIR/plugins/zsh-completions/src" $fpath)

autoload -Uz compinit
compinit

# --------------------------------------------------
# Plugins externos
# --------------------------------------------------

source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$ZDOTDIR/plugins/zsh-autopair/autopair.zsh"

# --------------------------------------------------
# Theme Powerlevel10k
# --------------------------------------------------

source "$ZDOTDIR/themes/powerlevel10k/powerlevel10k.zsh-theme"

[[ -f "$ZDOTDIR/.p10k.zsh" ]] && source "$ZDOTDIR/.p10k.zsh"

# --------------------------------------------------
# Micromamba
# --------------------------------------------------

export MAMBA_EXE="$HOME/.local/bin/micromamba"
export MAMBA_ROOT_PREFIX="$HOME/micromamba"

if [[ -x "$MAMBA_EXE" ]]; then
  __mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2>/dev/null)"
  if [[ $? -eq 0 ]]; then
    eval "$__mamba_setup"
  else
    alias micromamba="$MAMBA_EXE"
  fi
  unset __mamba_setup
fi

# --------------------------------------------------
# NVM
# --------------------------------------------------

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# --------------------------------------------------
# Aliases
# --------------------------------------------------

alias open='xdg-open'
