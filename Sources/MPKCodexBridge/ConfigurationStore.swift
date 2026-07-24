import Foundation

struct ConfigurationStore {
    let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            return
        }

        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        self.fileURL = baseURL
            .appendingPathComponent("MPK Codex Bridge", isDirectory: true)
            .appendingPathComponent("configuration.json")
    }

    func load() -> BridgeConfiguration {
        guard
            let data = try? Data(contentsOf: fileURL),
            let configuration = try? JSONDecoder().decode(
                BridgeConfiguration.self,
                from: data
            )
        else {
            return .defaultConfiguration
        }
        return configuration
    }

    func save(_ configuration: BridgeConfiguration) throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(configuration)
        try data.write(to: fileURL, options: .atomic)
    }
}
