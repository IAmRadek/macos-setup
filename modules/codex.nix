{
  ...
}:
let
  texts = import ./ai/texts.nix;
in
{
  home.file.".codex/AGENTS.md".text = texts.assistantGuidance;
}
