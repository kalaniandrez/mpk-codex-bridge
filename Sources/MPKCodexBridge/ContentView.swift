import AppKit
import SwiftUI

@MainActor
struct ContentView: View {
    @ObservedObject var model: BridgeModel
    @State private var reelMode = false

    var body: some View {
        ZStack {
            BridgeTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Divider()
                    .overlay(Color.white.opacity(0.08))

                if reelMode {
                    reelDashboard
                } else {
                    setupDashboard
                }
            }
        }
        .frame(minWidth: 820, idealWidth: 980, minHeight: 680)
        .tint(BridgeTheme.cyan)
        .preferredColorScheme(.dark)
        .onAppear {
            model.refreshAccessibilityStatus()
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: NSApplication.didBecomeActiveNotification
            )
        ) { _ in
            model.refreshAccessibilityStatus()
        }
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
            if let icon = NSApplication.shared.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 54, height: 54)
                    .shadow(color: BridgeTheme.cyan.opacity(0.22), radius: 14)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("MPK Codex Bridge")
                        .font(.title2.weight(.bold))
                    StatusPill(
                        text: "v1.0",
                        color: Color.white.opacity(0.55)
                    )
                    StatusPill(
                        text: "LOCAL ONLY",
                        color: BridgeTheme.cyan
                    )
                }
                Text("Turn a MIDI controller into a tactile command deck for Codex")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusPill(
                text: model.isReady ? "READY" : "SETUP \(model.setupCompletedSteps)/3",
                color: model.isReady ? BridgeTheme.green : BridgeTheme.orange,
                filled: true
            )

            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    reelMode.toggle()
                }
            } label: {
                Label(
                    reelMode ? "Setup view" : "Reel view",
                    systemImage: reelMode ? "slider.horizontal.3" : "play.rectangle.fill"
                )
            }
            .buttonStyle(.bordered)

            Toggle("Bridge enabled", isOn: $model.bridgeEnabled)
                .toggleStyle(.switch)
                .help("Pause or resume MIDI-triggered actions.")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 15)
        .background(Color.black.opacity(0.14))
    }

    private var setupDashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                setupCard
                activityCard
                mappingsCard
                knobHelpCard
                limitationsCard
            }
            .padding(22)
        }
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Three steps to ready")
                        .font(.headline)
                    Text("The bridge stays on your Mac. No account, API key, or network request.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(model.learnedMappingsCount) of \(model.configuration.mappings.count) controls learned")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                SetupStep(
                    number: 1,
                    title: "Connect MIDI",
                    detail: model.selectedSourceName,
                    complete: model.selectedSourceID != nil,
                    icon: "cable.connector"
                ) {
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
                    .frame(maxWidth: 205)
                }

                SetupStep(
                    number: 2,
                    title: "Allow control",
                    detail: model.isAccessibilityTrusted
                        ? "Accessibility allowed"
                        : "Required for shortcuts",
                    complete: model.isAccessibilityTrusted,
                    icon: "checkmark.shield"
                ) {
                    if model.isAccessibilityTrusted {
                        Text("ALLOWED")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(BridgeTheme.green)
                    } else {
                        Button("Allow…") {
                            model.requestAccessibilityAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

                SetupStep(
                    number: 3,
                    title: "Learn controls",
                    detail: model.learnedMappingsCount == 0
                        ? "Teach the first pad"
                        : "\(model.learnedMappingsCount) mappings ready",
                    complete: model.learnedMappingsCount > 0,
                    icon: "pianokeys"
                ) {
                    Text(model.learnedMappingsCount > 0 ? "ACTIVE" : "START BELOW")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            model.learnedMappingsCount > 0
                                ? BridgeTheme.green
                                : BridgeTheme.orange
                        )
                }
            }
        }
        .bridgeCard()
    }

    private var activityCard: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(model.selectedSourceID == nil
                              ? BridgeTheme.orange
                              : BridgeTheme.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE MIDI")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                }
                Text(model.lastMIDIMessage)
                    .font(.title3.monospaced().weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 54)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(BridgeTheme.coral)
                    Text("LAST ACTION")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                }
                Text(model.lastAction)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .bridgeCard()
    }

    private var mappingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Control mappings")
                        .font(.headline)
                    Text("Choose Learn, then move exactly one control. Every action focuses Codex first.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reset starter layout") {
                    model.resetMappings()
                }
            }

            mappingSection(
                title: "PADS & KEYS",
                subtitle: "Press once to trigger an action",
                indices: Array(model.configuration.mappings.indices.prefix(8))
            )

            mappingSection(
                title: "KNOBS",
                subtitle: "Turn INTERNAL SOUNDS off, then rotate each knob",
                indices: Array(model.configuration.mappings.indices.dropFirst(8))
            )
        }
        .bridgeCard()
    }

    @ViewBuilder
    private func mappingSection(
        title: String,
        subtitle: String,
        indices: [Int]
    ) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundStyle(BridgeTheme.cyan)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top, 2)

        VStack(spacing: 7) {
            ForEach(indices, id: \.self) { index in
                let mapping = model.configuration.mappings[index]
                MappingRow(
                    index: index,
                    mapping: mapping,
                    isLearning: model.learningMappingID == mapping.id,
                    isActive: model.lastTriggeredMappingID == mapping.id,
                    learningHint: model.learningMappingID == mapping.id
                        ? model.learningHint
                        : nil,
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
            }
        }
    }

    private var knobHelpCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(BridgeTheme.orange.opacity(0.14))
                Image(systemName: "dial.medium.fill")
                    .font(.title2)
                    .foregroundStyle(BridgeTheme.orange)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text("MPK Mini Play knob setup")
                    .font(.headline)
                Text(
                    "Turn INTERNAL SOUNDS off before learning Filter, Resonance, "
                    + "Reverb, and Chorus. A successful knob reads CC. "
                    + "The separate Volume control is audio-only and cannot send MIDI."
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                ForEach(["FILTER", "RESONANCE", "REVERB", "CHORUS"], id: \.self) {
                    label in
                    StatusPill(text: label, color: BridgeTheme.orange)
                }
            }
        }
        .bridgeCard()
    }

    private var limitationsCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(BridgeTheme.cyan)
            Text(
                "This independent utility recreates the command-controller idea, "
                + "not Codex Micro's private hardware identity, task-status lights, "
                + "or approval integration. It is not affiliated with OpenAI or Akai."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var reelDashboard: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    StatusPill(
                        text: model.selectedSourceID == nil
                            ? "MIDI DISCONNECTED"
                            : "\(model.selectedSourceName.uppercased()) CONNECTED",
                        color: model.selectedSourceID == nil
                            ? BridgeTheme.orange
                            : BridgeTheme.green,
                        filled: true
                    )
                    Spacer()
                    StatusPill(
                        text: "PRIVATE • LOCAL • REMAPPABLE",
                        color: BridgeTheme.cyan
                    )
                }

                VStack(spacing: 8) {
                    Text("MIDI  →  CODEX")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .tracking(2)
                    Text("One controller. Twelve commands. Zero API keys.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 10)

                HStack(spacing: 14) {
                    ReelMetric(
                        label: "LIVE MIDI",
                        value: model.lastMIDIMessage,
                        color: BridgeTheme.cyan
                    )
                    ReelMetric(
                        label: "CODEX ACTION",
                        value: model.lastAction,
                        color: BridgeTheme.coral
                    )
                }

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 10),
                        count: 4
                    ),
                    spacing: 10
                ) {
                    ForEach(model.configuration.mappings) { mapping in
                        MappingTile(
                            mapping: mapping,
                            isActive: model.lastTriggeredMappingID == mapping.id
                        )
                    }
                }

                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(BridgeTheme.green)
                    Text("No cloud bridge. No telemetry. Your mappings stay on this Mac.")
                        .font(.callout.weight(.medium))
                    Spacer()
                    Toggle("Bridge", isOn: $model.bridgeEnabled)
                        .toggleStyle(.switch)
                }
                .bridgeCard()
            }
            .padding(28)
        }
    }
}

