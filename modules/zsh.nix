{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # compinit runs in initContent below, after fpath is complete
    completionInit = "";

    history = {
      path = "$HOME/.zsh_history";
      size = 50000;
      save = 50000;
      share = false;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      system-edit = "zed ~/.nix-darwin";
      ".." = "cd ..";
      "g" = "git";
      "k" = "kubectl";
      "ls" = "eza -l";
      "lofi" = "mpv --no-video \"https://www.youtube.com/watch?v=3PFJ9SETS4M\"";
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
          mkdir -p "$ZCACHEDIR"
          autoload -Uz compinit

          # Fix CR/LF only when running inside tmux
          if [[ -n $TMUX ]]; then
            stty icrnl -inlcr -igncr 2>/dev/null
          fi

          # Disable Ctrl-S/Ctrl-Q flow control so Cmd+S (Ctrl-S) doesn't freeze
          # the terminal at the shell prompt (XOFF). Frees Ctrl-S for editors.
          stty -ixon 2>/dev/null
        '';
        zshConfigLateInit = lib.mkOrder 2000 ''
          # zprof
        '';
        zshConfig = lib.mkOrder 1000 ''
          [[ -r ~/.nix-darwin/private/env.private ]] && source ~/.nix-darwin/private/env.private

          export EDITOR="kartka"
          export VISUAL="kartka"

          # Fix for testcontainers with colima (https://github.com/testcontainers/testcontainers-go/issues/2952)
          export TESTCONTAINERS_RYUK_DISABLED=true
          export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE="unix://''${HOME}/.colima/default/docker.sock"
          export DOCKER_HOST=unix://$HOME/.colima/default/docker.sock

          export CLAUDE_CODE_CERT_STORE=bundled

          export PKG_CONFIG_PATH=${pkgs.openssl.dev}/lib/pkgconfig

          # Essential plugins
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

          ZAQ_PREFIXES=(
          'git commit( [^ ]##)# -[^ -]#m'
          'g commit( [^ ]##)# -[^ -]#m'
          )

          # History substring search for better history navigation
          source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

          # Configure autosuggestions
          bindkey '^ ' autosuggest-execute                        # Ctrl+Space to execute suggestion
          ZSH_AUTOSUGGEST_STRATEGY=(history completion)           # Use history and completion
          ZSH_AUTOSUGGEST_USE_ASYNC=1                             # Async suggestions for better performance

          # Setup history navigation
          bindkey '^[[A' history-substring-search-up              # Up arrow
          bindkey '^[[B' history-substring-search-down            # Down arrow
          bindkey '^R' history-incremental-search-backward        # Ctrl+R for history search

          # History options without a home-manager setting, the rest are in programs.zsh.history
          setopt INC_APPEND_HISTORY_TIME # append to shared history immediately, but keep per-session navigation
          setopt HIST_REDUCE_BLANKS      # remove superfluous blanks

          source ${
            pkgs.replaceVars ./zsh/completion.zsh {
              timeout = "${pkgs.coreutils}/bin/timeout";
            }
          }

          # Plugins that hook into completion or widgets load after compinit
          source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          source ${inputs.fzf-tab-source}/fzf-tab-source.plugin.zsh
          source ${pkgs.zsh-wd}/share/wd/wd.plugin.zsh
          source ${inputs.zsh-autoquoter}/zsh-autoquoter.zsh
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

          _ai-cmd() {
            zle -I
            local saved=$(stty -g < /dev/tty)
            stty sane < /dev/tty
            printf 'AI cmd> ' >&2
            local input cancelled=0
            trap 'cancelled=1; echo >&2' INT
            IFS= read -r input < /dev/tty
            trap - INT
            stty "$saved" < /dev/tty
            (( cancelled )) && zle redisplay && return
            [[ -z "$input" ]] && zle redisplay && return
            local result
            result=$(aichat --role %shell% --no-stream "$input" | tr -d '\n\r')
            BUFFER="$result"
            CURSOR=''${#BUFFER}
            zle redisplay
          }
          zle -N _ai-cmd
          bindkey '^Y' _ai-cmd
        '';
      in
      lib.mkMerge [
        zshConfigEarlyInit
        zshConfig
        zshConfigLateInit
      ];
  };

  # Completions for ~/.zsh/completions, see modules/zsh/completion.zsh for where they rank
  home.file =
    let
      generatedCompletion = import ./zsh/generated-completion.nix pkgs;
    in
    {
      ".zsh/completions/_sops".source = ./zsh/_sops;
      ".zsh/completions/_pass-cli".source =
        generatedCompletion pkgs.proton-pass-cli "pass-cli" "completions zsh";
      ".zsh/completions/_uvx".source =
        generatedCompletion pkgs.uv "uvx" "--generate-shell-completion zsh";
    };

  programs.starship = {
    enable = true;
    settings = {
      # Starship configuration
      add_newline = false;

      format = "$directory$nix_shell$git_branch$git_status$golang$kubernetes$docker_context\${custom.tm}$cmd_duration$line_break$character";

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

      docker_context = {
        format = ''\[[$symbol$context]($style)\]'';
        symbol = "🐳 ";
        style = "dimmed blue";
        disabled = false;
      };

      cmd_duration = {
        min_time = 2000;
        format = ''\[[⏱ $duration]($style)\]'';
      };

      custom = {
        tm = {
          command = "tm status --short";
          # Only run while a task is active
          when = "tm status --short >/dev/null 2>&1";
          format = ''\[[$output]($style)\]'';
          style = "bold green";
          disabled = false;
        };
      };
    };
  };

}
