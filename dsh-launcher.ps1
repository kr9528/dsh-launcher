# dsh-launcher.ps1
# Silent launcher for DeepSeek Harness (DSH)
# Checks if DSH web is running, starts it if needed, then opens the PWA

$ErrorActionPreference = "SilentlyContinue"

# Configuration
$DSH_URL        = "http://127.0.0.1:3080"
$PORT           = 3080
# DSH workspace: dsh web uses the current directory as workspace (skills/settings live here)
$DSH_WORKSPACE  = "D:\mi\Desktop\test\deepseek harness"
# Log file for debugging
$LOG_FILE       = Join-Path $PSScriptRoot "launcher.log"

# Find Chrome executable (for fallback)
$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

# Find DeepSeek Harness PWA shortcut
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$pwaShortcut   = Get-ChildItem -Path $chromeAppData -Filter "DeepSeek Harness.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $pwaShortcut) {
    # Fallback: search desktop shortcuts
    $pwaShortcut = Get-ChildItem -Path "$env:USERPROFILE\Desktop","$env:PUBDESKTOP" -Filter "DeepSeek Harness.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Write-Log {
    param([string]$Msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Msg
    Add-Content -Path $LOG_FILE -Value $line -ErrorAction SilentlyContinue
}

Write-Log "=== Launcher started ==="
Write-Log "Workspace: $DSH_WORKSPACE"
Write-Log "PWA: $(if ($pwaShortcut) { $pwaShortcut.FullName } else { 'NOT FOUND' })"
Write-Log "Chrome: $(if ($chromePath) { $chromePath } else { 'NOT FOUND' })"

# Make sure workspace exists
if (-not (Test-Path $DSH_WORKSPACE)) {
    Write-Log "WARN: Workspace not found, falling back to script dir"
    $DSH_WORKSPACE = $PSScriptRoot
}

# 1. Check if DSH is already running
# Wait for HTTP server to be ready, not just port listening
$serverReady = $false
$maxWait = 30
$waited = 0

while ($waited -lt $maxWait) {
    # Check if we can get an HTTP response (server is truly ready)
    try {
        $response = Invoke-WebRequest -Uri $DSH_URL -TimeoutSec 2 -ErrorAction Stop
        $serverReady = $true
        break
    } catch {
        # Server not ready yet, keep waiting
    }
    
    Start-Sleep -Seconds 1
    $waited++
}

if ($serverReady) {
    Write-Host "[OK] DSH is running on port $PORT"
    Write-Log "DSH ready (HTTP response OK)"
    
    # Extra delay to ensure server is fully initialized
    Start-Sleep -Seconds 2
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
    $waited2 = 0
    $started = $false

    while ($waited2 -lt $maxWait) {
        Start-Sleep -Seconds 1
        $waited2++
        
        # Check HTTP response
        try {
            $response = Invoke-WebRequest -Uri $DSH_URL -TimeoutSec 2 -ErrorAction Stop
            $started = $true
            break
        } catch {
            # Not ready yet
        }
    }

    if ($started) {
        Write-Host "[OK] DSH started successfully!"
        Write-Log "DSH started after ${waited2}s"
        
        # Extra delay to ensure server is fully initialized
        Start-Sleep -Seconds 2
    } else {
        Write-Host "[WARN] DSH did not start within $maxWait seconds"
        Write-Log "WARN: DSH did not start within $maxWait seconds"
    }
}

# 2. Open DeepSeek Harness PWA (only one window)
if ($pwaShortcut) {
    Write-Log "Opening DeepSeek Harness PWA..."
    Start-Process -FilePath $pwaShortcut.FullName
} else {
    Write-Log "WARN: PWA shortcut not found!"
    Write-Log "Please create a PWA shortcut for DeepSeek Harness"
}

Write-Log "=== Launcher finished ==="
