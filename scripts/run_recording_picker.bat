@echo off
echo starting recording picker...
powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0choose_and_process_recording.ps1"
pause