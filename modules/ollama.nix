{
  pkgs,
  config,
  lib,
  ...
}:
{
  # TODO: pull models after the service is first running:
  #   ollama pull qwen3:30b-a3b
  #   ollama pull qwen2.5-coder:14b
  #   ollama pull qwen3-embedding:8b

  home.activation.createOllamaModelDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.ollama/models"
  '';

  launchd.agents.ollama = {
    enable = true;
    config = {
      Label = "com.ollama.serve";
      ProgramArguments = [
        "${pkgs.ollama}/bin/ollama"
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_HOST = "0.0.0.0:11434";
        OLLAMA_MODELS = "${config.home.homeDirectory}/.ollama/models";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ollama-error.log";
    };
  };
}
