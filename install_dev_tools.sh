#!/bin/bash

# Install script for zsh, neovim, starship and dependencies
# Supports Ubuntu/Debian, CentOS/RHEL/Fedora, Arch Linux, and macOS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "Running as root. This script will install packages system-wide."
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Exiting..."
            exit 0
        fi
    fi
}

# Detect the operating system and package manager
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        log_info "Detected macOS"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                OS="debian"
                PACKAGE_MANAGER="apt"
                log_info "Detected Debian/Ubuntu system"
                ;;
            centos|rhel|fedora)
                OS="redhat"
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                else
                    PACKAGE_MANAGER="yum"
                fi
                log_info "Detected Red Hat/CentOS/Fedora system"
                ;;
            arch|manjaro)
                OS="arch"
                PACKAGE_MANAGER="pacman"
                log_info "Detected Arch Linux system"
                ;;
            *)
                log_error "Unsupported Linux distribution: $ID"
                exit 1
                ;;
        esac
    else
        log_error "Unable to detect operating system"
        exit 1
    fi
}

# Update package manager
update_packages() {
    log_info "Updating package manager..."
    case $OS in
        debian)
            sudo apt update
            ;;
        redhat)
            sudo $PACKAGE_MANAGER check-update || true
            ;;
        arch)
            sudo pacman -Sy
            ;;
        macos)
            # Check if Homebrew is installed
            if ! command -v brew &> /dev/null; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                # Add Homebrew to PATH for current session
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f "/usr/local/bin/brew" ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            brew update
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    case $OS in
        debian)
            sudo apt install -y curl wget git build-essential cmake unzip gettext
            ;;
        redhat)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                sudo dnf groupinstall -y "Development Tools"
                sudo dnf install -y curl wget git cmake unzip gettext ninja-build
            else
                sudo yum groupinstall -y "Development Tools"
                sudo yum install -y curl wget git cmake unzip gettext ninja-build
            fi
            ;;
        arch)
            sudo pacman -S --needed --noconfirm curl wget git base-devel cmake unzip gettext ninja
            ;;
        macos)
            # Xcode command line tools are usually needed
            if ! xcode-select -p &> /dev/null; then
                log_info "Installing Xcode command line tools..."
                xcode-select --install
                log_warning "Please complete the Xcode command line tools installation and run this script again."
                exit 1
            fi
            brew install cmake ninja gettext
            ;;
    esac
}

# Install zsh
install_zsh() {
    if command -v zsh &> /dev/null; then
        log_success "zsh is already installed"
        return
    fi

    log_info "Installing zsh..."
    case $OS in
        debian)
            sudo apt install -y zsh
            ;;
        redhat)
            sudo $PACKAGE_MANAGER install -y zsh
            ;;
        arch)
            sudo pacman -S --needed --noconfirm zsh
            ;;
        macos)
            # zsh is pre-installed on macOS Catalina and later
            if ! command -v zsh &> /dev/null; then
                brew install zsh
            fi
            ;;
    esac
    log_success "zsh installed successfully"
}

# Install neovim
install_neovim() {
    if command -v nvim &> /dev/null; then
        log_success "neovim is already installed"
        return
    fi

    log_info "Installing neovim..."
    case $OS in
        debian)
            # Try to install from official repositories first
            if apt-cache show neovim | grep -q "Version: 0\.[5-9]\|Version: [1-9]"; then
                sudo apt install -y neovim
            else
                # Install from snap or build from source for newer version
                if command -v snap &> /dev/null; then
                    sudo snap install nvim --classic
                else
                    log_warning "Installing older version from apt. Consider building from source for latest version."
                    sudo apt install -y neovim
                fi
            fi
            ;;
        redhat)
            # Enable EPEL repository for CentOS/RHEL
            if [[ "$ID" == "centos" || "$ID" == "rhel" ]]; then
                sudo $PACKAGE_MANAGER install -y epel-release
            fi
            sudo $PACKAGE_MANAGER install -y neovim python3-neovim
            ;;
        arch)
            sudo pacman -S --needed --noconfirm neovim python-pynvim
            ;;
        macos)
            brew install neovim
            ;;
    esac
    log_success "neovim installed successfully"
}

