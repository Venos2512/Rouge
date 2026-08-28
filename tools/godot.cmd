@echo off
set "GODOT_PROJECT_EXECUTABLE=C:\Users\namda\Desktop\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"
set "GODOT_PROJECT_USER_DIR=%~dp0..\.godot-user"
set "APPDATA=%GODOT_PROJECT_USER_DIR%\appdata"
set "LOCALAPPDATA=%GODOT_PROJECT_USER_DIR%\localappdata"
set "USERPROFILE=%GODOT_PROJECT_USER_DIR%\profile"

if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%USERPROFILE%" mkdir "%USERPROFILE%"

if not exist "%GODOT_PROJECT_EXECUTABLE%" (
    echo Godot executable not found: %GODOT_PROJECT_EXECUTABLE% 1>&2
    exit /b 1
)

"%GODOT_PROJECT_EXECUTABLE%" %*
exit /b %ERRORLEVEL%
