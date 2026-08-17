#!/usr/bin/env bash
#
# DeepSeek Harness (dsh) installer for macOS / Linux
#
# Installs @deepseek-ai/dsh globally, optionally installs plugins,
# and creates a .desktop entry (Linux) or .command script (macOS).
#
# Usage:
#   ./install.sh                                  # default: dshmarket + dsh-web-plugin-manager + dsh-better-sidebar + dsh-usage-stats + @deepseek-ai/dsh-persona
#   PLUGINS="a b" ./install.sh                    # custom plugin list (space-separated)
#   PLUGINS="" ./install.sh                       # skip plugins
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plugin list (override with PLUGINS env var; empty string disables)
DEFAULT_PLUGINS="dshmarket dsh-web-plugin-manager dsh-better-sidebar dsh-usage-stats @deepseek-ai/dsh-persona"
PLUGINS="${PLUGINS-${DEFAULT_PLUGINS}}"

echo ""
echo "========================================"
echo "  DeepSeek Harness Installer (macOS/Linux)"
echo "========================================"
echo ""

# === Step 1: Check Node.js ===
echo "[1/6] Checking Node.js..."
if command -v node &>/dev/null; then
    NODE_VER=$(node --version)
    echo "  Node.js $NODE_VER found."
else
    echo "  ERROR: Node.js is not installed."
    echo "  Please install Node.js from https://nodejs.org/ and try again."
    exit 1
fi

