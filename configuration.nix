{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.primaryUser = lib.mkDefault "radoslawdejnek";

  environment.systemPackages = with pkgs; [
    nixd
    git
    git-town
    gh
    mergiraf
    curl
    tmux
    fzf
    coreutils
    docker
    colima
    kubectl
    nodejs
    python3
    sops
    gnupg
    age

    dust
    duf
    hurl
    navi
    glow

    alacritty

    go
    gopls
    gotools
    gotest
    golangci-lint
    govulncheck

    uv

    jq
    fd
    watch
    _1password-cli
    delta
    nano
    oath-toolkit
    go-swag
  ];

  # GUI Applications
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "uninstall";
      upgrade = true;
    };

    # GUI Apps
    casks = [
      # Browsers
      "google-chrome"
      # "firefox"

      # Development
      # "google-cloud-sdk"
      "jetbrains-toolbox"
      "zed"
      # "docker"  # Docker Desktop

      # Utilities
      # "rectangle"  # Window managemen
      "languagetool-desktop"
      "moom"
      "macwhisper"
      "obsidian"
      "raycast" # Launcher
      "1password"
      "notion-calendar"
      "postman"
      "elgato-stream-deck"
      "alt-tab"

      # Communication
      "slack"
      "telegram"
      "signal"
      "whatsapp"
      # "discord"
      # "zoom"

      # Media
      "spotify"
      # "vlc"
    ];

    # Some CLI tools are better from Homebrew
    brews = [
      "helm"
      # macOS-specific tools that integrate deeply with the system
      # "mas"  # Mac App Store CLI
    ];

    # Mac App Store apps
    masApps = {
      #   "Amphetamine" = 937984704;
    };
  };

  nixpkgs.config.allowUnfreePredicate =
    let
      whitelist = map lib.getName [
        pkgs.google-chrome
        pkgs._1password-cli
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
          "/Applications/Google Chrome.app"
          "/Applications/Slack.app"
          "/Applications/Telegram.app"
          "/Users/radoslawdejnek/Applications/Goland.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
          "/Applications/Zed.app"
          "/Applications/1Password.app"
        ];
        persistent-others = [ ];
      };
      finder = {
        AppleShowAllFiles = true;
        FXPreferredViewStyle = "clmv";
        NewWindowTarget = "Home";
        ShowPathbar = true;
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
