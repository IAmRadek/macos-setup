{
  lib,
  pkgs,
  ...
}:
let
  texts = import ./ai/texts.nix;
  claude = "${pkgs.claude-code}/bin/claude";

  silverbulletMcp = pkgs.writeShellScript "silverbullet-mcp" ''
    SB_AUTH_TOKEN=$(${pkgs.proton-pass-cli}/bin/pass-cli item view --vault-name Personal --item-title Silverbullet --field SB_AUTH_TOKEN) || exit 1
    export SB_AUTH_TOKEN
    exec ${pkgs.nodejs}/bin/npx -y silverbullet-ai-mcp
  '';
in
{
  home.file.".claude/CLAUDE.md".text = texts.assistantGuidance;
  home.file.".claude/settings.json".source = ./ai/settings.json;

  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${claude} mcp remove -s user silverbullet >/dev/null 2>&1 || true
    $DRY_RUN_CMD ${claude} mcp add -s user silverbullet \
      --env SB_URL=https://notes.rdnx.dev \
      -- ${silverbulletMcp} >/dev/null
  '';
}
