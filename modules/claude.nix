{
  lib,
  pkgs,
  ...
}:
let
  texts = import ./ai/texts.nix;
  claude = "${pkgs.claude-code}/bin/claude";

  silverbulletMcp = import ./ai/silverbullet-mcp.nix { inherit pkgs; };
in
{
  home.file.".claude/CLAUDE.md".text = texts.assistantGuidance;
  home.file.".claude/settings.json".source = ./ai/settings.json;
  home.file.".claude/statusline.sh" = {
    source = ./ai/statusline.sh;
    executable = true;
  };
  home.activation.claudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${claude} mcp remove -s user silverbullet >/dev/null 2>&1 || true
    $DRY_RUN_CMD ${claude} mcp add -s user silverbullet \
      --env SB_URL=https://notes.rdnx.dev \
      -- ${silverbulletMcp} >/dev/null
  '';
}
