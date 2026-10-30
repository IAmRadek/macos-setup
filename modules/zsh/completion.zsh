# Completion setup. Completion functions come from, in order of preference:
#   1. the zsh completion that a package ships (on fpath through the Nix profiles)
#   2. a completion that a tool prints itself, generated at build time (modules/zsh/generated-completion.nix)
#   3. a hand-written file in ~/.zsh/completions, for a shipped completion that misbehaves
#   4. _default below, which reads `--help` of Nix and Homebrew binaries
# fzf-tab draws every completion list, so the zstyles here apply to all of them.

fpath=($HOME/.zsh/completions $fpath)

zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case insensitive completion
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZCACHEDIR/zcompcache"

# One fzf-tab group per tag (files, flags, subcommands, ...), each in its own color
zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%d'           # fzf-tab-source sets the same format
zstyle ':completion:*' list-colors 'di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01'

zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-preview 'ls -la $realpath'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1a $realpath'
zstyle ':fzf-tab:*' continuous-trigger 'tab'              # TAB cycles through options
zstyle ':fzf-tab:*' fzf-bindings 'tab:down,btab:up'       # TAB/Shift+TAB to navigate

compinit -u -d "$ZCACHEDIR/zcompdump-$ZSH_VERSION"

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
  local cmd=${_comp_command1:-$words[1]}
  local bin=${${commands[$cmd]:-$cmd}:A}
  if [[ $bin != (/nix/store|/opt/homebrew)/* ]]; then
    _default_files "$@"
    return
  fi

  local -a chain=(${${words[2,CURRENT-1]}:#-*})
  [[ $words[1] == $cmd ]] || chain=(${${words[1,CURRENT-1]}:#-*})
  local help
  while true; do
    help=$(@timeout@ 1 $bin $chain --help 2>&1) && [[ -n $help ]] && break
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
  for line in ${(f)help}; do
    # "Usage: cmd …" on one line (clap, commander) or below a "Usage:" header (cobra)
    if [[ -z $usage && $line == (#i)usage:[[:space:]]#[^[:space:]]* ]]; then
      usage=$line
    elif [[ -z $usage && $section == (#i)usage:* && $line == [[:space:]]##[^[:space:]]* ]]; then
      usage="Usage: ${line##[[:space:]]#}"
    fi
    if [[ $line == [[:alpha:]][[:alpha:][:blank:]]#:[[:space:]]# ]]; then
      section=$line
      continue
    fi
    # Entries sit at a small indent, wrapped descriptions further right
    [[ $line == [[:blank:]](#c1,8)[^[:space:]]* ]] || continue
    line=${line##[[:space:]]#}
    spec=${line%%[[:space:]][[:space:]]*}
    desc=${${line:$#spec}##[[:space:]]#}
    if [[ $spec == -* ]]; then
      parts=(${=spec//,/ })
      longs=(${(M)parts:#--[[:alnum:]]*})
      shorts=(${(M)parts:#-[[:alnum:]]*})
      spec=${${longs[1]:-$shorts[1]}%%[=\[]*}
      [[ -n $spec ]] && (( ! $+seen[$spec] )) && seen[$spec]=1 && flags+=("$spec:$desc")
    elif [[ $section == *ommand* && $spec == [[:alnum:]]* && -n $desc ]]; then
      spec=${spec%%[ ,|]*}
      (( ! $+seen[$spec] )) && seen[$spec]=1 && cmds+=("$spec:$desc")
    fi
  done
  # fzf-tab preview and usage header, set for this exact completion context so they
  # also apply to candidates that other functions add to the same popup
  local -a cmdline=(${(q)bin})
  (( $#chain )) && cmdline+=(${(q)chain})
  typeset -gx ZSH_HELP_COMPLETION_CMD="${cmdline[*]}"
  local ctx=":fzf-tab:${curcontext#:}"
  zstyle $ctx fzf-preview \
    'if [[ $group == *subcommand* ]]; then eval "$ZSH_HELP_COMPLETION_CMD ${(q)word} --help"; else eval "$ZSH_HELP_COMPLETION_CMD --help"; fi 2>&1'
  if [[ -n $usage ]]; then
    zstyle $ctx fzf-flags "--header=${usage//${(b)bin}/$cmd}"
  else
    zstyle -d $ctx fzf-flags
  fi

  # Commands with their own completion function call this for argument values. Once
  # the word starts with "-" their function lists the flags. Before that, a
  # placeholder that names the argument and inserts nothing comes first, next to the
  # flags, so zsh does not insert the common "--" prefix of the flags.
  if [[ -n $_comps[$cmd] ]]; then
    [[ $PREFIX == -* ]] && return 1
    local arg=${@[${@[(i)-X]}+1]:-value}
    local -a disp=("<${arg%% -- *}>")
    [[ $arg == *" -- "* ]] && disp=("$disp[1]  -- ${arg#* -- }")
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
