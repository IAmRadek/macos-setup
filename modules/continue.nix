{ lib, ... }:
{
  home.file.".continue/config.json".text = builtins.toJSON {
    models = [
      {
        title = "qwen3:30b-a3b";
        provider = "ollama";
        model = "qwen3:30b-a3b";
        apiBase = "http://localhost:11434";
      }
    ];
    tabAutocompleteModel = {
      title = "qwen2.5-coder:14b";
      provider = "ollama";
      model = "qwen2.5-coder:14b";
      apiBase = "http://localhost:11434";
    };
    embeddingsProvider = {
      provider = "ollama";
      model = "qwen3-embedding:8b";
      apiBase = "http://localhost:11434";
    };
    contextProviders = [
      { name = "code"; }
      { name = "docs"; }
      { name = "diff"; }
      { name = "terminal"; }
      { name = "problems"; }
      { name = "folder"; }
      { name = "codebase"; }
    ];
    slashCommands = [
      {
        name = "edit";
        description = "Edit highlighted code";
      }
      {
        name = "comment";
        description = "Write comments for the highlighted code";
      }
      {
        name = "share";
        description = "Export the current chat session to markdown";
      }
    ];
    allowAnonymousTelemetry = false;
  };
}
