{
  lib,
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
  # Install zsh and related tools
  home.packages = with pkgs; [
    zsh
    starship
    fzf
    eza
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # Source the portable zshrc and aliases from dotfiles
    initContent = lib.mkMerge [
      (lib.mkOrder 100 ''
        source ${dotfiles}/zsh/aliases.zsh
      '')
      (lib.mkOrder 500 (builtins.readFile "${dotfiles}/zsh/zshrc"))
    ];
  };

  # Starship prompt - symlink from dotfiles
  programs.starship.enable = true;
  xdg.configFile."starship.toml".source = "${dotfiles}/starship/starship.toml";
}
