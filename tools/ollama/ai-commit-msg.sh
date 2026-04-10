#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="ai-commit-msg"
DEFAULT_MODEL="${AI_COMMIT_MSG_MODEL:-qwen2.5-coder:14b}"
MODEL="$DEFAULT_MODEL"
COUNT="${AI_COMMIT_MSG_COUNT:-5}"

usage() {
  cat <<EOF
Usage:
  git diff | $SCRIPT_NAME [--model MODEL] [--count N]
  $SCRIPT_NAME --staged [--model MODEL] [--count N]

Options:
  --model MODEL   Ollama model to use (default: $DEFAULT_MODEL)
  --count N       Number of commit message candidates (default: $COUNT)
  --staged        Use git diff --cached when no stdin is piped
  -h, --help      Show this help

Environment:
  AI_COMMIT_MSG_MODEL  Default model override
  AI_COMMIT_MSG_COUNT  Default candidate count override
EOF
}

die() {
  echo "$SCRIPT_NAME: $*" >&2
  exit 1
}

read_from_git_staged=false

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
      read_from_git_staged=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ "$COUNT" =~ ^[1-9][0-9]*$ ]] || die "--count must be a positive integer"
command -v ollama >/dev/null 2>&1 || die "ollama is not installed or not in PATH"
command -v curl >/dev/null 2>&1 || die "curl is not installed or not in PATH"
command -v jq >/dev/null 2>&1 || die "jq is not installed or not in PATH"

diff_file="$(mktemp)"
system_file="$(mktemp)"
user_file="$(mktemp)"
trap 'rm -f "$diff_file" "$system_file" "$user_file"' EXIT

if [[ ! -t 0 ]]; then
  cat >"$diff_file"
elif [[ "$read_from_git_staged" == true ]]; then
  command -v git >/dev/null 2>&1 || die "git is not installed or not in PATH"
  git diff --cached >"$diff_file"
else
  usage >&2
  exit 1
fi

[[ -s "$diff_file" ]] || die "no diff received"

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
Prefer conventional commit prefixes like feat:, fix:, refactor:, docs:, test:, chore: when the type is clear.
Focus on the highest-signal change, not implementation trivia.
Even for a small diff, infer the most likely intent and write the messages.
EOF

cat >"$user_file" <<EOF
Generate commit message subjects for this diff:

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
  }' |
  curl -fsS \
    -H 'Content-Type: application/json' \
    -d @- \
    "$ollama_base_url/api/chat" |
  jq -r '.message.content'
