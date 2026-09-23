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

# Find Chrome executable
$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
    "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

function Write-Log {
    param([string]$Msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Msg
    Add-Content -Path $LOG_FILE -Value $line -ErrorAction SilentlyContinue
}

Write-Log "=== Launcher started ==="
Write-Log "Workspace: $DSH_WORKSPACE"
Write-Log "Chrome: $(if ($chromePath) { $chromePath } else { 'NOT FOUND' })"

# Make sure workspace exists
if (-not (Test-Path $DSH_WORKSPACE)) {
    Write-Log "WARN: Workspace not found, falling back to script dir"
    $DSH_WORKSPACE = $PSScriptRoot
}

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

# 2. Open DeepSeek Harness in Chrome app mode (minimized)
# --app= looks like an app but is a real browser (handles auth properly)
# --start-minimized opens it minimized in the taskbar
if ($chromePath) {
    Write-Log "Opening DeepSeek Harness in Chrome app mode (minimized)..."
    Start-Process -FilePath $chromePath `
        -ArgumentList "--app=$DSH_URL", "--start-minimized" `
        -WindowStyle Minimized
} else {
    Write-Log "Chrome not found, opening browser fallback..."
    Start-Process "explorer.exe" -ArgumentList $DSH_URL
}

Write-Log "=== Launcher finished ==="
