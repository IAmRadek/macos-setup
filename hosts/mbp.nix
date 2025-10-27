{ pkgs, ... }:

let
  username = "radoslawdejnek";
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  environment.systemPackages = with pkgs; [
    starship
  ];

  homebrew = {};

  system = {
    # Changes CapsLock to Control
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username} = { pkgs, lib, config, ... }: {
      home.stateVersion = "22.11";
      programs.home-manager.enable = true;

      # Create Development directory structure
      home.activation = {
        createDevDirectories = lib.hm.dag.entryAfter ["writeBoundary"] ''
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
                repo  = "godotenv";
                rev   = "v1.5.1";
                hash  = "sha256-kA0osKfsc6Kp+nuGTRJyXZZlJt1D/kuEazKMWYCWcQ8=";
            };

            # Build only the CLI
            subPackages = [ "cmd/godotenv" ];
            vendorHash = null;
        })
      ];

      programs.ssh = {
        enable = true;
        extraConfig = ''
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        '';
      };

      imports = [
          ../modules/alacritty.nix
          ../modules/zsh.nix
          ../modules/tmux.nix
          ../modules/git.nix
          ../modules/tools.nix
        ];

      # Configure nano with xdg.configFile
      xdg.configFile."nano/nanorc".text = ''
        # Display line numbers
        set linenumbers

        # Use auto-indentation
        set autoindent

        # Display cursor position in the status bar
        set constantshow

        # Enable mouse support
        set mouse

        # Don't wrap text at the end of the line
        set nowrap

        # Syntax highlighting
        include "${pkgs.nano}/share/nano/*.nanorc"
      '';
    };
  };
}
