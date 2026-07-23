import CoreMIDI
import Foundation

final class MIDIService: @unchecked Sendable {
    var onSourcesChanged: (@MainActor @Sendable ([MIDISourceDescriptor]) -> Void)?
    var onMessage: (@MainActor @Sendable (MIDIMessage) -> Void)?
    var onError: (@MainActor @Sendable (String) -> Void)?

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var connectedEndpoint = MIDIEndpointRef()
    private var parser = MIDIByteStreamParser()
    private let parserQueue = DispatchQueue(label: "com.kalani.mpk-codex-bridge.midi")

    init() {
        let clientStatus = MIDIClientCreateWithBlock(
            "MPK Codex Bridge" as CFString,
            &client
        ) { [weak self] _ in
            self?.publishSources()
        }

        guard clientStatus == noErr else {
            publishError("Could not create the CoreMIDI client (\(clientStatus)).")
            return
        }

        let portStatus = MIDIInputPortCreateWithBlock(
            client,
            "MPK Codex Bridge Input" as CFString,
            &inputPort
        ) { [weak self] packetList, _ in
            self?.receive(packetList)
        }

        guard portStatus == noErr else {
            publishError("Could not create the MIDI input port (\(portStatus)).")
            return
        }

        publishSources()
    }

    deinit {
        if connectedEndpoint != 0, inputPort != 0 {
            MIDIPortDisconnectSource(inputPort, connectedEndpoint)
        }
        if inputPort != 0 {
            MIDIPortDispose(inputPort)
        }
        if client != 0 {
            MIDIClientDispose(client)
        }
    }

    func availableSources() -> [MIDISourceDescriptor] {
        let count = MIDIGetNumberOfSources()
        return (0..<count).compactMap { index in
            let endpoint = MIDIGetSource(index)
            guard endpoint != 0 else {
                return nil
            }

            var uniqueID: Int32 = 0
            MIDIObjectGetIntegerProperty(
                endpoint,
                kMIDIPropertyUniqueID,
                &uniqueID
            )

            var unmanagedName: Unmanaged<CFString>?
            let nameStatus = MIDIObjectGetStringProperty(
                endpoint,
                kMIDIPropertyDisplayName,
                &unmanagedName
            )
            let name: String
            if nameStatus == noErr, let unmanagedName {
                name = unmanagedName.takeRetainedValue() as String
            } else {
                name = "MIDI Source \(index + 1)"
            }

            return MIDISourceDescriptor(
                id: uniqueID,
                endpoint: endpoint,
                name: name
            )
        }
    }

    func connect(to sourceID: Int32?) {
        if connectedEndpoint != 0 {
            MIDIPortDisconnectSource(inputPort, connectedEndpoint)
            connectedEndpoint = 0
        }
        parserQueue.async { [weak self] in
            self?.parser.reset()
        }

        guard
            let sourceID,
            let source = availableSources().first(where: { $0.id == sourceID })
        else {
            return
        }

        let endpoint = MIDIEndpointRef(source.endpoint)
        let status = MIDIPortConnectSource(inputPort, endpoint, nil)
        guard status == noErr else {
            publishError("Could not connect to \(source.name) (\(status)).")
            return
        }
        connectedEndpoint = endpoint
    }

    private func publishSources() {
        let sources = availableSources()
        Task { @MainActor [weak self] in
            self?.onSourcesChanged?(sources)
        }
    }

    private func publishError(_ message: String) {
        Task { @MainActor [weak self] in
            self?.onError?(message)
        }
    }

    private func receive(_ packetList: UnsafePointer<MIDIPacketList>) {
        let numPackets = Int(packetList.pointee.numPackets)
        guard
            numPackets > 0,
            let packetOffset = MemoryLayout<MIDIPacketList>.offset(of: \.packet)
        else {
            return
        }

        var packetPointer = UnsafeMutableRawPointer(mutating: packetList)
            .advanced(by: packetOffset)
            .assumingMemoryBound(to: MIDIPacket.self)
        var byteGroups: [[UInt8]] = []
        byteGroups.reserveCapacity(numPackets)

        for _ in 0..<numPackets {
            let packet = packetPointer.pointee
            let bytes = withUnsafeBytes(of: packet.data) {
                Array($0.prefix(Int(packet.length)))
            }
            byteGroups.append(bytes)
            packetPointer = MIDIPacketNext(packetPointer)
        }

        let capturedByteGroups = byteGroups
        parserQueue.async { [weak self, capturedByteGroups] in
            guard let self else {
                return
            }
            for bytes in capturedByteGroups {
                for message in parser.consume(bytes) {
                    Task { @MainActor [weak self] in
                        self?.onMessage?(message)
                    }
                }
            }
        }
    }
}
