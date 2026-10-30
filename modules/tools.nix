{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  git-pr = inputs.git-pr.packages.${pkgs.stdenv.hostPlatform.system}.git-pr;

  tm = inputs.tm.packages.${pkgs.stdenv.hostPlatform.system}.tm;

  kartka = inputs.kartka.packages.${pkgs.stdenv.hostPlatform.system}.kartka;

  markSrc = pkgs.fetchFromGitHub {
    owner = "IAmRadek";
    repo = "mark";
    rev = "main";
    hash = "sha256-6z+uvCy/+z9S8pAw/Rri0xni1QGyP1inoJIf0h3YtIY=";
  };

  mark = pkgs.rustPlatform.buildRustPackage {
    pname = "mark";
    version = "0.2.0";

    src = markSrc;
    cargoBuildFlags = [
      "--package"
      "mark"
    ];
    cargoLock.lockFile = "${markSrc}/Cargo.lock";

    doCheck = false;
    meta = with lib; {
      description = "Add notes to files are you change them.";
      homepage = "https://github.com/IAmRadek/mark";
      license = licenses.mit;
    };
  };

  # Prebuilt release binary for aarch64-darwin, the only macOS target fabro publishes
  fabro = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "fabro";
    version = "0.254.0";

    src = pkgs.fetchurl {
      url = "https://github.com/fabro-sh/fabro/releases/download/v${version}/fabro-aarch64-apple-darwin.tar.gz";
      hash = "sha256-zHf616NM7vtNLuHn9WpPP7Gur5kwaUN+ajCd3Pn1PxA=";
    };

    nativeBuildInputs = [ pkgs.installShellFiles ];

    installPhase = ''
      install -Dm755 fabro $out/bin/fabro
      installShellCompletion --cmd fabro --zsh <($out/bin/fabro completion zsh)
    '';

    meta = with lib; {
      description = "Open source dark software factory for expert engineers.";
      homepage = "https://github.com/fabro-sh/fabro";
      platforms = [ "aarch64-darwin" ];
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
in
{
  home.packages = [
    git-pr
    tm
    kartka
    mark
    fabro
    pkgs.mani
    (pkgs.writeShellScriptBin "colix" (builtins.readFile ../tools/colima/colix.sh))
    (pkgs.writeShellScriptBin "ai-commit-msg" (builtins.readFile ../tools/ollama/ai-commit-msg.sh))
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

  home.file.".npmrc".text = ''
    ignore-scripts=true
  '';

  home.file.".runbooks/new.sh".source = ../tools/runbooks/new.sh;
}
