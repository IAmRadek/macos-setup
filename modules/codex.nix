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
      extraSources ? [ ],
    }:
    let
      targetDir = "${config.home.homeDirectory}/.codex/skills/${name}";
      targetFile = "${targetDir}/SKILL.md";
      installExtraSource =
        extraSource:
        ''
          $DRY_RUN_CMD install -m 0644 $VERBOSE_ARG "${extraSource}" "${targetDir}/${baseNameOf extraSource}"
        '';
    in
    ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${targetDir}"
      if [ -L "${targetFile}" ] || [ -e "${targetFile}" ]; then
        $DRY_RUN_CMD rm -f $VERBOSE_ARG "${targetFile}"
      fi
      $DRY_RUN_CMD install -m 0644 $VERBOSE_ARG "${source}" "${targetFile}"
      ${lib.concatMapStrings installExtraSource extraSources}
    '';
in
{
  home.activation.installCodexSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${installSkill {
      name = "analyze-repo";
      source = ./ai/skills/analyze-repo/SKILL.md;
    }}
    ${installSkill {
      name = "ansible";
      source = ./ai/skills/ansible/SKILL.md;
    }}
    ${installSkill {
      name = "cynefin";
      source = ./ai/skills/cynefin/SKILL.md;
    }}
    ${installSkill {
      name = "grill-me";
      source = ./ai/skills/grill-me/SKILL.md;
    }}
    ${installSkill {
      name = "idiomatic-go";
      source = ./ai/skills/idiomatic-go/SKILL.md;
      extraSources = [ ./ai/skills/idiomatic-go/style-guide.md ];
    }}
    ${installSkill {
      name = "write";
      source = ./ai/skills/write/SKILL.md;
    }}
  '';

  home.file.".codex/AGENTS.md".text = texts.assistantGuidance;
}
