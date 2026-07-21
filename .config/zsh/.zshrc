# --------------------------------------------------
# Paths base
# --------------------------------------------------

export ZDOTDIR="$HOME/.config/zsh"
export ZSH="$ZDOTDIR/plugins/ohmyzsh"
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

# --------------------------------------------------
# Powerlevel10k instant prompt
# --------------------------------------------------

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --------------------------------------------------
# Completions externas
# Importante: antes de cargar Oh My Zsh
# --------------------------------------------------

fpath=("$ZDOTDIR/plugins/zsh-completions/src" $fpath)

# --------------------------------------------------
# Oh My Zsh
# --------------------------------------------------

ZSH_THEME=""

plugins=(
  git
)

source "$ZSH/oh-my-zsh.sh"

# No correr compinit aquí.
# Oh My Zsh ya lo ejecuta internamente.

# --------------------------------------------------
# Plugins externos
# --------------------------------------------------

source "$ZDOTDIR/plugins/zsh-autopair/autopair.zsh"
source "$ZDOTDIR/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

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
# NVM lazy-load
# --------------------------------------------------

export NVM_DIR="$HOME/.nvm"

load_nvm() {
  unset -f nvm node npm npx
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

nvm() {
  load_nvm
  nvm "$@"
}

node() {
  load_nvm
  node "$@"
}

npm() {
  load_nvm
  npm "$@"
}

npx() {
  load_nvm
  npx "$@"
}

# --------------------------------------------------
# Aliases
# --------------------------------------------------

alias open='xdg-open'
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons'
alias la='eza -lah --icons'
alias lt='eza --tree --level=2 --icons'
