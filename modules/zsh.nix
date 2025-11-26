{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellAliases = {
      system-update = "cd ~/.nix-darwin && make update";
      system-edit = "zed ~/.nix-darwin";
      ".." = "cd ..";
      "g" = "git";
      "k" = "kubectl";
      "ls" = "eza -l";
    };

    initContent =
      let
        zshConfigEarlyInit = lib.mkOrder 500 ''
          # zmodload zsh/zprof
          # record the time when zsh starts parsing rc files
          zmodload zsh/datetime 2>/dev/null
          zsh_start_time=$EPOCHREALTIME

          function show_startup_time() {
            return
            local elapsed=$(( ($EPOCHREALTIME - $zsh_start_time) * 1000 ))
            printf "\n🚀 Zsh startup took %.2f ms\n\n" $elapsed
            # only show once, then remove the hook
            unset -f show_startup_time
          }

          # precmd runs before the first prompt
          precmd_functions+=(show_startup_time)

          ZCACHEDIR="$HOME/.cache/zsh"
          autoload -Uz compinit

          # Fix CR/LF only when running inside tmux
          if [[ -n $TMUX ]]; then
            stty icrnl -inlcr -igncr 2>/dev/null
          fi
        '';
        zshConfigLateInit = lib.mkOrder 2000 ''
          # zprof
        '';
        zshConfig = lib.mkOrder 1000 ''
          # Set nano as default editor
          export EDITOR="zed"
          export VISUAL="zed"

          # Fix for testcontainers with colima (https://github.com/testcontainers/testcontainers-go/issues/2952)
          export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
          export DOCKER_HOST="unix://''${HOME}/.colima/docker.sock"

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
          export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig

          # Essential plugins
          zinit ice lucid wait"1"; zinit light zdharma-continuum/fast-syntax-highlighting
          zinit light zsh-users/zsh-autosuggestions
          zinit ice lucid wait"1"; zinit light Aloxaf/fzf-tab
          zinit ice lucid wait"2"; zinit light Freed-Wu/fzf-tab-source
          zinit ice lucid wait"1"; zinit light mfaerevaag/wd
          zinit ice lucid wait"1"; zinit light ianthehenry/zsh-autoquoter

          ZAQ_PREFIXES=('git commit -m' 'g commit -m' 'watch')

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

          fpath=($HOME/.zsh/completions $HOME/.cache/zsh $fpath)

          # Simple completion order
          zstyle ':completion:*' completer _expand_alias _complete _ignored

          # Basic fzf-tab configuration
          zstyle ':fzf-tab:*' fzf-command fzf
          zstyle ':fzf-tab:*' switch-group ',' '.'
          zstyle ':fzf-tab:*' fzf-preview 'ls -la $realpath'

          # Enable completion caching for better performance
          zstyle ':completion:*' use-cache on
          zstyle ':completion:*' cache-path "$ZCACHEDIR/zcompcache"

          # Simple fzf-tab key bindings
          zstyle ':fzf-tab:*' continuous-trigger 'tab'            # TAB cycles through options
          zstyle ':fzf-tab:*' fzf-bindings 'tab:down,btab:up'     # TAB/Shift+TAB to navigate

          # Improved fzf-tab defaults for better completion
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01'
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1a $realpath'

          # Ensure compinit is properly initialized for zinit
          compinit -u -d "$ZCACHEDIR/zcompdump-$ZSH_VERSION"

          compdef _nb nb 2>/dev/null
          compdef _helm helm 2>/dev/null
          compdef _git-town git-town 2>/dev/null
          compdef _watson watson 2>/dev/null
        '';
      in
      lib.mkMerge [
        zshConfigEarlyInit
        zshConfig
        zshConfigLateInit
      ];
  };

  home.packages = [
    (pkgs.writeShellScriptBin "tm-current-task" ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      # If tm is not available → hide module
      if ! command -v tm >/dev/null 2>&1; then
      exit 1
      fi

      out="$(tm status 2>/dev/null || true)"
      line="$(printf '%s\n' "$out" | head -n1)"

      case "$line" in
      "No active time entry."*)
          exit 1
          ;;
      "Tracking:"*)
          # Example: "Tracking: proj / task (1m 25s)"
          rest="''${line#Tracking: }"     # "proj / task (1m 25s)"

          project="''${rest%% / *}"       # before " / "
          tmp="''${rest#* / }"            # "task (1m 25s)"
          task="''${tmp%% (*}"            # before " ("
          elapsed="''${tmp#*(}"           # "1m 25s)"
          elapsed="''${elapsed%)}"        # "1m 25s"

          # ⏱️ = stopwatch emoji
          printf '%s / %s · %s\n' "''$project" "''$task" "''$elapsed"
          exit 0
          ;;
      *)
          # Unknown format → better hide
          exit 1
          ;;
      esac
    '')
  ];

  programs.starship = {
    enable = true;
    settings = {
      # Starship configuration
      add_newline = false;

      format = ''$directory$nix_shell$git_branch$git_status$golang$kubernetes''${custom.tm}$cmd_duration$line_break$character'';

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
        format = ''\[[$symbol$branch]($style)\]'';
        symbol = "🌱 ";
      };

      golang = {
        format = ''\[[$symbol($version)]($style)\]'';
      };

      git_status = {
        format = ''([\[$all_status$ahead_behind\]]($style))'';
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

      nix_shell = {
        format = ''\[[nix-shell](bold blue)\]'';
      };

      kubernetes = {
        format = ''\[[$cluster:$context](dimmed green)\]'';
        disabled = false;
      };

      cmd_duration = {
        min_time = 2000;
        format = ''\[[⏱ $duration]($style)\]'';
      };

      custom = {
        tm = {
          command = "tm-current-task";
          # Only run if the helper exists
          when = "tm-current-task >/dev/null 2>&1";
          format = ''\[[$output]($style)\]'';
          style = "bold green";
          disabled = false;
        };
      };
    };
  };

}
