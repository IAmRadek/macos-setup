{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Open WebUI — installed via `uv tool install open-webui`.
  # uv manages the virtualenv; the binary lands at ~/.local/bin/open-webui.
  # Accessible at http://localhost:10001 after login.
  # Data (users, chats, settings) persists in ~/.local/share/open-webui.

  home.activation.installOpenWebUI = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! "${pkgs.uv}/bin/uv" tool list 2>/dev/null | grep -q "^open-webui"; then
      $VERBOSE_ECHO "Installing open-webui via uv tool install..."
      $DRY_RUN_CMD "${pkgs.uv}/bin/uv" tool install open-webui
    fi
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "${config.home.homeDirectory}/.local/share/open-webui"
  '';

  launchd.agents.open-webui = {
    enable = true;
    config = {
      Label = "com.open-webui.serve";
      ProgramArguments = [
        "${config.home.homeDirectory}/.local/bin/open-webui"
        "serve"
        "--host"
        "127.0.0.1"
        "--port"
        "10001"
      ];
      EnvironmentVariables = {
        OLLAMA_BASE_URL = "http://localhost:11434";
        DATA_DIR = "${config.home.homeDirectory}/.local/share/open-webui";
        HOME = "${config.home.homeDirectory}";
      };
      WorkingDirectory = "${config.home.homeDirectory}/.local/share/open-webui";
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/open-webui.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/open-webui-error.log";
    };
  };
}
