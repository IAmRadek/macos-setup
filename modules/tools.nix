{
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

  archiveWebpage = pkgs.writeShellScriptBin "webarchive" ''
    #!/usr/bin/env bash

    set -euo pipefail

    # Check if URL is provided
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <URL>"
        echo "Example: $0 https://example.com"
        exit 1
    fi

    URL="$1"

    # Extract base domain from URL
    BASE=$(echo "$URL" | sed -E 's|^https?://||' | sed -E 's|^www\.||' | sed -E 's|/.*$||')

    # Create archive directory
    ARCHIVE_DIR="$HOME/Documents/WebArchive/$BASE"
    mkdir -p "$ARCHIVE_DIR"

    echo "Fetching $URL..."

    # Download the page to extract title
    TEMP_FILE=$(mktemp)
    trap "rm -f $TEMP_FILE" EXIT

    curl -sL "$URL" > "$TEMP_FILE"

    # Extract title from HTML
    TITLE=$(grep -i '<title>' "$TEMP_FILE" | head -n1 | sed -E 's/.*<title>([^<]+)<\/title>.*/\1/' | sed -E 's/^[[:space:]]+|[[:space:]]+$//')

    # Normalize title for filename: lowercase, replace spaces/special chars with hyphens, limit length
    if [ -n "$TITLE" ]; then
        FILENAME=$(echo "$TITLE" | \
            tr '[:upper:]' '[:lower:]' | \
            sed -E 's/[^a-z0-9]+/-/g' | \
            sed -E 's/^-+|-+$//g' | \
            cut -c1-80)

        # If filename is empty after normalization, use timestamp
        if [ -z "$FILENAME" ]; then
            FILENAME=$(date +%Y%m%d_%H%M%S)
        fi
    else
        # No title found, use timestamp
        FILENAME=$(date +%Y%m%d_%H%M%S)
    fi

    # Handle duplicate filenames by appending a number
    OUTPUT_FILE="$ARCHIVE_DIR/''${FILENAME}.html"
    COUNTER=1
    while [ -f "$OUTPUT_FILE" ]; do
        OUTPUT_FILE="$ARCHIVE_DIR/''${FILENAME}-''${COUNTER}.html"
        COUNTER=$((COUNTER + 1))
    done

    echo "Title: $TITLE"
    echo "Saving to: $OUTPUT_FILE"

    # Archive the webpage using monolith
    monolith "$URL" -o "$OUTPUT_FILE"

    echo "✓ Successfully archived to: $OUTPUT_FILE"
  '';
in
{
  home.packages = [
    git-pr
    tm
    tmCurrentTask
    archiveWebpage
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
