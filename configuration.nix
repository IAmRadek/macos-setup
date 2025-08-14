{ config, pkgs, ... }:

{
  # Minimal system packages - just essential tools
  environment.systemPackages = with pkgs; [
  ];

  # Basic Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      allowed-users = [
        "@admin"
      ];
    };
  };

  # Fix nixbld group GID mismatch
  ids.gids.nixbld = 350;

  # Create /etc/zshrc that loads the nix-darwin environment
  programs = {
    zsh = {
      enable = true;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