# Install Node.js (needed for some neovim plugins)
install_nodejs() {
    if command -v node &> /dev/null; then
        log_success "Node.js is already installed"
        return
    fi

    log_info "Installing Node.js..."
    case $OS in
        debian)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt install -y nodejs
            ;;
        redhat)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo $PACKAGE_MANAGER install -y nodejs npm
            ;;
        arch)
            sudo pacman -S --needed --noconfirm nodejs npm
            ;;
        macos)
            brew install node
            ;;
    esac
    log_success "Node.js installed successfully"
}

# Install Python and pip (needed for some neovim plugins)
install_python() {
    if command -v python3 &> /dev/null; then
        log_success "Python3 is already installed"
    else
        log_info "Installing Python3..."
        case $OS in
            debian)
                sudo apt install -y python3 python3-venv
                ;;
            redhat)
                sudo $PACKAGE_MANAGER install -y python3 python3-pip
                ;;
            arch)
                sudo pacman -S --needed --noconfirm python python-pip
                ;;
            macos)
                brew install python
                ;;
        esac
        log_success "Python3 installed successfully"
    fi

    # Install pynvim for neovim Python support
    log_info "Installing pynvim for neovim Python support..."
    case $OS in
        debian)
            # Try to install via apt first (recommended for externally managed environments)
            if apt-cache show python3-pynvim &> /dev/null; then
                sudo apt install -y python3-pynvim
                log_success "Installed pynvim via apt"
            else
                # Fallback: create a virtual environment for pynvim
                log_info "Creating virtual environment for pynvim..."
                python3 -m venv ~/.local/nvim-venv
                ~/.local/nvim-venv/bin/pip install pynvim
                log_success "Installed pynvim in virtual environment"
                log_info "Note: You may need to configure neovim to use ~/.local/nvim-venv/bin/python"
            fi
            ;;
        redhat)
            # Try pip install with user flag, fallback to venv if needed
            if pip3 install --user pynvim 2>/dev/null; then
                log_success "Installed pynvim via pip --user"
            else
                log_info "Creating virtual environment for pynvim..."
                python3 -m venv ~/.local/nvim-venv
                ~/.local/nvim-venv/bin/pip install pynvim
                log_success "Installed pynvim in virtual environment"
            fi
            ;;
        arch)
            sudo pacman -S --needed --noconfirm python-pynvim
            log_success "Installed pynvim via pacman"
            ;;
        macos)
            pip3 install --user pynvim
            log_success "Installed pynvim via pip --user"
            ;;
    esac
}

# Install ripgrep (useful for neovim telescope plugin)
install_ripgrep() {
    if command -v rg &> /dev/null; then
        log_success "ripgrep is already installed"
        return
    fi

    log_info "Installing ripgrep..."
    case $OS in
        debian)
            sudo apt install -y ripgrep
            ;;
        redhat)
            sudo $PACKAGE_MANAGER install -y ripgrep
            ;;
        arch)
            sudo pacman -S --needed --noconfirm ripgrep
            ;;
        macos)
            brew install ripgrep
            ;;
    esac
    log_success "ripgrep installed successfully"
}

# Install fd (useful for neovim telescope plugin)
install_fd() {
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        log_success "fd is already installed"
        return
    fi

    log_info "Installing fd..."
    case $OS in
        debian)
            sudo apt install -y fd-find
            # Create symlink if fd command doesn't exist
            if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
                mkdir -p ~/.local/bin
                ln -sf "$(which fdfind)" ~/.local/bin/fd
            fi
            ;;
        redhat)
            sudo $PACKAGE_MANAGER install -y fd-find
            ;;
        arch)
            sudo pacman -S --needed --noconfirm fd
            ;;
        macos)
            brew install fd
            ;;
    esac
    log_success "fd installed successfully"
}

