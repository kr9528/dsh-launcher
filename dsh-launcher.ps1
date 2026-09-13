# dsh-launcher.ps1
# Silent launcher for DeepSeek Harness (DSH)
# Checks if DSH web is running, starts it if needed, then opens the PWA

$ErrorActionPreference = "SilentlyContinue"

# Configuration
$DSH_URL      = "http://127.0.0.1:3080"
$PORT         = 3080
$DSH_HOME     = $env:DSH_HOME

# Try to find dsh web app shortcut (PWA)
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$pwaShortcut   = Get-ChildItem -Path $chromeAppData -Filter "DeepSeek Harness.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $pwaShortcut) {
    # Fallback: search desktop shortcuts
    $pwaShortcut = Get-ChildItem -Path "$env:USERPROFILE\Desktop","$env:PUBDESKTOP" -Filter "DeepSeek Harness.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
}

# 1. Check if DSH is already running
$portCheck = netstat -ano | Select-String ":$PORT\s+.*LISTENING"

if ($portCheck) {
    Write-Host "[OK] DSH is running on port $PORT"
} else {
    Write-Host "[WAIT] Starting DSH web..."

    # Start DSH web server (background)
    Start-Process -FilePath "dsh" -ArgumentList "web" -WindowStyle Hidden

    # Wait for server to become ready
    $maxWait = 15
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
    } else {
        Write-Host "[WARN] DSH did not start within $maxWait seconds"
    }
}

# 2. Launch the PWA app (or fall back to browser)
if ($pwaShortcut) {
    Start-Process -FilePath $pwaShortcut.FullName
} else {
    Start-Process "explorer.exe" -ArgumentList $DSH_URL
}
