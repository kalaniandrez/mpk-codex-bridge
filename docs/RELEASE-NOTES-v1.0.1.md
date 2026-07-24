# MPK Codex Bridge 1.0.1 Classic

This release restores the original working MPK Codex Bridge application.

## Restored

- Original compact mapping-list interface
- Original MIDI learning and mapping engine
- Original directional-knob behavior
- Original configuration schema
- Original 860 × 720 window
- Eight pad actions and four knob actions

The application runtime was recovered byte-for-byte from the local record of
the pre-upgrade build. Release packaging remains a universal Apple silicon and
Intel binary.

## Important setup

Connect the MPK by USB, allow Accessibility, then learn one control at a time.
For knobs, turn Internal Sounds off and move an assignable Filter, Resonance,
Reverb, or Chorus knob immediately after choosing Learn. The separate Volume
knob is hardware-only.

The app reports its original internal version, `0.1.0`, because the runtime and
bundle metadata were restored unchanged.

Requires macOS 13 or newer and the Codex desktop app. This community build is
not Apple-notarized, so first launch requires Control-click > Open.

This is an independent open-source utility and is not affiliated with or
endorsed by OpenAI or Akai Professional.
