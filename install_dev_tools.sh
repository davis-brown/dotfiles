#!/bin/bash
set -euo pipefail

log() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
ok()  { echo -e "\033[0;32m[OK]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERR]\033[0m $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS=""
OMARCHY=0

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "${ID:-}" in
            ubuntu|debian)       OS="debian" ;;
            centos|rhel|fedora)  OS="redhat" ;;
            arch|manjaro)        OS="arch" ;;
            *)
                # Derivatives (mint, pop, rocky, endeavouros, ...) declare a parent in ID_LIKE
                case " ${ID_LIKE:-} " in
                    *" debian "*|*" ubuntu "*)      OS="debian" ;;
                    *" rhel "*|*" fedora "*)        OS="redhat" ;;
                    *" arch "*)                     OS="arch" ;;
                    *) err "Unsupported distro: ${ID:-unknown}"; exit 1 ;;
                esac ;;
        esac
    else
        err "Unable to detect OS"; exit 1
    fi
    [[ -d /usr/share/omarchy ]] && OMARCHY=1
    log "Detected $OS$([[ $OMARCHY == 1 ]] && echo " (Omarchy)")"
}

# Only what mise cannot provide: a compiler for treesitter and
# telescope-fzf-native, the shell and its completion, tmux, the clipboard
# tools, and stow. Every other tool comes from mise (install_mise_tools).
install_system_packages() {
    log "Installing system packages..."
    case $OS in
        debian)
            sudo apt-get update -qq
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
                build-essential unzip curl git tmux bash-completion stow \
                xclip wl-clipboard inotify-tools ;;
        redhat)
            sudo dnf groupinstall -y "Development Tools"
            sudo dnf install -y unzip curl git tmux bash-completion stow \
                xclip wl-clipboard inotify-tools ;;
        arch)
            sudo pacman -S --needed --noconfirm \
                base-devel unzip curl git tmux bash-completion stow \
                xclip wl-clipboard inotify-tools ;;
        macos)
            xcode-select -p &>/dev/null || { xcode-select --install; err "Install Xcode CLT then re-run."; exit 1; }
            command -v brew &>/dev/null || {
                log "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
            }
            # macOS ships bash 3.2, too old for the Omarchy shell setup. eza is
            # here because it publishes no macOS builds for mise to install.
            brew install bash bash-completion@2 tmux stow eza ;;
    esac
    ok "System packages installed"
}

install_mise() {
    command -v mise &>/dev/null && { ok "mise already installed"; return; }
    log "Installing mise..."
    case $OS in
        arch)  sudo pacman -S --needed --noconfirm mise ;;
        macos) brew install mise ;;
        # Not packaged for these; the official installer puts it in ~/.local/bin.
        *)     curl -fsSL https://mise.run | sh ;;
    esac
    ok "mise installed"
}

# The ghostty config and the eza and starship icons expect this font. Only on
# machines with fontconfig, i.e. ones that have a desktop to draw it on.
install_font() {
    local dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    case $OS in
        arch)  sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd; return ;;
        macos) brew install --cask font-jetbrains-mono-nerd-font; return ;;
    esac
    command -v fc-cache &>/dev/null || return 0
    [[ -d "$dir" ]] && { ok "JetBrainsMono Nerd Font already installed"; return; }
    log "Installing JetBrainsMono Nerd Font..."
    mkdir -p "$dir"
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
        | tar -xJ -C "$dir"
    fc-cache -f "$dir" >/dev/null
    ok "JetBrainsMono Nerd Font installed"
}

