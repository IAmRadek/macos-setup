#!/usr/bin/env bash
#
# Standalone dotfiles installer
# Works on any system without Nix
#
# Usage:
#   ./install.sh           # Install all dotfiles
#   ./install.sh --minimal # Install only essential configs (git, zsh, tmux)
#   ./install.sh --dry-run # Show what would be done
#

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_SRC="$DOTFILES_DIR/dotfiles"

DRY_RUN=false
MINIMAL=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --minimal)
      MINIMAL=true
      shift
      ;;
    *)
      log_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create symlink or copy file
link_file() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  if [[ ! -e "$src" ]]; then
    log_warning "Source does not exist: $src"
    return
  fi

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would link: $dest -> $src"
    return
  fi

  # Create parent directory
  mkdir -p "$dest_dir"

  # Backup existing file if it's not a symlink
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    log_warning "Backing up existing file: $dest -> $dest.backup"
    mv "$dest" "$dest.backup"
  fi

  # Remove existing symlink
  if [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  log_success "Linked: $dest"
}

# Copy file (for files that might be modified locally)
copy_file() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"

  if [[ ! -e "$src" ]]; then
    log_warning "Source does not exist: $src"
    return
  fi

  if $DRY_RUN; then
    log_info "[DRY-RUN] Would copy: $src -> $dest"
    return
  fi

  mkdir -p "$dest_dir"

  if [[ -e "$dest" ]]; then
    log_warning "Backing up existing file: $dest -> $dest.backup"
    mv "$dest" "$dest.backup"
  fi

  cp "$src" "$dest"
  log_success "Copied: $dest"
}

echo ""
echo "=================================="
echo "  Dotfiles Installer"
echo "=================================="
echo ""
echo "Source: $DOTFILES_SRC"
echo "Dry run: $DRY_RUN"
echo "Minimal: $MINIMAL"
echo ""

# ─────────────────────────────────────────────────────────────
# Git
# ─────────────────────────────────────────────────────────────
log_info "Installing Git configuration..."
link_file "$DOTFILES_SRC/git/config" "$HOME/.config/git/config"
link_file "$DOTFILES_SRC/git/ignore" "$HOME/.config/git/ignore"
link_file "$DOTFILES_SRC/git/attributes" "$HOME/.config/git/attributes"
link_file "$DOTFILES_SRC/git/delta.gitconfig" "$HOME/.config/git/delta.gitconfig"
link_file "$DOTFILES_SRC/git/allowed_signers" "$HOME/.config/git/allowed_signers"
link_file "$DOTFILES_DIR/githooks" "$HOME/.config/git/hooks"

# Create private config if it doesn't exist
if [[ ! -f "$HOME/.config/git/config.private" ]]; then
  if ! $DRY_RUN; then
    touch "$HOME/.config/git/config.private"
    log_success "Created: ~/.config/git/config.private"
  else
    log_info "[DRY-RUN] Would create: ~/.config/git/config.private"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Zsh
# ─────────────────────────────────────────────────────────────
log_info "Installing Zsh configuration..."
link_file "$DOTFILES_SRC/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_SRC/zsh/aliases.zsh" "$HOME/.zsh_aliases"

# Update .zshrc to source aliases if using symlink approach
if ! $DRY_RUN; then
  mkdir -p "$HOME/.cache/zsh"
fi

# ─────────────────────────────────────────────────────────────
# Starship
# ─────────────────────────────────────────────────────────────
log_info "Installing Starship configuration..."
link_file "$DOTFILES_SRC/starship/starship.toml" "$HOME/.config/starship.toml"

# ─────────────────────────────────────────────────────────────
# Tmux
# ─────────────────────────────────────────────────────────────
log_info "Installing Tmux configuration..."
link_file "$DOTFILES_SRC/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"

