@echo off
setlocal enabledelayedexpansion

REM === Set up Visual Studio build environment ===
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

set "ROOT_DIR=%~dp0.."
set "BUILD_DIR=%ROOT_DIR%\build"
set "OUT_DIR=%BUILD_DIR%\out"

set "DEPOT_TOOLS_URL=https://chromium.googlesource.com/chromium/tools/depot_tools.git"
set "DEPOT_TOOLS_DIR=%BUILD_DIR%\depot_tools"

set "DEST_INCLUDE=%ROOT_DIR%\include"
set "DEST_LIB=%ROOT_DIR%\lib\Windows"

REM === Clone depot_tools if it doesn't exist ===
IF NOT EXIST "%DEPOT_TOOLS_DIR%" (
    mkdir "%DEPOT_TOOLS_DIR%"
    echo [INFO] depot_tools not found. Cloning...
    call git clone "%DEPOT_TOOLS_URL%" "%DEPOT_TOOLS_DIR%"
) ELSE (
    echo [INFO] depot_tools already present.
)

REM === Add depot_tools to PATH (temporarily for this session) ===
set "PATH=%DEPOT_TOOLS_DIR%;%PATH%"
call update_depot_tools

REM === Generate build files with GN ===
echo [INFO] Fetching crashpad...
cd /d "%BUILD_DIR%"
if NOT EXIST "crashpad" (
    call fetch crashpad
) ELSE (
    call gclient sync
)

@echo on

REM === Generate build files with GN ===
echo [INFO] Generating build files...
cd /d "%BUILD_DIR%\crashpad"
call gn gen "%OUT_DIR%"
REM --args="is_debug=false"

IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] GN generation failed.
    exit /b 1
)

REM === Build with Ninja ===
call ninja -C "%OUT_DIR%"

IF %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed.
    exit /b 1
)

REM === Copy built libraries ===

echo [INFO] Copying libraries...
if NOT EXIST "%DEST_LIB%" (
    mkdir "%DEST_LIB%"
)
copy "%BUILD_DIR%\out\obj\client\client.lib" "%DEST_LIB%\"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying client.lib
    exit /b 1
)
copy "%BUILD_DIR%\out\obj\handler\handler.lib" "%DEST_LIB%\"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying handler.lib
    exit /b 1
)
copy "%BUILD_DIR%\out\obj\util\util.lib" "%DEST_LIB%\"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying util.clib
    exit /b 1
)
copy "%BUILD_DIR%\out\obj\third_party\mini_chromium\mini_chromium\base\base.lib" "%DEST_LIB%\"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying base.lib
    exit /b 1
)
REM === Copy header files ===

echo [INFO] Copying client headers...
robocopy "%BUILD_DIR%\crashpad\client"  "%DEST_INCLUDE%\crashpad\client"  *.h *.hpp /S /PURGE /Z /R:0 /W:0
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying client headers
    exit /b 1
)

echo [INFO] Copying handler headers...
robocopy "%BUILD_DIR%\crashpad\handler" "%DEST_INCLUDE%\crashpad\handler" *.h *.hpp /S /PURGE /Z /R:0 /W:0
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying handler headers
    exit /b 1
)

echo [INFO] Copying util headers...
robocopy "%BUILD_DIR%\crashpad\util"    "%DEST_INCLUDE%\crashpad\util"    *.h *.hpp /S /PURGE /Z /R:0 /W:0
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying util headers
    exit /b 1
)

echo [INFO] Copying mini_chromium base headers...
robocopy "%BUILD_DIR%\crashpad\third_party\mini_chromium\mini_chromium" "%DEST_INCLUDE%\mini_chromium" *.h *.hpp /S /PURGE /Z /R:0 /W:0
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed copying mini_chromium headers
    exit /b 1
)

echo [SUCCESS] Crashpad headers and libraries copied.
exit /b 0
