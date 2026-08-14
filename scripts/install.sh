#!/usr/bin/env bash
#
# DeepSeek Harness (dsh) installer for macOS / Linux
#
# Installs @deepseek-ai/dsh globally, creates a .desktop entry
# (Linux) or .command script (macOS) with a custom icon.
#

set -e

echo ""
echo "========================================"
echo "  DeepSeek Harness Installer (macOS/Linux)"
echo "========================================"
echo ""

# === Step 1: Check Node.js ===
echo "[1/4] Checking Node.js..."
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    echo "  Node.js $NODE_VER found."
else
    echo "  ERROR: Node.js is not installed."
    echo "  Please install Node.js from https://nodejs.org/ and try again."
    exit 1
fi

# === Step 2: Install dsh ===
echo "[2/4] Installing @deepseek-ai/dsh globally..."
if npm install -g @deepseek-ai/dsh; then
    echo "  dsh installed successfully."
else
    echo "  Trying with sudo..."
    sudo npm install -g @deepseek-ai/dsh
    echo "  dsh installed successfully."
fi

# === Step 3: Determine platform and paths ===
echo "[3/4] Setting up launcher..."

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
        DESKTOP_FILE="$DESKTOP_DIR/dsh-installer.desktop"
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

# === Step 4: Done ===
echo "[4/4] Done!"
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
