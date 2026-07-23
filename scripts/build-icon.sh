#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
MASTER_ICON="${PROJECT_DIR}/Resources/Assets/app-icon-master.png"
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mpk-codex-icon.XXXXXX")"
ICONSET_DIR="${TEMP_ROOT}/AppIcon.iconset"
OUTPUT_ICON="${PROJECT_DIR}/Resources/AppIcon.icns"

mkdir -p "${ICONSET_DIR}"

sips -z 16 16 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_16x16.png" >/dev/null
sips -z 32 32 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_32x32.png" >/dev/null
sips -z 64 64 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_128x128.png" >/dev/null
sips -z 256 256 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_256x256.png" >/dev/null
sips -z 512 512 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_512x512.png" >/dev/null
sips -z 1024 1024 "${MASTER_ICON}" --out "${ICONSET_DIR}/icon_512x512@2x.png" >/dev/null

iconutil -c icns "${ICONSET_DIR}" -o "${OUTPUT_ICON}"
echo "${OUTPUT_ICON}"
