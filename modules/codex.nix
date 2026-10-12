{
  lib,
  pkgs,
  ...
}:
let
  texts = import ./ai/texts.nix;
  codex = "${pkgs.codex}/bin/codex";
  silverbulletMcp = import ./ai/silverbullet-mcp.nix { inherit pkgs; };
in
{
  home.file.".codex/AGENTS.md".text = texts.assistantGuidance;

  home.activation.codexMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${codex} mcp remove silverbullet >/dev/null 2>&1 || true
    $DRY_RUN_CMD ${codex} mcp add silverbullet \
      --env SB_URL=https://notes.rdnx.dev \
      -- ${silverbulletMcp} >/dev/null
  '';
}
