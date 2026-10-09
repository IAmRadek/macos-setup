{
  ...
}:
let
  texts = import ./ai/texts.nix;
in
{
  home.file.".claude/CLAUDE.md".text = texts.assistantGuidance;
  home.file.".claude/settings.json".source = ./ai/settings.json;
}
