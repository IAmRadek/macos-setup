{ pkgs, ... }:

let
  username = "rd";
in
{
  system.primaryUser = username;
  # TODO https://github.com/LnL7/nix-darwin/issues/682
  users.users.${username}.home = "/Users/${username}";

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
        };

        initExtraFirst = ''
          # Custom git prompt function
          function git_prompt_info() {
            local ref
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
              ref=$(git symbolic-ref HEAD 2> /dev/null) || \
              ref=$(git rev-parse --short HEAD 2> /dev/null) || return 0
              echo "%F{green}(${ref#refs/heads/}$(parse_git_dirty))%f"
            fi
          }

          # Check for uncommitted changes
          function parse_git_dirty() {
            local STATUS
            STATUS=$(git status --porcelain 2> /dev/null | tail -n1)
            if [[ -n $STATUS ]]; then
              echo "%F{red}✗%f"
            else
              echo "%F{green}✔%f"
            fi
          }

          # Define the prompt
          PROMPT='%F{blue}[ %F{red}%n@%m:%~%f$(git_prompt_info)%F{blue} ]%f
 $ '

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
        '';

        initExtra = ''
          # Load zinit plugins

          # Essential plugins
          zinit light zdharma-continuum/fast-syntax-highlighting  # Command syntax highlighting
          zinit light zsh-users/zsh-autosuggestions               # Inline command suggestions
          zinit light Aloxaf/fzf-tab                              # Enhanced tab completion with fzf

          # History search with up/down arrows
          zinit snippet OMZL::history.zsh

          # Configure autosuggestions
          bindkey '^I' autosuggest-accept # Allow TAB to accept suggestions
          bindkey '^ ' autosuggest-execute # Ctrl+Space to execute suggestion
          ZSH_AUTOSUGGEST_STRATEGY=(history completion) # Use both history and completion for suggestions

          # Enhance completion system
          zstyle ':completion:*' menu select # Use menu selection for completion
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive completion
          zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # Colorize completion menu

          # Configure fzf-tab (improved tab completion)
          zstyle ':fzf-tab:*' fzf-command fzf
          zstyle ':fzf-tab:*' switch-group ',' '.'
          zstyle ':fzf-tab:*' fzf-preview 'ls -la $realpath'

          # Improved fzf-tab defaults for better completion
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1a $realpath'

          # Ensure compinit is properly initialized for zinit
          autoload -Uz compinit
          compinit
        '';
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
