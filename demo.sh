#!/bin/bash
# Demo script — shows claude-picker UI with fake sessions for screenshot purposes
DEMO_DATA="  20/05 14:32  ~/work/my-saas-app       Add Stripe webhook handler
  19/05 23:11  ~/work/api-gateway         Fix rate limiting bug in middleware
  19/05 18:44  ~/work/my-saas-app         Migrate users table to Postgres
  18/05 21:03  ~/work/cli-tool            Add fuzzy search with fzf integration
  18/05 15:27  ~/work/api-gateway         Write integration tests for auth
  17/05 09:58  ~/work/data-pipeline       Fix memory leak in stream processor
  16/05 22:15  ~/work/cli-tool            Publish first release to GitHub
  15/05 17:30  ~/dotfiles                 Set up zsh aliases and PATH"

TMP_IN=$(mktemp)
TMP_OUT=$(mktemp)

printf "  ✦  New session in ~/work/my-saas-app\x1f\x1f\n" >> "$TMP_IN"
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    date=$(echo "$line" | awk '{print $1, $2}')
    dir=$(echo "$line" | awk '{print $3}')
    title=$(echo "$line" | sed 's/.*[0-9][0-9]:[0-9][0-9]  [^ ]*  //')
    printf "%s  %-26s  %s\x1f_FAKE_ID_\x1f%s\n" "$date" "$dir" "$title" "$dir" >> "$TMP_IN"
done <<< "$DEMO_DATA"

fzf --delimiter=$'\x1f' --with-nth=1 --no-sort --height=~100% --border=rounded \
    --border-label=" Claude Code — Sessions " --prompt="  Search: " --pointer="▶" \
    --highlight-line \
    --header=$'  ↑↓ navigate   Enter select   Esc cancel\n' \
    < "$TMP_IN" > "$TMP_OUT"

rm -f "$TMP_IN" "$TMP_OUT"
