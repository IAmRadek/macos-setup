{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Open WebUI — browser-based chat UI connecting to the local Ollama instance.
  # Accessible at http://localhost:8080 after login.
  # Data (users, chats, settings) persists in ~/.local/share/open-webui.

  home.packages = [ pkgs.open-webui ];

  home.activation.createOpenWebUIDataDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.local/share/open-webui"
  '';

  launchd.agents.open-webui = {
    enable = true;
    config = {
      Label = "com.open-webui.serve";
      ProgramArguments = [
        "${pkgs.open-webui}/bin/open-webui"
        "serve"
      ];
      EnvironmentVariables = {
        OLLAMA_BASE_URL = "http://localhost:11434";
        DATA_DIR = "${config.home.homeDirectory}/.local/share/open-webui";
        HOST = "127.0.0.1";
        PORT = "10001";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/open-webui-error.log";
    };
  };
}
