{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.primaryUser = "rd";

  # Minimal system packages - just essential tools
  environment.systemPackages = with pkgs; [
    git
    curl
    tmux
    fzf
    coreutils
    docker
    colima
    kubectl
    nodejs
    python3
    go
    jq
    watch
    _1password-cli
    git-delta
  ];

  # GUI Applications
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";

    # GUI Apps
    casks = [
      # Browsers
      "google-chrome"
      # "firefox"

      # Development
      "alacritty"
      "zed"
      "google-cloud-sdk"
      "jetbrains-toolbox"
      # "docker"  # Docker Desktop

      # Utilities
      # "rectangle"  # Window management
      "raycast" # Launcher
      "1password"
      "notion-calendar"
      "languagetool"
      "postman"

      # Communication
      # "slack"
      # "discord"
      # "zoom"

      # Media
      "spotify"
      # "vlc"
    ];

    # Some CLI tools are better from Homebrew
    brews = [
      # macOS-specific tools that integrate deeply with the system
      # "mas"  # Mac App Store CLI
    ];

    # Mac App Store apps
    masApps = {
      #   "Amphetamine" = 937984704;
      #   "Xcode" = 497799835;
    };
  };

  nixpkgs.config.allowUnfreePredicate =
    let
      whitelist = map lib.getName [
        pkgs.google-chrome
        pkgs._1password
      ];
    in
    pkg: builtins.elem (lib.getName pkg) whitelist;

  # Basic Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "rd"
      ];
      allowed-users = [
        "@admin"
      ];
    };
  };

  system = {
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        # Only these stay in Dock — everything else disappears
        persistent-apps = [
          "${pkgs.google-chrome}/Applications/Google Chrome.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
        ];
        persistent-others = [ ];
      };
      finder = {
        AppleShowAllFiles = true;
      };
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
      };
    };

    # Changes CapsLock to Control
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };

  # Fix nixbld group GID mismatch
  ids.gids.nixbld = 350;

  environment.systemPath = [
    config.homebrew.brewPrefix # TODO https://github.com/LnL7/nix-darwin/issues/596
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "jetbrains-mono" ]; })
  ];

  # Create /etc/zshrc that loads the nix-darwin environment
  programs = {
    zsh = {
      enable = true;

      # shellAliases = {
      #   system-update = "cd ~/.nix-darwin && make update";
      # };
    };

    alacritty = {
      enable = true;

      settings = {
        # "debug.render_timer" = false;
        # window_opacity = 1;

        colors = {
          bright = {
            black = "0x595959";
            blue = "0x1FB0FF";
            cyan = "0x00E5E5";
            green = "0x4FC414";
            magenta = "0xED7EED";
            red = "0xFF4050";
            white = "0xFFFFFF";
            yellow = "0xE5BF00";
          };

          cursor = {
            cursor = "CellForeground";
            text = "CellBackground";
          };

          footer_bar = {
            background = "0x282a36";
            foreground = "0xf8f8f2";
          };

          line_indicator = {
            background = "None";
            foreground = "None";
          };

          normal = {
            black = "0x000000";
            blue = "0x3993D4";
            cyan = "0x00A3A3";
            green = "0x5C962C";
            magenta = "0xA771BF";
            red = "0xF0524F";
            white = "0x808080";
            yellow = "0xA68A0D";
          };

          primary = {
            background = "0x2B2B2B";
            foreground = "0xBBBBBB";
          };

          search = {
            focused_match = {
              background = "0xffb86c";
              foreground = "0x245980";
            };
            matches = {
              background = "0x50fa7b";
              foreground = "0x44475a";
            };
          };

          selection = {
            background = "0x245980";
            text = "CellForeground";
          };
        };

        env = {
          TERM = "xterm-256color";
        };

        font = {
          size = 12.0;
          normal = {
            family = "JetBrainsMono Nerd Font";
            style = "Regular";
          };
          bold = {
            family = "JetBrainsMono Nerd Font";
            style = "Bold";
          };
          italic = {
            family = "JetBrainsMono Nerd Font";
            style = "Italic";
          };
        };

        keyboard.bindings = [
          {
            key = "Right";
            mods = "Alt";
            chars = "\\u001BF";
          }
          {
            key = "Left";
            mods = "Alt";
            chars = "\\u001BB";
          }
        ];

        window = {
          dynamic_padding = true;
          padding = {
            x = 10;
            y = 10;
          };
        };

        shell = {
          program = "${pkgs.tmux}/bin/tmux";
          args = [
            "new"
            "-A"
            "-s main"
            "-f"
            "${config.xdg.configHome}/tmux/tmux.conf"
          ];
        };
      };
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
