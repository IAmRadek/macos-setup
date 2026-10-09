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

  homebrew = { };

  system = {
    defaults = {
      dock = {
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
    users.${username} =
      { pkgs, lib, ... }:
      {
        home.activation = {
          hCloudCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/hcloud completion zsh > "$HOME/.cache/zsh/_hcloud"
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
          ../modules/ghostty.nix
          ../modules/aichat.nix
          ../modules/halloy.nix
          # LLM stack
          ../modules/ollama.nix
        ];
      };
  };
}
