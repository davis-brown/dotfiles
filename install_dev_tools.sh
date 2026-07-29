#!/bin/bash
set -euo pipefail

log() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
ok()  { echo -e "\033[0;32m[OK]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERR]\033[0m $1"; }

OS=""
ARCH=""       # x86_64 | arm64      (neovim, lazygit asset naming)
ARCH_MUSL=""  # x86_64 | aarch64    (starship asset naming)
APT_UPDATED=0

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
    log "Detected $OS"
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  ARCH="x86_64"; ARCH_MUSL="x86_64" ;;
        aarch64|arm64) ARCH="arm64";  ARCH_MUSL="aarch64" ;;
        *) err "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac
    log "Detected $ARCH"
}

# apt installs fail on a fresh box whose package lists are stale/empty; refresh once.
apt_update_once() {
    [[ $APT_UPDATED -eq 1 ]] && return
    log "Refreshing apt package lists..."
    sudo apt-get update -qq
    APT_UPDATED=1
}

apt_install() {
    apt_update_once
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"
}

# Latest release tag for a GitHub repo, minus the leading "v".
# Falls back to a pinned version when the API is unreachable or rate-limited.
latest_release() {
    local repo=$1 fallback=$2 ver=""
    ver=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null \
          | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1) || ver=""
    [[ -z "$ver" ]] && ver="$fallback"
    echo "$ver"
}

# install_pkg <package> [binary]
# The provided binary defaults to the package name, but they differ for some
# packages (ripgrep ships `rg`) and the check has to use the binary or the
# "already installed" path never fires.
install_pkg() {
    local name=$1 bin=${2:-$1}
    command -v "$bin" &>/dev/null && { ok "$name already installed"; return; }
    log "Installing $name..."
    case $OS in
        debian) apt_install "$name" ;;
        redhat) sudo dnf install -y "$name" 2>/dev/null || sudo yum install -y "$name" ;;
        arch)   sudo pacman -S --needed --noconfirm "$name" ;;
        macos)  brew install "$name" ;;
    esac
    ok "$name installed"
}

install_build_tools() {
    log "Installing build tools (gcc, make, unzip)..."
    case $OS in
        debian) apt_install gcc make unzip curl ;;
        redhat) sudo dnf groupinstall -y "Development Tools" && sudo dnf install -y unzip curl ;;
        arch)   sudo pacman -S --needed --noconfirm base-devel unzip curl ;;
        macos)
            xcode-select -p &>/dev/null || { xcode-select --install; err "Install Xcode CLT then re-run."; exit 1; }
            brew install make ;;
    esac
    ok "Build tools installed"
}

install_neovim() {
    # Check if neovim >= 0.10 is already installed
    if command -v nvim &>/dev/null; then
        local ver major minor
        ver=$(nvim --version | head -1 | sed 's/NVIM v//')
        major=$(echo "$ver" | cut -d. -f1)
        minor=$(echo "$ver" | cut -d. -f2)
        if [[ "$major" -gt 0 || "$minor" -ge 10 ]]; then
            ok "neovim $ver already installed"; return
        fi
        log "neovim $ver is too old (need >= 0.10), upgrading..."
    else
        log "Installing neovim..."
    fi
    case $OS in
        debian|redhat)
            # apt/dnf ship old versions; install from GitHub releases
            local ver
            ver=$(latest_release neovim/neovim 0.11.1)
            curl -fsSL "https://github.com/neovim/neovim/releases/download/v${ver}/nvim-linux-${ARCH}.tar.gz" \
                | sudo tar -xz -C /usr/local --strip-components=1 ;;
        arch)   sudo pacman -S --needed --noconfirm neovim ;;
        macos)  brew install neovim ;;
    esac
    ok "neovim $(nvim --version | head -1) installed"
}

install_nodejs() {
    command -v node &>/dev/null && { ok "node already installed"; return; }
    log "Installing Node.js (needed for Mason LSPs)..."
    case $OS in
        debian)
            apt_update_once
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs ;;
        redhat)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs ;;
        arch)   sudo pacman -S --needed --noconfirm nodejs npm ;;
        macos)  brew install node ;;
    esac
    ok "Node.js installed"
}

