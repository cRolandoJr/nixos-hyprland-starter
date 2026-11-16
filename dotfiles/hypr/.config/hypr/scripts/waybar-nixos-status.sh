#!/usr/bin/env bash
# waybar-nixos-status.sh — JSON output para custom/nixos.
# Símbolo NixOS: azul clean, rojo dirty, ámbar sin verificación.
# Tooltip:  versión, kernel, status del flake, fecha rebuild.

set -euo pipefail

ICON=$''   # nf-linux-nixos (símbolo NixOS NerdFont)
FLAKE_DIR="$HOME/projects/nix-config"
SYSTEM_PROFILE="${NIXOS_SYSTEM_PROFILE:-/nix/var/nix/profiles/system}"
NIXOS_VER_FILE="${NIXOS_VERSION_FILE:-/run/current-system/nixos-version}"

# Generation actual del system profile (sin sudo).
GEN=$(basename "$(readlink "$SYSTEM_PROFILE" 2>/dev/null)" | grep -oE '[0-9]+' || echo "?")

# Versión NixOS major.minor (e.g. "26.05").
VER=$(cut -d. -f1-2 "$NIXOS_VER_FILE" 2>/dev/null || echo "?")

KERNEL=$(uname -r)

# Última rebuild — sin segundos para que entre en una línea.
LAST=$(stat -c '%y' "$SYSTEM_PROFILE" 2>/dev/null | cut -d: -f1-2 || echo "?")

# Estado del flake (git porcelain).
FLAKE_LABEL="repositorio no encontrado"
CLASS="missing"
ICON_COLOR="#fbbf24"
# .git puede ser un directorio o un archivo (worktree).
if [ -e "$FLAKE_DIR/.git" ]; then
  if STATUS=$(git -C "$FLAKE_DIR" status --porcelain 2>/dev/null); then
    if [ -z "$STATUS" ]; then
      FLAKE_LABEL="clean"
      CLASS="clean"
      ICON_COLOR="#3b82f6"
    else
      DIRTY_COUNT=$(printf '%s\n' "$STATUS" | wc -l)
      FLAKE_LABEL="dirty ($DIRTY_COUNT archivos)"
      CLASS="dirty"
      ICON_COLOR="#f87171"
    fi
  else
    FLAKE_LABEL="error al consultar Git"
    CLASS="error"
  fi
fi

TEXT="<span color='$ICON_COLOR' size='15pt'>$ICON</span>"
TOOLTIP="NixOS $VER\nGen $GEN | Kernel $KERNEL\nFlake: $FLAKE_LABEL\nRebuild: $LAST"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
