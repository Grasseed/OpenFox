import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var botManager: BotManager
    @EnvironmentObject var locale: LocaleManager
    @StateObject private var modelService = ModelService.shared
    @State private var editableConfig: BotConfig = BotConfig()
    @State private var hasChanges = false
    @State private var showSaveAlert = false
    @State private var showTokenField = false
    @State private var selectedProvider: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locale.t(.cfgTitle))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text(locale.t(.cfgSubtitle))
                            .font(.system(size: 14)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button(locale.t(.btnReload)) {
                            botManager.loadConfig()
                            editableConfig = botManager.config
                            hasChanges = false
                        }
                        .buttonStyle(.bordered)

                        Button(locale.t(.btnSave)) {
                            botManager.config = editableConfig
                            botManager.saveConfig()
                            hasChanges = false
                            showSaveAlert = true
                        }
                        .buttonStyle(.borderedProminent).tint(.orange).disabled(!hasChanges)
                    }
                }
                .padding(.bottom, 8)

                // Project path
                ConfigSection(title: locale.t(.cfgProject), icon: "folder.fill", color: .brown) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(botManager.projectDirectory)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button(locale.t(.btnChange)) { pickProjectFolder() }
                                .buttonStyle(.bordered).controlSize(.small)
                        }
                        // Validation indicator
                        let hasBotFile = FileManager.default.fileExists(
                            atPath: botManager.projectDirectory + "/telegram-bot.mjs")
                        HStack(spacing: 6) {
                            Image(systemName: hasBotFile ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(hasBotFile ? .green : .orange)
                            Text(hasBotFile
                                 ? "telegram-bot.mjs found ✓"
                                 : "telegram-bot.mjs not found — bot cannot start from this path")
                                .font(.system(size: 11))
                                .foregroundStyle(hasBotFile ? Color.secondary : Color.orange)
                        }
                    }
                }

                // Telegram
                ConfigSection(title: locale.t(.cfgTelegram), icon: "paperplane.fill", color: .blue) {
                    VStack(spacing: 16) {
                        ConfigField(label: locale.t(.cfgBotToken), icon: "key.fill") {
                            HStack {
                                if showTokenField {
                                    TextField("", text: binding(\.botToken))
                                        .textFieldStyle(.plain).font(.system(size: 13, design: .monospaced))
                                } else {
                                    Text(editableConfig.maskedToken.isEmpty ? locale.t(.cfgNotConfigured) : editableConfig.maskedToken)
                                        .font(.system(size: 13, design: .monospaced)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(showTokenField ? locale.t(.cfgHide) : locale.t(.cfgShow)) { showTokenField.toggle() }
                                    .buttonStyle(.bordered).controlSize(.small)
                            }
                        }
                        ConfigField(label: locale.t(.cfgAllowGroups), icon: "person.3.fill") {
                            Toggle("", isOn: binding(\.allowGroups)).toggleStyle(.switch).controlSize(.small)
                        }
                        ConfigField(label: locale.t(.cfgSkipPending), icon: "forward.fill") {
                            Toggle("", isOn: binding(\.skipPendingUpdates)).toggleStyle(.switch).controlSize(.small)
                        }
                    }
                }

                // AI Model with provider picker
                ConfigSection(title: locale.t(.cfgModel), icon: "cpu.fill", color: .purple) {
                    VStack(spacing: 16) {
                        // Provider picker
                        ConfigField(label: locale.t(.cfgProvider), icon: "building.2.fill") {
                            HStack(spacing: 8) {
                                if modelService.isLoading {
                                    ProgressView().scaleEffect(0.7).frame(width: 16, height: 16)
                                    Text(locale.t(.cfgLoadingModels))
                                        .font(.system(size: 12)).foregroundStyle(.secondary)
                                } else if modelService.providers.isEmpty {
                                    Text(locale.t(.cfgLoadingModels))
                                        .font(.system(size: 12)).foregroundStyle(.secondary)
                                } else {
                                    Picker("", selection: $selectedProvider) {
                                        Text(locale.t(.cfgSelectProvider)).tag("")
                                        Text(locale.t(.cfgCustomModel)).tag("__custom__")
                                        ForEach(modelService.providers, id: \.self) { provider in
                                            Text(provider).tag(provider)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: 200)
                                    .onChange(of: selectedProvider) { newProvider in
                                        if newProvider != "__custom__" && newProvider != "" {
                                            // Auto-select first model of provider
                                            if let first = modelService.models(for: newProvider).first {
                                                editableConfig.opencodeModel = first.fullName
                                                hasChanges = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Model picker (shown when provider selected)
                        if selectedProvider != "" && selectedProvider != "__custom__" {
                            let models = modelService.models(for: selectedProvider)
                            ConfigField(label: locale.t(.cfgModelLabel), icon: "brain") {
                                Picker("", selection: binding(\.opencodeModel)) {
                                    ForEach(models) { m in
                                        Text(m.model).tag(m.fullName)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: 300)
                            }
                        }

                        // Custom model text field
                        if selectedProvider == "__custom__" || selectedProvider == "" {
                            ConfigField(label: locale.t(.cfgModelLabel), icon: "brain") {
                                TextField("e.g. lm-studio/llama2", text: binding(\.opencodeModel))
                                    .textFieldStyle(.plain).font(.system(size: 13, design: .monospaced))
                            }
                        }

                        // Current value display
                        if !editableConfig.opencodeModel.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.system(size: 12))
                                Text(editableConfig.opencodeModel)
                                    .font(.system(size: 12, design: .monospaced)).foregroundStyle(.secondary)
                            }
                            .padding(.leading, 32)
                        }

                        ConfigField(label: locale.t(.cfgVariant), icon: "sparkles") {
                            Picker("", selection: binding(\.opencodeVariant)) {
                                Text(locale.t(.cfgVariantLow)).tag("low")
                                Text(locale.t(.cfgVariantMedium)).tag("medium")
                                Text(locale.t(.cfgVariantHigh)).tag("high")
                            }
                            .pickerStyle(.segmented).frame(width: 240)
                        }
                        ConfigField(label: locale.t(.cfgPermission), icon: "lock.shield.fill") {
                            Picker("", selection: binding(\.opencodePermissionMode)) {
                                Text(locale.t(.cfgPermAsk)).tag("ask")
                                Text(locale.t(.cfgPermAllow)).tag("allow")
                            }
                            .pickerStyle(.segmented).frame(width: 160)
                        }
                    }
                }

                // Advanced
                ConfigSection(title: locale.t(.cfgAdvanced), icon: "wrench.and.screwdriver.fill", color: .gray) {
                    VStack(spacing: 16) {
                        ConfigField(label: locale.t(.cfgPollTimeout), icon: "clock") {
                            TextField("30", value: binding(\.pollTimeout), format: .number)
                                .textFieldStyle(.plain).frame(width: 80)
                        }
                        ConfigField(label: locale.t(.cfgOcTimeout), icon: "timer") {
                            TextField("600000", value: binding(\.opencodeTimeout), format: .number)
                                .textFieldStyle(.plain).frame(width: 100)
                        }
                        ConfigField(label: locale.t(.cfgWebhookPort), icon: "network") {
                            TextField("3000", value: binding(\.port), format: .number)
                                .textFieldStyle(.plain).frame(width: 80)
                        }
                        ConfigField(label: locale.t(.cfgDeleteWebhook), icon: "xmark.circle") {
                            Toggle("", isOn: binding(\.deleteWebhookOnStart)).toggleStyle(.switch).controlSize(.small)
                        }
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(32)
        }
        .onAppear {
            editableConfig = botManager.config
            syncProviderSelection()
            Task { await ModelService.shared.loadModels(projectPath: botManager.projectDirectory) }
        }
        .onChange(of: modelService.providers) { _ in syncProviderSelection() }
        .alert(locale.t(.cfgSaved), isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(locale.t(.cfgSavedMsg))
        }
    }

    private func syncProviderSelection() {
        let current = editableConfig.opencodeModel
        if current.isEmpty { return }
        let parts = current.split(separator: "/", maxSplits: 1)
        if parts.count == 2 {
            let provider = String(parts[0])
            if modelService.providers.contains(provider) {
                selectedProvider = provider
            }
        }
    }

    private func binding<T>(_ keyPath: WritableKeyPath<BotConfig, T>) -> Binding<T> {
        Binding(
            get: { editableConfig[keyPath: keyPath] },
            set: { editableConfig[keyPath: keyPath] = $0; hasChanges = true }
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
    let title: String; let icon: String; let color: Color
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(color)
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            content
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background)
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2))
    }
}

struct ConfigField<Content: View>: View {
    let label: String; let icon: String
    @ViewBuilder let content: Content
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 12)).foregroundStyle(.secondary).frame(width: 20)
            Text(label).font(.system(size: 13, weight: .medium)).frame(width: 180, alignment: .leading)
            content.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}
