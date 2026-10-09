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

**Pinch-to-Raycast:** the trackpad pinch (thumb + fingers) normally opens the
Launchpad / "Apps" launcher. On macOS 26 (Tahoe) it's the **five-finger** pinch that
does this. Those gestures are disabled by the `disableLaunchpadPinch` home-manager
activation in `hosts/r__d.nix` (both the four- and five-finger keys). Note macOS
stores trackpad gestures **per-host** (ByHost / `defaults -currentHost`), which
nix-darwin's `system.defaults` cannot reach — so they're written as the user with
`defaults -currentHost write … 0` and applied via `killall Dock` or a log out/in.
Then re-bind the pinch to Raycast in BTT:

1. **BetterTouchTool → Trackpad** → add a gesture: *4 Finger Pinch In* (a.k.a. TipTap).
2. Assign the action **Activate Application → Raycast** (or *Execute Terminal
   Command (async)* → `open raycast://`).

If you ever want Launchpad's pinch back, flip `TrackpadFourFingerPinchGesture` to `2`.