install_fd() {
    # Debian ships the binary as `fdfind`; we still want `fd` on PATH, so check
    # for `fd` specifically rather than accepting either name.
    command -v fd &>/dev/null && { ok "fd already installed"; return; }
    if command -v fdfind &>/dev/null; then
        mkdir -p ~/.local/bin
        ln -sf "$(command -v fdfind)" ~/.local/bin/fd
        ok "fd linked from fdfind"; return
    fi
    log "Installing fd..."
    case $OS in
        debian)
            apt_install fd-find
            if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
                mkdir -p ~/.local/bin
                ln -sf "$(command -v fdfind)" ~/.local/bin/fd
            fi ;;
        redhat) sudo dnf install -y fd-find ;;
        arch)   sudo pacman -S --needed --noconfirm fd ;;
        macos)  brew install fd ;;
    esac
    ok "fd installed"
}

install_lazygit() {
    command -v lazygit &>/dev/null && { ok "lazygit already installed"; return; }
    log "Installing lazygit..."
    case $OS in
        debian|redhat)
            local ver tmp
            ver=$(latest_release jesseduffield/lazygit 0.63.1)
            tmp=$(mktemp -d)
            curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_linux_${ARCH}.tar.gz" \
                | tar -xz -C "$tmp" lazygit
            sudo install -m755 "$tmp/lazygit" /usr/local/bin/lazygit
            rm -rf "$tmp" ;;
        arch)   sudo pacman -S --needed --noconfirm lazygit ;;
        macos)  brew install lazygit ;;
    esac
    ok "lazygit installed"
}

install_starship() {
    command -v starship &>/dev/null && { ok "starship already installed"; return; }
    log "Installing starship..."
    case $OS in
        macos) brew install starship ;;
        *)
            # The upstream install.sh re-escalates with its own `sudo`, which fails
            # under `Defaults use_pty` with no TTY. Fetch the release directly instead.
            local tmp
            tmp=$(mktemp -d)
            curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-${ARCH_MUSL}-unknown-linux-musl.tar.gz" \
                | tar -xz -C "$tmp" starship
            sudo install -m755 "$tmp/starship" /usr/local/bin/starship
            rm -rf "$tmp" ;;
    esac
    ok "starship installed"
}

install_stow() {
    command -v stow &>/dev/null && { ok "stow already installed"; return; }
    log "Installing stow..."
    case $OS in
        debian) apt_install stow ;;
        redhat) sudo dnf install -y stow ;;
        arch)   sudo pacman -S --needed --noconfirm stow ;;
        macos)  brew install stow ;;
    esac
    ok "stow installed"
}

install_clipboard() {
    [[ "$OS" == "macos" ]] && return  # pbcopy built-in on macOS
    command -v xclip &>/dev/null && { ok "xclip already installed"; return; }
    log "Installing xclip (clipboard support for nvim)..."
    case $OS in
        debian) apt_install xclip ;;
        redhat) sudo dnf install -y xclip ;;
        arch)   sudo pacman -S --needed --noconfirm xclip ;;
    esac
    ok "xclip installed"
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
    local dotfiles_dir
    dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    log "Linking dotfiles from $dotfiles_dir..."
    backup_stow_conflicts "$dotfiles_dir" "$HOME"
    stow --dir="$(dirname "$dotfiles_dir")" --target="$HOME" "$(basename "$dotfiles_dir")"
    ok "Dotfiles linked"
}

set_default_shell_zsh() {
    local zsh_path current user
    user=$(id -un)
    if ! zsh_path=$(command -v zsh); then
        err "zsh not on PATH; skipping default shell change"
        return
    fi
    # $SHELL reflects the *running* shell, not the login shell on record.
    if command -v getent &>/dev/null; then
        current=$(getent passwd "$user" | cut -d: -f7)
    else
        current="${SHELL:-}"
    fi
    if [[ "$current" == "$zsh_path" ]]; then
        ok "zsh is already the default shell"
        return
    fi
    grep -qx "$zsh_path" /etc/shells 2>/dev/null || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    # Plain `chsh` prompts through PAM even with passwordless sudo, which hangs a
    # non-interactive run; go through sudo so it can't block on a password.
    if sudo chsh -s "$zsh_path" "$user"; then
        ok "default shell set to zsh (log out and back in to apply)"
    else
        err "could not change default shell; run: sudo chsh -s $zsh_path $user"
    fi
}

main() {
    log "Installing dev tools..."
    detect_os
    detect_arch

    if [[ "$OS" == "macos" ]] && ! command -v brew &>/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    install_build_tools   # gcc, make, unzip — needed by treesitter + telescope-fzf-native
    install_pkg zsh
    install_neovim
    install_nodejs        # needed by Mason for LSP servers
    install_pkg ripgrep rg
    install_fd
    install_lazygit
    install_clipboard     # xclip for nvim clipboard = 'unnamedplus'
    install_starship
    install_stow
    link_dotfiles

    set_default_shell_zsh

    ok "Done! Log out and back in to use zsh."
}

main "$@"
