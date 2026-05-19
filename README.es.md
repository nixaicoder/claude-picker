# claude-picker

Selector interactivo de sesiones para [Claude Code](https://claude.ai/code) — navega tus sesiones anteriores con búsqueda fuzzy, retómalas al instante y aterriza automáticamente en el directorio correcto del proyecto.

## Por qué existe

El flag `--resume` de Claude Code es muy potente, pero recordar UUIDs de sesión no es lo nuestro. Este script lo envuelve con un menú `fzf` que muestra:

- **Cuándo** estuvo activa cada sesión por última vez
- **A qué proyecto** pertenece
- **En qué estabas trabajando** — usando el título generado automáticamente por Claude

Selecciona una sesión, pulsa Enter — estás de vuelta en contexto, en el directorio correcto.

## Qué lo diferencia de herramientas similares

La mayoría de los selectores de sesiones de Claude Code muestran UUIDs crudos o fragmentos de mensajes. `claude-picker` usa el campo `ai-title` que Claude Code escribe en el fichero JSONL de cada sesión — el mismo título que ves en la interfaz. Es la descripción más precisa de lo que trata una sesión.

Además **hace `cd` automáticamente** al directorio del proyecto antes de retomar, así tu terminal cae donde está el trabajo.

## Requisitos

- [Claude Code](https://claude.ai/code) instalado
- [fzf](https://github.com/junegunn/fzf) >= 0.50 (para soporte de `--highlight-line`)
- Python 3 (estándar en la mayoría de sistemas)
- bash / zsh

## Instalación

**1. Descarga el script:**

```bash
curl -o ~/claude.sh https://raw.githubusercontent.com/nixaicoder/claude-picker/main/claude.sh
chmod +x ~/claude.sh
```

**O con el instalador automático:**

```bash
git clone https://github.com/nixaicoder/claude-picker
cd claude-picker && bash install.sh
```

**2. Añade la función `cc` a tu configuración de shell** (`~/.zshrc` o `~/.bashrc`):

```bash
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
        cd "$_TARGET_DIR"
        echo "[→] $(pwd)"
    fi

    if [[ -n "$_SESSION_ID" ]]; then
        claude --resume "$_SESSION_ID" "$@"
    else
        claude "$@"
    fi
}
```

**3. Recarga tu shell:**

```bash
source ~/.zshrc
```

## Uso

Escribe `cc` desde cualquier carpeta:

```
  ┌─ Claude Code — Sesiones ──────────────────────────────────────────┐
  │  ↑↓ navegar   Enter seleccionar   Esc cancelar                    │
  │> 20/05 12:34  ~/work/mi-proyecto  Añadir soporte WebSocket        │
  │  19/05 22:10  ~/work/api          Corregir bug de autenticación   │
  │  19/05 14:05  ~                   Revisar pull request            │
  │  ✦  Nueva sesión en /directorio/actual                            │
  └───────────────────────────────────────────────────────────────────┘
    Buscar: _
```

- **↑ ↓** o **j k** — navegar
- **Escribe** — filtrar por fecha, proyecto o título
- **Enter** — retomar sesión seleccionada (o iniciar nueva)
- **Esc** — cancelar

## Cómo funciona

Claude Code almacena los datos de sesión como ficheros JSONL en `~/.claude/projects/<ruta-codificada>/`. Cada fichero de sesión contiene una entrada `ai-title` — una descripción corta generada por Claude al inicio de la conversación. `claude-picker` lee estos ficheros, los ordena por fecha de modificación y los pasa a `fzf`. El ID de sesión seleccionado se pasa a `claude --resume`.

La función `cc()` del shell (no el script en sí) gestiona el `cd`, ya que un subproceso no puede cambiar el directorio del shell padre.

## Nota sobre la versión de fzf

Los repositorios de Debian/Ubuntu pueden incluir una versión antigua de fzf. Si `--highlight-line` da errores, instala un binario reciente desde la [página de releases de fzf](https://github.com/junegunn/fzf/releases).

## Licencia

MIT
