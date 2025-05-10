#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR="${SCRIPT_DIR}/.."
BUILD_DIR="${ROOT_DIR}/build"
OUT_DIR="${BUILD_DIR}/out/Default"

DEPOT_TOOLS_URL="https://chromium.googlesource.com/chromium/tools/depot_tools.git"
DEPOT_TOOLS_DIR="${BUILD_DIR}/depot_tools"

INCLUDE_DIR="${ROOT_DIR}/include/"
LIB_DIR="${ROOT_DIR}/lib/Linux"

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

# Step 3: Build Crashpad
echo "Building Crashpad..."
cd "${BUILD_DIR}/crashpad"
gn gen "${OUT_DIR}"
ninja -C "${OUT_DIR}"

# Step 4: Build the combined output library
echo "Creating the library..."
if [ ! -d "${BUILD_DIR}/libobj" ]; then
    mkdir -p "${BUILD_DIR}/libobj"
fi
cd "${BUILD_DIR}/libobj"
ar x "${OUT_DIR}/obj/client/libclient.a"
ar x "${OUT_DIR}/obj/client/libcommon.a"
ar x "${OUT_DIR}/obj/util/libutil.a"
ar x "${OUT_DIR}/obj/third_party/mini_chromium/mini_chromium/base/libbase.a"

# Copy the newly created library
echo "Installing the library..."
if [ ! -d "${LIB_DIR}" ]; then
    mkdir -p "${LIB_DIR}"
fi
ar rcs "${LIB_DIR}/libcrashpad.a" *.o

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
    "${INCLUDE_DIR}/crashpad/third_party/mini_chromium/base"
