' dsh-launcher.vbs
' Runs dsh-launcher.ps1 silently (no window)
' Place this file in the same directory as dsh-launcher.ps1

Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

' Get script directory (where this .vbs file is)
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path   = scriptDir & "\dsh-launcher.ps1"

sh.Run "powershell -NoProfile -ExecutionPolicy Bypass -File """ & ps1Path & """", 0, False
