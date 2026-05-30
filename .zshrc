HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# Enable completion
autoload -Uz compinit
compinit

# Enable starship prompt
eval "$(starship init zsh)"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim'
alias vi='nvim'

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add Go to PATH
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"

# Python virtual environment for neovim (if created)
if [[ -d "$HOME/.local/nvim-venv" ]]; then
    export NVIM_PYTHON3="$HOME/.local/nvim-venv/bin/python"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
