{
  config,
  pkgs,
  lib,
  ...
}:

{
  system.primaryUser = lib.mkDefault "radoslawdejnek";

  environment.systemPackages = with pkgs; [
    # Nix
    nixd
    nil

    # Version Control
    git
    git-town
    gh
    mergiraf
    gitleaks
    delta

    # Core Utilities
    coreutils
    curl
    wget
    nano
    watch
    fzf
    tmux

    # Containers & Kubernetes
    docker
    docker-credential-helpers
    colima
    kubectl
    k3d

    # Go
    go
    gopls
    gotools
    gotest
    golangci-lint
    govulncheck
    gofumpt
    go-swag
    go-cover-treemap

    # Rust
    rustup
    cargo
    rust-analyzer
    openssl
    pkg-config

    # JavaScript / Python
    nodejs
    pnpm
    python3
    uv

    # Infrastructure & Secrets
    ansible
    sops
    gnupg
    age
    tailscale
    tailscale-gui

    # Database
    postgresql
    duckdb

    # Security & Auth
    _1password-cli
    oath-toolkit
    nmap
    proton-pass
    proton-pass-cli

    # File & Text Tools
    jq
    ripgrep
    fd
    ansifilter
    eza
    dust
    duf
    ghostscript

    # Web & Network
    curl # (already above, move here or keep in core)
    hurl
    w3m-full
    monolith

    # AI / LLM
    aichat
    ollama
    opencode
    codex

    # Media
    ffmpeg

    # Terminal Emulators
    alacritty

    # Docs, Presentations & Notes
    navi
    glow
    nb
    presenterm
    hugo
    tldr

    # Load Testing
    k6
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
      "firefox"

      # Development
      # "google-cloud-sdk"
      "jetbrains-toolbox"
      "zed"
      # "docker"  # Docker Desktop
      #
      "vlc"

      # Utilities
      # "rectangle"  # Window managemen
      "languagetool-desktop"
      "moom"
      "macwhisper"
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
      "discord"
      # "zoom"

      # Media
      "spotify"
      # "vlc"
      #
      "obsidian"
      "textual"
      "claude-code"
    ];

    taps = [ ];

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
        pkgs.proton-pass-cli
        pkgs.proton-pass
        pkgs.tailscale-gui
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
          # "/Applications/Google Chrome.app"
          # "/Applications/Slack.app"
          # "/Applications/Telegram.app"
          # "/Users/radoslawdejnek/Applications/Goland.app"
          # "${pkgs.alacritty}/Applications/Alacritty.app"
          # "/Applications/Zed.app"
          # "/Applications/1Password.app"
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
    "${config.homebrew.prefix}/bin" # TODO https://github.com/LnL7/nix-darwin/issues/596
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
