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

    init() {
        let savedID = UserDefaults.standard.string(forKey: "selected_model") ?? ""
        self.selectedModel = availableModels.first { $0.id == savedID } ?? availableModels[0]

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
        streamTask?.cancel()
        messages = []
        streamingContent = ""
        isLoading = false
    }

    func send(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !apiKey.isEmpty else {
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

        streamTask = Task {
            await streamResponse(history: history, model: model)
        }
    }

    private func streamResponse(history: [APIMessage], model: String) async {
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
                    errorBody += line
                }
                messages.append(ChatMessage(role: "assistant", content: "Error \(httpResponse.statusCode): \(errorBody)"))
                isLoading = false
                return
            }

            var accumulated = ""
            for try await line in bytes.lines {
                if Task.isCancelled { break }
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }

                if let data = payload.data(using: .utf8),
                   let chunk = try? JSONDecoder().decode(APIResponse.self, from: data),
                   let content = chunk.choices?.first?.delta?.content {
                    accumulated += content
                    streamingContent = accumulated
                }
            }

            if !accumulated.isEmpty {
                messages.append(ChatMessage(role: "assistant", content: accumulated))
            }
        } catch {
            if !Task.isCancelled {
                messages.append(ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)"))
            }
        }

        streamingContent = ""
        isLoading = false
    }
}
