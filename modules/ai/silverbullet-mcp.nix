{ pkgs }:
pkgs.writeShellScript "silverbullet-mcp" ''
  SB_AUTH_TOKEN=$(${pkgs.proton-pass-cli}/bin/pass-cli item view --vault-name Personal --item-title Silverbullet --field SB_AUTH_TOKEN) || exit 1
  export SB_AUTH_TOKEN
  exec ${pkgs.nodejs}/bin/npx -y silverbullet-mcp --stdio
''
