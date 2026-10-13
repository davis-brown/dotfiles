# Interactive zsh. Environment lives in ~/.zshenv.

setopt EXTENDED_GLOB          # also required by the compinit cache check below
setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# History
HISTFILE=~/.zsh_history
HISTSIZE=50000                # in-memory; keep larger than SAVEHIST so that
SAVEHIST=10000                # dedup has something to dedup against
setopt SHARE_HISTORY          # implies INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS   # supersedes HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# Completion. Rebuilding the dump on every startup is the single biggest
# avoidable cost in a zsh session, so only regenerate it once a day.
autoload -Uz compinit
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}
# Note the explicit missing-file test: the widely copied one-liner uses only
# the (#qN.mh+24) glob, which yields no match when the dump does not exist yet
# and so falls through to the -C (trust the cache) branch on a fresh machine.
if [[ ! -f $_zcompdump || -n ${_zcompdump}(#qN.mh+24) ]]; then
    compinit -d $_zcompdump
else
    compinit -C -d $_zcompdump
fi
unset _zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Up/Down search history for lines starting with what's already typed.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Shared aliases and colors
[[ -f "$HOME/.config/shell/interactive.sh" ]] && source "$HOME/.config/shell/interactive.sh"

# Plugins, installed by install_dev_tools.sh
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"
[[ -f $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]] &&
    source $ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh

# Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Machine-specific zsh config that should not be committed.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Syntax highlighting must be sourced last, after every other zle widget is
# defined, or it will not wrap them.
[[ -f $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] &&
    source $ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export TERM=xterm

# systemd user ssh-agent: keys added once stay loaded until logout
[ -z "$SSH_AUTH_SOCK" ] && [ -S "$XDG_RUNTIME_DIR/openssh_agent" ] && export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/openssh_agent"
