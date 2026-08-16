---
name: "dsh-deepseek-harness-installer"
description: "Installs DeepSeek Harness (dsh) and creates a one-click desktop shortcut with a custom whale icon. Invoke when user wants to install, set up, or create a shortcut for DeepSeek Harness."
---

# DeepSeek Harness Installer

Automates the installation of [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) and creates a one-click desktop shortcut with the official DeepSeek logo.

## What This Skill Does

1. Installs the `@deepseek-ai/dsh` npm package globally
2. Uses the official DeepSeek logo as the icon (falls back to a generated icon offline)
3. Creates a desktop shortcut that starts `dsh web` and opens the browser automatically

## Prerequisites

- **Node.js** v18+ must be installed. Check with `node --version`.
  - Download from https://nodejs.org/ if missing.
- **OS**: Windows, macOS, or Linux

## Execution Steps

### Step 1: Determine the Operating System

Detect the OS to choose the correct script:
- **Windows**: Use `scripts/install.ps1`
- **macOS / Linux**: Use `scripts/install.sh`

### Step 2: Run the Install Script

#### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

The script will:
1. Verify Node.js is installed
2. Run `npm install -g @deepseek-ai/dsh`
3. Download the official DeepSeek logo as the `.ico` icon (falls back to a System.Drawing generated icon if offline)
4. Create a robust PowerShell launcher (`dsh-start.ps1`) that starts `dsh web` (if not running), waits for port 3080, and opens the browser — with an error dialog if startup fails
5. Create a `.lnk` desktop shortcut with the custom icon
6. Clean up temporary files

#### macOS / Linux (Bash)

```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

The script will:
1. Verify Node.js is installed
2. Run `sudo npm install -g @deepseek-ai/dsh`
3. Create a `.desktop` entry with the SVG icon
4. Add the launcher to the desktop

### Step 3: Verify

- Check that the `dsh` command is available: `dsh --version` or `dsh --help`
- On Windows: verify the shortcut appears on the desktop
- On macOS/Linux: verify the `.desktop` file is created

### Step 4: Guide the User

After installation, inform the user:

1. **Double-click the desktop shortcut** to start DeepSeek Harness
2. The shortcut will automatically start `dsh web` and open the browser at `http://127.0.0.1:3080`
3. On first launch, configure the model:
   - Go to **Settings -> Models**
   - Enter a DeepSeek API Key
   - Save
4. Select a workspace directory
5. Start a session and send tasks

## Notes

- DeepSeek Harness is in **developer preview** (0.1.0-rc.x). Breaking changes may occur.
- The `dsh web` process must be running for the Web UI to be accessible. The shortcut handles this automatically.
- If port 3080 is already in use, the shortcut will detect the running service and just open the browser.
- The icon is the official DeepSeek logo (downloaded at install time); if the download fails, a fallback icon is generated programmatically.

## Troubleshooting

- **`dsh` not found after install**: Restart terminal or run `npm config get prefix` to find the global bin path and add it to PATH.
- **Port 3080 in use**: Close any existing `dsh web` process or specify a different port.
- **Port 3080 `EACCES` on Windows** (`listen EACCES: permission denied 127.0.0.1:3080`, typically after reboot on WSL2/Hyper-V/Docker machines): WinNAT reserved the port range. Verify with `netsh interface ipv4 show excludedportrange protocol=tcp`; if 3080 is inside a range, fix in an elevated shell: `net stop winnat; netsh int ipv4 add excludedportrange protocol=tcp startport=3080 numberofports=1; net start winnat`. One-time fix, survives reboots.
- **Icon not showing**: On Windows, refresh the desktop (F5) or clear icon cache.
