# Minimal macOS Nix Setup

A simplified Nix Darwin configuration that provides the most basic Nix setup for macOS.

## What This Does

This configuration sets up:
- Nix package manager with flakes enabled
- Nix-darwin for macOS system management
- zsh, alacritty, tmux integration

## Installation

### Quick Install (Recommended)

Run this one-liner to automatically install everything:

```bash
curl -fsSL https://raw.githubusercontent.com/IAmRadek/macos-setup/main/install.sh | bash -s -- personal
```

Or if you prefer wget:

```bash
wget -qO- https://raw.githubusercontent.com/IAmRadek/macos-setup/main/install.sh | bash -s -- personal
```

Use `work` in place of `personal` for the work machine.

This script will:
- Clone the repository to `~/.nix-darwin`
- Install Nix
- Install nix-darwin
- Install Homebrew (required by nix-darwin)
- Apply the configuration
- Show you next steps

## Updating

To apply the configuration for the current machine:
```bash
system-update
```

To update the flake inputs, run `make upgrade`.

## Host Configuration

Each machine has a configuration in `flake.nix` and a make target. The hostname and the user name of the machine do not matter.

| Make target            | Flake configuration | Host file          |
|------------------------|---------------------|--------------------|
| `make switch-personal` | `r__d`              | `hosts/r__d.nix`   |
| `make switch-work`     | `rdwk`              | `hosts/rdwk.nix`   |


## Additional tools:

```bash

uv tools install mcpdoc

```

## Manual setup (outside Nix)

### BetterTouchTool — trackpad gestures

BetterTouchTool (BTT) is **not managed by Nix** — its gestures live in its own
database (`~/Library/Application Support/BetterTouchTool`), so they must be
configured manually in the BTT UI and won't survive a fresh machine via the flake.

**Pinch-to-Raycast:** on macOS 26 (Tahoe), the five-finger trackpad pinch opens
the Launchpad "Apps" launcher. macOS stores trackpad gestures per host
(`defaults -currentHost`), and nix-darwin cannot set them. Run this one time
on each new machine to disable the four-finger and five-finger pinch:

```bash
for d in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  for k in TrackpadFourFingerPinchGesture TrackpadFiveFingerPinchGesture; do
    defaults -currentHost write "$d" "$k" -int 0
  done
done
killall Dock
```

Then re-bind the pinch to Raycast in BTT:

1. **BetterTouchTool → Trackpad** → add a gesture: *4 Finger Pinch In* (a.k.a. TipTap).
2. Assign the action **Activate Application → Raycast** (or *Execute Terminal
   Command (async)* → `open raycast://`).

If you ever want Launchpad's pinch back, flip `TrackpadFourFingerPinchGesture` to `2`.
