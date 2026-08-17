<#
.SYNOPSIS
    DeepSeek Harness (dsh) installer for Windows.
.DESCRIPTION
    Installs @deepseek-ai/dsh globally, optionally installs plugins,
    gets the official icon, and creates a one-click desktop shortcut.
.PARAMETER DesktopPath
    Custom desktop path. Defaults to the system desktop folder.
.PARAMETER Plugins
    Space-separated list of dsh plugin packages to install.
    Defaults to 'dshmarket' (the unofficial community market with the
    awesome-dsh-plugin catalog inside the Web UI; the installer badges its
    UI title as non-official), 'dsh-web-plugin-manager', 'dsh-better-sidebar',
    'dsh-usage-stats' and '@deepseek-ai/dsh-persona' (the persona engine that
    injects the minimal/standard presets' system prompt; the web profile does
    not bundle it by default).
.PARAMETER NoPlugins
    Skip plugin installation entirely.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1 -Plugins "dshmarket","dsh-better-sidebar"
#>

param(
    [string]$DesktopPath = "",
    [string[]]$Plugins = @("dshmarket", "dsh-web-plugin-manager", "dsh-better-sidebar", "dsh-usage-stats", "@deepseek-ai/dsh-persona"),
    [switch]$NoPlugins
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DeepSeek Harness Installer for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === Step 1: Check Node.js ===
Write-Host "[1/7] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVer = node --version 2>$null
    Write-Host "  Node.js $nodeVer found." -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org/ and try again." -ForegroundColor Red
    exit 1
}

# === Step 2: Install dsh ===
Write-Host "[2/7] Installing @deepseek-ai/dsh globally..." -ForegroundColor Yellow
# EAP=Continue around native calls: npm prints deprecation warnings to stderr,
# which PowerShell 5.1 would otherwise turn into a terminating NativeCommandError.
$ErrorActionPreference = "Continue"
npm install -g @deepseek-ai/dsh 2>&1 | Out-Host
$ErrorActionPreference = "Stop"
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to install @deepseek-ai/dsh." -ForegroundColor Red
    exit 1
}
Write-Host "  dsh installed successfully." -ForegroundColor Green

# === Step 3: Verify minimal-mode system prompt ===
# The 'minimal' agent preset's complete persona is the single line
# "You are a helpful software engineer assistant." - the community-dubbed
# "strongest form" prompt. Verify it survives dsh updates; rewrite if missing.
Write-Host "[3/7] Verifying minimal-mode system prompt..." -ForegroundColor Yellow
$MinimalLine = "You are a helpful software engineer assistant."
try {
    $npmRoot = (npm root -g | Out-String).Trim()
    $presetFile = Join-Path $npmRoot "@deepseek-ai\dsh\config\agent-presets\minimal\agent.cordis.yml"
    if (Test-Path $presetFile) {
        # Scope the check to the persona entry's own `text:` line - other rows
        # (e.g. the banner row) may carry the same sentence.
        $lines = Get-Content $presetFile
        $inPersona = $false
        $personaTextIdx = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*-\s*id:\s*(\S+)\s*$') { $inPersona = ($Matches[1] -eq 'persona'); continue }
            if ($inPersona -and $lines[$i] -match '^\s*text:\s*') { $personaTextIdx = $i; break }
        }
        if ($personaTextIdx -ge 0 -and $lines[$personaTextIdx] -match [regex]::Escape($MinimalLine)) {
            Write-Host "  OK: minimal mode persona already starts with the line." -ForegroundColor Green
        } elseif ($personaTextIdx -ge 0) {
            $lines[$personaTextIdx] = $lines[$personaTextIdx] -replace '(^\s*text:\s*).*$', ('$1' + $MinimalLine)
            # UTF-8 without BOM, so YAML loaders never see a BOM
            [System.IO.File]::WriteAllLines($presetFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
            Write-Host "  Patched: persona text reset to '$MinimalLine'" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: could not locate the persona 'text:' entry; skipping." -ForegroundColor Yellow
        }
        # Ensure the visible banner row (dsh-minimal-banner) exists in the preset,
        # so the persona line also shows up as a context message in the Web UI.
        if (-not (Select-String -Path $presetFile -Pattern ([regex]::Escape("name: 'dsh-minimal-banner'")) -Quiet)) {
            $lines = [System.Collections.Generic.List[string]](Get-Content $presetFile)
            $personaIdx = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^- id: persona\s*$') { $personaIdx = $i; break }
            }
            if ($personaIdx -ge 0) {
                $insertAt = $lines.Count
                for ($i = $personaIdx + 1; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match '^- id:\s') { $insertAt = $i; break }
                }
                $banner = @('', '- id: minimal-banner', '  name: ''dsh-minimal-banner''', '  config:', "    text: $MinimalLine")
                $lines.InsertRange($insertAt, [string[]]$banner)
                [System.IO.File]::WriteAllLines($presetFile, $lines, (New-Object System.Text.UTF8Encoding($false)))
                Write-Host "  Patched: visible banner row added to the minimal preset." -ForegroundColor Green
            } else {
                Write-Host "  WARNING: persona entry not found; banner row not added." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  OK: minimal preset already has the visible banner row." -ForegroundColor Green
        }
    } else {
        Write-Host "  WARNING: minimal preset not found (dsh layout may have changed): $presetFile" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: could not verify minimal preset: $_" -ForegroundColor Yellow
}