# Install starship
install_starship() {
    if command -v starship &> /dev/null; then
        log_success "starship is already installed"
        return
    fi

    log_info "Installing starship..."
    
    # Use the official installer
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    # Add to PATH if needed
    if ! command -v starship &> /dev/null; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    log_success "starship installed successfully"
}

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        log_success "Go is already installed"
        return
    fi

    log_info "Installing Go..."
    case $OS in
        debian)
            # Remove old Go installation if exists
            sudo rm -rf /usr/local/go
            
            # Get latest Go version and clean it up
            GO_VERSION_RAW=$(curl -s https://go.dev/VERSION?m=text | tr -d '\n' | tr -d '\r')
            # Extract just the version part (everything before any whitespace or "time")
            GO_VERSION=$(echo "$GO_VERSION_RAW" | sed 's/time.*//' | tr -d ' ')
            
            # Validate version format
            if [[ ! "$GO_VERSION" =~ ^go[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                log_warning "Extracted Go version '$GO_VERSION' from raw response '$GO_VERSION_RAW'"
                log_warning "Using fallback version instead"
                GO_VERSION="go1.21.13"
            fi
            
            log_info "Downloading Go $GO_VERSION..."
            
            # Download and install Go
            if wget -q "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"; then
                sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
                rm "${GO_VERSION}.linux-amd64.tar.gz"
            else
                log_error "Failed to download Go. Trying fallback version..."
                # Fallback to a known good version
                GO_VERSION="go1.21.13"
                wget "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
                sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
                rm "${GO_VERSION}.linux-amd64.tar.gz"
            fi
            ;;
        redhat)
            # Remove old Go installation if exists
            sudo rm -rf /usr/local/go
            
            # Get latest Go version and clean it up
            GO_VERSION_RAW=$(curl -s https://go.dev/VERSION?m=text | tr -d '\n' | tr -d '\r')
            # Extract just the version part (everything before any whitespace or "time")
            GO_VERSION=$(echo "$GO_VERSION_RAW" | sed 's/time.*//' | tr -d ' ')
            
            # Validate version format
            if [[ ! "$GO_VERSION" =~ ^go[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
                log_warning "Extracted Go version '$GO_VERSION' from raw response '$GO_VERSION_RAW'"
                log_warning "Using fallback version instead"
                GO_VERSION="go1.21.13"
            fi
            
            log_info "Downloading Go $GO_VERSION..."
            
            # Download and install Go
            if wget -q "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"; then
                sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
                rm "${GO_VERSION}.linux-amd64.tar.gz"
            else
                log_error "Failed to download Go. Trying fallback version..."
                # Fallback to a known good version
                GO_VERSION="go1.21.13"
                wget "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
                sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
                rm "${GO_VERSION}.linux-amd64.tar.gz"
            fi
            ;;
        arch)
            sudo pacman -S --needed --noconfirm go
            ;;
        macos)
            brew install go
            ;;
    esac
    
    # Verify installation
    if [[ -x "/usr/local/go/bin/go" ]] || command -v go &> /dev/null; then
        log_success "Go installed successfully"
        
        # Add Go to current PATH for immediate use
        if [[ -d "/usr/local/go/bin" ]]; then
            export PATH="/usr/local/go/bin:$PATH"
        fi
        
        # Show installed version
        if command -v go &> /dev/null; then
            log_info "Installed Go version: $(go version)"
        fi
    else
        log_error "Go installation may have failed"
        return 1
    fi
}

# Configure zsh as default shell
configure_zsh() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_success "zsh is already the default shell"
        return
    fi

    log_info "Setting zsh as default shell..."
    
    # Get zsh path
    ZSH_PATH=$(which zsh)
    if [[ -z "$ZSH_PATH" ]]; then
        log_error "Could not find zsh installation path"
        return 1
    fi
    
    # Add zsh to /etc/shells if not already there
    if ! grep -q "^$ZSH_PATH$" /etc/shells 2>/dev/null; then
        log_info "Adding zsh to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        log_success "Added $ZSH_PATH to /etc/shells"
    fi
    
    # Change default shell
    log_info "Changing default shell to zsh..."
    if chsh -s "$ZSH_PATH"; then
        log_success "zsh set as default shell"
        log_warning "Please log out and log back in (or restart terminal) for the shell change to take effect"
    else
        log_error "Failed to change default shell. You may need to run 'chsh -s $ZSH_PATH' manually"
        log_info "Alternative: You can also change your shell in your terminal emulator settings"
    fi
    
    # For some systems, also try to change it for the current user explicitly
    if [[ "$OS" == "macos" ]]; then
        log_info "On macOS, you may also need to change the shell in Terminal preferences"
    fi
}

# Setup basic configurations
setup_configs() {
    log_info "Setting up basic configurations..."
    
    # Create .zshrc with starship initialization if it doesn't exist
    if [[ ! -f "$HOME/.zshrc" ]]; then
        cat > "$HOME/.zshrc" << 'EOF'
# Basic zsh configuration
# History configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# Enable completion
autoload -Uz compinit
compinit

# Enable starship prompt
eval "$(starship init zsh)"

# Aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vim='nvim'
alias vi='nvim'

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add Go to PATH
export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"
export GOPATH="$HOME/go"

# Python virtual environment for neovim (if created)
if [[ -d "$HOME/.local/nvim-venv" ]]; then
    export NVIM_PYTHON3="$HOME/.local/nvim-venv/bin/python"
fi
EOF
        log_success "Created basic .zshrc configuration"
    else
        # Add starship to existing .zshrc if not already there
        if ! grep -q "starship init zsh" "$HOME/.zshrc"; then
            echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
            log_success "Added starship initialization to .zshrc"
        fi
        
        # Add Go PATH to existing .zshrc if not already there
        if ! grep -q "/usr/local/go/bin" "$HOME/.zshrc"; then
            echo 'export PATH="/usr/local/go/bin:$HOME/go/bin:$PATH"' >> "$HOME/.zshrc"
            echo 'export GOPATH="$HOME/go"' >> "$HOME/.zshrc"
            log_success "Added Go PATH to .zshrc"
        fi
    fi

    # Create basic starship config if it doesn't exist
    STARSHIP_CONFIG_DIR="$HOME/.config"
    mkdir -p "$STARSHIP_CONFIG_DIR"
    
    if [[ ! -f "$STARSHIP_CONFIG_DIR/starship.toml" ]]; then
        cat > "$STARSHIP_CONFIG_DIR/starship.toml" << 'EOF'
# Starship configuration
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Inserts a blank line between shell prompts
add_newline = true

# Replace the "❯" symbol in the prompt with "➜"
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

# Disable the package module, hiding it from the prompt completely
[package]
disabled = true

[git_branch]
symbol = "🌱 "

[nodejs]
symbol = "⬢ "

[golang]
symbol = "🐹 "
EOF
        log_success "Created basic starship configuration"
    fi
}

# Main installation function
main() {
    log_info "Starting installation of zsh, neovim, starship and dependencies..."
    echo "======================================================================="
    
    check_root
    detect_os
    update_packages
    install_dependencies
    install_zsh
    install_neovim
    install_nodejs
    install_python
    install_ripgrep
    install_fd
    install_starship
    install_go
    configure_zsh
    setup_configs
    
    echo "======================================================================="
    log_success "Installation completed successfully!"
    echo ""
    log_info "Next steps:"
    echo "  1. Log out and log back in (or restart your terminal) to use zsh as default shell"
    echo "  2. If shell didn't change automatically, run: chsh -s $(which zsh)"
    echo "  3. Your shell should now use starship prompt"
    echo "  4. Open neovim with: nvim"
    echo "  5. Configure neovim as needed (consider using LazyVim, NvChad, or AstroVim)"
    echo ""
    log_info "Installed tools:"
    echo "  • zsh (shell)"
    echo "  • neovim (editor)"
    echo "  • starship (prompt)"
    echo "  • go (programming language)"
    echo "  • ripgrep (search tool)"
    echo "  • fd (file finder)"
    echo "  • Node.js & Python (for neovim plugins)"
    echo ""
    log_warning "Please log out and log back in to use zsh as your default shell!"
}

# Run the main function
main "$@"
