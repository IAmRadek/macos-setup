{ pkgs, ... }:

let
  username = "r__d";
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  system.primaryUser = username;
  users.users.${username}.home = "/Users/${username}";

  environment.systemPackages = with pkgs; [
    starship
  ];

  homebrew = { };

  system = {
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        persistent-apps = [
          "/Applications/Firefox.app"
          "${pkgs.kitty}/Applications/Kitty.app"
          "/Users/${username}/Applications/Goland.app"
          "/Applications/Discord.app"
          "/Applications/Zed.app"
        ];
        persistent-others = [ ];
      };
    };
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username} =
      { pkgs, lib, ... }:
      {
        home.stateVersion = "22.11";
        programs.home-manager.enable = true;

        home.activation = {
          createDevDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/Development/github.com
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.config/tmux/plugins
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.cache/zsh
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.runbooks
          '';

          gitTownCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.git-town}/bin/git-town completions zsh > "$HOME/.cache/zsh/_git-town"
          '';

          helmCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/helm completion zsh > "$HOME/.cache/zsh/_helm"
          '';

          nbCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.curl}/bin/curl -L https://raw.githubusercontent.com/xwmx/nb/master/etc/nb-completion.zsh -o $HOME/.cache/zsh/_nb
          '';

          watsonCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.curl}/bin/curl -L https://raw.githubusercontent.com/jazzband/Watson/refs/heads/master/watson.zsh-completion -o $HOME/.cache/zsh/_watson
          '';
        };

        home.sessionPath = [
          "$HOME/Development/Go/bin"
          "$HOME/.local/bin"
          "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        ];

        home.packages = [ ];

        home.file.".hushlogin".text = "";

        # SSH configuration from dotfiles
        home.file.".ssh/config".source = "${dotfiles}/ssh/config";

        imports = [
          ../modules/kitty.nix
          ../modules/alacritty.nix
          ../modules/zsh.nix
          ../modules/tmux.nix
          ../modules/git.nix
          ../modules/tools.nix
          ../modules/aichat.nix
          ../modules/navi.nix
        ];

        # Nano configuration from dotfiles
        xdg.configFile."nano/nanorc".source = "${dotfiles}/nano/nanorc";
      };
  };
}
