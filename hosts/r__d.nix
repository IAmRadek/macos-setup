{ pkgs, ... }:

let
  username = "r__d";
in
{
  imports = [
    ../modules/tailscale.nix
  ];

  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  environment.systemPackages = with pkgs; [
    starship
  ];

  homebrew = { };

  system = {
    # Changes CapsLock to Control
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        # Only these stay in Dock — everything else disappears
        persistent-apps = [
          "/Applications/Zen.app"
          "${pkgs.ghostty-bin}/Applications/Ghostty.app"
          "/Users/${username}/Applications/Goland.app"
          "/Users/${username}/Applications/RustRover.app"
          "/Applications/Slack.app"
          "/Applications/Discord.app"
          { spacer.small = true; }
        ];
        persistent-others = [ ];
      };
    };
  };

  nix.linux-builder = {
    enable = true;
    maxJobs = 4;
    supportedFeatures = [
      "kvm"
      "benchmark"
      "big-parallel"
      "nixos-test"
    ];
    config = {
      virtualisation = {
        cores = 6;
        darwin-builder.diskSize = 60 * 1024;   # two VM store images + test payloads
        darwin-builder.memorySize = 8 * 1024;
      };
    };
  };

  # Let the builder pull from cache.nixos.org itself instead of routing
  # every dependency through your Mac. Currently false.
  nix.settings.builders-use-substitutes = true;

  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    users.${username} =
      { pkgs, lib, ... }:
      {
        home.stateVersion = "22.11";
        programs.home-manager.enable = true;

        # Create Development directory structure
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
          hCloudCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/hcloud completion zsh > "$HOME/.cache/zsh/_hcloud"
          '';

          helmCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/helm completion zsh > "$HOME/.cache/zsh/_helm"
          '';

          sshPrivateConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.nix-darwin/private"
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.ssh"
            if [ ! -f "$HOME/.nix-darwin/private/ssh.private" ]; then
              $DRY_RUN_CMD touch $VERBOSE_ARG "$HOME/.nix-darwin/private/ssh.private"
            fi
            $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$HOME/.nix-darwin/private/ssh.private" "$HOME/.ssh/config.private"
          '';

          # Disable the pinch-to-Launchpad / "Apps" gestures so the pinch can be
          # re-bound to Raycast in BetterTouchTool (see README). On macOS 26 (Tahoe)
          # it's the FIVE-finger pinch that opens the launcher; the four-finger key
          # is disabled too for good measure. macOS stores trackpad gestures per-host
          # (ByHost / -currentHost), which nix-darwin's system.defaults cannot reach,
          # so write them here as the user. 0 = off. Reload with `killall Dock` or a
          # log out/in.
          disableLaunchpadPinch = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
              for k in TrackpadFourFingerPinchGesture TrackpadFiveFingerPinchGesture; do
                $DRY_RUN_CMD /usr/bin/defaults -currentHost write "$d" "$k" -int 0
              done
            done
          '';
        };

        home.sessionVariables = {
          DFT_PARSE_ERROR_LIMIT = "100";
          SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-ssh-agent.sock";
        };

        home.sessionPath = [
          "$HOME/Development/Go/bin"
          "$HOME/.local/bin"
          "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        ];

        home.packages = [ ];

        home.file.".hushlogin".text = "";

        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings."*" = {
            identityAgent = ''"~/.ssh/proton-pass-ssh-agent.sock"'';
          };
          settings.homelab = {
            hostname = "10.10.0.100";
            user = "homelab";
            forwardAgent = true;
          };
          extraConfig = ''
            Include ~/.ssh/config.private
          '';
        };

        launchd.agents.proton-pass-ssh-agent = {
          enable = true;
          config = {
            Label = "com.protonpass.ssh-agent";
            ProgramArguments = [
              "${pkgs.proton-pass-cli}/bin/pass-cli"
              "ssh-agent"
              "start"
              "--vault-name"
              "SSH"
              "--socket-path"
              "/Users/${username}/.ssh/proton-pass-ssh-agent.sock"
            ];
            RunAtLoad = true;
            KeepAlive = true;
          };
        };

        imports = [

          ../modules/alacritty.nix
          ../modules/ghostty.nix
          ../modules/zsh.nix
          ../modules/tmux.nix
          ../modules/nvim.nix
          ../modules/git.nix
          ../modules/tools.nix
          ../modules/aichat.nix
          ../modules/claude.nix
          ../modules/codex.nix
          ../modules/pi.nix
          ../modules/zed.nix
          ../modules/halloy.nix
          # LLM stack
          ../modules/ollama.nix
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
