<#
.SYNOPSIS
    Test for the minimal-mode prompt verify/rewrite logic in install.ps1.

.DESCRIPTION
    Runs four scenarios against the real global dsh minimal preset file
    (@deepseek-ai\dsh\config\agent-presets\minimal\agent.cordis.yml):

      1. intact            -> installer reports "OK: minimal mode persona already starts with the line."
                              (and adds/keeps the visible banner row)
      2. tampered          -> installer reports "Patched: persona text reset to ..."
      3. text line gone    -> installer reports "WARNING: could not locate the persona 'text:' entry"
      4. banner row gone   -> installer reports "Patched: visible banner row added"

    Side-effect isolation:
      - npm is mocked via a PATH stub (npm.cmd): "npm install ..." succeeds
        instantly (so the tampered preset survives Step 2 of install.ps1),
        every other npm call (e.g. "npm root -g") is delegated to the real npm.
      - Desktop/icon/shortcut steps are redirected to a temp folder (-DesktopPath).
      - -NoPlugins skips plugin installation.

    The original preset file is backed up and restored in a finally block,
    even if a scenario throws.

.PARAMETER InstallPs1
    Path to the installer under test. Defaults to install.ps1 beside this script.

.PARAMETER LogPath
    Path of the result log. Defaults to test-minimal-restore.log beside this script.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\test-minimal-restore.ps1
#>

param(
    [string]$InstallPs1 = (Join-Path $PSScriptRoot 'install.ps1'),
    [string]$LogPath    = (Join-Path $PSScriptRoot 'test-minimal-restore.log')
)

$ErrorActionPreference = 'Stop'
$Line      = 'You are a helpful software engineer assistant.'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

if (-not (Test-Path $InstallPs1)) { throw "install.ps1 not found: $InstallPs1" }

function Write-Log([string]$msg = '') {
    Add-Content -Path $LogPath -Value $msg -Encoding utf8
    Write-Host $msg
}

# --- locate the real preset file and back it up --------------------------------
# Resolve npm.cmd (NOT npm.ps1): the batch mock below cannot `call` a .ps1 file.
$npmCmd = (Get-Command npm.cmd -ErrorAction SilentlyContinue).Source
if (-not $npmCmd) {
    $npmAny = (Get-Command npm -ErrorAction Stop).Source
    $npmCmd = Join-Path (Split-Path $npmAny -Parent) 'npm.cmd'
}
if (-not (Test-Path $npmCmd)) { throw "npm.cmd not found (looked at: $npmCmd)" }

$npmRoot = (& $npmCmd root -g | Out-String).Trim()
$preset  = Join-Path $npmRoot '@deepseek-ai\dsh\config\agent-presets\minimal\agent.cordis.yml'
if (-not (Test-Path $preset)) { throw "minimal preset not found: $preset" }
$original = [System.IO.File]::ReadAllText($preset, $Utf8NoBom)

# --- helpers --------------------------------------------------------------------
# Scoped check: only the `text:` line INSIDE the persona entry counts.
# (The banner row carries the same sentence, so a whole-file search would
#  produce false positives.)
function Test-HasLine {
    $inPersona = $false
    foreach ($l in (Get-Content $preset)) {
        if ($l -match '^\s*-\s*id:\s*(\S+)\s*$') { $inPersona = ($Matches[1] -eq 'persona'); continue }
        if ($inPersona -and $l -match '^\s*text:\s*') { return ($l -match [regex]::Escape($Line)) }
    }
    return $false
}

function Test-HasBannerRow {
    [bool](Select-String -Path $preset -Pattern ([regex]::Escape("name: 'dsh-minimal-banner'")) -Quiet)
}

function Remove-BannerRow {
    $lines = Get-Content $preset
    $out   = New-Object System.Collections.Generic.List[string]
    $skip  = $false
    foreach ($l in $lines) {
        if ($l -match '^- id: minimal-banner\s*$') {
            if ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
            $skip = $true
            continue
        }
        if ($skip) {
            if ($l -match '^- id:\s') { $skip = $false } else { continue }
        }
        $out.Add($l)
    }
    [System.IO.File]::WriteAllLines($preset, $out, $Utf8NoBom)
}

function Set-PersonaText([string]$value) {
    $lines = Get-Content $preset
    $inPersona = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*-\s*id:\s*(\S+)\s*$') { $inPersona = ($Matches[1] -eq 'persona'); continue }
        if ($inPersona -and $lines[$i] -match '^\s*text:\s*') {
            $lines[$i] = "    text: $value"
            [System.IO.File]::WriteAllLines($preset, $lines, $Utf8NoBom)
            return
        }
    }
    throw 'persona text entry not found while tampering'
}

function Remove-PersonaTextLine {
    $out = New-Object System.Collections.Generic.List[string]
    $inPersona = $false
    foreach ($l in (Get-Content $preset)) {
        if ($l -match '^\s*-\s*id:\s*(\S+)\s*$') { $inPersona = ($Matches[1] -eq 'persona') }
        if ($inPersona -and $l -match '^\s*text:\s*') { continue }
        $out.Add($l)
    }
    [System.IO.File]::WriteAllLines($preset, $out, $Utf8NoBom)
}

