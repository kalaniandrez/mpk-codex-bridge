#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
STAGE_DIR="$(mktemp -d "/private/tmp/mpk-codex-bridge-check.XXXXXX")"
CHECK_BINARY="${STAGE_DIR}/mpk-codex-bridge-check"

trap 'rm -rf -- "${STAGE_DIR}"' EXIT

# Compile from a stable local copy so iCloud materialization cannot change a
# source timestamp midway through the check build.
for source in \
    Models.swift \
    MIDIParser.swift \
    Shortcut.swift \
    ConfigurationStore.swift
do
    ditto \
        "${PROJECT_DIR}/Sources/MPKCodexBridge/${source}" \
        "${STAGE_DIR}/${source}"
done
ditto "${PROJECT_DIR}/Checks/main.swift" "${STAGE_DIR}/main.swift"

swiftc \
    "${STAGE_DIR}/Models.swift" \
    "${STAGE_DIR}/MIDIParser.swift" \
    "${STAGE_DIR}/Shortcut.swift" \
    "${STAGE_DIR}/ConfigurationStore.swift" \
    "${STAGE_DIR}/main.swift" \
    -o "${CHECK_BINARY}"

"${CHECK_BINARY}"
