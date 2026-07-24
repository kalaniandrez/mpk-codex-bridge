# Changelog

## 1.0.2 - 2026-07-24

- Added a dual-version download containing Classic and Modern / Reel View.
- Added separate direct-download archives for each version.
- Restored the custom app-icon reference and gave Classic a distinct macOS
  identity so Finder and the Dock do not confuse it with Modern.
- Added a choose-one guide explaining that only one version should run at a
  time.
- Added signature, icon-resource, archive, and checksum validation for both
  applications.

## 1.0.1 - 2026-07-24

- Restored the exact pre-upgrade Swift runtime recovered from the original
  working task record.
- Restored the original compact mapping-list interface and 860 × 720 window.
- Restored configuration schema v1 and the original MIDI learning and
  directional-knob behavior.
- Restored Kalani's previously working pad mappings on channel 10 and knob CC
  mappings on channel 1 in the local configuration.
- Kept the universal Apple silicon and Intel release packaging.
- Made release checks compile from a stable local staging copy to avoid iCloud
  source-timestamp races.

## 1.0.0 - 2026-07-23

- Added guided MIDI, Accessibility, and control-learning setup.
- Added a dedicated Reel View with live MIDI and action feedback.
- Added active mapping highlights for clearer demos.
- Labeled the MPK Mini Play knobs as Filter, Resonance, Reverb, and Chorus.
- Prevented piano notes and program changes from being learned as directional
  knobs.
- Migrated older configurations and cleared incompatible knob triggers.
- Added a universal Apple silicon and Intel release build.
- Added an original app icon and vertical reel artwork.
- Added local-only privacy and project-scope disclosures.
