@echo off
call "%~dp0godot.cmd" --headless --editor --path "%~dp0.." --quit
if errorlevel 1 exit /b %ERRORLEVEL%

call "%~dp0godot.cmd" --headless --path "%~dp0.." --script res://tests/architecture_smoke_test.gd
exit /b %ERRORLEVEL%
