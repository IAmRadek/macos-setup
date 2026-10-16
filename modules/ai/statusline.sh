#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
CTX_USED=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
CTX_MAX=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
SEVEN_D=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

fmt_tokens() {
    local n=$1
    if [ -z "$n" ] || [ "$n" = "null" ]; then
        echo "?"
    elif [ "$n" -ge 1000000 ]; then
        awk -v n="$n" 'BEGIN{printf "%.1fM", n/1000000}'
    elif [ "$n" -ge 1000 ]; then
        awk -v n="$n" 'BEGIN{printf "%.1fk", n/1000}'
    else
        echo "$n"
    fi
}

parts=("[$MODEL]")

if [ -n "$CTX_USED" ] && [ -n "$CTX_MAX" ]; then
    pct_disp=""
    if [ -n "$CTX_PCT" ]; then
        pct_disp=" ($(printf '%.0f' "$CTX_PCT")%)"
    fi
    parts+=("CTX: $(fmt_tokens "$CTX_USED")/$(fmt_tokens "$CTX_MAX")${pct_disp}")
fi

if [ -n "$FIVE_H" ]; then
    parts+=("5h: $(printf '%.0f' "$FIVE_H")%")
fi

if [ -n "$SEVEN_D" ]; then
    parts+=("Week: $(printf '%.0f' "$SEVEN_D")%")
fi

(IFS=" | "; echo "${parts[*]}")
