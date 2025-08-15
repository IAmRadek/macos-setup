#!/usr/bin/env bash
# colima-tools.sh — handy helpers for Colima on macOS (zsh/bash)

set -euo pipefail

# -------- CONFIG DEFAULTS (override via env or CLI flags) --------------------
COLIMA_PROFILE="${COLIMA_PROFILE:-default}"
COLIMA_CPU="${COLIMA_CPU:-4}"
COLIMA_MEM="${COLIMA_MEM:-6}"         # GB
COLIMA_DISK="${COLIMA_DISK:-60}"      # GB
COLIMA_VM="${COLIMA_VM:-vz}"          # vz (Apple HVF) or qemu
COLIMA_K8S="${COLIMA_K8S:-0}"         # 1 to enable Kubernetes
COLIMA_GPU="${COLIMA_GPU:-0}"         # 1 to enable Apple GPU (vz only, aarch64)
COLIMA_ARCH="${COLIMA_ARCH:-}"        # "", x86_64, aarch64
COLIMA_DNS="${COLIMA_DNS:-}"          # e.g. "1.1.1.1,8.8.8.8"
COLIMA_DOCKER_MIRROR="${COLIMA_DOCKER_MIRROR:-}" # e.g. "https://registry-1.docker.io"

# -------- UTIL ----------------------------------------------------------------
_die(){ echo "ERR: $*" >&2; exit 1; }
_has(){ command -v "$1" >/dev/null 2>&1; }

need() {
  for c in "$@"; do _has "$c" || _die "missing '$c'. Try: brew install $c"; done
}

# -------- CORE COMMANDS -------------------------------------------------------
cup() {
  # Start Colima with sensible defaults (idempotent)
  need colima

  local args=(start --profile "$COLIMA_PROFILE" --cpu "$COLIMA_CPU" --memory "$COLIMA_MEM" --disk "$COLIMA_DISK" --vm-type "$COLIMA_VM")
  [[ -n "$COLIMA_ARCH" ]] && args+=(--arch "$COLIMA_ARCH")
  [[ "$COLIMA_K8S" == "1" ]] && args+=(--kubernetes)
  [[ "$COLIMA_GPU" == "1" ]] && args+=(--gpu)
  [[ -n "$COLIMA_DNS" ]] && args+=(--dns "$COLIMA_DNS")
  [[ -n "$COLIMA_DOCKER_MIRROR" ]] && args+=(--registry-mirror "$COLIMA_DOCKER_MIRROR")

  echo "→ colima ${args[*]}"
  colima "${args[@]}"

  # Point Docker & kubectl to Colima if available
  if _has docker; then docker context use "colima-$COLIMA_PROFILE" >/dev/null 2>&1 || docker context use colima >/dev/null 2>&1 || true; fi
  if _has kubectl && [[ "$COLIMA_K8S" == "1" ]]; then kubectl config use-context "colima-$COLIMA_PROFILE" >/dev/null 2>&1 || true; fi

  cstatus
}

cstop() {
  need colima
  echo "→ colima stop --profile $COLIMA_PROFILE"
  colima stop --profile "$COLIMA_PROFILE"
}

crestart() {
  need colima
  echo "→ colima restart --profile $COLIMA_PROFILE"
  colima restart --profile "$COLIMA_PROFILE"
}

cstatus() {
  need colima
  colima status --profile "$COLIMA_PROFILE"
  if _has docker; then
    echo "Docker context: $(docker context show 2>/dev/null || echo 'n/a')"
  fi
  if _has kubectl; then
    kubectl config current-context 2>/dev/null || true
  fi
}

clogs() { need colima; colima logs --profile "$COLIMA_PROFILE"; }

cprune() {
  # Safe-ish prune of Docker objects inside Colima
  need docker
  echo "→ docker system prune -f --volumes"
  docker system prune -f --volumes
  echo "→ docker builder prune -f"
  docker builder prune -f || true
}

cnuke() {
  # ☢️ Full reset of the profile (keeps images on host, destroys VM state)
  need colima
  read -rp "This will STOP and DELETE Colima profile '$COLIMA_PROFILE'. Continue? (y/N) " yn
  [[ "${yn:-N}" =~ ^[Yy]$ ]] || exit 1
  colima stop --profile "$COLIMA_PROFILE" || true
  colima delete --profile "$COLIMA_PROFILE"
}

