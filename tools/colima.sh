#!/usr/bin/env bash
# ~/.local/bin/colima-tools
set -euo pipefail

# ----------------- defaults -----------------
: "${COLIMA_PROFILE:=default}"
: "${COLIMA_CPU:=4}"
: "${COLIMA_MEM:=6}"       # GB
: "${COLIMA_DISK:=5}"      # GB
: "${COLIMA_VM:=vz}"       # vz|qemu
: "${COLIMA_K8S:=0}"       # 1 to enable
: "${COLIMA_GPU:=0}"       # 1 to enable (vz aarch64)
: "${COLIMA_ARCH:=}"       # "", x86_64, aarch64
: "${COLIMA_DNS:=}"
: "${COLIMA_DOCKER_MIRROR:=}"

_die(){ echo "ERR: $*" >&2; exit 1; }
_has(){ command -v "$1" >/dev/null 2>&1; }
need(){ for c in "$@"; do _has "$c" || _die "missing '$c'"; done; }

_usage(){
cat <<'EOF'
Usage:
  colima-tools <subcommand> [args]
  or create symlinks to call directly: up, status, stop, restart, ...

Subcommands:
  up            Start Colima (env-tunable)
  stop          Stop
  restart       Restart
  status        Status (also prints Docker/K8s contexts)
  logs          Show Colima logs
  prune         Docker prune (incl. volumes)
  nuke          Stop+delete profile (DANGEROUS)
  ssh           SSH into the VM
  images        List images by size
  ports         Show forwarded ports
  snap_save [name]   Save snapshot
  snap_load <name>   Restore snapshot

Env knobs: COLIMA_PROFILE, COLIMA_CPU, COLIMA_MEM, COLIMA_DISK, COLIMA_VM,
           COLIMA_K8S=1, COLIMA_GPU=1, COLIMA_ARCH, COLIMA_DNS, COLIMA_DOCKER_MIRROR
EOF
}

# ----------------- functions -----------------
up(){
  need colima
  local args=(start --profile "$COLIMA_PROFILE" --cpu "$COLIMA_CPU" --memory "$COLIMA_MEM" --disk "$COLIMA_DISK" --vm-type "$COLIMA_VM")
  [[ -n "$COLIMA_ARCH" ]] && args+=(--arch "$COLIMA_ARCH")
  [[ "$COLIMA_K8S" == "1" ]] && args+=(--kubernetes)
  [[ "$COLIMA_GPU" == "1" ]] && args+=(--gpu)
  [[ -n "$COLIMA_DNS" ]] && args+=(--dns "$COLIMA_DNS")
  [[ -n "$COLIMA_DOCKER_MIRROR" ]] && args+=(--registry-mirror "$COLIMA_DOCKER_MIRROR")

  echo "→ colima ${args[*]}"
  colima "${args[@]}"

  if _has docker; then docker context use "colima-$COLIMA_PROFILE" >/dev/null 2>&1 || docker context use colima >/dev/null 2>&1 || true; fi
  if _has kubectl && [[ "$COLIMA_K8S" == "1" ]]; then kubectl config use-context "colima-$COLIMA_PROFILE" >/dev/null 2>&1 || true; fi

  cstatus
}
stop(){ need colima; echo "→ colima stop --profile $COLIMA_PROFILE"; colima stop --profile "$COLIMA_PROFILE"; }
restart(){ need colima; echo "→ colima restart --profile $COLIMA_PROFILE"; colima restart --profile "$COLIMA_PROFILE"; }
status(){
  need colima
  colima status --profile "$COLIMA_PROFILE" || true
  if _has docker; then echo "Docker context: $(docker context show 2>/dev/null || echo 'n/a')"; fi
  if _has kubectl; then kubectl config current-context 2>/dev/null || true; fi
}
logs(){ need colima; colima logs --profile "$COLIMA_PROFILE"; }
prune(){ need docker; echo "→ docker system prune -f --volumes"; docker system prune -f --volumes; echo "→ docker builder prune -f"; docker builder prune -f || true; }
nuke(){
  need colima
  read -rp "This will STOP and DELETE Colima profile '$COLIMA_PROFILE'. Continue? (y/N) " yn
  [[ "${yn:-N}" =~ ^[Yy]$ ]] || exit 1
  colima stop --profile "$COLIMA_PROFILE" || true
  colima delete --profile "$COLIMA_PROFILE"
}
ssh(){ need colima; colima ssh --profile "$COLIMA_PROFILE"; }
images(){ need docker; docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | sort -hr -k2; }
ports(){
  need colima
  colima list --json | awk -v p="$COLIMA_PROFILE" '
    /"name":/ { gsub(/[",]/,""); name=$2 }
    /"port":/ { gsub(/[",]/,""); port=$2 }
    /"host":/ { gsub(/[",]/,""); host=$2 }
    /"proto":/ { gsub(/[",]/,""); proto=$2 }
    /}/ && name==p && port!="" { printf "%s://%s:%s\n", proto, host, port; port=host=proto="" }
  '
}
snap_save(){ need colima; local name="${1:-snap-$(date +%Y%m%d-%H%M%S)}"; echo "→ snapshot save '$name'"; colima snapshot save --profile "$COLIMA_PROFILE" "$name"; }
snap_load(){ need colima; local name="${1:?snapshot name required}"; echo "→ snapshot load '$name'"; colima snapshot restore --profile "$COLIMA_PROFILE" "$name"; }

# ----------------- dispatcher -----------------
dispatch(){
  local base="$(basename -- "${0}")"
  case "$base" in
    colima-tools) ;; # go to subcommand mode
    up|stop|restart|status|logs|prune|nuke|ssh|images|ports|snap_save|snap_load)
      "$base" "$@"; return ;;
  esac

  local sub="${1:-}"
  case "$sub" in
    up|stop|restart|status|logs|prune|nuke|ssh|images|ports|snap_save|snap_load)
      shift
      "$sub" "$@"
      ;;
    ""|-h|--help) _usage ;;
    *) echo "Unknown subcommand: $sub" >&2; _usage; exit 1 ;;
  esac
}

dispatch "$@"
