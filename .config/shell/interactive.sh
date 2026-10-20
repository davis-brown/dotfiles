# Interactive-shell aliases and colors.
#
# Sourced from ~/.bashrc, after Omarchy's shell, so anything here wins. Omarchy
# already provides eza-based ls aliases, zoxide's cd and the ".." aliases.

# Color support.
if command -v dircolors >/dev/null 2>&1; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

# Omarchy aliases ls to eza when it is installed; only fall back to colored ls.
if ! command -v eza >/dev/null 2>&1; then
    alias ls='ls --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
fi
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias vim='nvim'
alias vi='nvim'

# less: don't clear the screen on exit, and keep colors.
export LESS='-R --mouse --no-init --quit-if-one-screen'

# Machine-specific interactive settings that should not be committed.
[ -f "$HOME/.shellrc.local" ] && . "$HOME/.shellrc.local"
