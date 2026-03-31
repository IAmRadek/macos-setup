{ pkgs, lib, ... }:

{
  home.activation.knowledgeVault = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    KNOWLEDGE_DIR="$HOME/Knowledge"
    GIT="${pkgs.git}/bin/git"

    # Clone or pull the Knowledge vault
    if [ ! -d "$KNOWLEDGE_DIR/.git" ]; then
      $DRY_RUN_CMD $GIT clone git@github.com:IAmRadek/Knowledge.git "$KNOWLEDGE_DIR"
    else
      $DRY_RUN_CMD $GIT -C "$KNOWLEDGE_DIR" pull --ff-only || true
    fi

    # Register the vault with Obsidian (idempotent, skipped in dry-run)
    OBSIDIAN_CFG="$HOME/Library/Application Support/obsidian/obsidian.json"
    JQ="${pkgs.jq}/bin/jq"

    if [ -f "$OBSIDIAN_CFG" ] && [ -z "''${DRY_RUN_CMD:-}" ]; then
      if ! $JQ -e --arg p "$KNOWLEDGE_DIR" \
          '.vaults // {} | to_entries[] | select(.value.path == $p)' \
          "$OBSIDIAN_CFG" > /dev/null 2>&1; then
        VAULT_ID="$(${pkgs.openssl}/bin/openssl rand -hex 8)"
        TS="$(${pkgs.coreutils}/bin/date +%s)000"
        $JQ --arg id "$VAULT_ID" --arg path "$KNOWLEDGE_DIR" --argjson ts "$TS" \
          '.vaults[$id] = {"path": $path, "ts": $ts}' \
          "$OBSIDIAN_CFG" > "$OBSIDIAN_CFG.tmp" \
          && mv "$OBSIDIAN_CFG.tmp" "$OBSIDIAN_CFG"
      fi
    fi
  '';
}
