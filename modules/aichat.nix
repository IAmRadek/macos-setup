{ pkgs, lib, ... }:

let
  dotfiles = builtins.path {
    path = ../dotfiles;
    name = "dotfiles";
  };
in
{
  # Set aichat environment variables
  home.sessionVariables = {
    AICHAT_CONFIG_DIR = "$HOME/.config/aichat";
    AICHAT_ENV_FILE = "$HOME/.config/aichat/.env";
    AICHAT_CONFIG_FILE = "$HOME/.config/aichat/config.yaml";
    AICHAT_ROLES_DIR = "$HOME/.config/aichat/roles";
    AICHAT_SESSIONS_DIR = "$HOME/.config/aichat/sessions";
    AICHAT_RAGS_DIR = "$HOME/.config/aichat/rags";
    AICHAT_FUNCTIONS_DIR = "$HOME/.config/aichat/functions";
    AICHAT_MESSAGES_FILE = "$HOME/.config/aichat/messages.md";
  };

  # Symlink AIChat configuration from dotfiles
  xdg.configFile."aichat/config.yaml".source = "${dotfiles}/aichat/config.yaml";
  xdg.configFile."aichat/roles.yaml".source = "${dotfiles}/aichat/roles.yaml";
  xdg.configFile."aichat/agents/adr/config.yaml".source = "${dotfiles}/aichat/agents/adr/config.yaml";

  # Populate OPENROUTER_API_KEY from 1Password
  home.activation.populateAichatEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    AICHAT_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/aichat"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$AICHAT_CONFIG_DIR"

    if command -v op &>/dev/null; then
      $VERBOSE_ECHO "Fetching OPENROUTER_API_KEY from 1Password..."
      API_KEY=$(op read "op://Private/OpenRouter/credentials" 2>/dev/null || echo "")

      if [ -n "$API_KEY" ]; then
        $DRY_RUN_CMD echo "OPENROUTER_API_KEY=$API_KEY" > "$AICHAT_CONFIG_DIR/.env"
        $DRY_RUN_CMD chmod 600 "$AICHAT_CONFIG_DIR/.env"
        $VERBOSE_ECHO "Successfully populated OPENROUTER_API_KEY"
      fi
    fi
  '';
}
