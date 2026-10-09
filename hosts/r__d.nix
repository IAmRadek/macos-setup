{ pkgs, ... }:

let
  username = "r__d";
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  environment.systemPackages = with pkgs; [
    infisical
    hugo
  ];

  homebrew.casks = [
    "whatsapp"
    "telegram"
    "discord"
    "little-snitch"
    "elgato-stream-deck"
  ];

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
      { pkgs, ... }:
      {
        home.sessionVariables = {
          DFT_PARSE_ERROR_LIMIT = "100";
        };

        home.sessionPath = [
          "$HOME/Development/Go/bin"
          "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
        ];

        home.packages = [ ];

        home.file.".hushlogin".text = "";

        programs.ssh.settings.homelab = {
          hostname = "10.10.0.100";
          user = "homelab";
          forwardAgent = true;
        };

        imports = [
          ../modules/ghostty.nix
        ];
      };
  };
}