@MainActor
private struct MappingRow: View {
    let index: Int
    let mapping: ControlMapping
    let isLearning: Bool
    let isActive: Bool
    let learningHint: String?
    let setEnabled: (Bool) -> Void
    let setAction: (BridgeActionKind) -> Void
    let setCustomShortcut: (String) -> Void
    let learn: () -> Void
    let clear: () -> Void
    let test: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 11) {
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
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    Text(mapping.label)
                        .font(.callout.weight(.semibold))
                    HStack(spacing: 6) {
                        if let trigger = mapping.trigger {
                            StatusPill(
                                text: trigger.kind.badgeText,
                                color: trigger.kind.isContinuous
                                    ? BridgeTheme.cyan
                                    : Color.white.opacity(0.6)
                            )
                        }
                        Text(mapping.trigger?.displayName ?? "Not learned")
                            .font(.caption.monospaced())
                            .foregroundStyle(
                                mapping.trigger == nil
                                    ? BridgeTheme.orange
                                    : Color.secondary
                            )
                    }
                }
                .frame(width: 175, alignment: .leading)

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
                    .frame(minWidth: 145)
                } else {
                    Text(mapping.action.helpText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(minWidth: 145, alignment: .leading)
                }

                Spacer(minLength: 4)

                Button(isLearning ? "Listening…" : "Learn") {
                    learn()
                }
                .buttonStyle(.borderedProminent)
                .tint(isLearning ? BridgeTheme.orange : BridgeTheme.cyan)

                Menu {
                    Button("Test action", action: test)
                    Button("Clear MIDI trigger", action: clear)
                        .disabled(mapping.trigger == nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 28)
            }

            if let issue = mapping.compatibilityIssue {
                InlineNotice(
                    text: issue,
                    icon: "exclamationmark.triangle.fill",
                    color: BridgeTheme.orange
                )
                .padding(.leading, 43)
            } else if let learningHint {
                InlineNotice(
                    text: learningHint,
                    icon: mapping.expectsContinuousInput
                        ? "dial.medium.fill"
                        : "waveform",
                    color: BridgeTheme.cyan
                )
                .padding(.leading, 43)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 10)
        .background(
            isActive
                ? BridgeTheme.cyan.opacity(0.13)
                : Color.white.opacity(0.025),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isActive
                        ? BridgeTheme.cyan.opacity(0.7)
                        : Color.white.opacity(0.06),
                    lineWidth: isActive ? 1.5 : 1
                )
        }
        .opacity(mapping.enabled ? 1 : 0.52)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

