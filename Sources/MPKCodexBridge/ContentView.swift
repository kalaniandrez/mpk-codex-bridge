import SwiftUI

@MainActor
struct ContentView: View {
    @ObservedObject var model: BridgeModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    connectionCard
                    mappingsCard
                    activityCard
                    limitationsCard
                }
                .padding(22)
            }
        }
        .frame(minWidth: 760, idealWidth: 860, minHeight: 640)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert(
            "MPK Codex Bridge",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.dismissError() } }
            )
        ) {
            Button("OK") {
                model.dismissError()
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.mint, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "pianokeys")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.78))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text("MPK Codex Bridge")
                    .font(.title2.weight(.semibold))
                Text("Turn your Akai controls into local Codex commands")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Bridge enabled", isOn: $model.bridgeEnabled)
                .toggleStyle(.switch)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var connectionCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MIDI input")
                                .font(.headline)
                            Text(model.sources.isEmpty
                                 ? "Connect the MPK Mini Play by USB."
                                 : "Choose the controller to listen to.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: model.sources.isEmpty
                              ? "cable.connector.slash"
                              : "cable.connector")
                            .foregroundStyle(model.sources.isEmpty ? .orange : .green)
                    }

                    Spacer()

                    Picker(
                        "MIDI input",
                        selection: Binding<Int32?>(
                            get: { model.selectedSourceID },
                            set: { model.selectSource($0) }
                        )
                    ) {
                        Text("No MIDI input").tag(Int32?.none)
                        ForEach(model.sources) { source in
                            Text(source.name).tag(Int32?.some(source.id))
                        }
                    }
                    .labelsHidden()
                    .frame(width: 270)
                }

                Divider()

                HStack(alignment: .center, spacing: 14) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility")
                                .font(.headline)
                            Text(model.isAccessibilityTrusted
                                 ? "Ready to send shortcuts to Codex."
                                 : "Required to send keyboard commands.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: model.isAccessibilityTrusted
                              ? "checkmark.shield.fill"
                              : "exclamationmark.shield.fill")
                            .foregroundStyle(model.isAccessibilityTrusted ? .green : .orange)
                    }

                    Spacer()

                    if model.isAccessibilityTrusted {
                        Text("Allowed")
                            .foregroundStyle(.green)
                            .font(.callout.weight(.medium))
                    } else {
                        Button("Allow Accessibility…") {
                            model.requestAccessibilityAccess()
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private var mappingsCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Control mappings")
                            .font(.headline)
                        Text("Choose Learn, then touch one MPK pad, key, joystick direction, or knob.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Reset") {
                        model.resetMappings()
                    }
                }
                .padding(8)

                Divider()
                    .padding(.vertical, 4)

                ForEach(Array(model.configuration.mappings.enumerated()), id: \.element.id) {
                    index,
                    mapping in
                    MappingRow(
                        index: index,
                        mapping: mapping,
                        isLearning: model.learningMappingID == mapping.id,
                        setEnabled: { model.setEnabled($0, for: mapping.id) },
                        setAction: { model.setAction($0, for: mapping.id) },
                        setCustomShortcut: {
                            model.setCustomShortcut($0, for: mapping.id)
                        },
                        learn: {
                            if model.learningMappingID == mapping.id {
                                model.cancelLearning()
                            } else {
                                model.startLearning(mapping.id)
                            }
                        },
                        clear: { model.clearTrigger(mapping.id) },
                        test: { model.test(mapping) }
                    )

                    if index < model.configuration.mappings.count - 1 {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
        }
    }

    private var activityCard: some View {
        GroupBox {
            HStack(spacing: 24) {
                activityColumn(
                    title: "Last MIDI",
                    value: model.lastMIDIMessage,
                    icon: "waveform"
                )
                Divider()
                    .frame(height: 42)
                activityColumn(
                    title: "Last action",
                    value: model.lastAction,
                    icon: "bolt.fill"
                )
            }
            .padding(8)
        }
    }

    private var limitationsCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
            Text(
                "This bridge controls the installed Codex app locally and uses no OpenAI API key. "
                + "Codex Micro's live task-status lights and hardware-only approval integration "
                + "are not exposed to third-party MIDI devices."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private func activityColumn(
        title: String,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.mint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.monospaced())
                    .lineLimit(1)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
private struct MappingRow: View {
    let index: Int
    let mapping: ControlMapping
    let isLearning: Bool
    let setEnabled: (Bool) -> Void
    let setAction: (BridgeActionKind) -> Void
    let setCustomShortcut: (String) -> Void
    let learn: () -> Void
    let clear: () -> Void
    let test: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle(
                "",
                isOn: Binding(
                    get: { mapping.enabled },
                    set: { setEnabled($0) }
                )
            )
            .labelsHidden()
            .toggleStyle(.checkbox)

            Text("\(index + 1)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(mapping.label)
                    .font(.callout.weight(.semibold))
                Text(mapping.trigger?.displayName ?? "Not learned")
                    .font(.caption.monospaced())
                    .foregroundStyle(mapping.trigger == nil ? .orange : .secondary)
            }
            .frame(width: 145, alignment: .leading)

            Picker(
                "Action",
                selection: Binding(
                    get: { mapping.action },
                    set: { setAction($0) }
                )
            ) {
                ForEach(BridgeActionKind.allCases) { action in
                    Text(action.displayName).tag(action)
                }
            }
            .labelsHidden()
            .frame(width: 190)
            .help(mapping.action.helpText)

            if mapping.action == .customShortcut {
                TextField(
                    "cmd+shift+p",
                    text: Binding(
                        get: { mapping.customShortcut },
                        set: { setCustomShortcut($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .font(.callout.monospaced())
                .frame(minWidth: 130)
            } else {
                Text(mapping.action.helpText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(minWidth: 130, alignment: .leading)
            }

            Spacer(minLength: 4)

            Button(isLearning ? "Listening…" : "Learn") {
                learn()
            }
            .buttonStyle(.borderedProminent)
            .tint(isLearning ? .orange : .accentColor)

            Menu {
                Button("Test action", action: test)
                Button("Clear MIDI trigger", action: clear)
                    .disabled(mapping.trigger == nil)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 26)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 9)
        .opacity(mapping.enabled ? 1 : 0.55)
    }
}
