#!/usr/bin/env bash
#
# DeepSeek Harness (dsh) installer for macOS / Linux
#
# Installs @deepseek-ai/dsh globally, optionally installs plugins,
# and creates a .desktop entry (Linux) or .command script (macOS).
#
# Usage:
#   ./install.sh                                  # default: dshmarket + dsh-better-sidebar + dsh-usage-stats + @deepseek-ai/dsh-persona
#   PLUGINS="a b" ./install.sh                    # custom plugin list (space-separated)
#   PLUGINS="" ./install.sh                       # skip plugins
#

set -e

# Plugin list (override with PLUGINS env var; empty string disables)
DEFAULT_PLUGINS="dshmarket dsh-better-sidebar dsh-usage-stats @deepseek-ai/dsh-persona"
PLUGINS="${PLUGINS-${DEFAULT_PLUGINS}}"

echo ""
echo "========================================"
echo "  DeepSeek Harness Installer (macOS/Linux)"
echo "========================================"
echo ""

# === Step 1: Check Node.js ===
echo "[1/5] Checking Node.js..."
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    echo "  Node.js $NODE_VER found."
else
    echo "  ERROR: Node.js is not installed."
    echo "  Please install Node.js from https://nodejs.org/ and try again."
    exit 1
fi

# === Step 2: Install dsh ===
echo "[2/5] Installing @deepseek-ai/dsh globally..."
if npm install -g @deepseek-ai/dsh; then
    echo "  dsh installed successfully."
else
    echo "  Trying with sudo..."
    sudo npm install -g @deepseek-ai/dsh
    echo "  dsh installed successfully."
fi

# === Step 3: Verify minimal-mode system prompt ===
# The 'minimal' agent preset's complete persona is the single line
# "You are a helpful software engineer assistant." - the community-dubbed
# "strongest form" prompt. Verify it survives dsh updates; rewrite if missing.
echo "[3/6] Verifying minimal-mode system prompt..."
MINIMAL_LINE="You are a helpful software engineer assistant."
NPM_ROOT="$(npm root -g 2>/dev/null)"
PRESET_FILE="$NPM_ROOT/@deepseek-ai/dsh/config/agent-presets/minimal/agent.cordis.yml"
if [ -f "$PRESET_FILE" ]; then
    if grep -qF "text: $MINIMAL_LINE" "$PRESET_FILE"; then
        echo "  OK: minimal mode persona already starts with the line."
    else
        TMP_FILE="$(mktemp)"
        if awk -v newline="    text: $MINIMAL_LINE" '
            /^- id:/ { inpersona = ($0 ~ /^- id:[[:space:]]*persona[[:space:]]*$/) }
            inpersona && !done && /^[[:space:]]*text:/ { print newline; done = 1; next }
            { print }
            END { exit done ? 0 : 3 }
        ' "$PRESET_FILE" > "$TMP_FILE"; then
            if cp "$TMP_FILE" "$PRESET_FILE" 2>/dev/null \
               || { command -v sudo >/dev/null 2>&1 && sudo cp "$TMP_FILE" "$PRESET_FILE"; }; then
                echo "  Patched: persona text reset to '$MINIMAL_LINE'"
            else
                echo "  WARNING: no permission to patch the minimal preset; it may lack the line."
            fi
        else
            echo "  WARNING: could not locate the persona 'text:' entry; skipping."
        fi
        rm -f "$TMP_FILE"
    fi
else
    echo "  WARNING: minimal preset not found (dsh layout may have changed): $PRESET_FILE"
fi

# === Step 4: Install plugins ===
if [ -z "$PLUGINS" ]; then
    echo "[4/6] Skipping plugins (PLUGINS is empty)."
else
    echo "[4/6] Installing plugins: $PLUGINS"

    # Refresh command lookup so freshly installed binaries are found
    hash -r 2>/dev/null || true

    # dsh plugin requires pnpm
    PNPM_OK=true
    if ! command -v pnpm &>/dev/null; then
        echo "  Installing pnpm (required by 'dsh plugin')..."
        if ! (npm install -g pnpm 2>/dev/null || sudo npm install -g pnpm); then
            echo "  WARNING: failed to install pnpm; skipping plugins."
            echo "  Retry later with: npm install -g pnpm && dsh plugin --profile web add <package>"
            PNPM_OK=false
        fi
    fi

    if $PNPM_OK; then
        FAILED=""
        for p in $PLUGINS; do
            if dsh plugin --profile web add "$p"; then
                echo "  Installed: $p"
            else
                echo "  WARNING: failed to install $p (retry later with: dsh plugin --profile web add $p)"
                FAILED="$FAILED $p"
            fi
        done
        [ -n "$FAILED" ] || echo "  Plugins installed. They load on next 'dsh web' start."
    fi
