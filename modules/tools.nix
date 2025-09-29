{ config, lib, pkgs, ... }:

let
  py = pkgs.python3.withPackages (ps: [ ps.invoke ]);
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "colima-tools" ''
      set -euo pipefail
      exec ${py}/bin/inv -r ''$HOME/.nix-darwin/tools/colima "''${1}" -- "''${@:2}"
    '')
  ];

  home.file.".zsh/completions/_colima-tools".source = ../tools/_colima;

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.activation.mySymlinks = lib.mkAfter ''
   	  ln -sf ~/.nix-darwin/tools/navi/cheats ~/.local/share/navi/cheats/local
   	'';

}
