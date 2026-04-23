{
  lib,
  pkgs,
  ...
}:

let
  git-pr = pkgs.rustPlatform.buildRustPackage {
    pname = "git-pr";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "IAmRadek";
      repo = "git-pr";
      rev = "main";
      hash = "sha256-5cfhRBHhV93QmiRK69ENRyn1w/AiQTNGzY2Ttj8Jxqw=";
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

  tmSrc = pkgs.fetchFromGitHub {
    owner = "IAmRadek";
    repo = "tm";
    rev = "main";
    hash = "sha256-pPsxGHv4+GTqrchJnqH7bsdvHCECmGuLdB49bsTVKXY=";
  };

  tm = pkgs.rustPlatform.buildRustPackage {
    pname = "tm";
    version = "0.2.0";

    src = tmSrc;
    cargoBuildFlags = [
      "--package"
      "tm"
    ];
    cargoLock.lockFile = "${tmSrc}/Cargo.lock";

    doCheck = false;
    meta = with lib; {
      description = "A minimal CLI time tracker for projects and tasks.";
      homepage = "https://github.com/IAmRadek/tm";
      license = licenses.mit;
    };
  };

  tmDaemon = pkgs.rustPlatform.buildRustPackage {
    pname = "tm-daemon";
    version = "0.1.0";

    src = tmSrc;
    cargoBuildFlags = [
      "--package"
      "tm-daemon"
    ];
    cargoLock.lockFile = "${tmSrc}/Cargo.lock";

    doCheck = false;
    meta = with lib; {
      description = "tm menu bar daemon for macOS";
      homepage = "https://github.com/IAmRadek/tm";
      license = licenses.mit;
    };
  };
  tmCurrentTask = pkgs.writeShellScriptBin "tm-current-task" ''
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
  '';

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
in
{
  home.packages = [
    git-pr
    tm
    tmDaemon
    tmCurrentTask
    mark
    (pkgs.writeShellScriptBin "colix" (builtins.readFile ../tools/colima/colix.sh))
    (pkgs.writeShellScriptBin "ai-commit-msg" (builtins.readFile ../tools/ollama/ai-commit-msg.sh))
  ];

  launchd.agents.tm-daemon = {
    enable = true;
    config = {
      Label = "com.iamradek.tm-daemon";
      ProgramArguments = [ "${tmDaemon}/bin/tm-daemon" ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/tm-daemon.log";
      StandardErrorPath = "/tmp/tm-daemon.err";
    };
  };

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
