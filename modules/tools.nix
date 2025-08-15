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

  # Optional: link shorter aliases
  home.file.".local/bin/cup" = {
    text = "#!/usr/bin/env bash\nsource ~/.local/bin/colima-tools\ncup \"\$@\"";
    executable = true;
  };
  home.file.".local/bin/cstop" = {
    text = "#!/usr/bin/env bash\nsource ~/.local/bin/colima-tools\ncstop \"\$@\"";
    executable = true;
  };
  home.file.".local/bin/crestart" = {
    text = "#!/usr/bin/env bash\nsource ~/.local/bin/colima-tools\ncrestart \"\$@\"";
    executable = true;
  };
  home.file.".local/bin/cstatus" = {
    text = "#!/usr/bin/env bash\nsource ~/.local/bin/colima-tools\ncstatus \"\$@\"";
    executable = true;
  };
}
