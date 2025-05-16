$ErrorActionPreference = "Stop"

# === Set up Visual Studio environment ===
if (-not $env:VSCMD_VER) {
    Write-Error "[ERROR] MSVC environment not initialized. Please run from Developer PowerShell or call vcvars64.bat."
    exit 1
}

# === Resolve root and paths ===
$RootDir = Resolve-Path "$PSScriptRoot\.."
Write-Host "[INFO] Root dir is ""$RootDir"""
$DepotToolsDir = "$RootDir\build\depot_tools"
$CrashpadBuildDir = "$RootDir\build\crashpad"

# === Ensure depot_tools is present ===
if (-not (Test-Path "$DepotToolsDir\gclient.py")) {
    Write-Host "[INFO] Cloning depot_tools into ""$DepotToolsDir""..."
    git clone "https://chromium.googlesource.com/chromium/tools/depot_tools.git" "$DepotToolsDir"
}
$env:PATH = "$DepotToolsDir;$env:PATH"

# === Fetch Crashpad source ===
if (-not (Test-Path "$CrashpadBuildDir")) {
    New-Item -ItemType Directory -Path "$CrashpadBuildDir" | Out-Null
    Set-Location "$CrashpadBuildDir"
    Write-Host "[INFO] Fetching Crashpad..."
    & fetch crashpad
} else {
    Set-Location "$CrashpadBuildDir\crashpad"
    Write-Host "[INFO] Syncing Crashpad..."
    & gclient sync
}

#=== Build crashpad ===
$TargetRuntimes = @(
    "MD",   # Use the multithread-specific and DLL-specific version of the runtime library.
    "MDd",  # Use the debug multithread-specific and DLL-specific version of the runtime library.
    "MT",   # Use the multithread, static version of the runtime library.
    "MTd"   # Use the debug multithread, static version of the runtime library.
)
$TargetLibs = @(
    "client\client.lib"
    "client\common.lib" # WARNING: common.lib from other subdirectories won't work
    "util\util.lib"
    "third_party\mini_chromium\mini_chromium\base\base.lib"
)
foreach ($Runtime in $TargetRuntimes) {

    # Determine output directory
    if ($Runtime.EndsWith("d")) {
        $Config = "debug"
        $IsDebug = "true"
    } else {
        $Config = "release"
        $IsDebug = "false"
    }
    $OutDir = "out\$Config\$Runtime"
    $GenArgs = "--args=""is_debug=$IsDebug extra_cflags=\""/$Runtime\"""""

    # Generate build files
    Set-Location "$CrashpadBuildDir\crashpad"
    Write-Host "[INFO] Build dir for $Runtime $Config is $CrashpadBuildDir\crashpad"
    Write-Host "[INFO] Running gn gen ""$OutDir"" $GenArgs"
    & gn gen "$OutDir" "$GenArgs"

    # Build crashpad
    Write-Host "[INFO] Building crashpad in ""$OutDir""..."
    & ninja -C "$OutDir"

    # Make sure output lib directory exists
    $Destination = "$RootDir\lib\windows\$Config\$Runtime"
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    # Copy libraries
    Write-Host "[INFO] Copying libraries to $Destination"
    foreach ($Lib in $TargetLibs) {
        $Source = Join-Path $OutDir "obj\$Lib"
        Write-Host "[INFO] Copying $Source"
        Copy-Item -Force -ErrorAction Stop $Source $Destination
    }
}

#=== Install crashpad handler ===
Write-Host "[INFO] Copying crashpad_handler"
Copy-Item -Force -ErrorAction Stop `
    "$RootDir/build/crashpad/crashpad/out/release/MT/crashpad_handler.exe" `
    "$RootDir/bin/windows/"

#=== Install crashpad headers ===
Write-Host "[INFO] Installing headers: crashpad/client..."
robocopy `
    "$RootDir/build/crashpad/crashpad/client/" `
    "$RootDir/include/crashpad/client/" `
    *.h *.hpp /S /PURGE /NFL /NDL /NJH /NJS /NC /NS
Write-Host "[INFO] Installing headers: crashpad/handler..."
robocopy `
    "$RootDir/build/crashpad/crashpad/handler/" `
    "$RootDir/include/crashpad/handler/" `
    *.h *.hpp /S /PURGE /NFL /NDL /NJH /NJS /NC /NS
Write-Host "[INFO] Installing headers: crashpad/util..."
robocopy `
    "$RootDir/build/crashpad/crashpad/util/" `
    "$RootDir/include/crashpad/util/" `
    *.h *.hpp /S /PURGE /NFL /NDL /NJH /NJS /NC /NS

#=== Install mini_chromium headers ===
Write-Host "[INFO] Installing headers: mini_chromium/base..."
robocopy `
    "$RootDir/build/crashpad/crashpad/third_party/mini_chromium/mini_chromium" `
    "$RootDir/include/mini_chromium" `
    *.h *.hpp /S /PURGE /NFL /NDL /NJH /NJS /NC /NS

#=== Done ===
Write-Host "[SUCCESS] Crashpad build and copy complete."
