#!/usr/bin/env bash
set -e

# ==============================================================================
# brave-pwa-maker uninstaller
# ==============================================================================

BIN_DEST="${HOME}/.local/bin"
CONFIG_DEST="${HOME}/.config/brave-pwa"
NIRI_CONFIG="${HOME}/.config/niri/config.kdl"

echo "==> Uninstalling brave-pwa-maker..."

# 1. Remove launcher symlinks
if [ -d "${BIN_DEST}" ]; then
    find "${BIN_DEST}" -maxdepth 1 -type l -lname "*brave-pwa-launcher*" -delete 2>/dev/null || true
    rm -f "${BIN_DEST}/brave-pwa" "${BIN_DEST}/brave-pwa-launcher"
    echo "[✓] Removed binaries and launcher symlinks from ${BIN_DEST}"
fi

# 2. Handle configuration files
if [ "$1" == "--purge" ]; then
    rm -rf "${CONFIG_DEST}"
    echo "[✓] Purged configuration directory: ${CONFIG_DEST}"
else
    echo "[i] Configuration directory preserved at ${CONFIG_DEST} (use --purge to remove)."
fi

# 3. Clean Niri rules block
if [ -f "${NIRI_CONFIG}" ]; then
    python3 -c "
import os, re
path = os.path.expanduser('~/.config/niri/config.kdl')
with open(path, 'r') as f:
    c = f.read()
begin_tag = '// >>> BEGIN BRAVE PWA RULES >>>'
end_tag = '// <<< END BRAVE PWA RULES <<<'
if begin_tag in c and end_tag in c:
    pat = re.compile(rf'{re.escape(begin_tag)}.*?{re.escape(end_tag)}\n?', re.DOTALL)
    new_c = pat.sub('', c)
    with open(path, 'w') as f:
        f.write(new_c)
    print('[✓] Removed PWA rules from ' + path)
"
    if command -v niri &>/dev/null; then
        niri msg action load-config-file 2>/dev/null || true
    fi
fi

echo "==> Uninstall complete."
