import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var botManager: BotManager
    @State private var editableConfig: BotConfig = BotConfig()
    @State private var hasChanges = false
    @State private var showSaveAlert = false
    @State private var showTokenField = false
    @State private var showProjectPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Configuration")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Manage your OpenFox bot settings")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    HStack(spacing: 12) {
                        Button("Reload") {
                            botManager.loadConfig()
                            editableConfig = botManager.config
                            hasChanges = false
                        }
                        .buttonStyle(.bordered)

                        Button("Save") {
                            botManager.config = editableConfig
                            botManager.saveConfig()
                            hasChanges = false
                            showSaveAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(!hasChanges)
                    }
                }
                .padding(.bottom, 8)

                // Project path
                ConfigSection(title: "Project", icon: "folder.fill", color: .brown) {
                    HStack {
                        Text(botManager.projectDirectory)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button("Change...") {
                            pickProjectFolder()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                // Telegram section
                ConfigSection(title: "Telegram", icon: "paperplane.fill", color: .blue) {
                    VStack(spacing: 16) {
                        ConfigField(label: "Bot Token", icon: "key.fill") {
                            HStack {
                                if showTokenField {
                                    TextField("Enter your Telegram bot token", text: binding(\.botToken))
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 13, design: .monospaced))
                                } else {
                                    Text(editableConfig.maskedToken.isEmpty ? "Not configured" : editableConfig.maskedToken)
                                        .font(.system(size: 13, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(showTokenField ? "Hide" : "Show") {
                                    showTokenField.toggle()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }

                        ConfigField(label: "Allow Groups", icon: "person.3.fill") {
                            Toggle("", isOn: binding(\.allowGroups))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }

                        ConfigField(label: "Skip Pending Updates", icon: "forward.fill") {
                            Toggle("", isOn: binding(\.skipPendingUpdates))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }
                }

                // Model section
                ConfigSection(title: "AI Model", icon: "cpu.fill", color: .purple) {
                    VStack(spacing: 16) {
                        ConfigField(label: "Model", icon: "brain") {
                            TextField("e.g. lm-studio/llama2", text: binding(\.opencodeModel))
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                        }

                        ConfigField(label: "Thinking Variant", icon: "sparkles") {
                            Picker("", selection: binding(\.opencodeVariant)) {
                                Text("Low").tag("low")
                                Text("Medium").tag("medium")
                                Text("High").tag("high")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 240)
                        }

                        ConfigField(label: "Permission Mode", icon: "lock.shield.fill") {
                            Picker("", selection: binding(\.opencodePermissionMode)) {
                                Text("Ask").tag("ask")
                                Text("Allow").tag("allow")
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }
                    }
                }

                // Advanced section
                ConfigSection(title: "Advanced", icon: "wrench.and.screwdriver.fill", color: .gray) {
                    VStack(spacing: 16) {
                        ConfigField(label: "Poll Timeout (seconds)", icon: "clock") {
                            TextField("30", value: binding(\.pollTimeout), format: .number)
                                .textFieldStyle(.plain)
                                .frame(width: 80)
                        }

                        ConfigField(label: "Opencode Timeout (ms)", icon: "timer") {
                            TextField("600000", value: binding(\.opencodeTimeout), format: .number)
                                .textFieldStyle(.plain)
                                .frame(width: 100)
                        }

                        ConfigField(label: "Webhook Port", icon: "network") {
                            TextField("3000", value: binding(\.port), format: .number)
                                .textFieldStyle(.plain)
                                .frame(width: 80)
                        }

                        ConfigField(label: "Delete Webhook on Start", icon: "xmark.circle") {
                            Toggle("", isOn: binding(\.deleteWebhookOnStart))
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .onAppear {
            editableConfig = botManager.config
        }
        .alert("Configuration Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your settings have been saved to .env file.\nRestart the bot for changes to take effect.")
        }
    }

    private func binding<T: Equatable>(_ keyPath: WritableKeyPath<BotConfig, T>) -> Binding<T> {
        Binding(
            get: { editableConfig[keyPath: keyPath] },
            set: { newValue in
                editableConfig[keyPath: keyPath] = newValue
                hasChanges = editableConfig[keyPath: keyPath] != botManager.config[keyPath: keyPath]
                // Simple change detection
                hasChanges = true
            }
        )
    }

    private func pickProjectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select the OpenFox project directory"
        panel.prompt = "Select"
        if panel.runModal() == .OK, let url = panel.url {
            botManager.setProjectPath(url.path)
            editableConfig = botManager.config
        }
    }
}

struct ConfigSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
    }
}

struct ConfigField<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 180, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
