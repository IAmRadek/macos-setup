{
  pkgs,
  ...
}:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  # Install navi
  home.packages = [ pkgs.navi ];

  # Symlink navi cheat sheets from dotfiles
  home.file.".local/share/navi/cheats/k3d.cheat".source = "${dotfiles}/navi/k3d.cheat";
  home.file.".local/share/navi/cheats/docker.cheat".source = "${dotfiles}/navi/docker.cheat";
  home.file.".local/share/navi/cheats/kubernetes.cheat".source = "${dotfiles}/navi/kubernetes.cheat";
  home.file.".local/share/navi/cheats/local.cheat".source = "${dotfiles}/navi/local.cheat";

  # Runbooks
  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
}
