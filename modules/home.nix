{ pkgs, lib, ... }:
{
  home.stateVersion = "22.11";
  programs.home-manager.enable = true;

  # Create Development directory structure
  home.activation = {
    createDevDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/Development/github.com
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.config/tmux/plugins
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.cache/zsh
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.runbooks
    '';

    gitTownCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.git-town}/bin/git-town completions zsh > "$HOME/.cache/zsh/_git-town"
    '';

    helmCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /opt/homebrew/bin/helm completion zsh > "$HOME/.cache/zsh/_helm"
    '';

    hCloudCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      /opt/homebrew/bin/hcloud completion zsh > "$HOME/.cache/zsh/_hcloud"
    '';
  };

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
    ./pi.nix
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