# --- mock npm + temp desktop -----------------------------------------------------
$work        = Join-Path ([IO.Path]::GetTempPath()) ("dsh-test-" + [guid]::NewGuid().ToString('N'))
$mockBin     = Join-Path $work 'mockbin'
$fakeDesktop = Join-Path $work 'desktop'
New-Item -ItemType Directory -Path $mockBin, $fakeDesktop -Force | Out-Null

$mockNpm = Join-Path $mockBin 'npm.cmd'
@"
@echo off
if /i "%~1"=="install" (
  echo   [test-mock] npm install skipped
  exit /b 0
)
call "$npmCmd" %*
exit /b %errorlevel%
"@ | Set-Content -Path $mockNpm -Encoding ascii

function Invoke-Installer {
    $savedPath = $env:Path
    $savedEap  = $ErrorActionPreference
    $env:Path = "$mockBin;$env:Path"
    $ErrorActionPreference = 'Continue'
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $InstallPs1 -NoPlugins -DesktopPath $fakeDesktop 2>&1 | Out-String
    }
    finally {
        $env:Path = $savedPath
        $ErrorActionPreference = $savedEap
    }
}

# --- run scenarios ----------------------------------------------------------------
Remove-Item $LogPath -ErrorAction SilentlyContinue
Write-Log "=== test-minimal-restore $(Get-Date -Format s) ==="
Write-Log "installer : $InstallPs1"
Write-Log "preset    : $preset"
Write-Log ""

$results = New-Object System.Collections.Generic.List[object]

try {
    # Scenario 1: intact preset (persona OK; banner row added or kept)
    [System.IO.File]::WriteAllText($preset, $original, $Utf8NoBom)
    $out = Invoke-Installer
    Write-Log "--- [1] intact: relevant installer output ---"
    Write-Log ((($out -split "`r?`n") | Where-Object { $_ -match 'minimal|persona|banner|WARNING|Patched' }) -join "`n")
    $results.Add([pscustomobject]@{
        Scenario = '1 intact'
        Expected = 'OK: persona line + visible banner row'
        Pass     = ($out -match 'OK: minimal mode persona already starts with the line') `
                   -and ($out -match 'visible banner row') -and (Test-HasLine) -and (Test-HasBannerRow)
    })

    # Scenario 2: tampered persona text
    Set-PersonaText 'WRONG PERSONA INSERTED BY TEST'
    $out = Invoke-Installer
    Write-Log ""
    Write-Log "--- [2] tampered: relevant installer output ---"
    Write-Log ((($out -split "`r?`n") | Where-Object { $_ -match 'minimal|persona|banner|WARNING|Patched' }) -join "`n")
    $results.Add([pscustomobject]@{
        Scenario = '2 tampered'
        Expected = 'Patched: persona text reset'
        Pass     = ($out -match 'Patched: persona text reset') -and (Test-HasLine)
    })

    # Scenario 3: persona text line removed entirely
    Remove-PersonaTextLine
    $out = Invoke-Installer
    Write-Log ""
    Write-Log "--- [3] text-line removed: relevant installer output ---"
    Write-Log ((($out -split "`r?`n") | Where-Object { $_ -match 'minimal|persona|banner|WARNING|Patched' }) -join "`n")
    $results.Add([pscustomobject]@{
        Scenario = '3 text-line removed'
        Expected = 'WARNING: could not locate the persona entry'
        Pass     = ($out -match 'WARNING: could not locate the persona')
    })

    # Scenario 4: visible banner row deleted -> installer re-adds it
    [System.IO.File]::WriteAllText($preset, $original, $Utf8NoBom)
    Invoke-Installer | Out-Null                      # ensure the banner row exists
    Remove-BannerRow
    $out = Invoke-Installer
    Write-Log ""
    Write-Log "--- [4] banner-row removed: relevant installer output ---"
    Write-Log ((($out -split "`r?`n") | Where-Object { $_ -match 'minimal|persona|banner|WARNING|Patched' }) -join "`n")
    $results.Add([pscustomobject]@{
        Scenario = '4 banner-row removed'
        Expected = 'Patched: visible banner row added'
        Pass     = ($out -match 'Patched: visible banner row added') -and (Test-HasBannerRow) -and (Test-HasLine)
    })
}
finally {
    # restore the pristine preset no matter what
    [System.IO.File]::WriteAllText($preset, $original, $Utf8NoBom)
    $script:restoredOk = ([System.IO.File]::ReadAllText($preset, $Utf8NoBom) -eq $original)
    Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

# --- summary -----------------------------------------------------------------------
Write-Log ""
Write-Log "--- summary ---"
$results | ForEach-Object { Write-Log ("{0,-22} {1,-45} {2}" -f $_.Scenario, $_.Expected, $(if ($_.Pass) { 'PASS' } else { 'FAIL' })) }
Write-Log ("preset restored to original : {0}" -f $restoredOk)
Write-Log "log: $LogPath"

$failCount = 0
foreach ($r in $results) { if (-not $r.Pass) { $failCount++ } }
$allPass = ($failCount -eq 0) -and $restoredOk
if ($allPass) {
    Write-Log 'RESULT: ALL PASS'
    exit 0
} else {
    Write-Log 'RESULT: FAILURES PRESENT'
    exit 1
}
