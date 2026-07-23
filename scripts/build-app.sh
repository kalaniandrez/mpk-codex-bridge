#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
APP_DIR="${PROJECT_DIR}/dist/MPK Codex Bridge.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
ARM_TRIPLE="arm64-apple-macosx13.0"
INTEL_TRIPLE="x86_64-apple-macosx13.0"
STAGE_DIR="$(mktemp -d "/private/tmp/mpk-codex-bridge-build.XXXXXX")"
ARM_SCRATCH="${STAGE_DIR}/.build-arm64"
INTEL_SCRATCH="${STAGE_DIR}/.build-x86_64"
ARM_BINARY="${STAGE_DIR}/MPKCodexBridge-arm64"
INTEL_BINARY="${STAGE_DIR}/MPKCodexBridge-x86_64"

trap 'rm -rf -- "${STAGE_DIR}"' EXIT

# Compile from a stable, local staging copy. This also avoids iCloud
# materialization changing source timestamps during a long release build.
ditto "${PROJECT_DIR}/Package.swift" "${STAGE_DIR}/Package.swift"
ditto "${PROJECT_DIR}/Sources" "${STAGE_DIR}/Sources"

cd "${STAGE_DIR}"
swift build -c release --triple "${ARM_TRIPLE}" --scratch-path "${ARM_SCRATCH}"
ARM_BIN_DIR="$(swift build -c release --triple "${ARM_TRIPLE}" --scratch-path "${ARM_SCRATCH}" --show-bin-path)"
cp "${ARM_BIN_DIR}/MPKCodexBridge" "${ARM_BINARY}"
swift package --scratch-path "${ARM_SCRATCH}" clean

swift build -c release --triple "${INTEL_TRIPLE}" --scratch-path "${INTEL_SCRATCH}"
INTEL_BIN_DIR="$(swift build -c release --triple "${INTEL_TRIPLE}" --scratch-path "${INTEL_SCRATCH}" --show-bin-path)"
cp "${INTEL_BIN_DIR}/MPKCodexBridge" "${INTEL_BINARY}"
swift package --scratch-path "${INTEL_SCRATCH}" clean

mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
lipo -create \
    "${ARM_BINARY}" \
    "${INTEL_BINARY}" \
    -output "${MACOS_DIR}/MPKCodexBridge"
cp "${PROJECT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${PROJECT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"

xattr -cr "${APP_DIR}"
# iCloud-backed workspaces may immediately restore this Finder-only flag after
# a bundle is written. It is not application data and must not be signed.
xattr -d com.apple.FinderInfo "${APP_DIR}" 2>/dev/null || true
codesign --force --deep --sign - "${APP_DIR}"

lipo -info "${MACOS_DIR}/MPKCodexBridge"
echo "${APP_DIR}"
