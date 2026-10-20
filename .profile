# ~/.profile: read by login shells. Kept in sync with the distro default,
# except that PATH is set via .config/shell/env.sh rather than by prepending
# directly.
#
# The stock Ubuntu .profile sources ~/.bashrc first and only then prepends
# ~/.local/bin, so that directory ends up in PATH twice. path_prepend is
# idempotent, so ordering no longer matters here.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

[ -f "$HOME/.config/shell/env.sh" ] && . "$HOME/.config/shell/env.sh"

# The stock file adds this one; env.sh does not, since it is rarely used.
if [ -d "$HOME/bin" ]; then
    case ":${PATH}:" in
        *":$HOME/bin:"*) ;;
        *) PATH="$HOME/bin${PATH:+:$PATH}" ;;
    esac
    export PATH
fi
