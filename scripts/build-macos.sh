#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script must be run on macOS (Darwin)." >&2
    exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build"
OUT_DIR="${BUILD_DIR}/out"

DEPOT_TOOLS_URL="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR="${BUILD_DIR}/depot_tools"

INCLUDE_DIR="${ROOT_DIR}/include/"
LIB_DIR="${ROOT_DIR}/lib/macOS"

# Step 2: Fetch Crashpad source
if [ ! -d "${BUILD_DIR}" ]; then
    mkdir -p "${BUILD_DIR}"
fi

# Step 1: Set up depot_tools
if [ ! -d "${DEPOT_TOOLS_DIR}" ]; then
    echo "Installing depot_tools..."
    mkdir -p "${DEPOT_TOOLS_DIR}"
    git clone "${DEPOT_TOOLS_URL}" "${DEPOT_TOOLS_DIR}"
fi
export PATH="${DEPOT_TOOLS_DIR}${PATH+:${PATH}}"

# Step 2: Fetch Crashpad source
if [ ! -d "${BUILD_DIR}/crashpad" ]; then
    echo "Fetching Crashpad source..."
    cd "${BUILD_DIR}"
    fetch crashpad
fi

echo "Building Crashpad..."
cd "${BUILD_DIR}/crashpad"
gn gen "${OUT_DIR}" --args="target_cpu=\"mac_universal\""
ninja -C "${OUT_DIR}"

# Step 4: Build the combined output library
echo "Installing the library..."
if [ ! -d "${LIB_DIR}" ]; then
    mkdir -p "${LIB_DIR}"
fi
cp "${OUT_DIR}/obj/client/libclient.a" "${LIB_DIR}"
cp "${OUT_DIR}/obj/client/libcommon.a" "${LIB_DIR}"
cp "${OUT_DIR}/obj/util/libutil.a" "${LIB_DIR}"
cp "${OUT_DIR}/obj/third_party/mini_chromium/mini_chromium/base/libbase.a" "${LIB_DIR}"

# Step 3: Copy headers
echo "Installing client headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "${BUILD_DIR}/crashpad/client/" \
    "${INCLUDE_DIR}/crashpad/client/"
echo "Installing util headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "${BUILD_DIR}/crashpad/util/" \
    "${INCLUDE_DIR}/crashpad/util/"
echo "Installing mini_chromium headers..."
rsync -a --delete --include='*/' --include='*.h' --include='*.hpp' --exclude='*' \
    "${BUILD_DIR}/crashpad/third_party/mini_chromium/mini_chromium/base" \
    "${INCLUDE_DIR}/mini_chromium/base"
