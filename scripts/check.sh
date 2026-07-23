#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_DIR="${SCRIPT_DIR:h}"
CHECK_BINARY="${PROJECT_DIR}/.build/mpk-codex-bridge-check"

cd "${PROJECT_DIR}"
mkdir -p ".build"

swiftc \
    "Sources/MPKCodexBridge/Models.swift" \
    "Sources/MPKCodexBridge/MIDIParser.swift" \
    "Sources/MPKCodexBridge/Shortcut.swift" \
    "Sources/MPKCodexBridge/ConfigurationStore.swift" \
    "Checks/main.swift" \
    -o "${CHECK_BINARY}"

"${CHECK_BINARY}"
