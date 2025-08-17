#!/usr/bin/env sh
# new-runbook.sh — create a new runbook in ~/.runbooks/

set -e

read -rp "Runbook name: " name

# Slugify: lowercase, spaces to -, strip invalid chars
slug=$(echo "$name" \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' ' '-' \
  | tr -cd '[:alnum:]-')

dir="$HOME/.runbooks"
file="$dir/$slug.md"

mkdir -p "$dir"

# If file doesn't exist, add a front-matter template
if [ ! -f "$file" ]; then
  cat > "$file" <<EOF
<!--
title: $name
tags: []
summary:
-->

# $name

## Steps

1.

EOF
fi

# Open in editor
"${EDITOR:-nano}" "$file"
