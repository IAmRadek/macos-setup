{ pkgs, ... }:

let
  username = "radoslawdejnek";
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
            ${pkgs.git-town}/bin/git-town completions zsh > "$HOME/.cache/zsh/_git-town.zsh"
          '';

          helmCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/helm completion zsh > "$HOME/.cache/zsh/_helm.zsh"
          '';
        };

        home.sessionPath = [
          "$HOME/go/bin"
          "$HOME/.local/bin"
        ];

        home.packages = [
          (pkgs.buildGoModule {
            pname = "godotenv";
            version = "1.5.1";

            src = pkgs.fetchFromGitHub {
              owner = "joho";
              repo = "godotenv";
              rev = "v1.5.1";
              hash = "sha256-kA0osKfsc6Kp+nuGTRJyXZZlJt1D/kuEazKMWYCWcQ8=";
            };

            subPackages = [ "cmd/godotenv" ];
            vendorHash = null;
          })
        ];

        # SSH configuration from dotfiles
        home.file.".ssh/config".source = "${dotfiles}/ssh/config";

        imports = [
          ../modules/alacritty.nix
          ../modules/zsh.nix
          ../modules/tmux.nix
          ../modules/git.nix
          ../modules/tools.nix
        ];

        # Nano configuration from dotfiles
        xdg.configFile."nano/nanorc".source = "${dotfiles}/nano/nanorc";
      };
  };
}
