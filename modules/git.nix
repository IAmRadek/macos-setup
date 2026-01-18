{
  config,
  pkgs,
  lib,
  ...
}:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  # Install git and related tools
  home.packages = with pkgs; [
    git
    git-lfs
    delta
    gh
  ];

  # Symlink git configuration from dotfiles
  xdg.configFile."git/config".source = "${dotfiles}/git/config";
  xdg.configFile."git/ignore".source = "${dotfiles}/git/ignore";
  xdg.configFile."git/attributes".source = "${dotfiles}/git/attributes";
  xdg.configFile."git/allowed_signers".source = "${dotfiles}/git/allowed_signers";
  xdg.configFile."git/delta.gitconfig".source = "${dotfiles}/git/delta.gitconfig";

  # Git hooks directory
  xdg.configFile."git/hooks" = {
    source = ../githooks;
    recursive = true;
  };

  # Create private config file if it doesn't exist
  home.activation.createGitPrivateConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -f "${config.xdg.configHome}/git/config.private" ]; then
      $DRY_RUN_CMD touch $VERBOSE_ARG "${config.xdg.configHome}/git/config.private"
    fi
  '';
}
