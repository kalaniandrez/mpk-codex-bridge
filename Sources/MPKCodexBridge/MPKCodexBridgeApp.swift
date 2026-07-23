import SwiftUI

@main
struct MPKCodexBridgeApp: App {
    @StateObject private var model = BridgeModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 980, height: 800)

        MenuBarExtra {
            Text(model.selectedSourceName)
            Text(model.lastMIDIMessage)
                .font(.caption)
            Divider()
            Toggle("Bridge enabled", isOn: $model.bridgeEnabled)
            Button("Focus Codex") {
                if let focusMapping = model.configuration.mappings.first(
                    where: { $0.action == .focusCodex }
                ) {
                    model.test(focusMapping)
                }
            }
            Divider()
            Button("Quit MPK Codex Bridge") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Label(
                "MPK Codex Bridge",
                systemImage: model.sources.isEmpty
                    ? "pianokeys.inverse"
                    : "pianokeys"
            )
        }
    }
}
