# nix-darwin system module — NOT a home-manager module.
# Imported at the darwin level in hosts/r__d.nix via the top-level `imports`.
#
# Why a system daemon and not a user agent:
#   .dev is in the HSTS preload list; browsers force HTTPS on port 443.
#   Binding port 443 requires root, so this must run as a launchd daemon.
#
# Caddy uses `tls internal` (its own local CA).  On first start it
# automatically installs the root CA into the macOS system Keychain
# because the daemon runs as root — no manual `caddy trust` needed.
# Restart your browser once after the first `darwin-rebuild switch`.
#
# Logs: /var/log/caddy.log  /var/log/caddy-error.log
{ pkgs, ... }:
{
  # NOTE: /etc/hosts entry for chat.local must be added once via `make hosts`.
  # nix-darwin does not own /etc/hosts so the entry survives rebuilds.

  # macOS ships with Apache httpd which grabs port 80 and blocks Caddy.
  # Disable it permanently on every activation.
  system.activationScripts.disableApacheHttpd.text = ''
    if /bin/launchctl list | /usr/bin/grep -q "org.apache.httpd"; then
      /bin/launchctl unload -w /System/Library/LaunchDaemons/org.apache.httpd.plist 2>/dev/null || true
    fi
  '';

  environment.systemPackages = [ pkgs.caddy ];

  environment.etc."caddy/Caddyfile" = {
    text = ''
      http://chat.local {
        reverse_proxy localhost:10001
      }
    '';
  };

  launchd.daemons.caddy = {
    serviceConfig = {
      Label = "com.caddy.server";
      ProgramArguments = [
        "${pkgs.caddy}/bin/caddy"
        "run"
        "--config"
        "/etc/caddy/Caddyfile"
        "--adapter"
        "caddyfile"
      ];
      EnvironmentVariables = {
        # Ensures XDG paths resolve predictably for root.
        # Caddy stores its local CA at $HOME/.local/share/caddy/pki/
        HOME = "/var/root";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/caddy.log";
      StandardErrorPath = "/var/log/caddy-error.log";
    };
  };
}
