@echo off
echo starting lecture picker...
powershell -ExecutionPolicy Bypass -NoExit -File "%~dp0choose_and_process_lecture.ps1"
pause