# Environment for every shell.
#
# Sourced from the top of ~/.bashrc, before its interactive-only guard, so that
# non-interactive shells get PATH too, and from ~/.profile for login shells.
# Kept POSIX sh so that ~/.profile can source it under any /bin/sh.
#
# Everything here must be idempotent: rc files are re-read by every nested
# interactive shell (tmux panes, subshells, `exec bash`), and unconditional
# `PATH="$dir:$PATH"` grows PATH by one entry each time.

# OMARCHY_PATH, and mise shims on PATH, on an Omarchy machine. Idempotent, and
# Omarchy's own rc sources it again.
[ -r /usr/share/omarchy/default/bash/env-bootstrap ] && . /usr/share/omarchy/default/bash/env-bootstrap

# Prepend $1 to PATH, but only if it is a real directory and not already there.
path_prepend() {
    [ -d "$1" ] || return 0
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

# Append $1 to PATH, on the same terms as path_prepend.
path_append() {
    [ -d "$1" ] || return 0
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) PATH="${PATH:+$PATH:}$1" ;;
    esac
}

# Homebrew on Apple silicon; Intel Macs use /usr/local/bin, already on PATH.
path_prepend "/opt/homebrew/sbin"
path_prepend "/opt/homebrew/bin"
path_prepend "/usr/local/go/bin"
path_prepend "$HOME/go/bin"
path_prepend "$HOME/.opencode/bin"
path_prepend "$HOME/.local/bin"
# mise-managed tools for shells that never run `mise activate`: scripts, ssh
# commands, editors. Appended, as Omarchy does, so system binaries win.
path_append "$HOME/.local/share/mise/shims"
export PATH

export GOPATH="$HOME/go"

export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='less'
export LESS='-R --mouse'

# Python provider for neovim, if the venv has been created.
if [ -d "$HOME/.local/nvim-venv" ]; then
    export NVIM_PYTHON3="$HOME/.local/nvim-venv/bin/python"
fi

# systemd user ssh-agent: keys added once stay loaded until logout. Arch's
# ssh-agent.socket listens on ssh-agent.socket, Debian's unit on openssh_agent.
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    for _sock in "${XDG_RUNTIME_DIR:-}/ssh-agent.socket" "${XDG_RUNTIME_DIR:-}/openssh_agent"; do
        if [ -S "$_sock" ]; then
            export SSH_AUTH_SOCK="$_sock"
            break
        fi
    done
    unset _sock
fi

# Machine-specific environment that should not be committed.
[ -f "$HOME/.shellenv.local" ] && . "$HOME/.shellenv.local"