# === Step 4: Install plugins ===
if ($NoPlugins) {
    Write-Host "[4/7] Skipping plugins (-NoPlugins)." -ForegroundColor Yellow
} else {
    # Always append the bundled local banner plugin (shows the minimal-mode
    # persona line as a visible context message) unless the user listed it.
    $bannerPluginPath = Join-Path $PSScriptRoot "..\plugins\dsh-minimal-banner"
    if (-not ($Plugins -match 'minimal-banner') -and (Test-Path (Join-Path $bannerPluginPath 'package.json'))) {
        $Plugins = @($Plugins) + @($bannerPluginPath)
    }
    # The banner plugin is linked into the profile via `link:`; a linked
    # package must carry its own node_modules (imports resolve from the link
    # target, not from the profile), so materialize its dependency once.
    if (($Plugins -match 'minimal-banner') -and -not (Test-Path (Join-Path $bannerPluginPath "node_modules\@deepseek-ai\schemastery"))) {
        Write-Host "  Preparing dsh-minimal-banner dependencies..." -ForegroundColor Yellow
        $ErrorActionPreference = "Continue"
        npm install --prefix $bannerPluginPath --no-audit --no-fund 2>&1 | Out-Host
        $ErrorActionPreference = "Stop"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  WARNING: dependency setup for dsh-minimal-banner failed; the banner may not load." -ForegroundColor Yellow
        }
    }
    Write-Host "[4/7] Installing plugins: $($Plugins -join ', ')" -ForegroundColor Yellow

    # dsh plugin requires pnpm
    $pnpmOk = $false
    try { pnpm --version 2>$null | Out-Null; $pnpmOk = $true } catch {}
    if (-not $pnpmOk) {
        Write-Host "  Installing pnpm (required by 'dsh plugin')..." -ForegroundColor Yellow
        $ErrorActionPreference = "Continue"
        npm install -g pnpm 2>&1 | Out-Host
        $ErrorActionPreference = "Stop"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ERROR: Failed to install pnpm. Plugin installation aborted." -ForegroundColor Red
            Write-Host "  Core installation continues; you can install plugins later with:" -ForegroundColor Yellow
            Write-Host "    dsh plugin --profile web add <package>" -ForegroundColor Yellow
        }
    }

    if ($pnpmOk -or $LASTEXITCODE -eq 0) {
        $failed = @()
        $profileWebDir = Join-Path $env:USERPROFILE ".dsh\profiles\web"
        $ErrorActionPreference = "Continue"
        foreach ($p in $Plugins) {
            dsh plugin --profile web add $p 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0 -and (Test-Path (Join-Path $profileWebDir "package.json"))) {
                # pnpm >= 11 hard-fails installs while dependency build scripts
                # are blocked. The dsh web profile bundles node-pty (the web
                # terminal's native module); allow-list it and retry the add.
                # Equivalent to: pnpm approve-builds node-pty && pnpm install
                $ws = Join-Path $profileWebDir "pnpm-workspace.yaml"
                if (-not (Test-Path $ws) -or -not (Select-String -Path $ws -Pattern "node-pty" -Quiet)) {
                    Write-Host "  Approving node-pty build (pnpm 11 blocks postinstall scripts by default)..." -ForegroundColor Yellow
                    Push-Location $profileWebDir
                    pnpm approve-builds node-pty 2>&1 | Out-Host
                    pnpm install 2>&1 | Out-Host
                    Pop-Location
                    dsh plugin --profile web add $p 2>&1 | Out-Host
                }
            }
            if ($LASTEXITCODE -ne 0) { $failed += $p }
        }
        $ErrorActionPreference = "Stop"
        if ($failed.Count -gt 0) {
            Write-Host "  WARNING: failed to install: $($failed -join ', ')" -ForegroundColor Yellow
            Write-Host "  You can retry later with: dsh plugin --profile web add <package>" -ForegroundColor Yellow
        } else {
            Write-Host "  Plugins installed. They load on next 'dsh web' start." -ForegroundColor Green
        }
    }

    # Badge the community market (dshmarket) as non-official in the Web UI.
    # Its labels are hardcoded in the shipped client bundle, so we patch the
    # strings in place (served straight from disk, hot-reloaded within ~1s;
    # a pnpm update of dshmarket overwrites this, so re-run to re-apply).
    $marketClient = Join-Path $env:USERPROFILE ".dsh\profiles\web\node_modules\dshmarket\client\client.js"
    if (Test-Path $marketClient) {
        $ErrorActionPreference = "Continue"
        $txt = [System.IO.File]::ReadAllText($marketClient)
        if ($txt.Contains("插件市场（非官方）") -or $txt.Contains("Plugin Market (community)")) {
            Write-Host "  OK: community market already badged as non-official." -ForegroundColor Green
        } else {
            $txt = $txt.Replace('nav: "插件市场"', 'nav: "插件市场（非官方）"')
            $txt = $txt.Replace('subtitle: "发现社区为 DeepSeek Harness 打造的能力"', 'subtitle: "发现社区为 DeepSeek Harness 打造的能力（非官方目录，数据源可直连，一般无需代理）"')
            $txt = $txt.Replace('设置 -> 插件市场 -> 主题', '设置 -> 插件市场（非官方） -> 主题')
            $txt = $txt.Replace('nav: "Plugin Market"', 'nav: "Plugin Market (community)"')
            $txt = $txt.Replace('subtitle: "Discover community plugins for DeepSeek Harness"', 'subtitle: "Discover community plugins for DeepSeek Harness (community catalog; usually works without a proxy)"')
            $txt = $txt.Replace('Settings -> Plugin Market -> Themes', 'Settings -> Plugin Market (community) -> Themes')
            [System.IO.File]::WriteAllText($marketClient, $txt, (New-Object System.Text.UTF8Encoding($false)))
            Write-Host "  Patched: community market badged as non-official in the Web UI." -ForegroundColor Green
        }
        $ErrorActionPreference = "Stop"
    }
}

