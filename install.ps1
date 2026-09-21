# install.ps1
# Installs the DeepSeek Harness launcher to your desktop
# Run with: powershell -ExecutionPolicy Bypass -File .\install.ps1

param(
    [string]$ShortcutName = "DeepSeek Harness",
    [string]$IconSource   = "DeepSeek Harness.ico"
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps1Path   = Join-Path $scriptDir "dsh-launcher.ps1"

if (-not (Test-Path $ps1Path)) {
    Write-Host "[ERROR] dsh-launcher.ps1 not found at: $ps1Path" -ForegroundColor Red
    exit 1
}

# Create launcher .bat on desktop (no .lnk association issues)
$desktopPath  = [Environment]::GetFolderPath("Desktop")
$batPath      = Join-Path $desktopPath "$ShortcutName.bat"

$batContent = @"
@echo off
cd /d "$scriptDir"
start /min powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$ps1Path"
exit
"@

[System.IO.File]::WriteAllText($batPath, $batContent, [System.Text.Encoding]::ASCII)

# Also create a .lnk shortcut if possible (for icon customization)
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$iconPath      = Get-ChildItem -Path $chromeAppData -Filter $IconSource -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

$shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"
try {
    $sh  = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($shortcutPath)
    $lnk.TargetPath       = $batPath
    $lnk.WorkingDirectory = $scriptDir
    if ($iconPath) {
        $lnk.IconLocation = "$($iconPath.FullName),0"
    }
    $lnk.Description      = "One-click DeepSeek Harness Launcher"
    $lnk.Save()
    Write-Host "[OK] Shortcut created: $shortcutPath" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not create .lnk shortcut, using .bat file directly" -ForegroundColor Yellow
}

Write-Host "[OK] Launcher created: $batPath" -ForegroundColor Green
Write-Host ""
Write-Host "Double-click '$ShortcutName' on your desktop to launch!" -ForegroundColor Cyan
