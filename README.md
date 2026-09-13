# DSH Launcher

One-click silent launcher for **DeepSeek Harness (DSH)** on Windows.

Double-click a desktop shortcut → DSH web server starts (if needed) → DeepSeek Harness app opens — no terminal, no window, no fuss.

## Requirements

- **Windows 10/11**
- **Node.js** (for `dsh` CLI)
- **Chrome** with DeepSeek Harness PWA installed
- **dsh** CLI installed (`npm install -g @deepseek-ai/dsh`)

## Quick Start

```bash
git clone https://github.com/<your-name>/dsh-launcher.git
cd dsh-launcher
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

That's it. A "DeepSeek Harness" shortcut appears on your desktop.

## Files

| File | Purpose |
|------|---------|
| `dsh-launcher.ps1` | Main script — checks port, starts DSH, opens PWA |
| `dsh-launcher.vbs` | Silent wrapper — runs the .ps1 with no window |
| `install.ps1` | Creates the desktop shortcut with the PWA icon |

## How It Works

```
Desktop Shortcut
    → wscript.exe dsh-launcher.vbs
        → powershell -WindowStyle Hidden dsh-launcher.ps1
            → Check port 3080
                ├─ Running? → Skip
                └─ Not running? → Start `dsh web` (hidden)
            → Find DeepSeek Harness PWA shortcut
                ├─ Found? → Launch PWA
                └─ Not found? → Open browser to 127.0.0.1:3080
```

## Uninstall

```powershell
Remove-Item "$env:USERPROFILE\Desktop\DeepSeek Harness.lnk"
```

Then delete this folder.

## License

MIT