cssh() {
  # SSH into the Lima VM backing Colima
  need colima
  colima ssh --profile "$COLIMA_PROFILE"
}

cimages() {
  # Quick image/use stats
  need docker
  echo "→ images by size"
  docker images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}' | sort -hr -k2
}

cports() {
  # Show forwarded ports for this profile
  need colima
  colima list --json | awk -v p="$COLIMA_PROFILE" '
    /"name":/ { gsub(/[",]/,""); name=$2 }
    /"port":/ { gsub(/[",]/,""); port=$2 }
    /"host":/ { gsub(/[",]/,""); host=$2 }
    /"proto":/ { gsub(/[",]/,""); proto=$2 }
    /}/ && name==p && port!="" { printf "%s://%s:%s\n", proto, host, port; port=host=proto="" }
  '
}

csnap_save() {
  # Save a VM snapshot (not a Docker image save)
  # Usage: csnap_save my-snap
  local name="${1:-snap-$(date +%Y%m%d-%H%M%S)}"
  need colima
  echo "→ snapshot save '$name'"
  colima snapshot save --profile "$COLIMA_PROFILE" "$name"
}

csnap_load() {
  # Restore a snapshot
  # Usage: csnap_load my-snap
  local name="${1:?snapshot name required}"
  need colima
  echo "→ snapshot load '$name'"
  colima snapshot restore --profile "$COLIMA_PROFILE" "$name"
}

# -------- CONTEXT HELPERS -----------------------------------------------------
dctx_colima() { need docker; docker context use "colima-$COLIMA_PROFILE" 2>/dev/null || docker context use colima; }
dctx_desktop(){ need docker; docker context use default; }   # replace 'default' if you keep Docker Desktop around
kctx_colima() { need kubectl; kubectl config use-context "colima-$COLIMA_PROFILE"; }

# -------- QUICK PRESETS -------------------------------------------------------
# Apple Silicon dev (fast, GPU off by default)
colima_preset_dev() {
  COLIMA_CPU=6 COLIMA_MEM=8 COLIMA_DISK=80 COLIMA_VM=vz COLIMA_K8S=0 COLIMA_GPU=0 cup
}

# Kubernetes local cluster
colima_preset_k8s() {
  COLIMA_CPU=6 COLIMA_MEM=10 COLIMA_DISK=80 COLIMA_VM=vz COLIMA_K8S=1 COLIMA_GPU=0 cup
}

# x86_64 VM for amd64-only images (Apple Silicon + Rosetta; vz required)
colima_preset_amd64() {
  COLIMA_CPU=4 COLIMA_MEM=6 COLIMA_DISK=60 COLIMA_VM=vz COLIMA_ARCH=x86_64 COLIMA_K8S=0 COLIMA_GPU=0 cup
}

# -------- CLI DISPATCH --------------------------------------------------------
_usage() {
  cat <<EOF
Usage: source this file, then run functions:

  cup                      Start colima with current defaults (env-overridable)
  cstop | crestart | cstatus | clogs
  cprune                   Docker prune (incl. volumes)
  cnuke                    Stop+delete profile
  cssh                     SSH into Lima VM
  cimages                  List images by size
  cports                   Show forwarded ports
  csnap_save [name]        Save snapshot
  csnap_load <name>        Restore snapshot

Contexts:
  dctx_colima              Use Docker context for this Colima profile
  dctx_desktop             Switch back to default Docker context
  kctx_colima              Use Kubernetes context for this profile

Presets:
  colima_preset_dev        Fast dev profile
  colima_preset_k8s        Local k8s
  colima_preset_amd64      x86_64 VM on Apple Silicon

Env knobs (override before calling cup):
  COLIMA_PROFILE, COLIMA_CPU, COLIMA_MEM, COLIMA_DISK, COLIMA_VM (vz|qemu),
  COLIMA_K8S=1, COLIMA_GPU=1, COLIMA_ARCH=x86_64|aarch64,
  COLIMA_DNS="1.1.1.1,8.8.8.8", COLIMA_DOCKER_MIRROR="https://…"
EOF
}

# If executed directly: show usage
[[ "${BASH_SOURCE[0]-/dev/null}" == "$0" ]] && _usage
