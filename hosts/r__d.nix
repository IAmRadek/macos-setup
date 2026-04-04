{ pkgs, ... }:

let
  username = "r__d";
in
{
  imports = [
    ../modules/caddy.nix
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
          "/Applications/Firefox.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
          "/Users/${username}/Applications/Goland.app"
          "/Applications/Discord.app"
          "/Applications/Zed.app"
        ];
        persistent-others = [ ];
      };
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

          helmCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            /opt/homebrew/bin/helm completion zsh > "$HOME/.cache/zsh/_helm"
          '';

          nbCompletion = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            ${pkgs.curl}/bin/curl -L https://raw.githubusercontent.com/xwmx/nb/master/etc/nb-completion.zsh -o $HOME/.cache/zsh/_nb
          '';

          sshPrivateConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.nix-darwin/private"
            $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$HOME/.ssh"
            if [ ! -f "$HOME/.nix-darwin/private/ssh.private" ]; then
              $DRY_RUN_CMD touch $VERBOSE_ARG "$HOME/.nix-darwin/private/ssh.private"
            fi
            $DRY_RUN_CMD ln -sf $VERBOSE_ARG "$HOME/.nix-darwin/private/ssh.private" "$HOME/.ssh/config.private"
          '';
        };

        home.sessionVariables = {
          SSH_AUTH_SOCK = "$HOME/.ssh/proton-pass-agent.sock";
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
          matchBlocks."*" = {
            extraOptions.IdentityAgent = ''"~/.ssh/proton-pass-agent.sock"'';
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
              "/Users/${username}/.ssh/proton-pass-agent.sock"
            ];
            RunAtLoad = true;
            KeepAlive = true;
          };
        };

        imports = [
          ../modules/kitty.nix
          ../modules/alacritty.nix
          ../modules/zsh.nix
          ../modules/tmux.nix
          ../modules/git.nix
          ../modules/tools.nix
          ../modules/aichat.nix
          ../modules/navi.nix
          ../modules/claude.nix
          ../modules/knowledge.nix
          # LLM stack
          ../modules/ollama.nix
          ../modules/open-webui.nix
          ../modules/continue.nix
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
