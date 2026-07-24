#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
DIST_DIR="${PROJECT_DIR}/dist"
DUAL_ARCHIVE="${DIST_DIR}/MPK-Codex-Bridge-macOS.zip"
CLASSIC_ARCHIVE="${DIST_DIR}/MPK-Codex-Bridge-Classic-macOS.zip"
MODERN_ARCHIVE="${DIST_DIR}/MPK-Codex-Bridge-Modern-macOS.zip"
CHECKSUM_PATH="${DIST_DIR}/SHA256.txt"
MODERN_RELEASE_BASE="https://github.com/kalaniandrez/mpk-codex-bridge/releases/download/v1.0.0"
MODERN_EXPECTED_SHA256="a82dac512cc78154cc7d17c6a474de1f85397c3baf84f1ef17b6738bf8d14043"
STAGE_DIR="$(mktemp -d "/private/tmp/mpk-codex-bridge-dual.XXXXXX")"
PACK_ROOT="${STAGE_DIR}/MPK Codex Bridge"
VERIFY_DIR="${STAGE_DIR}/verify"
STAGED_DUAL_ARCHIVE="${STAGE_DIR}/MPK-Codex-Bridge-macOS.zip"
MODERN_SOURCE_ARCHIVE="${STAGE_DIR}/modern-source.zip"
MODERN_SOURCE_CHECKSUM="${STAGE_DIR}/modern-SHA256.txt"

trap 'rm -rf -- "${STAGE_DIR}"' EXIT

"${SCRIPT_DIR}/package-release.sh"
cp "${DUAL_ARCHIVE}" "${CLASSIC_ARCHIVE}"

curl -fL \
    "${MODERN_RELEASE_BASE}/MPK-Codex-Bridge-macOS.zip" \
    -o "${MODERN_SOURCE_ARCHIVE}"
curl -fL \
    "${MODERN_RELEASE_BASE}/SHA256.txt" \
    -o "${MODERN_SOURCE_CHECKSUM}"

PUBLISHED_MODERN_HASH="$(
    awk '/MPK-Codex-Bridge-macOS.zip/ { print $1; exit }' \
        "${MODERN_SOURCE_CHECKSUM}"
)"
ACTUAL_MODERN_HASH="$(
    shasum -a 256 "${MODERN_SOURCE_ARCHIVE}" | awk '{ print $1 }'
)"
if [[ -z "${PUBLISHED_MODERN_HASH}" || \
      "${PUBLISHED_MODERN_HASH}" != "${MODERN_EXPECTED_SHA256}" || \
      "${ACTUAL_MODERN_HASH}" != "${MODERN_EXPECTED_SHA256}" ]]
then
    echo "Modern v1.0.0 checksum verification failed." >&2
    exit 1
fi
cp "${MODERN_SOURCE_ARCHIVE}" "${MODERN_ARCHIVE}"

mkdir -p \
    "${PACK_ROOT}/Classic" \
    "${PACK_ROOT}/Modern - Reel View" \
    "${VERIFY_DIR}"
ditto --norsrc -x -k \
    "${CLASSIC_ARCHIVE}" \
    "${PACK_ROOT}/Classic"
ditto --norsrc -x -k \
    "${MODERN_SOURCE_ARCHIVE}" \
    "${PACK_ROOT}/Modern - Reel View"
ditto \
    "${PROJECT_DIR}/Resources/DUAL-PACK-README.txt" \
    "${PACK_ROOT}/README FIRST.txt"
dot_clean -m "${PACK_ROOT}" >/dev/null 2>&1 || true

for app_path in \
    "${PACK_ROOT}/Classic/MPK Codex Bridge.app" \
    "${PACK_ROOT}/Modern - Reel View/MPK Codex Bridge.app"
do
    xattr -cr "${app_path}"
    xattr -d com.apple.FinderInfo "${app_path}" 2>/dev/null || true
    codesign --force --deep --sign - "${app_path}"
    codesign --verify --deep --strict --verbose=2 "${app_path}"

    icon_name="$(
        /usr/libexec/PlistBuddy \
            -c "Print :CFBundleIconFile" \
            "${app_path}/Contents/Info.plist"
    )"
    icon_file="${icon_name%.icns}.icns"
    if [[ ! -f "${app_path}/Contents/Resources/${icon_file}" ]]; then
        echo "Missing app icon for ${app_path}." >&2
        exit 1
    fi
done

ditto --norsrc -c -k --keepParent \
    "${PACK_ROOT}" \
    "${STAGED_DUAL_ARCHIVE}"
unzip -t "${STAGED_DUAL_ARCHIVE}" >/dev/null
if unzip -Z1 "${STAGED_DUAL_ARCHIVE}" | rg '/\._'; then
    echo "Dual archive contains unwanted AppleDouble metadata." >&2
    exit 1
fi

ditto -x -k "${STAGED_DUAL_ARCHIVE}" "${VERIFY_DIR}"
for app_path in \
    "${VERIFY_DIR}/MPK Codex Bridge/Classic/MPK Codex Bridge.app" \
    "${VERIFY_DIR}/MPK Codex Bridge/Modern - Reel View/MPK Codex Bridge.app"
do
    codesign --verify --deep --strict --verbose=2 "${app_path}"
done

cp "${STAGED_DUAL_ARCHIVE}" "${DUAL_ARCHIVE}"
{
    for archive_path in \
        "${DUAL_ARCHIVE}" \
        "${CLASSIC_ARCHIVE}" \
        "${MODERN_ARCHIVE}"
    do
        archive_hash="$(shasum -a 256 "${archive_path}" | awk '{ print $1 }')"
        echo "${archive_hash}  ${archive_path:t}"
    done
} > "${CHECKSUM_PATH}"

while IFS= read -r checksum_line
do
    archive_hash="${checksum_line%% *}"
    archive_name="${checksum_line##*  }"
    echo "${archive_hash}  ${DIST_DIR}/${archive_name}" | shasum -a 256 -c -
done < "${CHECKSUM_PATH}"

echo "${DUAL_ARCHIVE}"
echo "${CLASSIC_ARCHIVE}"
echo "${MODERN_ARCHIVE}"
echo "${CHECKSUM_PATH}"
