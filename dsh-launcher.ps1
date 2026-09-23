# dsh-launcher.ps1
# Silent launcher for DeepSeek Harness (DSH)
# Flow: start dsh web -> wait HTTP ready -> open PWA (one window)

$ErrorActionPreference = "SilentlyContinue"

# Configuration
$DSH_URL        = "http://127.0.0.1:3080"
$PORT           = 3080
# DSH workspace: dsh web uses the current directory as workspace
$DSH_WORKSPACE  = "D:\mi\Desktop\test\deepseek harness"
# Log file for debugging
$LOG_FILE       = Join-Path $PSScriptRoot "launcher.log"

# Find DeepSeek Harness PWA shortcut
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$pwaShortcut   = Get-ChildItem -Path $chromeAppData -Filter "DeepSeek Harness.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

function Write-Log {
    param([string]$Msg)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Msg
    Add-Content -Path $LOG_FILE -Value $line -ErrorAction SilentlyContinue
}

Write-Log "=== Launcher started ==="
Write-Log "PWA: $(if ($pwaShortcut) { $pwaShortcut.FullName } else { 'NOT FOUND' })"

# Make sure workspace exists
if (-not (Test-Path $DSH_WORKSPACE)) {
    Write-Log "WARN: Workspace not found, falling back to script dir"
    $DSH_WORKSPACE = $PSScriptRoot
}

# ============================================
# Step 1: Start dsh web (only if not running)
# ============================================
$portCheck = netstat -ano | Select-String ":$PORT\s+.*LISTENING"

if ($portCheck) {
    Write-Host "[OK] dsh web is already running on port $PORT"
    Write-Log "dsh web already running on port $PORT"
} else {
    Write-Host "[WAIT] Starting dsh web..."
    Write-Log "Starting dsh web (minimized, in taskbar)..."
    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c", "dsh web" `
        -WorkingDirectory $DSH_WORKSPACE `
        -WindowStyle Minimized
}

# ============================================
# Step 2: Wait for HTTP response (max 30s)
# ============================================
Write-Host "[WAIT] Waiting for HTTP response..."
Write-Log "Waiting for HTTP response (max 30s)..."

$started = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        Invoke-WebRequest -Uri $DSH_URL -TimeoutSec 2 -ErrorAction Stop
        $started = $true
        Write-Log "HTTP response OK after ${i}s"
        break
    } catch {
        # Not ready yet
    }
}

if ($started) {
    Write-Host "[OK] DSH HTTP ready!"
} else {
    Write-Host "[WARN] DSH did not respond within 30 seconds"
    Write-Log "WARN: DSH did not respond within 30 seconds"
}

# ============================================
# Step 3: Extra 2s wait (ensure fully initialized)
# ============================================
Write-Log "Extra 2s wait for full initialization..."
Start-Sleep -Seconds 2

# ============================================
# Step 4: Open DeepSeek Harness PWA (one window only)
# ============================================
if ($pwaShortcut) {
    Write-Log "Opening DeepSeek Harness PWA..."
    Start-Process -FilePath $pwaShortcut.FullName
} else {
    Write-Log "WARN: PWA shortcut not found!"
    Write-Host "[WARN] PWA shortcut not found, opening browser..."
    Start-Process "explorer.exe" -ArgumentList $DSH_URL
}

Write-Log "=== Launcher finished ==="
