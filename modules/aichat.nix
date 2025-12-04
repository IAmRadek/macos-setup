{ pkgs, lib, ... }:
{
  # Configure aichat with custom roles and agents
  xdg.configFile."aichat/roles.yaml".text = '''';

  xdg.configFile."aichat/config.yaml".text = ''
    model: claude:claude-sonnet-4-5-20250929
    save: true
    highlight: true
    light_theme: false
    wrap: no
    wrap_code: false
  '';

  # Configure custom agents (RAG-based with files/functions)
  xdg.configFile."aichat/agents/adr.yaml".text = ''
    model: openai:gpt-4o
    temperature: 0.3
    top_p: 0.9

    # Optionally give it tools (e.g. fs, web_search if you set them up)
    use_tools: null

    agent_prelude: default

    instructions: |
      You are an Architecture Decision Record (ADR) mentor working with a senior engineer.
      Your job is to interrogate and deepen their thinking about architectural decisions.

      Core principles:
      - You primarily ask questions. Your messages are mostly questions.
      - You help the user clarify:
        - Business context & drivers
        - Quality attributes (scalability, reliability, latency, cost, compliance, etc.)
        - Constraints (teams, tech, legacy systems, deadlines)
        - Alternatives considered and why they might be rejected
        - Risks, unknowns, experiments, and roll-back plans
      - You DO NOT write ADRs for the user.
        - If the user asks for “the ADR”, you respond with clarifying questions instead.
        - You may suggest what sections they might want to fill in next (in 3–7 bullets).
      - Encourage explicit trade-offs: X vs Y, pros/cons, and impact analysis.

      Conversation style:
      - Short, precise questions, usually grouped (2–4 per turn).
      - Use the user’s language and concepts; reuse their own words.
      - When something is vague, ask them to make it more concrete.

    variables: {}
  '';

  # Populate OPENROUTER_API_KEY from 1Password
  home.activation.populateAichatEnv = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    AICHAT_CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/aichat"
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG "$AICHAT_CONFIG_DIR"

    # Fetch API key from 1Password and write to .env file
    if command -v op &> /dev/null; then
      $VERBOSE_ECHO "Fetching OPENROUTER_API_KEY from 1Password..."
      API_KEY=$(${pkgs._1password}/bin/op read "op://Private/OpenRouter/credentials" 2>/dev/null || echo "")

      if [ -n "$API_KEY" ]; then
        $DRY_RUN_CMD echo "OPENROUTER_API_KEY=$API_KEY" > "$AICHAT_CONFIG_DIR/.env"
        $DRY_RUN_CMD chmod 600 "$AICHAT_CONFIG_DIR/.env"
        $VERBOSE_ECHO "Successfully populated OPENROUTER_API_KEY"
      else
        $VERBOSE_ECHO "Warning: Could not fetch OPENROUTER_API_KEY from 1Password"
        $VERBOSE_ECHO "Please ensure the item exists at: op://Private/OpenRouter/credentials"
      fi
    fi
  '';
}
