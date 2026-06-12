{
  assistantGuidance = ''
    - Terse, direct responses — skip preamble, filler, and trailing summaries
    - No emojis unless asked
    - Lead with the answer or action, not the reasoning
    - When referencing code, include `file:line` for easy navigation
    - Prefer CLI tools over training knowledge for API and library docs — they reflect the actual installed version and are always accurate
    - Use man pages, doc, or help commands when not sure about params:
        `go doc <pkg>`, `go doc <pkg>.<Symbol>`
        `man <cmd>`
        `<cmd> --help` / `<cmd> -h` for flags and usage
        `tldr <cmd>` for concise practical examples
    - Only fall back to training knowledge when no CLI tool is available.
    - When working with Go: do not run `go test` — signal when tests should be run instead
    - Use subagents for expensive or broad tasks: codebase exploration, multi-file searches, research — keeps the main context clean
    - Run independent subagents in parallel in a single message when possible
    - Prefer foreground subagents when their result is needed before proceeding; background subagents for genuinely independent work
    - Before making non-trivial code changes, briefly state the plan (1-3 bullets) and wait for confirmation on ambiguous scope.
    - When searching for symbols, try variations (e.g., related types, partial names) before reporting 'not found'.
    - For large UI rewrites or multi-file ports, break the work into chunks across multiple responses rather than attempting a single 32k-token output.
    - Prefer targeted Edits over full-file rewrites when only a few values change (e.g., palette swaps).
    - Preserve existing doc comments unless explicitly asked to remove them.
    - Use the Edit tool for file modifications. Do NOT use `sed` for editing files.
    - Stay strictly within the requested ticket/task scope. Do not make additional 'improvement' edits to files outside the explicit ask without confirming first.
  '';
}
