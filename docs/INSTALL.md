# Install and setup

## Install the app

1. Download `MPK-Codex-Bridge-macOS.zip` from the latest GitHub release.
2. Double-click the ZIP, then drag **MPK Codex Bridge** into Applications.
3. Because this first community build is not Apple-notarized, Control-click the
   app, choose **Open**, and choose **Open** again.
4. If macOS still blocks it, open **System Settings > Privacy & Security** and
   choose **Open Anyway** beside the MPK Codex Bridge message.

The app is ad-hoc signed and its source is public. It does not auto-update.

## Connect MIDI

1. Connect the MPK Mini Play directly to the Mac by USB.
2. Launch the bridge. It should choose a source containing `MPK` or `Akai`
   automatically. Otherwise, pick the controller from the MIDI Source menu.
3. Press a key or pad. **Last MIDI** should change immediately.

If the source list is empty, reconnect USB, close any music app that may be
holding the device, then relaunch the bridge.

## Allow keyboard control

Choose **Allow Accessibility**, then enable **MPK Codex Bridge** under **System
Settings > Privacy & Security > Accessibility**. Return to the app and confirm
the setup step changes to **Accessibility allowed**.

This permission only lets the bridge send the keyboard shortcuts you map.

## Learn pads

Choose **Learn** on one pad row, then hit exactly one physical pad. The row
should show a learned MIDI Note or CC trigger. Use the row menu's **Test
action** command to verify the corresponding Codex shortcut.

## Learn knobs

The assignable knobs are **Filter**, **Resonance**, **Reverb**, and **Chorus**.
The separate Volume knob is hardware-only and cannot be learned.

1. Turn **Internal Sounds off** on the keyboard.
2. Choose **Learn** beside one knob.
3. Turn that knob through several positions.
4. Confirm the learned trigger says `CC`, not `Note`.

If the app says it heard a piano note, cancel learning, turn Internal Sounds
off, and try the assignable knob again.

## First-launch limitations

- Codex must be installed for actions to run.
- This build supports macOS 13 or newer.
- The app controls Codex through public macOS keyboard events. It cannot read
  private Codex task status, approvals, or hardware-light data.
- MPK pad lights remain controlled by the keyboard firmware.
