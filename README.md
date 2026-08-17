# DeepSeek Harness Installer

English | [中文](README.zh.md)

One-click installer for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) — an open-source agent harness developed by DeepSeek AI.

This tool automatically:
- Installs the `@deepseek-ai/dsh` npm package globally
- Installs plugins (defaults to `dshmarket` - the [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) catalog of 341 community plugins inside the Web UI - plus `dsh-better-sidebar` and `dsh-usage-stats`)
- Verifies the minimal-mode system prompt contains `You are a helpful software engineer assistant.` and rewrites it if missing (see ["Minimal mode & the 'strongest form' prompt"](#minimal-mode--the-strongest-form-prompt))
- Uses the official DeepSeek logo as the desktop icon (offline fallback: generated icon)
- Creates a one-click desktop shortcut that starts the service and opens the browser

## Preview

The shortcut uses the official DeepSeek logo:

![deepseek-official-icon](assets/deepseek-official.png)

## Prerequisites

- **Node.js** v18+ — Download from https://nodejs.org/

## Quick Start

### Windows

```powershell
git clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer.git
cd dsh-deepseek-harness-installer
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

<details>
<summary><b>Need a custom desktop path? (Click to expand)</b></summary>

Most users **don't need this** — the script auto-detects your desktop. But if your desktop has been moved to another drive (e.g., `D:\` or `E:\`), you can specify it manually.

**How to find your desktop path:**

**Method 1** — File Explorer:
1. Open File Explorer
2. Right-click **Desktop** in the left sidebar → **Properties**
3. Check the **Location** field

**Method 2** — PowerShell:
```powershell
[Environment]::GetFolderPath("Desktop")
```
This prints your desktop path, e.g., `C:\Users\YourName\Desktop` or `D:\Desktop`.

Then install with the `-DesktopPath` parameter:
```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -DesktopPath "D:\Desktop"
```

</details>

### macOS / Linux

```bash
git clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer.git
cd dsh-deepseek-harness-installer
chmod +x scripts/install.sh
./scripts/install.sh
```

## What Happens During Installation

| Step | Windows | macOS / Linux |
|------|---------|---------------|
| 1. Check Node.js | `node --version` | `node --version` |
| 2. Install dsh | `npm install -g @deepseek-ai/dsh` | `sudo npm install -g @deepseek-ai/dsh` |
| 3. Verify minimal-mode prompt | Check/rewrite the minimal preset's persona line | Same |
| 4. Install plugins | Installs pnpm if missing, then `dsh plugin --profile web add <pkg>` | Same |
| 5. Generate icon | Official DeepSeek logo (.ico, with offline fallback) | Copy SVG icon |
| 6. Create shortcut | PowerShell launcher + `.lnk` shortcut | `.command` (macOS) / `.desktop` (Linux) |

## Bundled Plugins

By default the installer adds three plugins:

| Plugin | Description |
|--------|-------------|
| `dshmarket` | The official companion market for [awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin): browse, search, check stars and one-click install/update/uninstall all 341 community plugins from inside the Web UI - most take effect without a restart |
| `dsh-better-sidebar` | VSCode-like sidebar (explorer / terminal / git / browser) |
| `dsh-usage-stats` | GitHub-style usage heatmap: per-workspace counts, token spend (with cache hit rate) and DeepSeek balance lookup |

> The previous default marketplace `dsh-web-plugin-manager` (manages installed plugins only) can still be installed manually: `dsh plugin --profile web add dsh-web-plugin-manager`

**Customize which plugins get installed:**

```powershell
# Windows - a custom set
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -Plugins "dshmarket","dsh-better-sidebar"

# Windows - core only, no plugins
powershell -ExecutionPolicy Bypass -File scripts/install.ps1 -NoPlugins
```

```bash
# macOS / Linux - a custom set
PLUGINS="dshmarket dsh-better-sidebar" ./scripts/install.sh

# macOS / Linux — core only, no plugins
PLUGINS="" ./scripts/install.sh
```

**Install more plugins anytime:**

```bash
dsh plugin --profile web add <package>
```

Popular community plugins (search [npm](https://www.npmjs.com/search?q=dsh) or browse the [awesome list](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) for more):

| Plugin | Description |
|--------|-------------|
| `dshmarket` | The awesome plugin catalog inside the Web UI (341 entries) |
| `dsh-better-sidebar` | VSCode-like sidebar (explorer / terminal / git / browser) |
| `dsh-pocket` | Access your DSH from a phone (LAN + public network) |
| `@linxin666/dsh-pet` | Floating desktop pet that reacts to model activity |

> Note: plugin installation requires `pnpm`; the installer installs it automatically if missing. Plugins load the next time `dsh web` starts.

## Minimal mode & the "strongest form" prompt

DSH ships a built-in "minimal mode" (the `minimal` agent preset): a coding agent with only a persistent bash shell and `str_replace_editor`, whose **entire system prompt is a single line**:

```text
You are a helpful software engineer assistant.
```

The installer verifies on every run that this line is still present (and rewrites it if an upstream dsh update drops it), so **every time you open minimal mode, this is the first line sent to the model**.

**The community-dubbed "strongest form"**: community posts (Reddit r/DeepSeek, X, Korean forums, etc.) speculate that DeepSeek 4 Pro may be overfitted to DSH-minimal-mode-like environments, and that `minimal mode + Thinking Max` performs best on continuous coding tasks. If you cannot use DSH minimal mode (e.g. a plain chat client), pasting this line at the very top of your custom prompt is said to approximate it.

> ⚠️ **Disclaimer**: the above is community hearsay based on small-sample tests, **not an official DeepSeek statement**. Actual results vary by model version, task type and the rest of your prompt - please test it yourself before adopting. This installer only guarantees the prompt line exists and **makes no claim about its effectiveness**.

## Using the Shortcut

1. **Double-click** the "DeepSeek Harness" shortcut on your desktop
2. The shortcut will:
   - Check if `dsh web` is already running (port 3080)
   - Start the service if not running
   - Wait for it to be ready (polls every 2 seconds)
   - Open your browser at `http://127.0.0.1:3080`
3. On first launch, configure your model:
   - Go to **Settings -> Models**
   - Enter your DeepSeek API Key
   - Save
4. Choose a session preset (standard / code / minimal mode - see ["Minimal mode & the 'strongest form' prompt"](#minimal-mode--the-strongest-form-prompt))
5. Select a workspace directory
6. Start a session and send tasks!

## Project Structure

```
dsh-deepseek-harness-installer/
├── README.md              # English documentation
├── README.zh.md           # Chinese documentation
├── SKILL.md               # AI agent skill definition
├── LICENSE                # MIT license
├── assets/
│   ├── deepseek-official.png  # Official DeepSeek logo (used on Windows)
│   └── dsh-icon.svg           # Icon source (SVG, macOS/Linux)
└── scripts/
    ├── install.ps1        # Windows installer
    └── install.sh         # macOS / Linux installer
```

## Compatible AI Agents

This project includes a `SKILL.md` file with structured instructions that any AI coding agent can read and execute. Here's how to use it with popular agents:

### TRAE

Copy `SKILL.md` to `.trae/skills/`:

```bash
mkdir -p .trae/skills/dsh-deepseek-harness-installer
cp SKILL.md .trae/skills/dsh-deepseek-harness-installer/
```

Then ask: *"Install DeepSeek Harness and create a desktop shortcut."*

### Claude Code

```bash
claude "Read SKILL.md from https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer and execute the installation"
```

Or save `SKILL.md` as `CLAUDE.md` in your project root and ask Claude Code to execute it.

### Cursor

Add the `SKILL.md` content to `.cursorrules` in your project:

```bash
curl -o .cursorrules https://raw.githubusercontent.com/plkiouyhh-max/dsh-deepseek-harness-installer/main/SKILL.md
```

Then open Cursor chat and ask: *"Follow the instructions to install DeepSeek Harness."*

### Windsurf (Codeium)

Save `SKILL.md` as `.windsurfrules` in your workspace, then ask Cascade: *"Execute the DeepSeek Harness installation steps."*

### GitHub Copilot Chat

In VS Code with Copilot Chat, type:

```
@workspace Read SKILL.md and follow the steps to install DeepSeek Harness
```

### Cline

Create a new task in Cline with the prompt:

```
Read and execute the instructions from https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer/blob/main/SKILL.md
```

### Continue.dev

Add the `SKILL.md` content to `.continuerc` or paste it into a new chat session, then ask Continue to execute.

### Aider

```bash
aider --message "Read SKILL.md and run the DeepSeek Harness installation"
```

### OpenHands

Create a new task with:

```
Clone https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer and run the installation script for my OS.
```

### Any Other Agent

The `SKILL.md` contains universal, step-by-step instructions. Simply point your agent to [this repository](https://github.com/plkiouyhh-max/dsh-deepseek-harness-installer) and ask it to follow the installation guide.

## Manual Installation (No Script)

If you prefer to do it manually:

```bash
# 1. Install dsh
npm install -g @deepseek-ai/dsh

# 2. Start the Web UI
dsh web

# 3. Open browser to http://127.0.0.1:3080
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `dsh` command not found | Restart terminal, or add npm global bin to PATH |
| Port 3080 already in use | Close existing `dsh web` process |
| Port 3080 permission denied (`EACCES`) | See [below](#port-3080-blocked-by-windows-eacces-permission-denied) |
| Icon not showing (Windows) | Press F5 to refresh desktop |
| npm permission error (Linux/macOS) | Use `sudo npm install -g @deepseek-ai/dsh` |

### Port 3080 blocked by Windows (EACCES: permission denied)

**Symptom**: `dsh web` fails with `listen EACCES: permission denied 127.0.0.1:3080`, and the desktop shortcut shows a "failed to start" dialog. This is a Windows quirk, not an installer bug — it typically appears **after a reboot** on machines using WSL2 / Hyper-V / Docker.

**Cause**: The Windows WinNAT service dynamically reserves random port ranges at every boot. If port 3080 happens to fall into a reserved range, no application is allowed to listen on it.

**Check** — run in PowerShell:

```powershell
netsh interface ipv4 show excludedportrange protocol=tcp
```

If 3080 falls inside any listed range, apply the fix below.

**Fix** — permanently reserve port 3080 for dsh (one-time, survives reboots). Open **PowerShell or CMD as Administrator** and run:

```powershell
net stop winnat
netsh int ipv4 add excludedportrange protocol=tcp startport=3080 numberofports=1
net start winnat
```

After this, `dsh web` and the desktop shortcut will work normally again — permanently, even across reboots.

## About DeepSeek Harness

DeepSeek Harness is an open-source agent harness developed by DeepSeek AI. It uses an "everything is a plugin" architecture powered by Cordis.

- **Repository**: https://github.com/deepseek-ai/deepseek-harness
- **License**: MIT
- **Status**: Developer Preview (0.1.0-rc.x)

## License

MIT — See [LICENSE](LICENSE)
