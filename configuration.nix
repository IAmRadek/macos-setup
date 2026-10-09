{
  config,
  pkgs,
  lib,
  ...
}:

let
  googleCloudSdkWithPubsub = pkgs.google-cloud-sdk.withExtraComponents [
    pkgs.google-cloud-sdk.components."pubsub-emulator"
  ];
in
{
  imports = [
    ./modules/tailscale.nix
  ];

  environment.systemPackages = with pkgs; [
    # Nix
    nixd

    # Version Control
    git
    git-town
    gh
    mergiraf
    gitleaks
    difftastic
    github-mcp-server

    # Core Utilities
    starship
    coreutils
    curl
    wget
    nano
    watch
    fzf
    tmux
    neovim
    btop
    go-task

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

    # Wasm
    twiggy
    binaryen

    # JavaScript / Python
    nodejs
    pnpm
    python3
    uv
    playwright
    playwright-driver
    tailwindcss_4

    # Infrastructure & Secrets
    ansible
    sops
    gnupg
    age
    tailscale
    googleCloudSdkWithPubsub
    google-cloud-sql-proxy

    # Database
    postgresql

    # Security & Auth
    oath-toolkit
    nmap
    proton-pass-cli

    # File & Text Tools
    jq
    ripgrep
    fd
    tree
    eza
    dust
    duf
    ghostscript

    # Web & Network
    curl # (already above, move here or keep in core)
    httpie

    # AI / LLM
    aichat
    ollama
    opencode
    codex
    claude-code
    pi-coding-agent

    # Media
    ffmpeg
    transmission_4-mac
    # Terminal Emulators
    alacritty
    ghostty-bin

    # Docs, Presentations & Notes
    glow
    presenterm
    tldr

    # Load Testing
    k6
  ];

  nixpkgs.config.allowUnfree = true;

  # GUI Applications
  homebrew = {
    enable = true;
    onActivation = {
      # Don't hit the network / upgrade casks on every rebuild — do it
      # deliberately with `brew update && brew upgrade` when you want to.
      autoUpdate = false;
      cleanup = "uninstall";
      upgrade = false;
    };

    # GUI Apps
    casks = [
      # Browsers
      "google-chrome"
      "zen"

      # Development
      # "google-cloud-sdk"
      "jetbrains-toolbox"
      "zed"
      "claude"
      # "docker"  # Docker Desktop
      #
      "vlc"

      # Utilities
      "languagetool-desktop"
      "moom"
      "macwhisper"
      "raycast" # Launcher
      "notion-calendar"
      "postman"
      "menubar-apps/menubar-apps/pullbar"
      "pearcleaner"
      "proton-pass"
      "anarlog"
      "istat-menus"
      "macs-fan-control"

      # Communication
      "slack"
      # "zoom"

      # Media
      "spotify"
      # "vlc"
      #
      "coteditor"
    ];

    taps = [
    ];

    # Some CLI tools are better from Homebrew
    brews = [
      "helm"
      "hcloud"
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
        pkgs.proton-pass-cli
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

    # Weekly garbage collection: drop generations older than 14 days.
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      };
      options = "--delete-older-than 14d";
    };

    # Deduplicate the store via hardlinks after each build.
    optimise.automatic = true;
  };

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
          # "/Applications/Google Chrome.app"
          # "/Applications/Slack.app"
          # "/Applications/Telegram.app"
          # "/Users/radoslawdejnek/Applications/Goland.app"
          # "${pkgs.alacritty}/Applications/Alacritty.app"
          # "/Applications/Zed.app"
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

    # Spotlight: keep it as an app launcher, not a file search.
    # Enables the Applications category (plus harmless menu utilities) and
    # disables every file category so documents/images/PDFs/etc. don't show up.
    # Note: this controls what Spotlight *searches/shows*; the volume metadata
    # index (mds) still runs — macOS can't index "apps only".
    defaults.CustomUserPreferences."com.apple.Spotlight".orderedItems = [
      { enabled = true;  name = "APPLICATIONS"; }
      { enabled = true;  name = "MENU_EXPRESSION"; }         # Calculator
      { enabled = true;  name = "MENU_DEFINITION"; }         # Dictionary
      { enabled = true;  name = "MENU_CONVERSION"; }         # Unit conversion
      { enabled = true;  name = "SYSTEM_PREFS"; }            # System Settings panes
      { enabled = false; name = "MENU_SPOTLIGHT_SUGGESTIONS"; }
      { enabled = false; name = "MENU_WEBSEARCH"; }
      { enabled = false; name = "DOCUMENTS"; }
      { enabled = false; name = "DIRECTORIES"; }
      { enabled = false; name = "PRESENTATIONS"; }
      { enabled = false; name = "SPREADSHEETS"; }
      { enabled = false; name = "PDF"; }
      { enabled = false; name = "MESSAGES"; }
      { enabled = false; name = "CONTACT"; }
      { enabled = false; name = "EVENT_TODO"; }
      { enabled = false; name = "IMAGES"; }
      { enabled = false; name = "BOOKMARKS"; }
      { enabled = false; name = "MUSIC"; }
      { enabled = false; name = "MOVIES"; }
      { enabled = false; name = "FONTS"; }
      { enabled = false; name = "SOURCE"; }
      { enabled = false; name = "MENU_OTHER"; }
    ];
  };

  # Fix nixbld group GID mismatch
  ids.gids.nixbld = 350;

  environment.systemPath = [
    "${config.homebrew.prefix}/bin" # TODO https://github.com/LnL7/nix-darwin/issues/596
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

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
