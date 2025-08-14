#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/IAmRadek/macos-setup.git"
INSTALL_DIR="$HOME/Documents/macos-setup"

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}================================${NC}"
    echo -e "${BLUE} macOS Nix Setup Installer${NC}"
    echo -e "${BLUE}================================${NC}\n"
}

check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only."
        exit 1
    fi
}

check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first:"
        echo "  xcode-select --install"
        exit 1
    fi
}

check_make() {
    if ! command -v make &> /dev/null; then
        print_error "Make is not installed. Please install Xcode Command Line Tools:"
        echo "  xcode-select --install"
        exit 1
    fi
}

check_admin() {
    if ! groups | grep -q admin; then
        print_error "Your user account is not an administrator."
        print_error "This installation requires admin privileges to install Nix and Homebrew."
        print_error "Please run this script with an administrator account."
        exit 1
    fi
}

clone_repository() {
    print_info "Cloning repository..."

    if [[ -d "$INSTALL_DIR" ]]; then
        print_warning "Directory $INSTALL_DIR already exists."
        if [[ -t 0 ]]; then
            # Interactive mode - can read from user
            read -p "Do you want to remove it and clone fresh? (y/N): " -n 1 -r </dev/tty
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Removing existing directory..."
                rm -rf "$INSTALL_DIR"
            else
                print_info "Using existing directory. Pulling latest changes..."
                cd "$INSTALL_DIR"
                git pull origin main || git pull origin master
                return 0
            fi
        else
            # Non-interactive mode (piped) - automatically update
            print_info "Non-interactive mode: Using existing directory. Pulling latest changes..."
            cd "$INSTALL_DIR"
            git pull origin main || git pull origin master
            return 0
        fi
    fi

    git clone "$REPO_URL" "$INSTALL_DIR"
    print_success "Repository cloned successfully!"
}

install_setup() {
    print_info "Changing to installation directory..."
    cd "$INSTALL_DIR"

    print_info "Starting installation process..."
    print_warning "This will install Nix, nix-darwin, and Homebrew."
    print_warning "You WILL be prompted for your password multiple times during installation."
    print_warning "This is normal and required for system-level changes."

    if [[ -t 0 ]]; then
        # Interactive mode - ask for confirmation
        read -p "Do you want to continue? (Y/n): " -n 1 -r </dev/tty
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
    else
        # Non-interactive mode (piped) - automatically continue
        print_info "Non-interactive mode: Proceeding with installation..."
    fi

    print_info "Running make command..."
    make

    print_success "Installation completed successfully!"
}

print_next_steps() {
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN} Installation Complete!${NC}"
    echo -e "${GREEN}================================${NC}\n"

    echo "Next steps:"
    echo "1. Restart your terminal or run: source ~/.zshrc"
    echo "2. Test Nix: nix-shell -p hello --command hello"
    echo "3. View configuration: cd $INSTALL_DIR"
    echo "4. Make changes: edit configuration.nix"
    echo "5. Apply changes: darwin-rebuild switch --flake ."
    echo ""
    echo "For more information, see: $INSTALL_DIR/README.md"
}

main() {
    print_header

    print_info "Checking system requirements..."
    check_macos
    check_git
    check_make
    check_admin

    clone_repository
    install_setup
    print_next_steps
}

# Handle interruption
trap 'print_error "Installation interrupted."; exit 1' INT

# Run main function
main "$@"
