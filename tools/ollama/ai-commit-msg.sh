#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="ai-commit-msg"
DEFAULT_MODEL="${AI_COMMIT_MSG_MODEL:-qwen2.5-coder:14b}"
MODEL="$DEFAULT_MODEL"
COUNT="${AI_COMMIT_MSG_COUNT:-5}"
DIFF_MODE="staged"
REV_RANGE=""
EXTRA_CONTEXT=""

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [--staged] [--model MODEL] [--count N] [CONTEXT]
  $SCRIPT_NAME --unstaged [--model MODEL] [--count N] [CONTEXT]
  $SCRIPT_NAME --rev RANGE [--model MODEL] [--count N] [CONTEXT]

Options:
  --model MODEL   Ollama model to use (default: $DEFAULT_MODEL)
  --count N       Number of commit message candidates (default: $COUNT)
  --staged        Use staged changes (default)
  --unstaged      Use working tree changes
  --rev RANGE     Use git diff for a revision/range, e.g. HEAD~1..HEAD
  -h, --help      Show this help

Arguments:
  CONTEXT         Extra guidance appended before the diff

Environment:
  AI_COMMIT_MSG_MODEL  Default model override
  AI_COMMIT_MSG_COUNT  Default candidate count override
EOF
}

die() {
  echo "$SCRIPT_NAME: $*" >&2
  exit 1
}

start_progress() {
  if [[ -t 2 ]]; then
    printf 'Generating commit messages' >&2
    (
      while true; do
        printf '.' >&2
        sleep 1
      done
    ) &
    PROGRESS_PID=$!
  else
    PROGRESS_PID=""
  fi
}

stop_progress() {
  if [[ -n "${PROGRESS_PID:-}" ]]; then
    kill "$PROGRESS_PID" >/dev/null 2>&1 || true
    wait "$PROGRESS_PID" 2>/dev/null || true
    printf '\n' >&2
    PROGRESS_PID=""
  fi
}

require_git_repo() {
  command -v git >/dev/null 2>&1 || die "git is not installed or not in PATH"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      [[ $# -ge 2 ]] || die "missing value for --model"
      MODEL="$2"
      shift 2
      ;;
    --model=*)
      MODEL="${1#*=}"
      shift
      ;;
    --count)
      [[ $# -ge 2 ]] || die "missing value for --count"
      COUNT="$2"
      shift 2
      ;;
    --count=*)
      COUNT="${1#*=}"
      shift
      ;;
    --staged)
      DIFF_MODE="staged"
      REV_RANGE=""
      shift
      ;;
    --unstaged)
      DIFF_MODE="unstaged"
      REV_RANGE=""
      shift
      ;;
    --rev)
      [[ $# -ge 2 ]] || die "missing value for --rev"
      DIFF_MODE="rev"
      REV_RANGE="$2"
      shift 2
      ;;
    --rev=*)
      DIFF_MODE="rev"
      REV_RANGE="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$EXTRA_CONTEXT" ]]; then
        EXTRA_CONTEXT="$1"
      else
        EXTRA_CONTEXT="$EXTRA_CONTEXT $1"
      fi
      shift
      ;;
  esac
done

[[ "$COUNT" =~ ^[1-9][0-9]*$ ]] || die "--count must be a positive integer"
command -v ollama >/dev/null 2>&1 || die "ollama is not installed or not in PATH"
command -v curl >/dev/null 2>&1 || die "curl is not installed or not in PATH"
command -v jq >/dev/null 2>&1 || die "jq is not installed or not in PATH"
require_git_repo

diff_file="$(mktemp)"
system_file="$(mktemp)"
user_file="$(mktemp)"
request_file="$(mktemp)"
response_file="$(mktemp)"
trap 'stop_progress; rm -f "$diff_file" "$system_file" "$user_file" "$request_file" "$response_file"' EXIT

git_diff_args=(
  -c core.pager=cat
  diff
  --no-ext-diff
  --no-color
  --patch
)

case "$DIFF_MODE" in
  staged)
    git "${git_diff_args[@]}" --cached >"$diff_file"
    diff_label="staged changes"
    ;;
  unstaged)
    git "${git_diff_args[@]}" >"$diff_file"
    diff_label="unstaged changes"
    ;;
  rev)
    [[ -n "$REV_RANGE" ]] || die "missing revision range"
    git "${git_diff_args[@]}" "$REV_RANGE" >"$diff_file"
    diff_label="changes for $REV_RANGE"
    ;;
  *)
    die "unsupported diff mode: $DIFF_MODE"
    ;;
esac

[[ -s "$diff_file" ]] || die "no diff found for $diff_label"

cat >"$system_file" <<EOF
You write git commit message subjects from diffs.
Return exactly $COUNT candidates.
Return one candidate per line.
Return only the candidates.
Do not number the lines.
Do not use bullets.
Do not use code fences.
Do not explain anything.
Do not apologize.
Do not mention uncertainty.
Keep each line at 72 characters or fewer.
Use imperative mood.
Always use Conventional Commits format.
Every line must match this shape:
type(scope): subject
or, if no scope is useful:
type: subject
Allowed types: feat, fix, refactor, docs, test, chore, ci, build, perf, style, revert.
Choose the single best type for each candidate based on the diff.
Use a short, specific scope only when it adds signal.
Do not invent ticket numbers or issue IDs.
Do not end the subject with punctuation.
Do not use vague subjects like "update stuff" or "misc changes".
Focus on the highest-signal change, not implementation trivia.
Even for a small diff, infer the most likely intent and write the messages.
EOF

cat >"$user_file" <<EOF
Generate commit message subjects for these $diff_label:

EOF

if [[ -n "$EXTRA_CONTEXT" ]]; then
  cat >>"$user_file" <<EOF
Additional context:
$EXTRA_CONTEXT

EOF
fi

cat >>"$user_file" <<EOF
$(cat "$diff_file")
EOF

ollama_host="${OLLAMA_HOST:-127.0.0.1:11434}"
if [[ "$ollama_host" == http://* || "$ollama_host" == https://* ]]; then
  ollama_base_url="$ollama_host"
else
  ollama_base_url="http://$ollama_host"
fi

jq -n \
  --arg model "$MODEL" \
  --arg system "$(cat "$system_file")" \
  --arg user "$(cat "$user_file")" \
  '{
    model: $model,
    messages: [
      {role: "system", content: $system},
      {role: "user", content: $user}
    ],
    stream: false
  }' >"$request_file"

start_progress
curl -fsS \
  -H 'Content-Type: application/json' \
  -d @"$request_file" \
  "$ollama_base_url/api/chat" \
  >"$response_file"
stop_progress

jq -r '.message.content' "$response_file"
