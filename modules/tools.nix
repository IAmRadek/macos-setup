{
  config,
  lib,
  pkgs,
  ...
}:

let
  git-pr = pkgs.rustPlatform.buildRustPackage rec {
    pname = "git-pr";
    version = "1.1.2";

    src = pkgs.fetchFromGitHub {
      owner = "IAmRadek";
      repo = "git-pr";
      rev = "v${version}";
      hash = "sha256-rZKZGoqt+INwgDc3WhIQYP55OetsB1aHJWjhRiIGNZE=";
    };

    cargoHash = "sha256-dWb1m01PJsAnxj1fA4WnQU8JV9uD9UahZeUr3Go7aLc=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    doCheck = false;
    meta = with lib; {
      description = "Highly opinionated tool for PR creation";
      homepage = "https://github.com/IAmRadek/git-pr";
      license = licenses.mit;
    };
  };
in
{
  home.packages = [
    git-pr
    (pkgs.writeShellScriptBin "colima-tools" (builtins.readFile ../tools/colima/colima-tools.sh))
  ];

  home.file.".zsh/completions/_colima-tools".text = ''
    # Completions for colima-tools
    _colima_tools_complete() {
        local cur="''${COMP_WORDS[COMP_CWORD]}"
        local cmd="''${COMP_WORDS[1]:-}"

        if [[ $COMP_CWORD -eq 1 ]]; then
            COMPREPLY=( $(compgen -W "help start stop restart status logs prune nuke ssh images ports completions" -- "$cur") )
            return
        fi

        case "$cmd" in
            start)
                COMPREPLY=( $(compgen -W "--profile --cpu --mem --disk --vm --k8s --gpu --arch --dns --mirror --help" -- "$cur") )
                ;;
            stop|restart|status|logs|ssh|ports)
                COMPREPLY=( $(compgen -W "--profile --help" -- "$cur") )
                ;;
            nuke)
                COMPREPLY=( $(compgen -W "--profile --yes --help" -- "$cur") )
                ;;
            prune|images|help|completions)
                COMPREPLY=( $(compgen -W "--help" -- "$cur") )
                ;;
        esac
    }

    complete -F _colima_tools_complete colima-tools
  '';

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.activation.mySymlinks = lib.mkAfter ''
    	  ln -sf ~/.nix-darwin/tools/navi/cheats ~/.local/share/navi/cheats/local
    	'';

}
