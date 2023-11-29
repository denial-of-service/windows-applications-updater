@echo off

set scriptFileName=%~n0
set scriptFolderPath=%~dp0
set powershellScriptFileName=%scriptFileName%.ps1

:: Run powershell script as administrator
powershell -Command "Start-Process powershell \"-ExecutionPolicy Bypass -NoProfile -WindowStyle Maximized -Command `\"cd \`\"%scriptFolderPath%`\"; & \`\".\%powershellScriptFileName%\`\"`\"\" -Verb RunAs"
