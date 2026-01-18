{ pkgs, ... }:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  # Install alacritty
  home.packages = [ pkgs.alacritty ];

  # Symlink alacritty configuration from dotfiles
  xdg.configFile."alacritty/alacritty.toml".source = "${dotfiles}/alacritty/alacritty.toml";
}
