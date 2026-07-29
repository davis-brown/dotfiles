# Interactive-shell settings shared by bash and zsh.
#
# Sourced from ~/.bashrc and ~/.zshrc, only for interactive shells. Anything
# shell-specific (setopt/shopt, completion, prompt init) stays in its own rc.

# Color support. dircolors also gives zsh's completion menu its colors.
if command -v dircolors >/dev/null 2>&1; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias vim='nvim'
alias vi='nvim'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# less: don't clear the screen on exit, and keep colors.
export LESS='-R --mouse --no-init --quit-if-one-screen'

# Machine-specific interactive settings that should not be committed.
[ -f "$HOME/.shellrc.local" ] && . "$HOME/.shellrc.local"