fi

# === Step 5: Determine platform and paths ===
echo "[5/6] Setting up launcher..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="$SCRIPT_DIR/../assets/dsh-icon.svg"
PLATFORM=$(uname -s)

case "$PLATFORM" in
    Darwin*)
        # macOS
        DESKTOP_DIR="$HOME/Desktop"
        LAUNCHER="$DESKTOP_DIR/DeepSeek Harness.command"
        ICON_DEST="$HOME/.dsh-icon.svg"

        # Copy icon
        cp "$ICON_SRC" "$ICON_DEST" 2>/dev/null || true

        # Create launcher script
        cat > "$LAUNCHER" << 'EOF'
#!/usr/bin/env bash
# Check if dsh web is already running
if curl -s --connect-timeout 2 http://127.0.0.1:3080 >/dev/null 2>&1; then
    open "http://127.0.0.1:3080"
    exit 0
fi
# Start dsh web
dsh web &
DSH_PID=$!
# Wait for service to be ready
for i in $(seq 1 20); do
    sleep 2
    if curl -s --connect-timeout 2 http://127.0.0.1:3080 >/dev/null 2>&1; then
        open "http://127.0.0.1:3080"
        exit 0
    fi
done
echo "DeepSeek Harness failed to start within 40 seconds."
EOF
        chmod +x "$LAUNCHER"
        echo "  Launcher created: $LAUNCHER"
        ;;

    Linux*)
        # Linux
        DESKTOP_DIR="$HOME/.local/share/applications"
        DESKTOP_FILE="$DESKTOP_DIR/dsh-deepseek-harness-installer.desktop"
        ICON_DEST="$HOME/.local/share/dsh-icon.svg"
        mkdir -p "$DESKTOP_DIR"
        mkdir -p "$(dirname "$ICON_DEST")"

        # Copy icon
        cp "$ICON_SRC" "$ICON_DEST" 2>/dev/null || true

        # Create launcher script
        LAUNCHER="$HOME/.local/bin/dsh-launch.sh"
        mkdir -p "$(dirname "$LAUNCHER")"
        cat > "$LAUNCHER" << 'EOF'
#!/usr/bin/env bash
# Check if dsh web is already running
if curl -s --connect-timeout 2 http://127.0.0.1:3080 >/dev/null 2>&1; then
    xdg-open "http://127.0.0.1:3080" >/dev/null 2>&1 &
    exit 0
fi
# Start dsh web
dsh web &
DSH_PID=$!
# Wait for service to be ready
for i in $(seq 1 20); do
    sleep 2
    if curl -s --connect-timeout 2 http://127.0.0.1:3080 >/dev/null 2>&1; then
        xdg-open "http://127.0.0.1:3080" >/dev/null 2>&1 &
        exit 0
    fi
done
echo "DeepSeek Harness failed to start within 40 seconds."
EOF
        chmod +x "$LAUNCHER"

        # Create .desktop entry
        cat > "$DESKTOP_FILE" << DESKTOP
[Desktop Entry]
Type=Application
Name=DeepSeek Harness
Comment=Start DeepSeek Harness Web UI
Exec=$LAUNCHER
Icon=$ICON_DEST
Terminal=false
Categories=Development;
DESKTOP
        chmod +x "$DESKTOP_FILE"

        # Update desktop database
        update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
        echo "  Desktop entry created: $DESKTOP_FILE"
        ;;

    *)
        echo "  ERROR: Unsupported platform: $PLATFORM"
        exit 1
        ;;
esac

# === Step 6: Done ===
echo "[6/6] Done!"
echo ""
echo "========================================"
echo "  Installation Complete!"
echo "========================================"
echo ""
echo "  Launch DeepSeek Harness from your"
echo "  desktop / application menu."
echo ""
echo "  The Web UI will open at http://127.0.0.1:3080"
echo ""
echo "  First time? Configure your model:"
echo "    Settings -> Models -> Enter API Key"
echo ""
echo "  Manage plugins from the Web UI (dshmarket)"
echo "  or via: dsh plugin --profile web add <package>"
echo ""
