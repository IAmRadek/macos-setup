{
  config,
  lib,
  ...
}:
let
  texts = import ./ai/texts.nix;
  installSkill =
    {
      name,
      source,
    }:
    let
      targetDir = "${config.home.homeDirectory}/.claude/skills/${name}";
      targetFile = "${targetDir}/SKILL.md";
    in
    ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${targetDir}"
      if [ -L "${targetFile}" ] || [ -e "${targetFile}" ]; then
        $DRY_RUN_CMD rm -f $VERBOSE_ARG "${targetFile}"
      fi
      $DRY_RUN_CMD install -m 0644 $VERBOSE_ARG "${source}" "${targetFile}"
    '';
in
{
  home.activation.installClaudeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${installSkill {
      name = "analyze-repo";
      source = ./ai/skills/analyze-repo/SKILL.md;
    }}
    ${installSkill {
      name = "ansible";
      source = ./ai/skills/ansible/SKILL.md;
    }}
  '';

  home.file.".claude/CLAUDE.md".text = texts.assistantGuidance;
}
