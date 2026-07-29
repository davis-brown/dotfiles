# Environment shared by bash and zsh.
#
# Sourced from ~/.zshenv (zsh) and the top of ~/.bashrc (bash), i.e. before any
# interactive-only guard, so that non-interactive shells get PATH too.
#
# Everything here must be idempotent: rc files are re-read by every nested
# interactive shell (tmux panes, subshells, `exec zsh`), and unconditional
# `PATH="$dir:$PATH"` grows PATH by one entry each time.

# Prepend $1 to PATH, but only if it is a real directory and not already there.
path_prepend() {
    [ -d "$1" ] || return 0
    case ":${PATH}:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

path_prepend "/usr/local/go/bin"
path_prepend "$HOME/go/bin"
path_prepend "$HOME/.opencode/bin"
path_prepend "$HOME/.local/bin"
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

# Machine-specific environment that should not be committed.
[ -f "$HOME/.shellenv.local" ] && . "$HOME/.shellenv.local"
