{ config, lib, pkgs, ... }:

let
  colimaTools = pkgs.writeShellScriptBin "colima-tools" (builtins.readFile ../tools/colima.sh);
in
{
  home.packages = [
    colimaTools
  ];

  home.file.".local/bin/colima-tools".source = ../tools/colima.sh;
  home.file.".local/bin/colima-tools".executable = true;
  home.file.".zsh/completions/_colima-tools".source = ../tools/_colima;

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.activation.mySymlinks = lib.mkAfter ''
   	  ln -sf ~/.nix-darwin/tools/navi/cheats ~/.local/share/navi/cheats/local
   	'';

}