# === Step 2: Install dsh ===
echo "[2/6] Installing @deepseek-ai/dsh globally..."
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
    # Scope the check to the persona entry's own `text:` line - other rows
    # (e.g. the banner row) may carry the same sentence.
    PERSONA_TEXT="$(awk '/^- id: persona[[:space:]]*$/{inp=1} inp && /^[[:space:]]*text:/{print; exit}' "$PRESET_FILE" | sed 's/^[[:space:]]*//')"
    if [ "$PERSONA_TEXT" = "text: $MINIMAL_LINE" ]; then
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
    # Ensure the visible banner row exists so the line also shows in the Web UI.
    if grep -qF "name: 'dsh-minimal-banner'" "$PRESET_FILE"; then
        echo "  OK: minimal preset already has the visible banner row."
    else
        TMP_FILE="$(mktemp)"
        if awk -v b1="- id: minimal-banner" \
                -v b2="  name: 'dsh-minimal-banner'" \
                -v b3="  config:" \
                -v b4="    text: $MINIMAL_LINE" '
            BEGIN { inp = 0; done = 0 }
            /^- id: persona[[:space:]]*$/ { inp = 1 }
            inp && !done && /^- id:/ && $0 !~ /^- id: persona[[:space:]]*$/ {
                print ""; print b1; print b2; print b3; print b4; done = 1
            }
            { print }
            END {
                if (inp && !done) { print ""; print b1; print b2; print b3; print b4; done = 1 }
                exit (inp && done) ? 0 : 3
            }
        ' "$PRESET_FILE" > "$TMP_FILE"; then
            if cp "$TMP_FILE" "$PRESET_FILE" 2>/dev/null \
               || { command -v sudo >/dev/null 2>&1 && sudo cp "$TMP_FILE" "$PRESET_FILE"; }; then
                echo "  Patched: visible banner row added to the minimal preset."
            else
                echo "  WARNING: no permission to patch the minimal preset; banner row missing."
            fi
        else
            echo "  WARNING: persona entry not found; banner row not added."
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
    # Always append the bundled local banner plugin (shows the minimal-mode
    # persona line as a visible context message) unless already listed.
    BANNER_PLUGIN="$SCRIPT_DIR/../plugins/dsh-minimal-banner"
    case " $PLUGINS " in
        *"minimal-banner"*) : ;;
        *) [ -f "$BANNER_PLUGIN/package.json" ] && PLUGINS="$PLUGINS $BANNER_PLUGIN" ;;
    esac
    # The banner plugin is linked into the profile via `link:`; a linked
    # package must carry its own node_modules (imports resolve from the link
    # target, not from the profile), so materialize its dependency once.
    case " $PLUGINS " in
        *"minimal-banner"*)
            if [ ! -d "$BANNER_PLUGIN/node_modules/@deepseek-ai/schemastery" ]; then
                echo "  Preparing dsh-minimal-banner dependencies..."
                if ! (cd "$BANNER_PLUGIN" && npm install --no-audit --no-fund); then
                    echo "  WARNING: dependency setup for dsh-minimal-banner failed; the banner may not load."
                fi
            fi
            ;;
    esac
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
        PROFILE_WEB="$HOME/.dsh/profiles/web"
        for p in $PLUGINS; do
            if dsh plugin --profile web add "$p"; then
                echo "  Installed: $p"
            elif [ -f "$PROFILE_WEB/package.json" ] \
                 && ! grep -q "node-pty" "$PROFILE_WEB/pnpm-workspace.yaml" 2>/dev/null; then
                # pnpm >= 11 hard-fails installs while dependency build scripts
                # are blocked; node-pty (the web terminal's native module) needs
                # an explicit allow-list. Approve it and retry the add once.
                echo "  Approving node-pty build (pnpm 11 blocks postinstall scripts by default)..."
                (cd "$PROFILE_WEB" && pnpm approve-builds node-pty && pnpm install) || true
                if dsh plugin --profile web add "$p"; then
                    echo "  Installed: $p (after node-pty build approval)"
                else
                    echo "  WARNING: failed to install $p (retry later with: dsh plugin --profile web add $p)"
                    FAILED="$FAILED $p"
                fi
            else
                echo "  WARNING: failed to install $p (retry later with: dsh plugin --profile web add $p)"
                FAILED="$FAILED $p"
            fi
        done
        [ -n "$FAILED" ] || echo "  Plugins installed. They load on next 'dsh web' start."
    fi

    # Badge the community market (dshmarket) as non-official in the Web UI.
    # Its labels are hardcoded in the shipped client bundle, so we patch the
    # strings in place (served straight from disk, hot-reloaded within ~1s;
    # a pnpm update of dshmarket overwrites this, so re-run to re-apply).
    MARKET_CLIENT="$HOME/.dsh/profiles/web/node_modules/dshmarket/client/client.js"
    if [ -f "$MARKET_CLIENT" ]; then
        if grep -q "插件市场（非官方）" "$MARKET_CLIENT" \
           || grep -q "Plugin Market (community)" "$MARKET_CLIENT"; then
            echo "  OK: community market already badged as non-official."
        else
            sed -i.bak \
                -e 's/nav: "插件市场"/nav: "插件市场（非官方）"/' \
                -e 's/subtitle: "发现社区为 DeepSeek Harness 打造的能力"/subtitle: "发现社区为 DeepSeek Harness 打造的能力（非官方目录，数据源可直连，一般无需代理）"/' \
                -e 's/设置 -> 插件市场 -> 主题/设置 -> 插件市场（非官方） -> 主题/' \
                -e 's/nav: "Plugin Market"/nav: "Plugin Market (community)"/' \
                -e 's/subtitle: "Discover community plugins for DeepSeek Harness"/subtitle: "Discover community plugins for DeepSeek Harness (community catalog; usually works without a proxy)"/' \
                -e 's|Settings -> Plugin Market -> Themes|Settings -> Plugin Market (community) -> Themes|' \
                "$MARKET_CLIENT" \
                && rm -f "$MARKET_CLIENT.bak" \
                && echo "  Patched: community market badged as non-official in the Web UI." \
                || echo "  WARNING: failed to badge the community market."
        fi
    fi
fi

# === Step 5: Determine platform and paths ===
echo "[5/6] Setting up launcher..."

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
