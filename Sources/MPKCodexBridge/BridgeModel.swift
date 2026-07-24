import Combine
import Foundation

@MainActor
final class BridgeModel: ObservableObject {
    @Published private(set) var configuration: BridgeConfiguration
    @Published private(set) var sources: [MIDISourceDescriptor] = []
    @Published private(set) var lastMIDIMessage = "Waiting for MIDI…"
    @Published private(set) var lastAction = "No action yet"
    @Published private(set) var errorMessage: String?
    @Published var learningMappingID: UUID?
    @Published var bridgeEnabled = true

    let actionExecutor: ActionExecutor

    private let midiService: MIDIService
    private let store: ConfigurationStore
    private var mappingEngine = MappingEngine()
    private var lastActivationDates: [UUID: Date] = [:]

    init(
        midiService: MIDIService = MIDIService(),
        store: ConfigurationStore = ConfigurationStore(),
        actionExecutor: ActionExecutor = ActionExecutor()
    ) {
        self.midiService = midiService
        self.store = store
        self.actionExecutor = actionExecutor
        configuration = store.load()

        midiService.onSourcesChanged = { [weak self] sources in
            self?.handleSourcesChanged(sources)
        }
        midiService.onMessage = { [weak self] message in
            self?.handle(message)
        }
        midiService.onError = { [weak self] message in
            self?.errorMessage = message
        }

        handleSourcesChanged(midiService.availableSources())
    }

    var selectedSourceID: Int32? {
        configuration.preferredSourceID
    }

    var selectedSourceName: String {
        sources.first(where: { $0.id == selectedSourceID })?.name
            ?? "No MIDI input"
    }

    var isAccessibilityTrusted: Bool {
        actionExecutor.isAccessibilityTrusted
    }

    func selectSource(_ sourceID: Int32?) {
        configuration.preferredSourceID = sourceID
        persist()
        midiService.connect(to: sourceID)
    }

    func startLearning(_ mappingID: UUID) {
        learningMappingID = mappingID
        errorMessage = nil
    }

    func cancelLearning() {
        learningMappingID = nil
    }

    func clearTrigger(_ mappingID: UUID) {
        mutateMapping(mappingID) { mapping in
            mapping.trigger = nil
        }
    }

    func setEnabled(_ enabled: Bool, for mappingID: UUID) {
        mutateMapping(mappingID) { mapping in
            mapping.enabled = enabled
        }
    }

    func setAction(_ action: BridgeActionKind, for mappingID: UUID) {
        mutateMapping(mappingID) { mapping in
            mapping.action = action
        }
    }

    func setCustomShortcut(_ shortcut: String, for mappingID: UUID) {
        mutateMapping(mappingID) { mapping in
            mapping.customShortcut = shortcut
        }
    }

    func resetMappings() {
        let sourceID = configuration.preferredSourceID
        configuration = .defaultConfiguration
        configuration.preferredSourceID = sourceID
        learningMappingID = nil
        persist()
    }

    func test(_ mapping: ControlMapping) {
        let activation = MappingActivation(
            mappingID: mapping.id,
            action: mapping.action,
            customShortcut: mapping.customShortcut,
            direction: mapping.action.isDirectional ? .positive : nil
        )
        run(activation)
    }

    func requestAccessibilityAccess() {
        actionExecutor.requestAccessibilityAccess()
    }

    func dismissError() {
        errorMessage = nil
    }

    private func handleSourcesChanged(_ newSources: [MIDISourceDescriptor]) {
        sources = newSources

        if
            let preferredSourceID = configuration.preferredSourceID,
            newSources.contains(where: { $0.id == preferredSourceID })
        {
            midiService.connect(to: preferredSourceID)
            return
        }

        let automaticSource = newSources.first {
            let lowercaseName = $0.name.lowercased()
            return lowercaseName.contains("mpk")
                || lowercaseName.contains("akai")
        } ?? newSources.first

        if let automaticSource {
            selectSource(automaticSource.id)
        } else {
            configuration.preferredSourceID = nil
        }
    }

    private func handle(_ message: MIDIMessage) {
        lastMIDIMessage = message.summary

        if let learningMappingID, message.canBeLearned {
            mutateMapping(learningMappingID) { mapping in
                mapping.trigger = MIDITrigger(message: message)
            }
            self.learningMappingID = nil
            lastAction = "Learned \(message.summary)"
            return
        }

        guard bridgeEnabled else {
            return
        }

        let activations = mappingEngine.activations(
            for: message,
            mappings: configuration.mappings
        )
        for activation in activations where shouldRun(activation) {
            run(activation)
        }
    }

    private func shouldRun(_ activation: MappingActivation) -> Bool {
        let now = Date()
        let minimumInterval = activation.action.isDirectional ? 0.075 : 0.2
        if
            let lastDate = lastActivationDates[activation.mappingID],
            now.timeIntervalSince(lastDate) < minimumInterval
        {
            return false
        }
        lastActivationDates[activation.mappingID] = now
        return true
    }

    private func run(_ activation: MappingActivation) {
        Task { [weak self] in
            guard let self else {
                return
            }
            lastAction = await actionExecutor.perform(activation)
        }
    }

    private func mutateMapping(
        _ mappingID: UUID,
        mutation: (inout ControlMapping) -> Void
    ) {
        guard let index = configuration.mappings.firstIndex(
            where: { $0.id == mappingID }
        ) else {
            return
        }
        mutation(&configuration.mappings[index])
        persist()
    }

    private func persist() {
        do {
            try store.save(configuration)
        } catch {
            errorMessage = "Could not save the mapping: \(error.localizedDescription)"
        }
    }
}