# Clone tmux plugins if not present
if ! $DRY_RUN; then
  mkdir -p "$HOME/.config/tmux/plugins"

  if [[ ! -d "$HOME/.config/tmux/plugins/kube-tmux" ]]; then
    log_info "Cloning kube-tmux plugin..."
    git clone --depth 1 https://github.com/jonmosco/kube-tmux.git "$HOME/.config/tmux/plugins/kube-tmux" 2>/dev/null || true
  fi

  if [[ ! -d "$HOME/.config/tmux/plugins/tmux-k8s-context-switcher" ]]; then
    log_info "Cloning tmux-k8s-context-switcher plugin..."
    git clone --depth 1 https://github.com/IAmRadek/tmux-k8s-context-switcher.git "$HOME/.config/tmux/plugins/tmux-k8s-context-switcher" 2>/dev/null || true
  fi
fi

# ─────────────────────────────────────────────────────────────
# Nano
# ─────────────────────────────────────────────────────────────
log_info "Installing Nano configuration..."
link_file "$DOTFILES_SRC/nano/nanorc" "$HOME/.config/nano/nanorc"

if ! $MINIMAL; then
  # ─────────────────────────────────────────────────────────────
  # SSH
  # ─────────────────────────────────────────────────────────────
  log_info "Installing SSH configuration..."
  copy_file "$DOTFILES_SRC/ssh/config" "$HOME/.ssh/config"

  if ! $DRY_RUN; then
    chmod 600 "$HOME/.ssh/config"
  fi

  # ─────────────────────────────────────────────────────────────
  # Kitty
  # ─────────────────────────────────────────────────────────────
  log_info "Installing Kitty configuration..."
  link_file "$DOTFILES_SRC/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
  link_file "$DOTFILES_SRC/kitty/navi_select.py" "$HOME/.config/kitty/navi_select.py"

  # ─────────────────────────────────────────────────────────────
  # Alacritty
  # ─────────────────────────────────────────────────────────────
  log_info "Installing Alacritty configuration..."
  link_file "$DOTFILES_SRC/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

  # ─────────────────────────────────────────────────────────────
  # AIChat
  # ─────────────────────────────────────────────────────────────
  log_info "Installing AIChat configuration..."
  link_file "$DOTFILES_SRC/aichat/config.yaml" "$HOME/.config/aichat/config.yaml"
  link_file "$DOTFILES_SRC/aichat/roles.yaml" "$HOME/.config/aichat/roles.yaml"
  link_file "$DOTFILES_SRC/aichat/agents/adr/config.yaml" "$HOME/.config/aichat/agents/adr/config.yaml"

  # ─────────────────────────────────────────────────────────────
  # Navi
  # ─────────────────────────────────────────────────────────────
  log_info "Installing Navi cheat sheets..."
  link_file "$DOTFILES_SRC/navi/docker.cheat" "$HOME/.local/share/navi/cheats/docker.cheat"
  link_file "$DOTFILES_SRC/navi/k3d.cheat" "$HOME/.local/share/navi/cheats/k3d.cheat"
  link_file "$DOTFILES_SRC/navi/kubernetes.cheat" "$HOME/.local/share/navi/cheats/kubernetes.cheat"
  link_file "$DOTFILES_SRC/navi/local.cheat" "$HOME/.local/share/navi/cheats/local.cheat"

  # ─────────────────────────────────────────────────────────────
  # Runbooks
  # ─────────────────────────────────────────────────────────────
  log_info "Installing runbooks..."
  if ! $DRY_RUN; then
    mkdir -p "$HOME/.runbooks"
  fi
  link_file "$DOTFILES_DIR/tools/runbooks/new.sh" "$HOME/.runbooks/new.sh"
fi

echo ""
echo "=================================="
log_success "Installation complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Install required tools: git, zsh, tmux, starship, fzf, eza, delta"
echo "  2. Restart your shell or run: source ~/.zshrc"
echo "  3. (Optional) Install zinit plugins on first zsh launch"
echo ""
