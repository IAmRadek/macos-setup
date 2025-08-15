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
    delta
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
      # "google-cloud-sdk"
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
  };

  # Fix nixbld group GID mismatch
  ids.gids.nixbld = 350;

  environment.systemPath = [
    config.homebrew.brewPrefix # TODO https://github.com/LnL7/nix-darwin/issues/596
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Create /etc/zshrc that loads the nix-darwin environment
  programs = {
    zsh = {
      enable = true;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
