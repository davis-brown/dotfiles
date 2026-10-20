# Environment first, before the interactive guard, so that non-interactive
# bash (ssh host 'cmd', scp, rsync) still gets PATH.
[ -f "$HOME/.config/shell/env.sh" ] && . "$HOME/.config/shell/env.sh"

# Everything below is interactive-only. Without this guard, any future line
# that writes to stdout breaks scp/rsync, which parse the stream.
case $- in
    *i*) ;;
      *) return ;;
esac

# Omarchy's shell: history, completion, aliases, functions, and the mise,
# starship, zoxide and fzf hooks. On Omarchy, use the live copy so it follows
# Omarchy updates; elsewhere, the portable copy kept in this repo.
if [ -n "${OMARCHY_PATH:-}" ] && [ -r "$OMARCHY_PATH/default/bash/rc" ]; then
    . "$OMARCHY_PATH/default/bash/rc"
else
    . "$HOME/.config/shell/omarchy/rc"
fi

# Everything below overrides Omarchy's defaults.

# History: share between terminals as each command finishes. Appended after
# the prompt hooks, because starship reads $? first thing and `history -a`
# ahead of it would reset every exit status to 0. PROMPT_COMMAND is an array
# from bash 5.1 on, and starship and zoxide register themselves that way.
HISTCONTROL=ignoreboth:erasedups
if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )); then
    PROMPT_COMMAND+=("history -a")
else
    # shellcheck disable=SC2128,SC2178 # a plain string before bash 5.1
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a"
fi

# Shell options
shopt -s checkwinsize
shopt -s globstar
shopt -s cdspell
shopt -s autocd 2>/dev/null

# Shared aliases and colors
[ -f "$HOME/.config/shell/interactive.sh" ] && . "$HOME/.config/shell/interactive.sh"

# Machine-specific bash config that should not be committed.
[ -f "$HOME/.bashrc.local" ] && . "$HOME/.bashrc.local"
