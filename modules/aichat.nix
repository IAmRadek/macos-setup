{ pkgs, lib, ... }:
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

  # Configure aichat with custom roles and agents
  xdg.configFile."aichat/roles.yaml".text = '''';

  xdg.configFile."aichat/config.yaml".text = ''
    model: openrouter:openai/gpt-4.1-mini
    save: true
    highlight: true
    light_theme: false
    wrap: no
    wrap_code: false

    rag_embedding_model: openrouter:text-embedding-3-large
    rag_reranker_model: null
    rag_top_k: 5
    rag_chunk_size: 1500
    rag_chunk_overlap: 150

    rag_template: |
      Answer the query based on the context while respecting the rules. (user query, some textual context and rules, all inside xml tags)

      <context>
      __CONTEXT__
      </context>

      <rules>
      - If you don't know, just say so.
      - If you are not sure, ask for clarification.
      - Answer in the same language as the user query.
      - If the context appears unreadable or of poor quality, tell the user then answer as best as you can.
      - If the answer is not in the context but you think you know the answer, explain that to the user then answer with your own knowledge.
      - Answer directly and without using xml tags.
      </rules>

      <user_query>
      __INPUT__
      </user_query>

    clients:
      - type: openai-compatible
        name: openrouter
        api_base: https://openrouter.ai/api/v1
      - type: openai-compatible
        name: openrouter
        models:
        - name: text-embedding-3-large
          type: embedding
  '';

  # Configure custom agents (RAG-based with files/functions)
  xdg.configFile."aichat/agents/adr/config.yaml".text = ''
    model: openrouter:openai/gpt-4.1-mini
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

    $VERBOSE_ECHO "Fetching OPENROUTER_API_KEY from 1Password..."
    API_KEY=$(${pkgs._1password-cli}/bin/op read "op://Private/OpenRouter/credentials" 2>/dev/null || echo "")

    if [ -n "$API_KEY" ]; then
      $DRY_RUN_CMD echo "OPENROUTER_API_KEY=$API_KEY" > "$AICHAT_CONFIG_DIR/.env"
      $DRY_RUN_CMD chmod 600 "$AICHAT_CONFIG_DIR/.env"
      $VERBOSE_ECHO "Successfully populated OPENROUTER_API_KEY"
    else
      echo "Warning: Could not fetch OPENROUTER_API_KEY from 1Password"
      echo "Please ensure the item exists at: op://Private/OpenRouter/credentials"
    fi
  '';
}
