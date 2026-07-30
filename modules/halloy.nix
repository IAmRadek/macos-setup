{ pkgs, lib, ... }:
let
  # Where SASL reads the password from (must match servers.liberachat.sasl below).
  passFile = "/Users/r__d/.nix-darwin/private/liberachat.pass";
  # Proton Pass location of the Libera Chat login — adjust to your vault/item.
  protonVault = "Personal";
  protonItem = "Libera Chat";
in
{
  programs.halloy = {
    enable = true;
    # halloy is already installed via environment.systemPackages, so don't
    # pull a second copy in through home-manager.
    package = null;

    # Written to ~/.config/halloy/config.toml.
    # Full reference: https://halloy.chat/configuration.html
    settings = {
      theme = "ferra";

      font = {
        family = "JetBrainsMono Nerd Font";
        size = 13;
      };

      # At least one server is required. Adjust nickname / channels to taste.
      servers.liberachat = {
        nickname = "r__d";
        server = "irc.libera.chat";
        port = 6697;
        channels = [ "#lobsters" ];

        sasl.plain = {
          username = "r__d";
          password_file = passFile;
        };
      };

      buffer = {
        channel.topic.enabled = true;
        nickname.color = "unique";
        timestamp.format = "%H:%M";
      };

      sidebar = {
        buttons.file_transfer = false;
        position = "left";
      };

      notification.highlight.sound = "dong";
    };
  };

  # Pull the Libera Chat SASL password out of Proton Pass into `passFile` on
  # each rebuild. Read-only, and non-fatal: if Proton Pass isn't authenticated
  # (or the item is missing) we warn and skip rather than abort the switch.
  home.activation.halloyLiberaPassword = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    passFile=${lib.escapeShellArg passFile}
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$(dirname "$passFile")"
    if secret=$(${pkgs.proton-pass-cli}/bin/pass-cli item view \
          --vault-name ${lib.escapeShellArg protonVault} \
          --item-title ${lib.escapeShellArg protonItem} \
          --field password \
          --output human 2>/dev/null) && [ -n "$secret" ]; then
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        ( umask 077; printf '%s' "$secret" > "$passFile" )
      else
        echo "Would write Libera Chat password to $passFile"
      fi
    else
      echo "halloy: could not fetch '${protonItem}' from Proton Pass vault '${protonVault}' — skipping (run 'pass-cli login' and rebuild)" >&2
    fi
  '';
}
