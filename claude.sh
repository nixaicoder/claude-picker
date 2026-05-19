#!/bin/bash
# claude.sh — Menú interactivo de sesiones Claude Code (fzf)
# Escribe SESSION_ID<TAB>CWD a $1 si el usuario elige sesión existente.

CHOICE_FILE="${1:-}"

SESSION_DATA=$(python3 - <<'PYEOF'
import json, datetime
from pathlib import Path

HOME = Path.home()
projects_dir = HOME / '.claude' / 'projects'
sessions = []

def folder_to_path(n):
    return n.replace('-', '/', 1)

def get_info(p):
    cwd = folder_to_path(p.parent.name)
    title = '(sin titulo)'
    try:
        with open(p) as f:
            for line in f:
                try:
                    e = json.loads(line)
                    if e.get('cwd'):
                        cwd = e['cwd']
                    if e.get('type') == 'ai-title' and e.get('aiTitle'):
                        title = e['aiTitle'][:60]
                        break
                except Exception:
                    pass
    except Exception:
        pass
    return cwd, title

if projects_dir.exists():
    for jsonl in projects_dir.rglob('*.jsonl'):
        mtime = jsonl.stat().st_mtime
        sid = jsonl.stem
        cwd, title = get_info(jsonl)
        dcwd = cwd.replace(str(HOME), '~')
        date = datetime.datetime.fromtimestamp(mtime).strftime('%d/%m %H:%M')
        sessions.append((mtime, sid, date, cwd, dcwd, title))

sessions.sort(reverse=True)
for _, sid, date, cwd, dcwd, title in sessions[:30]:
    # separador: \x1f (ASCII Unit Separator) — no aparece en rutas ni títulos
    print(f"{sid}\x1f{date}\x1f{cwd}\x1f{dcwd}\x1f{title}")
PYEOF
)

# Construir input para fzf: línea display real + datos ocultos tras \x00
TMP_FZF_IN=$(mktemp)
TMP_FZF_OUT=$(mktemp)

# Primera opción: nueva sesión
printf "  ✦  Nueva sesión en $(pwd)\x1f\x1f\n" >> "$TMP_FZF_IN"

while IFS=$'\x1f' read -r sid date cwd dcwd title; do
    [[ -z "$sid" ]] && continue
    printf "  %s  %-24s  %s\x1f%s\x1f%s\n" \
        "$date" "${dcwd:0:24}" "$title" "$sid" "$cwd" >> "$TMP_FZF_IN"
done <<< "$SESSION_DATA"

# Lanzar fzf
fzf \
    --delimiter=$'\x1f' \
    --with-nth=1 \
    --no-sort \
    --height=~100% \
    --border=rounded \
    --border-label=" Claude Code — Sesiones " \
    --prompt="  Buscar: " \
    --pointer="▶" \
    --highlight-line \
    --header=$'  ↑↓ navegar   Enter seleccionar   Esc cancelar\n' \
    < "$TMP_FZF_IN" > "$TMP_FZF_OUT"

FZF_EXIT=$?
SELECTED=$(cat "$TMP_FZF_OUT")
rm -f "$TMP_FZF_IN" "$TMP_FZF_OUT"

if [[ $FZF_EXIT -ne 0 || -z "$SELECTED" ]]; then
    exit 0
fi

# Extraer campos ocultos (separador \x00)
IFS=$'\x1f' read -r _display SESSION_ID TARGET_DIR <<< "$SELECTED"

[[ -z "$CHOICE_FILE" ]] && exit 0

if [[ -n "$SESSION_ID" ]]; then
    printf '%s\t%s' "$SESSION_ID" "$TARGET_DIR" > "$CHOICE_FILE"
fi
