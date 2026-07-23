import Foundation

final class MIDIByteStreamParser {
    private var runningStatus: UInt8?
    private var pendingData: [UInt8] = []

    func consume(_ bytes: [UInt8]) -> [MIDIMessage] {
        var messages: [MIDIMessage] = []

        for byte in bytes {
            if byte >= 0xF8 {
                // Realtime messages can appear between channel-message bytes.
                continue
            }

            if byte & 0x80 != 0 {
                if byte >= 0xF0 {
                    runningStatus = nil
                    pendingData.removeAll(keepingCapacity: true)
                    continue
                }

                runningStatus = byte
                pendingData.removeAll(keepingCapacity: true)
                continue
            }

            guard let status = runningStatus else {
                continue
            }

            pendingData.append(byte)
            let expectedCount = MIDIByteStreamParser.dataByteCount(for: status)
            guard pendingData.count >= expectedCount else {
                continue
            }

            if let message = MIDIByteStreamParser.decode(
                status: status,
                data: Array(pendingData.prefix(expectedCount))
            ) {
                messages.append(message)
            }
            pendingData.removeFirst(expectedCount)
        }

        return messages
    }

    func reset() {
        runningStatus = nil
        pendingData.removeAll(keepingCapacity: false)
    }

    private static func dataByteCount(for status: UInt8) -> Int {
        switch status & 0xF0 {
        case 0xC0, 0xD0:
            return 1
        default:
            return 2
        }
    }

    private static func decode(status: UInt8, data: [UInt8]) -> MIDIMessage? {
        let kind = status & 0xF0
        let channel = status & 0x0F

        switch kind {
        case 0x80:
            return MIDIMessage(
                kind: .note,
                channel: channel,
                number: data[0],
                value: Int(data[1]),
                phase: .ended
            )
        case 0x90:
            let velocity = Int(data[1])
            return MIDIMessage(
                kind: .note,
                channel: channel,
                number: data[0],
                value: velocity,
                phase: velocity == 0 ? .ended : .began
            )
        case 0xB0:
            return MIDIMessage(
                kind: .controlChange,
                channel: channel,
                number: data[0],
                value: Int(data[1]),
                phase: .changed
            )
        case 0xC0:
            return MIDIMessage(
                kind: .programChange,
                channel: channel,
                number: data[0],
                value: Int(data[0]),
                phase: .began
            )
        case 0xE0:
            let value = Int(data[0]) | (Int(data[1]) << 7)
            return MIDIMessage(
                kind: .pitchBend,
                channel: channel,
                number: 0,
                value: value,
                phase: .changed
            )
        default:
            return nil
        }
    }
}

struct MappingEngine {
    private var previousValues: [MIDITrigger: Int] = [:]

    mutating func activations(
        for message: MIDIMessage,
        mappings: [ControlMapping]
    ) -> [MappingActivation] {
        let matchingMappings = mappings.filter {
            $0.enabled && $0.trigger?.matches(message) == true
        }
        guard !matchingMappings.isEmpty else {
            recordValueIfContinuous(message)
            return []
        }

        let trigger = MIDITrigger(message: message)
        let previousValue = previousValues[trigger]
        recordValueIfContinuous(message)

        return matchingMappings.compactMap { mapping in
            if mapping.action.isDirectional {
                guard let direction = direction(
                    for: message,
                    previousValue: previousValue
                ) else {
                    return nil
                }
                return MappingActivation(
                    mappingID: mapping.id,
                    action: mapping.action,
                    customShortcut: mapping.customShortcut,
                    direction: direction
                )
            }

            guard shouldFireDiscrete(
                message,
                previousValue: previousValue
            ) else {
                return nil
            }
            return MappingActivation(
                mappingID: mapping.id,
                action: mapping.action,
                customShortcut: mapping.customShortcut,
                direction: nil
            )
        }
    }

    private mutating func recordValueIfContinuous(_ message: MIDIMessage) {
        switch message.kind {
        case .controlChange, .pitchBend:
            previousValues[MIDITrigger(message: message)] = message.value
        case .note, .programChange:
            break
        }
    }

    private func shouldFireDiscrete(
        _ message: MIDIMessage,
        previousValue: Int?
    ) -> Bool {
        switch message.kind {
        case .note:
            return message.phase == .began && message.value > 0
        case .controlChange:
            // Supports pads configured as CC buttons without firing repeatedly
            // while an absolute knob is moving.
            return message.value > 0 && (previousValue == nil || previousValue == 0)
        case .programChange:
            return true
        case .pitchBend:
            guard let previousValue else {
                return false
            }
            return previousValue < 8_192 && message.value >= 8_192
        }
    }

    private func direction(
        for message: MIDIMessage,
        previousValue: Int?
    ) -> DialDirection? {
        switch message.kind {
        case .controlChange, .pitchBend:
            guard let previousValue, previousValue != message.value else {
                return nil
            }
            return message.value > previousValue ? .positive : .negative
        case .note, .programChange:
            return nil
        }
    }
}