# === Step 5: Determine desktop path ===
Write-Host "[5/7] Locating desktop..." -ForegroundColor Yellow
if ([string]::IsNullOrEmpty($DesktopPath)) {
    $DesktopPath = [Environment]::GetFolderPath("Desktop")
}
if (-not (Test-Path $DesktopPath)) {
    Write-Host "  ERROR: Desktop path not found: $DesktopPath" -ForegroundColor Red
    Write-Host "  You can specify a custom path with -DesktopPath" -ForegroundColor Red
    exit 1
}
Write-Host "  Desktop: $DesktopPath" -ForegroundColor Green

# === Step 5: Get official DeepSeek icon ===
Write-Host "[6/7] Getting official DeepSeek icon..." -ForegroundColor Yellow
$icoPath = Join-Path $DesktopPath "dsh-official.ico"

$downloaded = $false
foreach ($u in @("https://www.deepseek.com/favicon.ico", "https://chat.deepseek.com/favicon.ico")) {
    try {
        Invoke-WebRequest -Uri $u -OutFile $icoPath -UseBasicParsing -TimeoutSec 20
        if ((Get-Item $icoPath).Length -gt 1000) { $downloaded = $true; break }
    } catch { continue }
}

if ($downloaded) {
    Write-Host "  Official DeepSeek logo downloaded." -ForegroundColor Green
} else {
    Write-Host "  Download failed, generating fallback icon..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.Drawing

$size = 256
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
$g.Clear([System.Drawing.Color]::Transparent)

# Background: rounded rectangle with gradient
$radius = 56
$rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$bgPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$bgPath.AddArc($rect.X, $rect.Y, $radius, $radius, 180, 90)
$bgPath.AddArc($rect.Right - $radius, $rect.Y, $radius, $radius, 270, 90)
$bgPath.AddArc($rect.Right - $radius, $rect.Bottom - $radius, $radius, $radius, 0, 90)
$bgPath.AddArc($rect.X, $rect.Bottom - $radius, $radius, $radius, 90, 90)
$bgPath.CloseFigure()

$gradBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 25, 50, 120),
    [System.Drawing.Color]::FromArgb(255, 79, 120, 255),
    [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
)
$g.FillPath($gradBrush, $bgPath)

