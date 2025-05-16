@echo off
setlocal enabledelayedexpansion

REM === Set up Visual Studio build environment ===
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

REM === Call the build script ===
powershell %~dp0build-windows.ps1
