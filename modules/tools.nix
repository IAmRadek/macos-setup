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

  tm = pkgs.rustPlatform.buildRustPackage rec {
    pname = "tm";
    version = "0.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "IAmRadek";
      repo = "tm";
      rev = "v${version}";
      hash = "sha256-rFUzBBR/H7slnRJDDFcqA1SB9A9Tp4bdgTpDM4k041o=";
    };

    cargoHash = "sha256-0QhIiRLuiZ4tlUGAkOC711XJ9TRaxYvMIrkxIqPzfA8=";

    nativeBuildInputs = [ pkgs.pkg-config ];

    doCheck = false;
    meta = with lib; {
      description = "A minimal CLI time tracker for projects and tasks.";
      homepage = "https://github.com/IAmRadek/tm";
      license = licenses.mit;
    };
  };
in
{
  home.packages = [
    git-pr
    tm
    (pkgs.writeShellScriptBin "colix" (builtins.readFile ../tools/colima/colix.sh))
  ];

  home.file.".zsh/completions/_colix".text = ''
    #compdef colix

    _colix() {
        local -a commands
        commands=(
            'help:Show help message'
            'start:Start Colima and set Docker/K8s contexts'
            'stop:Stop Colima'
            'restart:Restart Colima'
            'status:Show Colima status and Docker/K8s contexts'
            'prune:Docker prune (incl. volumes) + builder prune'
            'nuke:STOP and DELETE the Colima profile (DANGEROUS)'
            'ssh:SSH into the Colima VM'
            'images:List Docker images by size (desc)'
            'ports:Show forwarded ports'
            'completions:Output shell completions'
        )

        _arguments -C \
            '1:command:->command' \
            '*::arg:->args'

        case "$state" in
            command)
                _describe -t commands 'colix commands' commands
                ;;
            args)
                case "$words[1]" in
                    start)
                        _arguments \
                            '--profile=[Colima profile name]:profile:' \
                            '--cpu=[vCPUs]:cpus:' \
                            '--mem=[Memory in GB]:memory:' \
                            '--disk=[Disk in GB]:disk:' \
                            '--vm=[VM backend]:vm:(vz qemu)' \
                            '--k8s[Enable Kubernetes]' \
                            '--rosetta[Enable Rosetta for amd64 emulation]' \
                            '--arch=[Guest architecture]:arch:(x86_64 aarch64)' \
                            '--dns=[Custom DNS server]:dns:' \
                            '--help[Show help]'
                        ;;
                    stop|restart|status|ssh|ports)
                        _arguments \
                            '--profile=[Colima profile name]:profile:' \
                            '--help[Show help]'
                        ;;
                    nuke)
                        _arguments \
                            '--profile=[Colima profile name]:profile:' \
                            '--yes[Skip confirmation]' \
                            '--help[Show help]'
                        ;;
                    prune|images|help|completions)
                        _arguments \
                            '--help[Show help]'
                        ;;
                esac
                ;;
        esac
    }

    _colix "$@"
  '';

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
  home.activation.mySymlinks = lib.mkAfter ''
    ln -sf ~/.nix-darwin/tools/navi/cheats ~/.local/share/navi/cheats/local
  '';

}
