import Foundation
import SwiftUI
import AppKit
import ApplicationServices

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedModel: LLMModel {
        didSet { UserDefaults.standard.set(selectedModel.id, forKey: "selected_model") }
    }
    @Published var isLoading = false
    @Published var streamingContent = ""
    @Published var models: [LLMModel] = []
    @Published var isLoadingModels = false
    @Published var hfError: String?

    @AppStorage("provider_url") private var providerUrl = ""

    private var selectionSnapshotsByAssistantID: [UUID: SelectionSnapshot] = [:]
    private var insertionErrors: [UUID: String] = [:]
    @Published var insertionError: String?
    private var pendingSelectionSnapshot: SelectionSnapshot?


    private var streamTask: Task<Void, Never>?
    private var streamingUpdateTask: Task<Void, Never>?
    private var pendingStreamingContent: String?
    private var activeRequestID: UUID?

    var apiEndpointURL: String {
        providerUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "http://127.0.0.1:8000/v1/chat/completions"
            : providerUrl.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "selected_model") ?? ""
        let savedID = raw.hasSuffix(":nitro") ? String(raw.dropLast(5)) : raw
        let fallbackLabel = savedID.replacingOccurrences(of: "/", with: " ")
        self.selectedModel = LLMModel(id: savedID, label: fallbackLabel.isEmpty ? "Unknown" : fallbackLabel)
        Task { [weak self] in self?.loadModelsFromHF() }
    }

    var apiKey: String {
        let key = Keychain.load(key: "openrouter_api_key").trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            return ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return key
    }

    var systemPrompt: String {
        UserDefaults.standard.string(forKey: "system_prompt") ?? ""
    }

    func loadModelsFromHF() {
        guard !isLoadingModels else { return }
        isLoadingModels = true

        Task { [weak self] in
            guard let self else { return }
            do {
                // GUI apps (Finder/Dock launch) inherit a minimal PATH that misses Homebrew etc.
                // Resolve an absolute hf path instead of relying on /usr/bin/env lookup.
                let env = ProcessInfo.processInfo.environment
                let override = UserDefaults.standard.string(forKey: CLIPath.hfOverrideKey)
                guard let hfPath = CLIPath.resolveExecutable(named: "hf", override: override, envPath: env["PATH"]) else {
                    await MainActor.run {
                        self.isLoadingModels = false
                        self.hfError = "hf not found. Searched: \(CLIPath.searchedLocationsDescription). Install: brew install hf or set the path in Settings."
                    }
                    return
                }

                let task = Process()
                task.executableURL = URL(fileURLWithPath: hfPath)
                task.arguments = ["cache", "ls", "--json"]

                var childEnv = env
                childEnv["PATH"] = CLIPath.augmentedPath(inherited: env["PATH"])
                task.environment = childEnv

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                task.standardOutput = stdoutPipe
                task.standardError = stderrPipe

                try task.run()
                task.waitUntilExit()

                if task.terminationStatus == 0 {
                    let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                    let parsed = ModelLoader.parseHFModels(data)
                    await MainActor.run {
                        self.models = parsed
                        self.isLoadingModels = false
                        self.hfError = nil
                    }
                } else {
                    let err = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let errStr = String(data: err, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "unknown error"
                    await MainActor.run {
                        self.isLoadingModels = false
                        self.hfError = "hf command failed: \(errStr)"
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingModels = false
                    self.hfError = "hf not found. Install: brew install hf"
                }
            }
        }
    }

    func reset() {
        cancelActiveRequest(keepingPartialResponse: false)
        messages = []
    }

    func stop() {
        cancelActiveRequest(keepingPartialResponse: true)
    }

    func send(_ text: String) {
        send(text, template: nil)
    }

    func send(_ text: String, template: String?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        let requestAPIKey = apiKey
        guard !requestAPIKey.isEmpty else {
            messages.append(ChatMessage(role: "assistant", content: "Set your OpenRouter API key in Settings (⌘,)."))
            return
        }

        var messageContent = text
        if let template {
            if template.contains(PresetTemplate.placeholder) {
                messageContent = template.replacingOccurrences(of: PresetTemplate.placeholder, with: text)
            } else {
                messageContent = template + "\n\n" + text
            }
        }

        messages.append(ChatMessage(role: "user", content: messageContent))
        isLoading = true
        streamingContent = ""

        var history = messages.map { APIMessage(role: $0.role, content: $0.content) }
        if !systemPrompt.isEmpty {
            history.insert(APIMessage(role: "system", content: systemPrompt), at: 0)
        }
        let model = selectedModel.id
        let requestID = UUID()
        activeRequestID = requestID
        let endpointURL = apiEndpointURL

        streamTask = Task {
            await streamResponse(history: history, model: model, apiKey: requestAPIKey, requestID: requestID, endpointURL: endpointURL)
        }
    }

    func send(selectionSnapshot: SelectionSnapshot, template: String? = nil) {
        pendingSelectionSnapshot = selectionSnapshot
        send(selectionSnapshot.selectedText, template: template)
    }

    func snapshotForMessage(_ id: UUID) -> SelectionSnapshot? {
        selectionSnapshotsByAssistantID[id]
    }

    func insertSelection(for messageId: UUID) {
        guard let snapshot = selectionSnapshotsByAssistantID[messageId] else { return }
        let axApp = AXUIElementCreateApplication(snapshot.appPID)
        var rawFocused: AnyObject?
        AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &rawFocused)
        guard let raw = rawFocused else {
            selectionSnapshotsByAssistantID[messageId] = nil
            insertionError = "Insert failed: no focused element"
            return
        }
        guard let focused = bridgeToAXUIElement(raw) else {
            selectionSnapshotsByAssistantID[messageId] = nil
            insertionError = "Insert failed: no focused element"
            return
        }
        let result = AXUIElementSetAttributeValue(focused, kAXSelectedTextAttribute as CFString, snapshot.selectedText as CFString)
        selectionSnapshotsByAssistantID[messageId] = nil
        if result != .success {
            insertionErrors[messageId] = "Insert failed: could not modify selection"
        }
    }

    func clearInsertionError(for messageId: UUID) {
        insertionErrors[messageId] = nil
    }

    private func bridgeToAXUIElement(_ obj: AnyObject) -> AXUIElement? {
        let ptr = Unmanaged.passUnretained(obj).toOpaque()
        return Unmanaged<AXUIElement>.fromOpaque(ptr).takeUnretainedValue()
    }

    nonisolated private func streamResponse(history: [APIMessage], model: String, apiKey: String, requestID: UUID, endpointURL: String) async {
        guard let url = URL(string: endpointURL) else { await failRequest(message: "Invalid provider URL", id: requestID); return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = APIRequest(model: model, messages: history, stream: true, includeUsage: true)
        guard let bodyData = try? JSONEncoder().encode(body) else {
            await failRequest(message: "Invalid request body", id: requestID)
            return
        }
        request.httpBody = bodyData

        let startTime = Date()

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                var errorBody = ""
                for try await line in bytes.lines {
                    try Task.checkCancellation()
                    errorBody += line
                    if errorBody.count > 20_000 { break }
                }
                await failRequest(message: "Error \(httpResponse.statusCode): \(errorBody)", id: requestID)
                return
            }

            let decoder = JSONDecoder()
            var accumulated = ""
            var lastUsage: ResponseUsage?
            for try await line in bytes.lines {
                try Task.checkCancellation()
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }

                if let data = payload.data(using: .utf8),
                   let chunk = try? decoder.decode(APIResponse.self, from: data) {
                    if let content = chunk.choices?.first?.delta?.content {
                        accumulated += content
                        await queueStreamingUpdate(accumulated, id: requestID)
                    }
                    if let usage = chunk.usage {
                        lastUsage = usage
                    }
                }
            }

            let responseTime = Date().timeIntervalSince(startTime)
            try Task.checkCancellation()
            await completeRequest(content: accumulated, usage: lastUsage, responseTime: responseTime, model: model, id: requestID)
        } catch {
            if !Task.isCancelled {
                await failRequest(message: "Error: \(error.localizedDescription)", id: requestID)
            }
        }
    }

    private func queueStreamingUpdate(_ content: String, id: UUID) {
        guard activeRequestID == id else { return }
        if streamingContent.isEmpty {
            streamingContent = content
            return
        }

        pendingStreamingContent = content
        guard streamingUpdateTask == nil else { return }
        streamingUpdateTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(33))
            } catch {
                return
            }
            self?.flushStreamingUpdate(id: id)
        }
    }

    private func flushStreamingUpdate(id: UUID) {
        streamingUpdateTask = nil
        guard activeRequestID == id, let content = pendingStreamingContent else { return }
        pendingStreamingContent = nil
        streamingContent = content
    }

    private func completeRequest(content: String, usage: ResponseUsage?, responseTime: TimeInterval, model: String, id: UUID) {
        guard activeRequestID == id else { return }
        if !content.isEmpty {
            let msg = ChatMessage(
                role: "assistant",
                content: content,
                promptTokens: usage?.prompt_tokens,
                completionTokens: usage?.completion_tokens,
                totalTokens: usage?.total_tokens,
                responseTime: responseTime,
                model: model
            )
            messages.append(msg)
            if let snapshot = pendingSelectionSnapshot {
                selectionSnapshotsByAssistantID[msg.id] = snapshot
                pendingSelectionSnapshot = nil
            }
        }
        finishRequest(id: id)
    }

    private func failRequest(message: String, id: UUID) {
        guard activeRequestID == id else { return }
        messages.append(ChatMessage(role: "assistant", content: message))
        finishRequest(id: id)
    }

    private func cancelActiveRequest(keepingPartialResponse: Bool) {
        let partialResponse = pendingStreamingContent ?? streamingContent
        streamTask?.cancel()
        streamingUpdateTask?.cancel()
        streamTask = nil
        streamingUpdateTask = nil
        pendingStreamingContent = nil
        activeRequestID = nil
        streamingContent = ""
        isLoading = false

        if keepingPartialResponse, !partialResponse.isEmpty {
            messages.append(ChatMessage(role: "assistant", content: partialResponse))
        }
    }

    private func finishRequest(id: UUID) {
        guard activeRequestID == id else { return }
        streamingUpdateTask?.cancel()
        streamTask = nil
        streamingUpdateTask = nil
        pendingStreamingContent = nil
        activeRequestID = nil
        streamingContent = ""
        isLoading = false
    }
}
