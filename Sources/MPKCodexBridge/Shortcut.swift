import CoreGraphics
import Foundation

struct KeyboardShortcut: Equatable, Sendable {
    let keyCode: CGKeyCode
    let flags: CGEventFlags

    static func parse(_ rawValue: String) -> KeyboardShortcut? {
        let parts = rawValue
            .lowercased()
            .split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard let keyName = parts.last, let keyCode = keyCodes[keyName] else {
            return nil
        }

        var flags: CGEventFlags = []
        for modifier in parts.dropLast() {
            switch modifier {
            case "cmd", "command", "⌘":
                flags.insert(.maskCommand)
            case "shift", "⇧":
                flags.insert(.maskShift)
            case "option", "opt", "alt", "⌥":
                flags.insert(.maskAlternate)
            case "control", "ctrl", "⌃":
                flags.insert(.maskControl)
            default:
                return nil
            }
        }

        return KeyboardShortcut(keyCode: keyCode, flags: flags)
    }

    private static let keyCodes: [String: CGKeyCode] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5,
        "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
        "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
        "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23,
        "=": 24, "equal": 24, "9": 25, "7": 26, "-": 27,
        "minus": 27, "8": 28, "0": 29, "]": 30, "rightbracket": 30,
        "o": 31, "u": 32, "[": 33, "leftbracket": 33, "i": 34,
        "p": 35, "return": 36, "enter": 36, "l": 37, "j": 38,
        "'": 39, "quote": 39, "k": 40, ";": 41, "semicolon": 41,
        "\\": 42, "backslash": 42, ",": 43, "comma": 43,
        "/": 44, "slash": 44, "n": 45, "m": 46,
        ".": 47, "period": 47, "tab": 48, "space": 49,
        "delete": 51, "backspace": 51, "escape": 53, "esc": 53,
        "left": 123, "right": 124, "down": 125, "up": 126
    ]
}
