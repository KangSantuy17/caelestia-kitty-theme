#!/usr/bin/env bash
set -Eeuo pipefail

# Caelestia -> Kitty dynamic theme installer
# Installs a generator and registers it as Caelestia CLI's theme.postHook.

readonly APP_NAME="caelestia-kitty-theme"
readonly BIN_DIR="${HOME}/.local/bin"
readonly CONFIG_DIR="${HOME}/.config/kitty"
readonly CAELESTIA_CONFIG_DIR="${HOME}/.config/caelestia"
readonly GENERATOR="${BIN_DIR}/${APP_NAME}"
readonly THEME_FILE="${CONFIG_DIR}/current-theme.conf"
readonly CLI_CONFIG="${CAELESTIA_CONFIG_DIR}/cli.json"
readonly KITTY_CONFIG="${CONFIG_DIR}/kitty.conf"
readonly INCLUDE_LINE="include current-theme.conf"

log() { printf '\033[1;32m[+] \033[0m%s\n' "$*"; }
die() {
  printf '\033[1;31m[ERROR] \033[0m%s\n' "$*" >&2
  exit 1
}

backup_file() {
  local file="$1"
  [[ -f "$file" ]] && cp -a -- "$file" "${file}.bak.$(date +%Y%m%d-%H%M%S)"
}

command -v jq >/dev/null 2>&1 || die "jq is required. Install it first (Arch: sudo pacman -S jq)."
[[ -n "${HOME:-}" ]] || die "HOME is not set."

mkdir -p "$BIN_DIR" "$CONFIG_DIR" "$CAELESTIA_CONFIG_DIR"

cat >"$GENERATOR" <<'GENERATOR_EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

SCHEME="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json"
OUTPUT="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/current-theme.conf"

command -v jq >/dev/null 2>&1 || {
    printf 'caelestia-kitty-theme: jq is required\n' >&2
    exit 1
}
[[ -r "$SCHEME" ]] || {
    printf 'caelestia-kitty-theme: scheme not found: %s\n' "$SCHEME" >&2
    exit 1
}

mkdir -p "$(dirname "$OUTPUT")"
tmp="$(mktemp "${OUTPUT}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

jq -er '
    .colours as $c
    | [
        "background #\($c.background)",
        "foreground #\($c.onBackground)",
        "selection_background #\($c.primaryContainer)",
        "selection_foreground #\($c.onPrimaryContainer)",
        "cursor #\($c.primary)",
        "cursor_text_color #\($c.onPrimary)",
        "url_color #\($c.primary)",
        "active_border_color #\($c.primary)",
        "inactive_border_color #\($c.outline)"
      ]
      + [range(0; 16) as $i | "color\($i) #\($c["term\($i)"])"]
    | .[]
' "$SCHEME" > "$tmp"

chmod 0644 "$tmp"
mv -f -- "$tmp" "$OUTPUT"
trap - EXIT
GENERATOR_EOF

chmod 0755 "$GENERATOR"
log "Installed generator: $GENERATOR"

# Preserve existing CLI settings while setting theme.postHook.
if [[ -f "$CLI_CONFIG" ]]; then
  jq empty "$CLI_CONFIG" >/dev/null 2>&1 || die "$CLI_CONFIG contains invalid JSON; fix it before installing."
  backup_file "$CLI_CONFIG"
else
  printf '{}\n' >"$CLI_CONFIG"
fi

tmp_cli="$(mktemp "${CLI_CONFIG}.XXXXXX")"
jq --arg hook "$GENERATOR" \
  '.theme = ((.theme // {}) + {"postHook": $hook})' \
  "$CLI_CONFIG" >"$tmp_cli"
chmod 0644 "$tmp_cli"
mv -f -- "$tmp_cli" "$CLI_CONFIG"
log "Registered Caelestia theme.postHook in $CLI_CONFIG"

# Ensure Kitty includes the generated palette. Do not duplicate the include.
if [[ -f "$KITTY_CONFIG" ]]; then
  if ! grep -Fqx "$INCLUDE_LINE" "$KITTY_CONFIG"; then
    backup_file "$KITTY_CONFIG"
    {
      printf '\n# Caelestia dynamic theme (managed by %s)\n' "$APP_NAME"
      printf '%s\n' "$INCLUDE_LINE"
    } >>"$KITTY_CONFIG"
    log "Added theme include to $KITTY_CONFIG"
  else
    log "Kitty theme include already exists"
  fi
else
  printf '# Caelestia dynamic theme\n%s\n' "$INCLUDE_LINE" >"$KITTY_CONFIG"
  log "Created $KITTY_CONFIG"
fi

# Generate the current palette immediately.
"$GENERATOR"
log "Generated $THEME_FILE"

cat <<EOF

Installation complete.
Restart Your Kitty Twin.
Backups are created before modifying existing config files.
EOF