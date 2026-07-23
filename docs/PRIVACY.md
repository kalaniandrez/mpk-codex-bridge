# Privacy

MPK Codex Bridge is local-only.

- It reads MIDI events from the source selected in the app.
- It sends the configured keyboard shortcuts to the Codex desktop app.
- It stores mappings locally in the user's Application Support folder.
- It does not require an account or OpenAI API key.
- It has no analytics, telemetry, advertising, or network code.

The macOS Accessibility permission is required because sending keyboard events
to another app is protected by the operating system. You can revoke that
permission at any time under **System Settings > Privacy & Security >
Accessibility**.
