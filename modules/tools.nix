{ config, lib, pkgs, ... }:

let
  colimaTools = pkgs.writeShellScriptBin "colima-tools" (builtins.readFile ../tools/colima.sh);
in
{
  home.packages = [
    colimaTools
  ];

  # Also symlink individual functions to ~/.local/bin
  # We'll split them from the original script
  # This assumes ./colima-tools.sh is in the same dir as this module
  home.file.".local/bin/colima-tools".source = ../tools/colima.sh;
  home.file.".local/bin/colima-tools".executable = true;
  home.file.".zsh/completions/_colima-tools".source = ../tools/_colima;

  home.file.".local/share/navi/cheats/local".source = ../tools/navi/cheats;

}
