# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"

# Shell options
shopt -s checkwinsize
shopt -s globstar
shopt -s cdspell

# Enable color support
if [ -x /usr/bin/dircolors ]; then
    eval "$(dircolors -b)"
fi

# Aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias vim='nvim'
alias vi='nvim'
alias ..='cd ..'
alias ...='cd ../..'

# Environment
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R --mouse'

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"
export PATH="$HOME/.opencode/bin:$PATH"

# Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init bash)"
fi

# Python venv for neovim
if [[ -d "$HOME/.local/nvim-venv" ]]; then
    export NVIM_PYTHON3="$HOME/.local/nvim-venv/bin/python"
fi
