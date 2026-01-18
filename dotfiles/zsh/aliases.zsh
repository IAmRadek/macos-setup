# Zsh Aliases
# Portable - works with or without Nix

# Navigation
alias ..="cd .."
alias ...="cd ../.."

# Git
alias g="git"

# Kubernetes
alias k="kubectl"

# File listing (eza if available, otherwise ls)
if command -v eza &>/dev/null; then
  alias ls="eza -l"
  alias la="eza -la"
  alias lt="eza -lT"
else
  alias ls="ls -l"
  alias la="ls -la"
fi

# System management (only on systems with nix-darwin)
if [[ -d "$HOME/.nix-darwin" ]]; then
  alias system-update="cd ~/.nix-darwin && make update"
  alias system-edit="${EDITOR:-nano} ~/.nix-darwin"
fi
