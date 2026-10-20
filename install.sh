#!/usr/bin/env bash
set -e

# ==============================================================================
# brave-pwa-maker installer
# ==============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DEST="${HOME}/.local/bin"
CONFIG_DEST="${HOME}/.config/brave-pwa"
NIRI_CONFIG="${HOME}/.config/niri/config.kdl"

echo "==> Installing brave-pwa-maker..."

# 1. Dependency checks
if ! command -v python3 &>/dev/null; then
    echo "[!] Error: Python 3 is required but not installed." >&2
    exit 1
fi

if ! command -v brave-browser &>/dev/null && [ ! -f /opt/brave.com/brave/brave-browser ]; then
    echo "[!] Warning: Brave Browser executable not found in PATH or /opt/brave.com/brave/brave-browser." >&2
fi

if ! command -v niri &>/dev/null; then
    echo "[!] Warning: 'niri' command not found. Window management features require Niri compositor." >&2
fi

# 2. Copy binaries
mkdir -p "${BIN_DEST}"
install -m 755 "${PROJECT_DIR}/bin/brave-pwa" "${BIN_DEST}/brave-pwa"
install -m 755 "${PROJECT_DIR}/bin/brave-pwa-launcher" "${BIN_DEST}/brave-pwa-launcher"
echo "[✓] Installed binaries to ${BIN_DEST}"

# 3. Setup configuration directory
mkdir -p "${CONFIG_DEST}"
if [ ! -f "${CONFIG_DEST}/apps.json" ]; then
    echo "{}" > "${CONFIG_DEST}/apps.json"
    echo "[✓] Initialized ${CONFIG_DEST}/apps.json"
fi

# 4. Check Niri config markers
if [ -f "${NIRI_CONFIG}" ]; then
    if ! grep -q "BEGIN BRAVE PWA RULES" "${NIRI_CONFIG}"; then
        echo "" >> "${NIRI_CONFIG}"
        echo "// >>> BEGIN BRAVE PWA RULES >>>" >> "${NIRI_CONFIG}"
        echo "// <<< END BRAVE PWA RULES <<<" >> "${NIRI_CONFIG}"
        echo "[✓] Injected PWA rule delimiters into ${NIRI_CONFIG}"
    fi

    # Check for general Brave max-width rule
    if ! grep -q 'match app-id=r#"\^(brave-browser|Brave-browser|brave)\$#' "${NIRI_CONFIG}"; then
        echo "" >> "${NIRI_CONFIG}"
        echo "// Brave browser main and private windows - max width" >> "${NIRI_CONFIG}"
        echo 'window-rule {' >> "${NIRI_CONFIG}"
        echo '    match app-id=r#"^(brave-browser|Brave-browser|brave)$"#' >> "${NIRI_CONFIG}"
        echo '    default-column-width { proportion 1.0; }' >> "${NIRI_CONFIG}"
        echo '    open-maximized true' >> "${NIRI_CONFIG}"
        echo '}' >> "${NIRI_CONFIG}"
        echo "[✓] Injected Brave max-width window rule into ${NIRI_CONFIG}"
    fi

    if command -v niri &>/dev/null; then
        niri msg action load-config-file 2>/dev/null || true
    fi
fi

# 5. Check PATH
if [[ ":$PATH:" != *":${BIN_DEST}:"* ]]; then
    echo "[!] Note: ${BIN_DEST} is not in your current PATH."
    echo "    Add this to your shell config (~/.bashrc or ~/.zshrc):"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# 6. Run initial sync
"${BIN_DEST}/brave-pwa" sync

echo ""
echo "========================================================================"
echo "  Installation Complete!"
echo "========================================================================"
echo "  Create a new PWA in seconds:"
echo "    brave-pwa add <name> <url> <container> [width]"
echo ""
echo "  Examples:"
echo "    brave-pwa add chatgpt https://chatgpt.com LLM 100%"
echo "    brave-pwa add gmail https://mail.google.com Google 100%"
echo "    brave-pwa add threads https://threads.net Social 33%"
echo ""
echo "  List configured apps:"
echo "    brave-pwa list"
echo "========================================================================"
