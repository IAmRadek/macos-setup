{ pkgs, ... }:
{
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  imports = [
    ./alacritty.nix
    ./zsh.nix
    ./tmux.nix
    ./nvim.nix
    ./git.nix
    ./tools.nix
    ./claude.nix
    ./codex.nix
    ./zed.nix
    ./aichat.nix
    # LLM stack
    ./ollama.nix
  ];

  # Configure nano with xdg.configFile
  xdg.configFile."nano/nanorc".text = ''
    # Display line numbers
    set linenumbers

    # Use auto-indentation
    set autoindent

    # Display cursor position in the status bar
    set constantshow

    # Enable mouse support
    set mouse

    # Don't wrap text at the end of the line
    set nowrap

    # Syntax highlighting
    include "${pkgs.nano}/share/nano/*.nanorc"
  '';
}
