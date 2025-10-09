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
curl -fsSL https://raw.githubusercontent.com/IAmRadek/macos-setup/main/install.sh | bash
```

Or if you prefer wget:

```bash
wget -qO- https://raw.githubusercontent.com/IAmRadek/macos-setup/main/install.sh | bash
```

This script will:
- Clone the repository to `~/macos-setup`
- Install Nix
- Install nix-darwin
- Install Homebrew (required by nix-darwin)
- Apply the configuration
- Show you next steps

## Updating

To update all packages and flake inputs:
```bash
system-update
```

## Host Configuration

The hostname used for the configuration is "rdwk". If your hostname is different, either:
1. Change your hostname: `sudo scutil --set HostName rdkw`
2. Or update the `darwinConfigurations` name in `flake.nix` to match your hostname

Check your hostname with: `hostname -s`


## Additional tools:

```bash

uv tools install mcpdoc

```
