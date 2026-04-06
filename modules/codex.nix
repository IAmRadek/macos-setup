{ ... }:
{
  home.file.".codex/prompts/analyze-repo.md".text = ''
    Analyze this repository and provide prioritized, actionable feedback.
    Use subagents for broad codebase exploration so the main context stays clean, and run independent subagents in parallel when possible.
    Cover:
    Architecture & structure: does the layout make sense, is there clear separation of concerns, any obvious design issues?
    Code quality: inconsistencies in style or patterns, dead code, overly complex areas, missing error handling.
    Security: hardcoded secrets, unsafe inputs, dependency risks, anything that should be flagged.
    Tech debt: areas that are brittle, poorly tested, or will cause pain as the project grows.
    Before presenting findings, verify each one by re-reading the relevant code.
    Remove any finding you cannot point to a specific file:line.
    If a finding is based on an assumption about runtime behavior, mark it explicitly as unverified.
    Output: a prioritized list grouped by severity (critical / important / minor). Be specific — include file:line references.
    Skip generic advice that applies to every project.
  '';

  home.file.".codex/AGENTS.md".text = ''
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
  '';
}
