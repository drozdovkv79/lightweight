import SwiftUI

struct SettingsView: View {
    @State private var apiKey = Keychain.load(key: "openrouter_api_key")
    @AppStorage("system_prompt") private var systemPrompt = ""
    @AppStorage("provider_url") private var providerUrl = ""
    @AppStorage("selection_assistant_enabled") private var selectionAssistantEnabled = true
    @AppStorage("selection_mode") private var selectionMode = SelectionMode.actionbar.rawValue
    @AppStorage("selection_hotkey") private var selectionHotkey = SelectionHotkey.cmdShiftSpace.rawValue
    @AppStorage("auto_invoke_delay") private var autoInvokeDelay: Double = 0.3
    @AppStorage(CLIPath.hfOverrideKey) private var hfBinaryPath = ""
    @State private var presets: [PresetTemplate] = PresetStore.load()
    @FocusState private var focusedPresetIndex: Int?
    @EnvironmentObject var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Provider URL")
                            .font(.headline)

                        TextField("http://127.0.0.1:8000/v1/chat/completions", text: $providerUrl)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .onChange(of: providerUrl) { _, newValue in
                                if !newValue.isEmpty && !newValue.hasPrefix("http://") && !newValue.hasPrefix("https://") {
                                    providerUrl = "https://" + newValue
                                }
                            }

                        Text("Leave empty for OpenRouter default.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenRouter API Key")
                            .font(.headline)

                        SecureField("sk-or-...", text: $apiKey, prompt: Text("sk-or-..."))
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                            .onSubmit(saveAPIKey)

                        Text("Stored securely in your Mac's Keychain.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Models") {
                    if vm.isLoadingModels {
                        ProgressView("Loading models from Hugging Face...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("\(vm.models.count) models loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(vm.models) { model in
                                    Text(model.label)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(height: 30)
                    }

                    Button(action: refreshModels) {
                        Label(vm.isLoadingModels ? "Loading..." : "Refresh Models", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(vm.isLoadingModels)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Path to hf binary (optional)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        TextField("/opt/homebrew/bin/hf", text: $hfBinaryPath)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                    }
                }

                Section("System Prompt") {
                    TextEditor(text: $systemPrompt)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(height: 90)
                }

                Section("Selection Assistant") {
                    Toggle("Enabled", isOn: $selectionAssistantEnabled)
                        .onChange(of: selectionAssistantEnabled) { _, _ in
                            NotificationCenter.default.post(name: .selectionAssistantCheckPermission, object: nil)
                        }
                    Picker("Mode", selection: $selectionMode) {
                        Text("Direct").tag(SelectionMode.direct.rawValue)
                        Text("ActionBar").tag(SelectionMode.actionbar.rawValue)
                    }
                    Picker("Hotkey", selection: $selectionHotkey) {
                        Text(SelectionHotkey.cmdShiftSpace.displayName).tag(SelectionHotkey.cmdShiftSpace.rawValue)
                        Text(SelectionHotkey.ctrlOptCmdSpace.displayName).tag(SelectionHotkey.ctrlOptCmdSpace.rawValue)
                        Text(SelectionHotkey.optShiftSpace.displayName).tag(SelectionHotkey.optShiftSpace.rawValue)
                    }
                    .onChange(of: selectionHotkey) { _, _ in
                        NotificationCenter.default.post(name: .selectionHotkeyChanged, object: nil)
                    }
                    HStack {
                        Text("Auto-invoke delay")
                        TextField("0.3", value: $autoInvokeDelay, format: .number)
                            .frame(width: 60)
                        Text("s")
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Presets")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        ForEach(presets.indices, id: \.self) { index in
                            presetRow(index)
                        }
                        Button(action: addPreset) {
                            Label("Add Preset", systemImage: "plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Text("Use {{text}} where the selected text should be inserted. Without it, the text is appended on a new line.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .environment(\.defaultMinListHeaderHeight, 4)
            .padding(.top, 8)
            .onChange(of: presets) { _, newValue in
                PresetStore.save(newValue)
            }
            .alert("Hugging Face Error", isPresented: Binding(
                get: { vm.hfError != nil },
                set: { _ in vm.hfError = nil }
            )) {
                Button("OK") { vm.hfError = nil }
            } message: {
                Text(vm.hfError ?? "")
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 460, height: 460)
        .onDisappear(perform: saveAPIKey)
        .task {
            if vm.models.isEmpty && !vm.isLoadingModels {
                vm.loadModelsFromHF()
            }
        }
    }

    private func presetRow(_ index: Int) -> some View {
        HStack(alignment: .top, spacing: 6) {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $presets[index].name)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                    .focused($focusedPresetIndex, equals: index)
                TextField("Template ({{text}} = selected text)", text: $presets[index].template)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
            }
            VStack(spacing: 2) {
                Button {
                    movePreset(index, by: -1)
                } label: {
                    Image(systemName: "chevron.up")
                }
                .disabled(index == 0)
                Button {
                    movePreset(index, by: 1)
                } label: {
                    Image(systemName: "chevron.down")
                }
                .disabled(index == presets.count - 1)
            }
            .buttonStyle(.borderless)
            Button {
                deletePreset(at: index)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    private func addPreset() {
        presets.append(PresetTemplate(name: "", template: ""))
        focusedPresetIndex = presets.count - 1
    }

    private func movePreset(_ index: Int, by offset: Int) {
        let newIndex = index + offset
        guard presets.indices.contains(index), presets.indices.contains(newIndex) else { return }
        presets.swapAt(index, newIndex)
    }

    private func deletePreset(at index: Int) {
        guard presets.indices.contains(index) else { return }
        presets.remove(at: index)
    }

    private func refreshModels() {
        vm.loadModelsFromHF()
    }

    private func saveAPIKey() {
        Keychain.save(key: "openrouter_api_key", value: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