# stow aborts on any target that already exists as a real file (a distro-default
# ~/.bashrc, say). Move those aside first so the run doesn't die under `set -e`.
backup_stow_conflicts() {
    local pkg_dir=$1 target=$2 stamp rel dest
    stamp=$(date +%Y%m%d%H%M%S)
    while IFS= read -r -d '' file; do
        rel=${file#"$pkg_dir"/}
        dest="$target/$rel"
        # Already stowed: $dest resolves through a symlinked parent dir back to
        # the package file itself. Never touch those — that would eat the repo.
        [[ "$dest" -ef "$file" ]] && continue
        if [[ -f "$dest" && ! -L "$dest" ]]; then
            log "Backing up existing $dest -> $dest.pre-stow.$stamp"
            mv "$dest" "$dest.pre-stow.$stamp"
        fi
    done < <(find "$pkg_dir" -name .git -prune -o -type f -print0)
}

link_dotfiles() {
    log "Linking dotfiles from $DOTFILES_DIR..."
    backup_stow_conflicts "$DOTFILES_DIR" "$HOME"
    # The repo root *is* the package, and it lives inside the target ($HOME).
    # Passing --dir=$HOME with package "dotfiles" makes the stow dir equal the
    # target, and stow then refuses to touch anything beneath its own stow dir,
    # silently skipping the whole package. Point --dir at the repo instead and
    # stow ".".
    #
    # --no-folding links file by file into real directories. Otherwise a
    # directory missing from $HOME becomes one symlink into the repo, and
    # whatever programs later write there (conf.d links, state, caches) lands
    # in the working tree.
    stow --no-folding --dir="$DOTFILES_DIR" --target="$HOME" .
    ok "Dotfiles linked"
}

# ~/.config/mise/config.toml (every machine) lists the language tools. Off
# Omarchy, cli-tools.toml adds the command-line tools that Omarchy otherwise
# installs with pacman; it is linked into conf.d, which mise reads globally.
install_mise_tools() {
    local mise_bin conf_d="$HOME/.config/mise/conf.d"
    mise_bin=$(command -v mise || echo "$HOME/.local/bin/mise")

    if [[ $OMARCHY == 0 ]]; then
        mkdir -p "$conf_d"
        ln -sfn ../cli-tools.toml "$conf_d/cli-tools.toml"
    fi

    # Inside the repo, mise sees .config/mise/*.toml as project config and
    # warns until it is trusted.
    "$mise_bin" trust --quiet "$DOTFILES_DIR/.config/mise/config.toml"
    "$mise_bin" trust --quiet "$DOTFILES_DIR/.config/mise/cli-tools.toml"

    log "Installing mise tools..."
    if "$mise_bin" install --yes; then
        ok "mise tools installed"
    else
        err "mise install failed; re-run it once the problem is fixed"
    fi
}

# Earlier versions of this script made zsh the login shell, and macOS defaults
# to zsh; switch to bash (Homebrew's on macOS, since the system one is 3.2).
set_default_shell_bash() {
    local bash_path current user
    user=$(id -un)
    if [[ "$OS" == "macos" ]]; then
        bash_path="$(brew --prefix)/bin/bash"
    else
        bash_path=$(command -v bash)
    fi
    # $SHELL reflects the *running* shell, not the login shell on record.
    if command -v getent &>/dev/null; then
        current=$(getent passwd "$user" | cut -d: -f7)
    else
        current=$(dscl . -read "/Users/$user" UserShell 2>/dev/null | awk '{print $2}')
    fi
    if [[ "$current" == "$bash_path" ]]; then
        ok "bash is already the default shell"
        return
    fi
    grep -qx "$bash_path" /etc/shells 2>/dev/null || echo "$bash_path" | sudo tee -a /etc/shells >/dev/null
    # Plain `chsh` prompts through PAM even with passwordless sudo, which hangs a
    # non-interactive run; go through sudo so it can't block on a password.
    if sudo chsh -s "$bash_path" "$user"; then
        ok "default shell set to $bash_path (log out and back in to apply)"
    else
        err "could not change default shell; run: sudo chsh -s $bash_path $user"
    fi
}

main() {
    log "Installing dev tools..."
    detect_os

    install_system_packages
    install_mise
    install_font
    link_dotfiles
    install_mise_tools
    set_default_shell_bash

    ok "Done! Open a new terminal to pick up the shell config."
}

main "$@"
