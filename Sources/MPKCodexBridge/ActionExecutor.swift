import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

@MainActor
final class ActionExecutor {
    static let codexBundleIdentifier = "com.openai.codex"

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityAccess() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func perform(_ activation: MappingActivation) async -> String {
        guard await focusCodex() else {
            return "Codex is not installed or could not be opened."
        }

        if activation.action == .focusCodex {
            return "Focused Codex"
        }

        guard isAccessibilityTrusted else {
            return "Accessibility permission is required for shortcuts."
        }

        try? await Task.sleep(for: .milliseconds(120))

        let shortcut: KeyboardShortcut?
        switch activation.action {
        case .focusCodex:
            shortcut = nil
        case .newTask:
            shortcut = KeyboardShortcut.parse("cmd+n")
        case .confirm:
            shortcut = KeyboardShortcut.parse("return")
        case .cancel:
            shortcut = KeyboardShortcut.parse("escape")
        case .historyBack:
            shortcut = KeyboardShortcut.parse("cmd+[")
        case .historyForward:
            shortcut = KeyboardShortcut.parse("cmd+]")
        case .showShortcuts:
            shortcut = KeyboardShortcut.parse("cmd+/")
        case .dictation:
            sendDoubleCommand()
            return "Voice dictation"
        case .composerDial:
            shortcut = activation.direction == .negative
                ? KeyboardShortcut.parse("shift+tab")
                : KeyboardShortcut.parse("tab")
        case .historyDial:
            shortcut = activation.direction == .negative
                ? KeyboardShortcut.parse("cmd+[")
                : KeyboardShortcut.parse("cmd+]")
        case .arrowDial:
            shortcut = activation.direction == .negative
                ? KeyboardShortcut.parse("left")
                : KeyboardShortcut.parse("right")
        case .customShortcut:
            shortcut = KeyboardShortcut.parse(activation.customShortcut)
        }

        guard let shortcut else {
            return "Invalid or empty shortcut."
        }
        send(shortcut)
        return activation.action.displayName
    }

    private func focusCodex() async -> Bool {
        if let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.codexBundleIdentifier
        ).first {
            return running.activate(options: [.activateIgnoringOtherApps])
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: Self.codexBundleIdentifier
        ) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(
                at: appURL,
                configuration: configuration
            ) { application, _ in
                continuation.resume(returning: application != nil)
            }
        }
    }

    private func send(_ shortcut: KeyboardShortcut) {
        guard
            let keyDown = CGEvent(
                keyboardEventSource: nil,
                virtualKey: shortcut.keyCode,
                keyDown: true
            ),
            let keyUp = CGEvent(
                keyboardEventSource: nil,
                virtualKey: shortcut.keyCode,
                keyDown: false
            )
        else {
            return
        }

        keyDown.flags = shortcut.flags
        keyUp.flags = shortcut.flags
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    private func sendDoubleCommand() {
        let commandKeyCode: CGKeyCode = 55
        for _ in 0..<2 {
            guard
                let keyDown = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: commandKeyCode,
                    keyDown: true
                ),
                let keyUp = CGEvent(
                    keyboardEventSource: nil,
                    virtualKey: commandKeyCode,
                    keyDown: false
                )
            else {
                return
            }
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
            keyUp.flags = []
            keyUp.post(tap: .cghidEventTap)
        }
    }
}
