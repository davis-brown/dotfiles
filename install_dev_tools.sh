#!/bin/bash
set -e

log() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
ok()  { echo -e "\033[0;32m[OK]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERR]\033[0m $1"; }

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)       OS="debian" ;;
            centos|rhel|fedora)  OS="redhat" ;;
            arch|manjaro)        OS="arch" ;;
            *) err "Unsupported distro: $ID"; exit 1 ;;
        esac
    else
        err "Unable to detect OS"; exit 1
    fi
    log "Detected $OS"
}

install_pkg() {
    local name=$1
    command -v "$name" &>/dev/null && { ok "$name already installed"; return; }
    log "Installing $name..."
    case $OS in
        debian) sudo apt install -y "$name" ;;
        redhat) sudo dnf install -y "$name" 2>/dev/null || sudo yum install -y "$name" ;;
        arch)   sudo pacman -S --needed --noconfirm "$name" ;;
        macos)  brew install "$name" ;;
    esac
    ok "$name installed"
}

install_build_tools() {
    log "Installing build tools (gcc, make, unzip)..."
    case $OS in
        debian) sudo apt install -y gcc make unzip curl ;;
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
            ver=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" \
                  | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
            [[ -z "$ver" ]] && ver="0.11.1"
            curl -sL "https://github.com/neovim/neovim/releases/download/v${ver}/nvim-linux-x86_64.tar.gz" \
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
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs ;;
        redhat)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo dnf install -y nodejs ;;
        arch)   sudo pacman -S --needed --noconfirm nodejs npm ;;
        macos)  brew install node ;;
    esac
    ok "Node.js installed"
}

install_fd() {
    command -v fd &>/dev/null || command -v fdfind &>/dev/null && { ok "fd already installed"; return; }
    log "Installing fd..."
    case $OS in
        debian)
            sudo apt install -y fd-find
            if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
                mkdir -p ~/.local/bin
                ln -sf "$(which fdfind)" ~/.local/bin/fd
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
            local ver
            ver=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
            curl -sL "https://github.com/jesseduffield/lazygit/releases/download/v${ver}/lazygit_${ver}_Linux_x86_64.tar.gz" | tar -xz -C /tmp lazygit
            sudo install /tmp/lazygit /usr/local/bin/lazygit ;;
        arch)   sudo pacman -S --needed --noconfirm lazygit ;;
        macos)  brew install lazygit ;;
    esac
    ok "lazygit installed"
}

install_starship() {
    command -v starship &>/dev/null && { ok "starship already installed"; return; }
    log "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "starship installed"
}

install_stow() {
    command -v stow &>/dev/null && { ok "stow already installed"; return; }
    log "Installing stow..."
    case $OS in
        debian) sudo apt install -y stow ;;
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
        debian) sudo apt install -y xclip ;;
        redhat) sudo dnf install -y xclip ;;
        arch)   sudo pacman -S --needed --noconfirm xclip ;;
    esac
    ok "xclip installed"
}

set_default_shell_zsh() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        ok "zsh is already the default shell"
        return
    fi
    ZSH_PATH=$(which zsh)
    grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null || echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$ZSH_PATH" && ok "default shell set to zsh (log out and back in to apply)"
}

main() {
    log "Installing dev tools..."
    detect_os

    if [[ "$OS" == "macos" ]] && ! command -v brew &>/dev/null; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    install_build_tools   # gcc, make, unzip — needed by treesitter + telescope-fzf-native
    install_pkg zsh
    install_neovim
    install_nodejs        # needed by Mason for LSP servers
    install_pkg ripgrep
    install_fd
    install_lazygit
    install_clipboard     # xclip for nvim clipboard = 'unnamedplus'
    install_starship
    install_stow

    set_default_shell_zsh

    ok "Done! Log out and back in to use zsh."
}

main "$@"