private struct SetupStep<Accessory: View>: View {
    let number: Int
    let title: String
    let detail: String
    let complete: Bool
    let icon: String
    let accessory: Accessory

    init(
        number: Int,
        title: String,
        detail: String,
        complete: Bool,
        icon: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.number = number
        self.title = title
        self.detail = detail
        self.complete = complete
        self.icon = icon
        self.accessory = accessory()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            complete
                                ? BridgeTheme.green.opacity(0.18)
                                : Color.white.opacity(0.06)
                        )
                    Image(systemName: complete ? "checkmark" : icon)
                        .font(.callout.weight(.bold))
                        .foregroundStyle(
                            complete ? BridgeTheme.green : BridgeTheme.cyan
                        )
                }
                .frame(width: 32, height: 32)

                Text("0\(number)")
                    .font(.caption2.monospaced().weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            accessory
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .topLeading)
        .background(
            Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    complete
                        ? BridgeTheme.green.opacity(0.28)
                        : Color.white.opacity(0.07)
                )
        }
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color
    var filled = false

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(filled ? Color.black.opacity(0.82) : color)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                filled ? color : color.opacity(0.12),
                in: Capsule()
            )
            .overlay {
                if !filled {
                    Capsule()
                        .stroke(color.opacity(0.28), lineWidth: 1)
                }
            }
    }
}

private struct InlineNotice: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .foregroundStyle(color)
    }
}

private struct ReelMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(label)
                .font(.caption2.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.weight(.bold))
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 74, alignment: .topLeading)
        .bridgeCard()
    }
}

private struct MappingTile: View {
    let mapping: ControlMapping
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(mapping.shortLabel)
                    .font(.caption.weight(.bold))
                    .lineLimit(2)
                Spacer()
                Circle()
                    .fill(
                        mapping.trigger == nil
                            ? Color.white.opacity(0.18)
                            : BridgeTheme.green
                    )
                    .frame(width: 7, height: 7)
            }
            Text(mapping.action.displayName)
                .font(.callout.weight(.semibold))
                .foregroundStyle(isActive ? Color.white : Color.secondary)
                .lineLimit(1)
            Text(mapping.trigger?.displayName ?? "Not learned")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(13)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .background(
            isActive
                ? BridgeTheme.cyan.opacity(0.2)
                : Color.white.opacity(0.035),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isActive
                        ? BridgeTheme.cyan
                        : Color.white.opacity(0.07),
                    lineWidth: isActive ? 2 : 1
                )
        }
        .shadow(
            color: isActive ? BridgeTheme.cyan.opacity(0.22) : .clear,
            radius: 16
        )
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }
}

private enum BridgeTheme {
    static let cyan = Color(red: 0.18, green: 0.89, blue: 0.93)
    static let green = Color(red: 0.33, green: 0.91, blue: 0.60)
    static let orange = Color(red: 1.00, green: 0.65, blue: 0.30)
    static let coral = Color(red: 1.00, green: 0.47, blue: 0.38)
    static let background = LinearGradient(
        colors: [
            Color(red: 0.025, green: 0.075, blue: 0.13),
            Color(red: 0.025, green: 0.045, blue: 0.075),
            Color(red: 0.055, green: 0.035, blue: 0.065)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

private struct BridgeCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                Color.white.opacity(0.045),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

private extension View {
    func bridgeCard() -> some View {
        modifier(BridgeCardModifier())
    }
}