# Whale silhouette
$darkBlue = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 25, 50, 120))
$whalePath = New-Object System.Drawing.Drawing2D.GraphicsPath
$pts = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF(56, 128)),
    (New-Object System.Drawing.PointF(56, 105)),
    (New-Object System.Drawing.PointF(60, 92)),
    (New-Object System.Drawing.PointF(76, 88)),
    (New-Object System.Drawing.PointF(95, 84)),
    (New-Object System.Drawing.PointF(130, 86)),
    (New-Object System.Drawing.PointF(160, 88)),
    (New-Object System.Drawing.PointF(180, 90)),
    (New-Object System.Drawing.PointF(190, 93)),
    (New-Object System.Drawing.PointF(200, 98)),
    (New-Object System.Drawing.PointF(215, 88)),
    (New-Object System.Drawing.PointF(235, 72)),
    (New-Object System.Drawing.PointF(244, 68)),
    (New-Object System.Drawing.PointF(240, 82)),
    (New-Object System.Drawing.PointF(232, 105)),
    (New-Object System.Drawing.PointF(226, 125)),
    (New-Object System.Drawing.PointF(232, 145)),
    (New-Object System.Drawing.PointF(240, 158)),
    (New-Object System.Drawing.PointF(244, 168)),
    (New-Object System.Drawing.PointF(235, 172)),
    (New-Object System.Drawing.PointF(215, 162)),
    (New-Object System.Drawing.PointF(200, 156)),
    (New-Object System.Drawing.PointF(180, 160)),
    (New-Object System.Drawing.PointF(130, 172)),
    (New-Object System.Drawing.PointF(100, 170)),
    (New-Object System.Drawing.PointF(85, 168)),
    (New-Object System.Drawing.PointF(60, 158)),
    (New-Object System.Drawing.PointF(56, 128))
)
$whalePath.AddBeziers($pts)
$g.FillPath([System.Drawing.Brushes]::White, $whalePath)

# Eye
$g.FillEllipse($darkBlue, 82, 106, 14, 14)
$g.FillEllipse([System.Drawing.Brushes]::White, 85, 108, 5, 5)

