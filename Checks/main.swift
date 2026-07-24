import CoreGraphics
import Darwin
import Foundation

var passedChecks = 0
var failedChecks: [String] = []

func expect(_ condition: @autoclosure () -> Bool, _ name: String) {
    if condition() {
        passedChecks += 1
        print("PASS  \(name)")
    } else {
        failedChecks.append(name)
        print("FAIL  \(name)")
    }
}

do {
    let parser = MIDIByteStreamParser()
    let messages = parser.consume([
        0x99, 36, 127,
        0x89, 36, 0
    ])
    expect(messages.count == 2, "note on and off count")
    expect(
        messages.first == MIDIMessage(
            kind: .note,
            channel: 9,
            number: 36,
            value: 127,
            phase: .began
        ),
        "note on fields"
    )
    expect(messages.last?.phase == .ended, "note off phase")
}

do {
    let parser = MIDIByteStreamParser()
    expect(parser.consume([0x90, 60]).isEmpty, "partial packet waits")
    let messages = parser.consume([100, 61, 101])
    expect(messages.map(\.number) == [60, 61], "running status across chunks")
    expect(messages.map(\.value) == [100, 101], "running status values")
}

do {
    let parser = MIDIByteStreamParser()
    let messages = parser.consume([0xB0, 1, 0xF8, 64])
    expect(messages.count == 1, "realtime byte ignored")
    expect(messages.first?.kind == .controlChange, "control change decoded")
    expect(messages.first?.value == 64, "control change value")
}

do {
    let parser = MIDIByteStreamParser()
    let messages = parser.consume([0xC2, 7, 0xE0, 0, 64])
    expect(messages.first?.kind == .programChange, "program change decoded")
    expect(messages.last?.value == 8_192, "pitch bend decoded")
}

do {
    let mapping = ControlMapping(
        label: "Pad",
        trigger: MIDITrigger(kind: .note, channel: 9, number: 36),
        action: .confirm
    )
    var engine = MappingEngine()
    let press = MIDIMessage(
        kind: .note,
        channel: 9,
        number: 36,
        value: 100,
        phase: .began
    )
    let release = MIDIMessage(
        kind: .note,
        channel: 9,
        number: 36,
        value: 0,
        phase: .ended
    )
    expect(
        engine.activations(for: press, mappings: [mapping]).count == 1,
        "note mapping fires on press"
    )
    expect(
        engine.activations(for: release, mappings: [mapping]).isEmpty,
        "note mapping ignores release"
    )
}

do {
    let mapping = ControlMapping(
        label: "CC Pad",
        trigger: MIDITrigger(kind: .controlChange, channel: 0, number: 20),
        action: .confirm
    )
    var engine = MappingEngine()
    func message(_ value: Int) -> MIDIMessage {
        MIDIMessage(
            kind: .controlChange,
            channel: 0,
            number: 20,
            value: value,
            phase: .changed
        )
    }
    expect(
        engine.activations(for: message(127), mappings: [mapping]).count == 1,
        "CC button fires on press"
    )
    expect(
        engine.activations(for: message(126), mappings: [mapping]).isEmpty,
        "CC button does not repeat while high"
    )
    _ = engine.activations(for: message(0), mappings: [mapping])
    expect(
        engine.activations(for: message(127), mappings: [mapping]).count == 1,
        "CC button rearms after release"
    )
}

do {
    let mapping = ControlMapping(
        label: "Knob",
        trigger: MIDITrigger(kind: .controlChange, channel: 0, number: 1),
        action: .composerDial
    )
    var engine = MappingEngine()
    func message(_ value: Int) -> MIDIMessage {
        MIDIMessage(
            kind: .controlChange,
            channel: 0,
            number: 1,
            value: value,
            phase: .changed
        )
    }
    expect(
        engine.activations(for: message(64), mappings: [mapping]).isEmpty,
        "dial establishes initial position"
    )
    expect(
        engine.activations(for: message(70), mappings: [mapping]).first?.direction
            == .positive,
        "dial detects clockwise movement"
    )
    expect(
        engine.activations(for: message(65), mappings: [mapping]).first?.direction
            == .negative,
        "dial detects counterclockwise movement"
    )
}

do {
    let expected = BridgeConfiguration.defaultConfiguration
    let data = try JSONEncoder().encode(expected)
    let decoded = try JSONDecoder().decode(BridgeConfiguration.self, from: data)
    expect(decoded == expected, "configuration round trip")
    expect(decoded.mappings.count == 12, "starter mapping count")
}

do {
    let shortcut = KeyboardShortcut.parse("cmd+shift+p")
    expect(shortcut?.keyCode == 35, "shortcut key parsed")
    expect(
        shortcut?.flags.contains(.maskCommand) == true,
        "shortcut Command parsed"
    )
    expect(
        shortcut?.flags.contains(.maskShift) == true,
        "shortcut Shift parsed"
    )
    expect(
        KeyboardShortcut.parse("hyper+banana") == nil,
        "invalid shortcut rejected"
    )
}

if failedChecks.isEmpty {
    print("\n\(passedChecks) checks passed.")
} else {
    print("\n\(failedChecks.count) checks failed:")
    for failure in failedChecks {
        print("- \(failure)")
    }
    exit(1)
}
