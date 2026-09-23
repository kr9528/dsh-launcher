# dsh-launcher.ps1
# Silent launcher for DeepSeek Harness (DSH)
# Checks if DSH web is running, starts it if needed, then opens the PWA

$ErrorActionPreference = "SilentlyContinue"

# Configuration
$DSH_URL        = "http://127.0.0.1:3080"
$PORT           = 3080
# DSH workspace: dsh web uses the current directory as workspace (skills/settings live here)
$DSH_WORKSPACE  = "D:\mi\Desktop\test\deepseek harness"
# Log file for debugging (everything runs hidden, so log what we do)
$LOG_FILE       = Join-Path $PSScriptRoot "launcher.log"

function Write-Log {
    param([string]$Msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Msg
    Add-Content -Path $LOG_FILE -Value $line -ErrorAction SilentlyContinue
}

Write-Log "=== Launcher started ==="
Write-Log "Workspace: $DSH_WORKSPACE"

# Make sure workspace exists
if (-not (Test-Path $DSH_WORKSPACE)) {
    Write-Log "WARN: Workspace not found, falling back to script dir"
    $DSH_WORKSPACE = $PSScriptRoot
}

# Try to find dsh web app shortcut (PWA)
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$pwaShortcut   = Get-ChildItem -Path $chromeAppData -Filter "DeepSeek Harness.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $pwaShortcut) {
    # Fallback: search desktop shortcuts
    $pwaShortcut = Get-ChildItem -Path "$env:USERPROFILE\Desktop","$env:PUBDESKTOP" -Filter "DeepSeek Harness.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
}
Write-Log "PWA shortcut: $(if ($pwaShortcut) { $pwaShortcut.FullName } else { 'NOT FOUND' })"

# 1. Check if DSH is already running
$portCheck = netstat -ano | Select-String ":$PORT\s+.*LISTENING"

if ($portCheck) {
    Write-Host "[OK] DSH is running on port $PORT"
    Write-Log "DSH already running on port $PORT"
} else {
    Write-Host "[WAIT] Starting DSH web..."
    Write-Log "Starting DSH web via cmd /c in workspace..."

    # Start DSH web server, in the correct workspace directory.
    # dsh is an npm .cmd shim, so run it through cmd.exe.
    # Window starts minimized but visible in taskbar
    Write-Log "Starting DSH web (minimized, in taskbar)..."
    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "dsh web" `
        -WorkingDirectory $DSH_WORKSPACE `
        -WindowStyle Minimized

    # Wait for server to become ready
    $maxWait = 20
    $waited  = 0
    $started = $false

    while ($waited -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited++
        $check = netstat -ano | Select-String ":$PORT\s+.*LISTENING"
        if ($check) {
            $started = $true
            break
        }
    }

    if ($started) {
        Write-Host "[OK] DSH started successfully!"
        Write-Log "DSH started after ${waited}s"
    } else {
        Write-Host "[WARN] DSH did not start within $maxWait seconds"
        Write-Log "WARN: DSH did not start within $maxWait seconds"
    }
}

# 2. Open browser first for authentication, then open PWA
# Browser handles the auth flow, PWA needs auth to be complete first
Write-Log "Opening browser for authentication..."
Start-Process "explorer.exe" -ArgumentList $DSH_URL

# Wait for auth to complete, then open PWA
Start-Sleep -Seconds 3
Write-Log "Opening DeepSeek Harness PWA..."
if ($pwaShortcut) {
    Start-Process -FilePath $pwaShortcut.FullName
    Write-Log "Launched PWA: $($pwaShortcut.FullName)"
} else {
    Write-Log "PWA shortcut not found, browser already open"
}

Write-Log "=== Launcher finished ==="
