{ config, lib, pkgs, ... }:
{

  programs.zsh = {
    enable = true;
    enableCompletion = true;

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
      zinit light ianthehenry/zsh-autoquoter

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

      fpath=("$HOME/.zsh/completions" $fpath)

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

  programs.starship = {
    enable = true;
    settings = {
      # Starship configuration
      add_newline = false;

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


}
