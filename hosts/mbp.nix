{ pkgs, ... }:

let
  username = "rd";
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

  environment.systemPackages = with pkgs; [
    starship
  ];

  homebrew = {
    # casks = [
    # ];
    # masApps = {
    # };
  };

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
        '';
      };

      programs.ssh = {
        enable = true;
        extraConfig = ''
          IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        '';
      };

      programs.zsh = {
        enable = true;

        shellAliases = {
          system-update = "cd ~/.nix-darwin && make update";
          ".." = "cd ..";
          "g" = "git";
          "k" = "kubectl";
        };

        initContent = ''
          # Set nano as default editor
          export EDITOR="nano"
          export VISUAL="nano"

          # Define zinit home directory
          ZINIT_HOME="$HOME/.zinit"

          # Check if zinit is installed, if not, install it
          if [[ ! -d "$ZINIT_HOME" ]]; then
            print -P "%F{33}▓▒░ %F{220}Installing %F{33}ZINIT%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
            mkdir -p "$ZINIT_HOME"
            git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME/bin"
            print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b"
          fi

          # Source zinit
          source "$ZINIT_HOME/bin/zinit.zsh"

          # Load zinit plugins

          # Essential plugins
          zinit light zdharma-continuum/fast-syntax-highlighting  # Command syntax highlighting
          zinit light zsh-users/zsh-autosuggestions               # Inline command suggestions
          zinit light Aloxaf/fzf-tab                              # Enhanced tab completion with fzf
          zinit light Freed-Wu/fzf-tab-source
          zinit light mfaerevaag/wd

          # History substring search for better history navigation
          zinit light zsh-users/zsh-history-substring-search

          # Configure autosuggestions
          bindkey '^ ' autosuggest-execute                        # Ctrl+Space to execute suggestion
          ZSH_AUTOSUGGEST_STRATEGY=(history completion)           # Use history and completion
          ZSH_AUTOSUGGEST_USE_ASYNC=1                             # Async suggestions for better performance

          # Setup history navigation
          bindkey '^[[A' history-substring-search-up              # Up arrow
          bindkey '^[[B' history-substring-search-down            # Down arrow
          bindkey '^R' history-incremental-search-backward        # Ctrl+R for history search

          # Configure history for better suggestion quality
          HISTFILE=~/.zsh_history
          HISTSIZE=50000
          SAVEHIST=50000
          setopt SHARE_HISTORY          # share history between sessions
          setopt EXTENDED_HISTORY        # add timestamps to history
          setopt HIST_IGNORE_DUPS        # don't record duplicated commands
          setopt HIST_FIND_NO_DUPS       # don't show duplicates in search
          setopt HIST_REDUCE_BLANKS      # remove superfluous blanks
          setopt HIST_IGNORE_SPACE       # don't record commands starting with space
          setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicates first

          # Enhance completion system for history-based suggestions
          # Basic completion system configuration
          zstyle ':completion:*' menu select                       # Use menu selection for completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive completion
          zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01' # Colorize completion menu

          # Simple completion order
          zstyle ':completion:*' completer _expand_alias _complete _ignored

          # Basic fzf-tab configuration
          zstyle ':fzf-tab:*' fzf-command fzf
          zstyle ':fzf-tab:*' switch-group ',' '.'
          zstyle ':fzf-tab:*' fzf-preview 'ls -la $realpath'

          # Enable completion caching for better performance
          zstyle ':completion:*' use-cache on
          zstyle ':completion:*' cache-path "$HOME/.zcompcache"

          # Simple fzf-tab key bindings
          zstyle ':fzf-tab:*' continuous-trigger 'tab'            # TAB cycles through options
          zstyle ':fzf-tab:*' fzf-bindings 'tab:down,btab:up'     # TAB/Shift+TAB to navigate

          # Initialize completion system
          autoload -Uz compinit
          compinit

          # Ensure nano is used for editing
          alias edit='nano'

          # Improved fzf-tab defaults for better completion
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01'
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1a $realpath'

          # Ensure compinit is properly initialized for zinit
          autoload -Uz compinit
          compinit

          eval "$(starship init zsh)"
        '';
      };

      # Configure nano with xdg.configFile
      xdg.configFile."nano/nanorc".text = ''
        # Display line numbers
        set linenumbers

        # Use auto-indentation
        set autoindent

        # Display cursor position in the status bar
        set constantshow

        # Use smooth scrolling
        set smooth

        # Enable mouse support
        set mouse

        # Don't wrap text at the end of the line
        set nowrap

        # Syntax highlighting
        include "${pkgs.nano}/share/nano/*.nanorc"
      '';

      # Configure tmux
      programs.tmux = {
        enable = true;
        historyLimit = 100000;
        terminal = "screen-256color";
        keyMode = "vi";
        mouse = true;
        escapeTime = 0;
        baseIndex = 1;
        prefix = "C-a";
        shell = "${pkgs.zsh}/bin/zsh";

        extraConfig = ''
          set -ag terminal-overrides ",xterm-256color:RGB"
          setw -g xterm-keys on

          # # Change CTRL-B to more convenient CTRL-A
          # unbind C-b
          # set-option -g prefix C-a
          # bind-key C-a send-prefix

          set -g @plugin 'IAmRadek/tmux-k8s-context-switcher'

          # Fix titlebar
          set -g set-titles on
          set -g set-titles-string "#T"

          # Avoid date/time taking up space
          set -g status-right \'\'
          set -g status-right '#(/bin/bash $HOME/.config/tmux/plugins/kube-tmux/kube.tmux 250 red cyan) #[fg=yellow]%a %Y-%m-%d %H:%M'
          set -g status-right-length 250
          set -g status-right-style default

          # Split current window horizontally
          bind - split-window -v -c "#{pane_current_path}"
          unbind %
          # Split current window vertically
          bind | split-window -h -c "#{pane_current_path}"
          unbind '"'

          bind t new-window \; display "new window opened"
          bind w kill-window

          # Start numbering panes at 1, not 0.
          set -g pane-base-index 1

          ######################
          ### DESIGN CHANGES ###
          ######################
          set -g status-style "bg=default"
          setw -g window-status-current-style fg=black,bg=white

          set -g window-status-format '#I:#(pwd="#{pane_current_path}"; echo $${pwd###*/})#F'
          set -g window-status-current-format '#I:#(pwd="#{pane_current_path}"; echo $${pwd###*/})#F'
          set -g status-interval 10
        '';

        # plugins = with pkgs; [
        #   {
        #     plugin = tmuxPlugins.tpm;
        #     extraConfig = "set -g @plugin 'tmux-plugins/tpm'";
        #   }
        #   {
        #     plugin = tmuxPlugins.sensible;
        #     extraConfig = "set -g @plugin 'tmux-plugins/tmux-sensible'";
        #   }
        # ];
      };

      # Install custom tmux plugins
      home.file.".config/tmux/plugins/tmux-k8s-context-switcher".source = pkgs.fetchFromGitHub {
        owner = "IAmRadek";
        repo = "tmux-k8s-context-switcher";
        rev = "main";
        sha256 = "17hl1q0lm6nv1rj9frwbanvb3sa75pmd7hbh79f28q138llpbm22";
      };

      home.file.".config/tmux/plugins/kube-tmux".source = pkgs.fetchFromGitHub {
        owner = "jonmosco";
        repo = "kube-tmux";
        rev = "master";
        sha256 = "0wfsqlcs24jkm1szih0s5g0i17qj8laks0wbd9nnm77q92q77gb7";
      };

      programs.starship = {
        enable = true;
        settings = {
          # Starship configuration
          add_newline = true;

          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[✗](bold red)";
          };

          directory = {
            truncation_length = 0;
            truncate_to_repo = false;
            home_symbol = "~";
            use_os_path_sep = true;
          };

          git_branch = {
            format = "[$symbol$branch]($style) ";
            symbol = "🌱 ";
          };

          git_status = {
            format = ''([\[$all_status$ahead_behind\]]($style) )'';
            conflicted = "🏳";
            ahead = "⇡\${count}";
            behind = "⇣\${count}";
            diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
            untracked = "?";
            stashed = "📦";
            modified = "!";
            staged = "+";
            renamed = "»";
            deleted = "✘";
          };

          cmd_duration = {
            min_time = 2000;
            format = "took [$duration]($style) ";
          };
        };
      };

      programs.alacritty = {
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

          terminal.shell = {
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
  };
}
