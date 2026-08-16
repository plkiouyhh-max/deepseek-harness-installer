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
    Defaults to 'dsh-web-plugin-manager' (adds a plugin marketplace to the Web UI).
.PARAMETER NoPlugins
    Skip plugin installation entirely.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install.ps1 -Plugins "dsh-web-plugin-manager","dsh-better-sidebar"
#>

param(
    [string]$DesktopPath = "",
    [string[]]$Plugins = @("dsh-web-plugin-manager"),
    [switch]$NoPlugins
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  DeepSeek Harness Installer for Windows" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# === Step 1: Check Node.js ===
Write-Host "[1/6] Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVer = node --version 2>$null
    Write-Host "  Node.js $nodeVer found." -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "  Please install Node.js from https://nodejs.org/ and try again." -ForegroundColor Red
    exit 1
}

# === Step 2: Install dsh ===
Write-Host "[2/6] Installing @deepseek-ai/dsh globally..." -ForegroundColor Yellow
npm install -g @deepseek-ai/dsh 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
    Write-Host "  ERROR: Failed to install @deepseek-ai/dsh." -ForegroundColor Red
    exit 1
}
Write-Host "  dsh installed successfully." -ForegroundColor Green

# === Step 3: Install plugins ===
if ($NoPlugins) {
    Write-Host "[3/6] Skipping plugins (-NoPlugins)." -ForegroundColor Yellow
} else {
    Write-Host "[3/6] Installing plugins: $($Plugins -join ', ')" -ForegroundColor Yellow

    # dsh plugin requires pnpm
    $pnpmOk = $false
    try { pnpm --version 2>$null | Out-Null; $pnpmOk = $true } catch {}
    if (-not $pnpmOk) {
        Write-Host "  Installing pnpm (required by 'dsh plugin')..." -ForegroundColor Yellow
        npm install -g pnpm 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ERROR: Failed to install pnpm. Plugin installation aborted." -ForegroundColor Red
            Write-Host "  Core installation continues; you can install plugins later with:" -ForegroundColor Yellow
            Write-Host "    dsh plugin --profile web add <package>" -ForegroundColor Yellow
        }
    }

    if ($pnpmOk -or $LASTEXITCODE -eq 0) {
        $failed = @()
        foreach ($p in $Plugins) {
            dsh plugin --profile web add $p 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0) { $failed += $p }
        }
        if ($failed.Count -gt 0) {
            Write-Host "  WARNING: failed to install: $($failed -join ', ')" -ForegroundColor Yellow
            Write-Host "  You can retry later with: dsh plugin --profile web add <package>" -ForegroundColor Yellow
        } else {
            Write-Host "  Plugins installed. They load on next 'dsh web' start." -ForegroundColor Green
        }
    }
}

# === Step 4: Determine desktop path ===
Write-Host "[4/6] Locating desktop..." -ForegroundColor Yellow
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
Write-Host "[5/6] Getting official DeepSeek icon..." -ForegroundColor Yellow
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

# === Step 6: Create launcher and shortcut ===
Write-Host "[6/6] Creating desktop shortcut..." -ForegroundColor Yellow

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
Write-Host "  Manage plugins from the Web UI (dsh-web-plugin-manager)" -ForegroundColor Yellow
Write-Host "  or via: dsh plugin --profile web add <package>" -ForegroundColor White
Write-Host ""
