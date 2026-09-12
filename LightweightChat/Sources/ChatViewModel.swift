import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var selectedModel: LLMModel {
        didSet { UserDefaults.standard.set(selectedModel.id, forKey: "selected_model") }
    }
    @Published var isLoading = false
    @Published var streamingContent = ""

    private var streamTask: Task<Void, Never>?
    private var streamingUpdateTask: Task<Void, Never>?
    private var pendingStreamingContent: String?
    private var activeRequestID: UUID?

    init() {
        let savedID = UserDefaults.standard.string(forKey: "selected_model") ?? ""
        let nitroID = savedID.hasSuffix(":nitro") ? savedID : "\(savedID):nitro"
        self.selectedModel = availableModels.first { $0.id == savedID || $0.id == nitroID } ?? availableModels[0]

        // Migrate API key from UserDefaults to Keychain
        if let oldKey = UserDefaults.standard.string(forKey: "openrouter_api_key"), !oldKey.isEmpty {
            Keychain.save(key: "openrouter_api_key", value: oldKey)
            UserDefaults.standard.removeObject(forKey: "openrouter_api_key")
        }
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

    func reset() {
        cancelActiveRequest(keepingPartialResponse: false)
        messages = []
    }

    func stop() {
        cancelActiveRequest(keepingPartialResponse: true)
    }

    func send(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isLoading else { return }
        let requestAPIKey = apiKey
        guard !requestAPIKey.isEmpty else {
            messages.append(ChatMessage(role: "assistant", content: "Set your OpenRouter API key in Settings (⌘,)."))
            return
        }

        messages.append(ChatMessage(role: "user", content: text))
        isLoading = true
        streamingContent = ""

        var history = messages.map { APIMessage(role: $0.role, content: $0.content) }
        if !systemPrompt.isEmpty {
            history.insert(APIMessage(role: "system", content: systemPrompt), at: 0)
        }
        let model = selectedModel.id
        let requestID = UUID()
        activeRequestID = requestID

        streamTask = Task {
            await streamResponse(history: history, model: model, apiKey: requestAPIKey, requestID: requestID)
        }
    }

    nonisolated private func streamResponse(history: [APIMessage], model: String, apiKey: String, requestID: UUID) async {
        let url = URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body = APIRequest(model: model, messages: history, stream: true)
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                var errorBody = ""
                for try await line in bytes.lines {
                    try Task.checkCancellation()
                    errorBody += line
                }
                await failRequest(message: "Error \(httpResponse.statusCode): \(errorBody)", id: requestID)
                return
            }

            let decoder = JSONDecoder()
            var accumulated = ""
            for try await line in bytes.lines {
                try Task.checkCancellation()
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }

                if let data = payload.data(using: .utf8),
                   let chunk = try? decoder.decode(APIResponse.self, from: data),
                   let content = chunk.choices?.first?.delta?.content {
                    accumulated += content
                    await queueStreamingUpdate(accumulated, id: requestID)
                }
            }

            try Task.checkCancellation()
            await completeRequest(content: accumulated, id: requestID)
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

    private func completeRequest(content: String, id: UUID) {
        guard activeRequestID == id else { return }
        if !content.isEmpty {
            messages.append(ChatMessage(role: "assistant", content: content))
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
