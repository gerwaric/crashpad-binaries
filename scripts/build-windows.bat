@echo off

REM === Set up Visual Studio build environment ===
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

REM === Add depot_tools to PATH ===
set BUILD_DIR=
set DEPOT_TOOLS_DIR=%~dp0..\depot_tools
set PATH=%DEPOT_TOOLS_DIR%;%PATH%

REM === Change to Crashpad root directory ===
cd /d %~dp0..\crashpad

REM === Generate build files with GN ===
gn gen out\Default --args="is_debug=false target_cpu=\"x64\""

IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] GN generation failed.
    exit /b 1
)

REM === Build with Ninja ===
ninja -C out\Default

IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed.
    exit /b 1
)

echo [SUCCESS] Crashpad built successfully!
exit /b 0
