# Environment first, before the interactive guard, so that non-interactive
# bash (ssh host 'cmd', scp, rsync) still gets PATH.
[ -f "$HOME/.config/shell/env.sh" ] && . "$HOME/.config/shell/env.sh"

# Everything below is interactive-only. Without this guard, any future line
# that writes to stdout breaks scp/rsync, which parse the stream.
case $- in
    *i*) ;;
      *) return ;;
esac

# History
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend
PROMPT_COMMAND="history -a; ${PROMPT_COMMAND}"

# Shell options
shopt -s checkwinsize
shopt -s globstar
shopt -s cdspell
shopt -s autocd 2>/dev/null

# Completion
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Shared aliases and colors
[ -f "$HOME/.config/shell/interactive.sh" ] && . "$HOME/.config/shell/interactive.sh"

# Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi

# Machine-specific bash config that should not be committed.
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