# Water spout
$spoutPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$spoutPath.AddBezier(
    (New-Object System.Drawing.PointF(92, 88)),
    (New-Object System.Drawing.PointF(86, 62)),
    (New-Object System.Drawing.PointF(104, 48)),
    (New-Object System.Drawing.PointF(98, 30))
)
$spoutPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 6)
$spoutPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$spoutPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$g.DrawPath($spoutPen, $spoutPath)
$g.FillEllipse([System.Drawing.Brushes]::White, 91, 20, 14, 14)

# Save as ICO (PNG-compressed)
$ms = New-Object System.IO.MemoryStream
$bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
$pngData = $ms.ToArray()
$ms.Close()

$icoStream = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($icoStream)
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)
$bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([byte]0)
$bw.Write([uint16]1); $bw.Write([uint16]32)
$bw.Write([uint32]$pngData.Length); $bw.Write([uint32]22)
$bw.Write($pngData); $bw.Flush()

$icoPath = Join-Path $DesktopPath "dsh-icon.ico"
[System.IO.File]::WriteAllBytes($icoPath, $icoStream.ToArray())
$icoStream.Close()

# Cleanup drawing objects
$darkBlue.Dispose()
$gradBrush.Dispose()
$spoutPen.Dispose()
$g.Dispose()
$bmp.Dispose()
Write-Host "  Fallback icon saved: $icoPath" -ForegroundColor Green
}
Write-Host "  Icon: $icoPath" -ForegroundColor Green

# === Step 7: Create launcher and shortcut ===
Write-Host "[7/7] Creating desktop shortcut..." -ForegroundColor Yellow

# Create PowerShell launcher (robust: no 'timeout' cmd dependency, error dialog on failure)
$ps1Path = Join-Path $DesktopPath "dsh-start.ps1"
$ps1Content = @'
# DeepSeek Harness launcher
$ErrorActionPreference = "SilentlyContinue"
$url = "http://127.0.0.1:3080"

function Test-Dsh {
    try {
        $c = New-Object Net.Sockets.TcpClient
        $c.Connect("127.0.0.1", 3080)
        $c.Close()
        return $true
    } catch { return $false }
}

if (Test-Dsh) {
    Start-Process $url
    exit
}

# Locate npm global dsh.cmd
$dsh = Join-Path $env:APPDATA "npm\dsh.cmd"
if (-not (Test-Path $dsh)) { $dsh = "dsh" }

Start-Process -FilePath $dsh -ArgumentList "web" -WindowStyle Minimized

$ok = $false
for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Seconds 2
    if (Test-Dsh) { $ok = $true; break }
}

if ($ok) {
    Start-Process $url
} else {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "DeepSeek Harness failed to start within 40 seconds.`n`nPlease run 'dsh web' in a terminal to see the error.",
        "DeepSeek Harness", "OK", "Error") | Out-Null
}
'@
[System.IO.File]::WriteAllText($ps1Path, $ps1Content)

# Create .lnk shortcut
$lnkPath = Join-Path $DesktopPath "DeepSeek Harness.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($lnkPath)
$Shortcut.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps1Path`""
$Shortcut.IconLocation = "$icoPath, 0"
$Shortcut.WindowStyle = 7
$Shortcut.WorkingDirectory = $DesktopPath
$Shortcut.Description = "Start DeepSeek Harness and open web UI"
$Shortcut.Save()

Write-Host "  Shortcut created: $lnkPath" -ForegroundColor Green

# === Done ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Double-click 'DeepSeek Harness' on your" -ForegroundColor White
Write-Host "  desktop to start the service and open" -ForegroundColor White
Write-Host "  the Web UI at http://127.0.0.1:3080" -ForegroundColor White
Write-Host ""
Write-Host "  First time? Configure your model:" -ForegroundColor Yellow
Write-Host "    Settings -> Models -> Enter API Key" -ForegroundColor White
Write-Host ""
Write-Host "  Manage plugins from the Web UI (dshmarket)" -ForegroundColor Yellow
Write-Host "  or via: dsh plugin --profile web add <package>" -ForegroundColor White
Write-Host ""
