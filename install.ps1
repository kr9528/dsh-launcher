# install.ps1
# Installs the DeepSeek Harness launcher shortcut to your desktop
# Run with: powershell -ExecutionPolicy Bypass -File .\install.ps1

param(
    [string]$ShortcutName = "DeepSeek Harness",
    [string]$IconSource   = "DeepSeek Harness.ico"
)

$ErrorActionPreference = "Stop"

# Resolve paths
$scriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$vbsPath     = Join-Path $scriptDir "dsh-launcher.vbs"

if (-not (Test-Path $vbsPath)) {
    Write-Host "[ERROR] dsh-launcher.vbs not found at: $vbsPath" -ForegroundColor Red
    exit 1
}

# Find the DeepSeek Harness PWA icon
$chromeAppData = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Web Applications"
$iconPath      = Get-ChildItem -Path $chromeAppData -Filter $IconSource -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($iconPath) {
    $iconFull = $iconPath.FullName
} else {
    Write-Host "[WARN] PWA icon not found, using default icon" -ForegroundColor Yellow
    $iconFull = "C:\Windows\System32\shell32.dll,0"
}

# Create desktop shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "$ShortcutName.lnk"

$sh  = New-Object -ComObject WScript.Shell
$lnk = $sh.CreateShortcut($shortcutPath)
$lnk.TargetPath       = "C:\Windows\System32\wscript.exe"
$lnk.Arguments        = """$vbsPath"""
$lnk.WorkingDirectory = $scriptDir
$lnk.IconLocation     = "$iconFull,0"
$lnk.Description      = "One-click DeepSeek Harness Launcher"
$lnk.Save()

Write-Host "[OK] Shortcut created: $shortcutPath" -ForegroundColor Green
Write-Host ""
Write-Host "Double-click '$ShortcutName' on your desktop to launch!" -ForegroundColor Cyan
