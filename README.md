# DSH Launcher

**DeepSeek Harness (DSH)** 的一键静默启动器，适用于 Windows。

One-click silent launcher for **DeepSeek Harness (DSH)** on Windows.

双击桌面快捷方式 → DSH Web 服务器自动启动（如未运行）→ DeepSeek Harness 应用打开。无终端窗口，无命令行，开箱即用。
Double-click a desktop shortcut → DSH web server starts (if needed) → DeepSeek Harness app opens — no terminal, no window, no fuss.

---

## 环境要求 / Requirements

- **Windows 10/11**
- **Node.js**（用于 `dsh` CLI / for `dsh` CLI）
- **Chrome**（已安装 DeepSeek Harness PWA / with DeepSeek Harness PWA installed）
- **dsh CLI**（`npm install -g @deepseek-ai/dsh`）

## 快速开始 / Quick Start

```bash
git clone https://github.com/kr9528/dsh-launcher.git
cd dsh-launcher
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

桌面会出现 "DeepSeek Harness" 快捷方式，双击即可。
A "DeepSeek Harness" shortcut appears on your desktop — double-click to launch.

## 文件说明 / Files

| 文件 / File | 用途 / Purpose |
|------|---------|
| `dsh-launcher.ps1` | 主脚本 — 检测端口、启动 DSH、打开 PWA / Main script — checks port, starts DSH, opens PWA |
| `dsh-launcher.vbs` | 静默包装器 — 无窗口运行 .ps1 / Silent wrapper — runs the .ps1 with no window |
| `install.ps1` | 安装脚本 — 在桌面创建快捷方式 / Creates the desktop shortcut with the PWA icon |

## 工作原理 / How It Works

```
桌面快捷方式 / Desktop Shortcut
    → wscript.exe dsh-launcher.vbs
        → powershell -WindowStyle Hidden dsh-launcher.ps1
            → 检测端口 3080 / Check port 3080
                ├─ 已运行？→ 跳过 / Running? → Skip
                └─ 未运行？→ 启动 `dsh web`（隐藏窗口）/ Not running? → Start `dsh web` (hidden)
            → 查找 DeepSeek Harness PWA 快捷方式 / Find DeepSeek Harness PWA shortcut
                ├─ 找到？→ 启动 PWA / Found? → Launch PWA
                └─ 未找到？→ 用浏览器打开 127.0.0.1:3080 / Not found? → Open browser to 127.0.0.1:3080
```

## 卸载 / Uninstall

```powershell
Remove-Item "$env:USERPROFILE\Desktop\DeepSeek Harness.lnk"
```

然后删除此文件夹即可。
Then delete this folder.

## 许可 / License

MIT
