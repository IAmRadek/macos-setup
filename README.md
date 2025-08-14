# Minimal macOS Nix Setup

A simplified Nix Darwin configuration that provides the most basic Nix setup for macOS.

## What This Does

This configuration sets up:
- Nix package manager with flakes enabled
- Nix-darwin for macOS system management
- Basic zsh integration
- **Nothing else** - this is intentionally minimal

## Installation

1. Clone this repository:
   ```bash
   git clone <your-repo-url> ~/macos-setup
   cd ~/macos-setup
   ```

2. Run the setup:
   ```bash
   make
   ```

   This will:
   - Install Nix
   - Install nix-darwin
   - Install Homebrew (required by nix-darwin)
   - Apply the configuration

3. Restart your terminal or source your shell profile.

## File Structure

- `flake.nix` - Defines inputs (nixpkgs, nix-darwin) and the system configuration
- `configuration.nix` - Main system configuration (currently minimal)
- `hosts/mbp.nix` - Host-specific configuration (currently just user setup)
- `Makefile` - Installation and build automation

## Usage

After installation, you can:

- Install packages temporarily: `nix-shell -p <package-name>`
- Search for packages: `nix search nixpkgs <term>`
- Update the system: `darwin-rebuild switch --flake .`

## Adding More Features

To expand this setup, you can:

1. **Add packages**: Edit `configuration.nix` and add packages to `environment.systemPackages`
2. **Configure system settings**: Add macOS preferences to `system.defaults` in `configuration.nix`
3. **Add Homebrew packages**: Add `homebrew` section to `configuration.nix`
4. **Add services**: Configure services in the `services` section of `configuration.nix`

## Example: Adding Basic Tools

To add some common tools, edit `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  git
  curl
  tree
  htop
];
```

Then run: `darwin-rebuild switch --flake .`

## Updating

To update all packages and flake inputs:
```bash
make update
```

## Host Configuration

The hostname used for the configuration is "PersonalMacbookPro". If your hostname is different, either:
1. Change your hostname: `sudo scutil --set HostName PersonalMacbookPro`
2. Or update the `darwinConfigurations` name in `flake.nix` to match your hostname

Check your hostname with: `hostname -s`
