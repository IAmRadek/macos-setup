{ pkgs, ... }:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };

  # Helper script for kubernetes context switching
  kubeContextPopup = pkgs.writeShellScriptBin "kube-context-popup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    ctx="$(kubectl config get-contexts -o name | fzf --prompt='Kubernetes context> ')"
    [ -z "$ctx" ] && exit 0

    kubectl config use-context "$ctx"

    echo
    echo "Switched to context: $ctx"
    echo
    read -n 1 -s -r -p "Press any key to close..."
  '';
in
{
  # Install kitty and helper tools
  home.packages = with pkgs; [
    kitty
    kubeContextPopup
  ];

  # Symlink kitty configuration from dotfiles
  xdg.configFile."kitty/kitty.conf".source = "${dotfiles}/kitty/kitty.conf";
  xdg.configFile."kitty/navi_select.py".source = "${dotfiles}/kitty/navi_select.py";

  # Fetch search kittens from upstream
  home.file.".config/kitty/scroll_mark.py".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/trygveaa/kitty-kitten-search/refs/heads/master/scroll_mark.py";
    sha256 = "1a1l7sp2x247da8fr54wwq7ffm987wjal9nw2f38q956v3cfknzi";
  };

  home.file.".config/kitty/search.py".source = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/trygveaa/kitty-kitten-search/refs/heads/master/search.py";
    sha256 = "035y3gwlr9ymb8y5zygv3knn91z1p5blj6gzv5vl2zcyhn7281n9";
  };
}
