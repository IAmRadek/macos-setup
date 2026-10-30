# zsh completion file that a tool prints itself, generated at build time.
# Usage: generatedCompletion pkgs.uv "uvx" "--generate-shell-completion zsh"
pkgs: pkg: cmd: args:
pkgs.runCommand "_${cmd}" { } ''
  HOME=$TMPDIR ${pkg}/bin/${cmd} ${args} > $out
''
