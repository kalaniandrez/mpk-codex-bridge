#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
APP_PATH="${PROJECT_DIR}/dist/MPK Codex Bridge.app"
ARCHIVE_PATH="${PROJECT_DIR}/dist/MPK-Codex-Bridge-macOS.zip"
CHECKSUM_PATH="${PROJECT_DIR}/dist/SHA256.txt"
VERIFY_DIR="$(mktemp -d "/private/tmp/mpk-codex-bridge-verify.XXXXXX")"
STAGED_APP_PATH="${VERIFY_DIR}/MPK Codex Bridge.app"
STAGED_ARCHIVE_PATH="${VERIFY_DIR}/MPK-Codex-Bridge-macOS.zip"
EXTRACT_DIR="${VERIFY_DIR}/extracted"

trap 'rm -rf -- "${VERIFY_DIR}"' EXIT

"${SCRIPT_DIR}/build-app.sh"
"${SCRIPT_DIR}/check.sh"

cd "${PROJECT_DIR}"
ditto --norsrc "${APP_PATH}" "${STAGED_APP_PATH}"
xattr -cr "${STAGED_APP_PATH}"
xattr -d com.apple.FinderInfo "${STAGED_APP_PATH}" 2>/dev/null || true
codesign --force --deep --sign - "${STAGED_APP_PATH}"
codesign --verify --deep --strict --verbose=2 "${STAGED_APP_PATH}"
ditto --norsrc -c -k --keepParent \
    "${STAGED_APP_PATH}" \
    "${STAGED_ARCHIVE_PATH}"

ARCHIVE_HASH="$(shasum -a 256 "${STAGED_ARCHIVE_PATH}" | awk '{print $1}')"
cp "${STAGED_ARCHIVE_PATH}" "${ARCHIVE_PATH}"
echo "${ARCHIVE_HASH}  MPK-Codex-Bridge-macOS.zip" > "${CHECKSUM_PATH}"

unzip -t "${STAGED_ARCHIVE_PATH}" >/dev/null
if unzip -Z1 "${STAGED_ARCHIVE_PATH}" | rg '/\._'; then
    echo "Archive contains unwanted AppleDouble metadata." >&2
    exit 1
fi
mkdir -p "${EXTRACT_DIR}"
ditto -x -k "${STAGED_ARCHIVE_PATH}" "${EXTRACT_DIR}"
codesign --verify --deep --strict --verbose=2 \
    "${EXTRACT_DIR}/MPK Codex Bridge.app"
echo "${ARCHIVE_HASH}  ${ARCHIVE_PATH}" | shasum -a 256 -c -

echo "${ARCHIVE_PATH}"
echo "${CHECKSUM_PATH}"
