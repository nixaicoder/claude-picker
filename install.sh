#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/claude.sh"

echo "Installing claude-picker..."

cp "$SCRIPT_DIR/claude.sh" "$DEST"
chmod +x "$DEST"
echo "  ✓ Script installed to $DEST"

# Detect shell config file
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
else
    echo "  ! Could not detect shell config. Add the cc() function manually (see README)."
    exit 0
fi

# Check if cc() already exists
if grep -q "^cc()" "$SHELL_RC" 2>/dev/null; then
    echo "  ✓ cc() function already present in $SHELL_RC — skipping."
else
    cat >> "$SHELL_RC" << 'EOF'

# claude-picker — https://github.com/nixaicoder/claude-picker
cc() {
    local _CHOICE_FILE
    _CHOICE_FILE=$(mktemp)
    bash "$HOME/claude.sh" "$_CHOICE_FILE"
    local _SESSION_ID="" _TARGET_DIR=""
    if [[ -s "$_CHOICE_FILE" ]]; then
        IFS=$'\t' read -r _SESSION_ID _TARGET_DIR < "$_CHOICE_FILE"
    fi
    rm -f "$_CHOICE_FILE"
    if [[ -n "$_TARGET_DIR" && -d "$_TARGET_DIR" ]]; then
        cd "$_TARGET_DIR" && echo "[→] $(pwd)"
    fi
    if [[ -n "$_SESSION_ID" ]]; then
        claude --resume "$_SESSION_ID" "$@"
    else
        claude "$@"
    fi
}
EOF
    echo "  ✓ cc() function added to $SHELL_RC"
fi

echo ""
echo "Done! Run: source $SHELL_RC"
echo "Then type 'cc' to launch claude-picker."
