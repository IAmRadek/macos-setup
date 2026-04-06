---
name: analyze-repo
description: Analyze a repository and provide prioritized, actionable feedback on architecture, code quality, security, and tech debt. Use when the user wants a codebase review or audit.
---

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
