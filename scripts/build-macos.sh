#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script must be run on macOS (Darwin)." >&2
    exit 1
fi

#=== Resolve root and paths ===
SCRIPT_DIR=$( cd -- "$( dirname -- "$BASH_SOURCE[0]" )" &> /dev/null && pwd )
ROOT_DIR="$SCRIPT_DIR/.."
echo "[INFO] Root dir is \"$ROOT_DIR\""
DEPOT_TOOLS_DIR="$ROOT_DIR/build/depot_tools"
CRASHPAD_BUILD_DIR="$ROOT_DIR/build/crashpad"

#=== Setup depot_tools ===
if [ ! -f "$DEPOT_TOOLS_DIR/gclient.py" ]; then
    echo "[INFO] Installing depot_tools..."
    mkdir -p "$DEPOT_TOOLS_DIR"
    git clone "https://chromium.googlesource.com/chromium/tools/depot_tools.git" "$DEPOT_TOOLS_DIR"
fi
export PATH="$DEPOT_TOOLS_DIR${PATH+:$PATH}"

#=== Fetch crashpad ===
if [ ! -d "$CRASHPAD_BUILD_DIR/crashpad" ]; then
    echo "[INFO] Fetching Crashpad..."
    mkdir -p "$CRASHPAD_BUILD_DIR"
    cd "$CRASHPAD_BUILD_DIR"
    fetch crashpad
else
    echo "[INFO] Syncing Crashpad..."
    cd "$CRASHPAD_BUILD_DIR/crashpad"
    gclient sync
fi

#== Build crashpad ===
cd "$CRASHPAD_BUILD_DIR/crashpad"
for config in release debug; do

    if [[ "$config" == "debug" ]]; then
        is_debug=true
    else
        is_debug=false
    fi

    # Generate build
    echo "[INFO] Generating $config build..."
    gn gen "out/$config" --args="target_cpu=\"mac_universal\" is_debug=$is_debug"

    # Build release
    echo "[INFO] Building $config..."
    ninja -C "out/$config"

    # Copy libraries
    destination="$ROOT_DIR/lib/macos/$config"
    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
    fi

    echo "[INFO] Copying client/libclient.a to \"$destination\""
    cp "out/$config/obj/client/libclient.a" "$destination"

    echo "[INFO] Copying client/libcommon.a to \"$destination\""
    cp "out/$config/obj/client/libcommon.a" "$destination"

    echo "[INFO] Copying util/libutil.a to \"$destination\""
    cp "out/$config/obj/util/libutil.a" "$destination"

    echo "[INFO] Copying mini_chromium/base/libbase.a to \"$destination\""
    cp "out/$config/obj/third_party/mini_chromium/mini_chromium/base/libbase.a" "$destination"

done

#=== Copy crashpad headers ===
echo "[INFO] Installing client headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "$ROOT_DIR/build/crashpad/crashpad/client/" \
    "$ROOT_DIR/include/crashpad/client/"
echo "[INFO] Installing handler headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "$ROOT_DIR/build/crashpad/crashpad/handler/" \
    "$ROOT_DIR/include/crashpad/handler/"
echo "[INFO] Installing util headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "$ROOT_DIR/build/crashpad/crashpad/util/" \
    "$ROOT_DIR/include/crashpad/util/"

#=== Copy mini_chromium headers ===
echo "[INFO] Installing mini_chromium headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "$ROOT_DIR/build/crashpad/crashpad/third_party/mini_chromium/mini_chromium/" \
    "$ROOT_DIR/include/mini_chromium/"

#=== Copy crashpad_handler executable ===
if [ ! -d "$ROOT_DIR/bin/macos" ]; then
    mkdir -p "$ROOT_DIR/bin/macos"
fi
echo "[INFO] Copying crashpad_handler executable..."
cp  "$ROOT_DIR/build/crashpad/crashpad/out/release/crashpad_handler" \
    "$ROOT_DIR/bin/macos/"

echo "[INFO] Done."
