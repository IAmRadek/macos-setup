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

          # Configure history for better suggestion quality
          HISTFILE=~/.zsh_history
          HISTSIZE=50000
          SAVEHIST=50000
          setopt INC_APPEND_HISTORY_TIME # append to shared history immediately, but keep per-session navigation
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

          compinit -u -d "$ZCACHEDIR/zcompdump-$ZSH_VERSION"

          # Plugins that hook into completion or widgets load after compinit
          source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
          source ${inputs.fzf-tab-source}/fzf-tab-source.plugin.zsh
          source ${pkgs.zsh-wd}/share/wd/wd.plugin.zsh
          source ${inputs.zsh-autoquoter}/zsh-autoquoter.zsh
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

          # _default is the file name fallback for commands without a completion function and
          # for arguments without a value hint. For Nix and Homebrew binaries it completes the
          # subcommands and flags listed by `--help` of the longest command prefix on the line
          # whose `--help` succeeds. Tab runs that `--help`, hence the path limit and timeout.
          autoload -Uz +X _default
          functions[_default_files]=$functions[_default]
          _default() {
            emulate -L zsh -o extendedglob
            # _comp_command1 is the command word set by _normal. words loses it when a
            # completion function shifts it away, as clap's does for subcommands.
            local cmd=''${_comp_command1:-$words[1]}
            local bin=''${''${commands[$cmd]:-$cmd}:A}
            if [[ $bin != (/nix/store|/opt/homebrew)/* ]]; then
              _default_files "$@"
              return
            fi

            local -a chain=(''${''${words[2,CURRENT-1]}:#-*})
            [[ $words[1] == $cmd ]] || chain=(''${''${words[1,CURRENT-1]}:#-*})
            local help
            while true; do
              help=$(${pkgs.coreutils}/bin/timeout 1 $bin $chain --help 2>&1) && [[ -n $help ]] && break
              help=
              (( $#chain )) || break
              chain[-1]=()
            done
            if [[ -z $help ]]; then
              _default_files "$@"
              return
            fi

            local line spec desc section usage
            local -a parts longs shorts cmds flags
            local -A seen
            for line in ''${(f)help}; do
              # "Usage: cmd …" on one line (clap, commander) or below a "Usage:" header (cobra)
              if [[ -z $usage && $line == (#i)usage:[[:space:]]#[^[:space:]]* ]]; then
                usage=$line
              elif [[ -z $usage && $section == (#i)usage:* && $line == [[:space:]]##[^[:space:]]* ]]; then
                usage="Usage: ''${line##[[:space:]]#}"
              fi
              if [[ $line == [[:alpha:]][[:alpha:][:blank:]]#:[[:space:]]# ]]; then
                section=$line
                continue
              fi
              # Entries sit at a small indent, wrapped descriptions further right
              [[ $line == [[:blank:]](#c1,8)[^[:space:]]* ]] || continue
              line=''${line##[[:space:]]#}
              spec=''${line%%[[:space:]][[:space:]]*}
              desc=''${''${line:$#spec}##[[:space:]]#}
              if [[ $spec == -* ]]; then
                parts=(''${=spec//,/ })
                longs=(''${(M)parts:#--[[:alnum:]]*})
                shorts=(''${(M)parts:#-[[:alnum:]]*})
                spec=''${''${longs[1]:-$shorts[1]}%%[=\[]*}
                [[ -n $spec ]] && (( ! $+seen[$spec] )) && seen[$spec]=1 && flags+=("$spec:$desc")
              elif [[ $section == *ommand* && $spec == [[:alnum:]]* && -n $desc ]]; then
                spec=''${spec%%[ ,|]*}
                (( ! $+seen[$spec] )) && seen[$spec]=1 && cmds+=("$spec:$desc")
              fi
            done
            # fzf-tab preview and usage header, set for this exact completion context so they
            # also apply to candidates that other functions add to the same popup
            local -a cmdline=(''${(q)bin})
            (( $#chain )) && cmdline+=(''${(q)chain})
            typeset -gx ZSH_HELP_COMPLETION_CMD="''${cmdline[*]}"
            local ctx=":fzf-tab:''${curcontext#:}"
            zstyle $ctx fzf-preview \
              'if [[ $group == *subcommand* ]]; then eval "$ZSH_HELP_COMPLETION_CMD ''${(q)word} --help"; else eval "$ZSH_HELP_COMPLETION_CMD --help"; fi 2>&1'
            if [[ -n $usage ]]; then
              zstyle $ctx fzf-flags "--header=''${usage//''${(b)bin}/$cmd}"
            else
              zstyle -d $ctx fzf-flags
            fi

            # Commands with their own completion function call this for argument values. Once
            # the word starts with "-" their function lists the flags. Before that, a
            # placeholder that names the argument and inserts nothing comes first, next to the
            # flags, so zsh does not insert the common "--" prefix of the flags.
            if [[ -n $_comps[$cmd] ]]; then
              [[ $PREFIX == -* ]] && return 1
              local arg=''${@[''${@[(i)-X]}+1]:-value}
              local -a disp=("<''${arg%% -- *}>")
              [[ $arg == *" -- "* ]] && disp=("$disp[1]  -- ''${arg#* -- }")
              compadd -U -Q -S "" -J help-argument -X argument -d disp -- ""
              (( $#flags )) && _describe -t help-flags flag flags
              return 0
            fi

            if (( ! $#cmds && ! $#flags )); then
              _message -r "$help"
              return 0
            fi
            local ret=1
            (( $#cmds )) && _describe -t help-commands subcommand cmds && ret=0
            (( $#flags )) && _describe -t help-flags flag flags && ret=0
            return ret
          }

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
