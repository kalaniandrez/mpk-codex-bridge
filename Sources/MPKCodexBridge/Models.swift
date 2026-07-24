import Foundation

enum MIDIMessageKind: String, Codable, CaseIterable, Sendable {
    case note
    case controlChange
    case programChange
    case pitchBend
}

struct MIDIMessage: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case began
        case changed
        case ended
    }

    let kind: MIDIMessageKind
    let channel: UInt8
    let number: UInt8
    let value: Int
    let phase: Phase

    var canBeLearned: Bool {
        switch kind {
        case .note:
            return phase == .began
        case .controlChange, .programChange, .pitchBend:
            return true
        }
    }

    var summary: String {
        let channelNumber = Int(channel) + 1
        switch kind {
        case .note:
            return "Note \(number) · Ch \(channelNumber) · \(value)"
        case .controlChange:
            return "CC \(number) · Ch \(channelNumber) · \(value)"
        case .programChange:
            return "Program \(number) · Ch \(channelNumber)"
        case .pitchBend:
            return "Pitch bend · Ch \(channelNumber) · \(value)"
        }
    }
}

struct MIDITrigger: Codable, Equatable, Hashable, Sendable {
    let kind: MIDIMessageKind
    let channel: UInt8
    let number: UInt8

    init(message: MIDIMessage) {
        kind = message.kind
        channel = message.channel
        number = message.kind == .pitchBend ? 0 : message.number
    }

    init(kind: MIDIMessageKind, channel: UInt8, number: UInt8) {
        self.kind = kind
        self.channel = channel
        self.number = kind == .pitchBend ? 0 : number
    }

    func matches(_ message: MIDIMessage) -> Bool {
        kind == message.kind
            && channel == message.channel
            && (kind == .pitchBend || number == message.number)
    }

    var displayName: String {
        let channelNumber = Int(channel) + 1
        switch kind {
        case .note:
            return "Note \(number), ch \(channelNumber)"
        case .controlChange:
            return "CC \(number), ch \(channelNumber)"
        case .programChange:
            return "Program \(number), ch \(channelNumber)"
        case .pitchBend:
            return "Pitch bend, ch \(channelNumber)"
        }
    }
}

enum BridgeActionKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case focusCodex
    case newTask
    case confirm
    case cancel
    case historyBack
    case historyForward
    case showShortcuts
    case dictation
    case composerDial
    case historyDial
    case arrowDial
    case customShortcut

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .focusCodex:
            return "Focus Codex"
        case .newTask:
            return "New task"
        case .confirm:
            return "Return / confirm"
        case .cancel:
            return "Escape / cancel"
        case .historyBack:
            return "Go back"
        case .historyForward:
            return "Go forward"
        case .showShortcuts:
            return "Show Codex shortcuts"
        case .dictation:
            return "Voice dictation"
        case .composerDial:
            return "Composer dial"
        case .historyDial:
            return "History dial"
        case .arrowDial:
            return "Left / right dial"
        case .customShortcut:
            return "Custom shortcut"
        }
    }

    var helpText: String {
        switch self {
        case .focusCodex:
            return "Brings the ChatGPT / Codex app forward."
        case .newTask:
            return "Sends ⌘N after focusing Codex."
        case .confirm:
            return "Sends Return. Use this to send a prompt or activate a focused control."
        case .cancel:
            return "Sends Escape. Use this to close a menu or cancel a focused control."
        case .historyBack:
            return "Sends ⌘[ after focusing Codex."
        case .historyForward:
            return "Sends ⌘] after focusing Codex."
        case .showShortcuts:
            return "Sends ⌘/ to open Codex's shortcut reference."
        case .dictation:
            return "Sends the Codex Double Command dictation shortcut."
        case .composerDial:
            return "A knob sends Tab clockwise and Shift-Tab counterclockwise."
        case .historyDial:
            return "A knob sends ⌘] clockwise and ⌘[ counterclockwise."
        case .arrowDial:
            return "A knob sends Right clockwise and Left counterclockwise."
        case .customShortcut:
            return "Sends your shortcut after focusing Codex, for example cmd+shift+p."
        }
    }

    var isDirectional: Bool {
        switch self {
        case .composerDial, .historyDial, .arrowDial:
            return true
        default:
            return false
        }
    }
}

struct ControlMapping: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var label: String
    var trigger: MIDITrigger?
    var action: BridgeActionKind
    var customShortcut: String
    var enabled: Bool

    init(
        id: UUID = UUID(),
        label: String,
        trigger: MIDITrigger? = nil,
        action: BridgeActionKind,
        customShortcut: String = "",
        enabled: Bool = true
    ) {
        self.id = id
        self.label = label
        self.trigger = trigger
        self.action = action
        self.customShortcut = customShortcut
        self.enabled = enabled
    }
}

struct BridgeConfiguration: Codable, Equatable, Sendable {
    var version: Int
    var preferredSourceID: Int32?
    var mappings: [ControlMapping]

    static var defaultConfiguration: BridgeConfiguration {
        BridgeConfiguration(
            version: 1,
            preferredSourceID: nil,
            mappings: [
                ControlMapping(label: "Pad 1", action: .focusCodex),
                ControlMapping(label: "Pad 2", action: .newTask),
                ControlMapping(label: "Pad 3", action: .confirm),
                ControlMapping(label: "Pad 4", action: .cancel),
                ControlMapping(label: "Pad 5", action: .historyBack),
                ControlMapping(label: "Pad 6", action: .historyForward),
                ControlMapping(label: "Pad 7", action: .showShortcuts),
                ControlMapping(label: "Pad 8", action: .dictation),
                ControlMapping(label: "Knob 1", action: .composerDial),
                ControlMapping(label: "Knob 2", action: .historyDial),
                ControlMapping(label: "Knob 3", action: .arrowDial),
                ControlMapping(
                    label: "Knob 4",
                    action: .customShortcut,
                    customShortcut: "cmd+shift+p"
                )
            ]
        )
    }
}

enum DialDirection: Equatable, Sendable {
    case negative
    case positive
}

struct MappingActivation: Equatable, Sendable {
    let mappingID: UUID
    let action: BridgeActionKind
    let customShortcut: String
    let direction: DialDirection?
}

struct MIDISourceDescriptor: Identifiable, Equatable, Sendable {
    let id: Int32
    let endpoint: UInt32
    let name: String
}
