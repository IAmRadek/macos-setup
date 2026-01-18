{ pkgs, ... }:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  # Install tmux and related tools
  home.packages = with pkgs; [
    tmux
    (writeShellScriptBin "cmdai-tmux" ''
      #!/usr/bin/env bash
      set -euo pipefail
      printf 'AI cmd> ' >&2
      IFS= read -r input || exit 0
      aichat --role %shell% --no-stream "$input" | tr -d '\n\r'
    '')
  ];

  # Symlink tmux configuration from dotfiles
  xdg.configFile."tmux/tmux.conf".source = "${dotfiles}/tmux/tmux.conf";

  # Install tmux plugins
  home.file.".config/tmux/plugins/tmux-k8s-context-switcher".source = pkgs.fetchFromGitHub {
    owner = "IAmRadek";
    repo = "tmux-k8s-context-switcher";
    rev = "main";
    sha256 = "17hl1q0lm6nv1rj9frwbanvb3sa75pmd7hbh79f28q138llpbm22";
  };

  home.file.".config/tmux/plugins/kube-tmux".source = pkgs.fetchFromGitHub {
    owner = "jonmosco";
    repo = "kube-tmux";
    rev = "master";
    sha256 = "0wfsqlcs24jkm1szih0s5g0i17qj8laks0wbd9nnm77q92q77gb7";
  };
}
