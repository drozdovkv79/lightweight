import Foundation
import Markdown

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    let responseTime: TimeInterval?
    let model: String?

    init(role: String, content: String, promptTokens: Int? = nil, completionTokens: Int? = nil, totalTokens: Int? = nil, responseTime: TimeInterval? = nil, model: String? = nil) {
        self.role = role
        self.content = content
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.responseTime = responseTime
        self.model = model
    }


    var parsedBlocks: [Markdown.Markup]? {
        guard !content.isEmpty else { return nil }
        let doc = Markdown.Document(parsing: content)
        return doc.childCount > 0 ? Array(doc.children) : nil
    }

    var statsLine: String? {
        guard role == "assistant" else { return nil }
        let prompt = promptTokens.map { "\($0)" } ?? "—"
        let completion = completionTokens.map { "\($0)" } ?? "—"
        let speed: String
        if let completionTokens, let responseTime, responseTime > 0 {
            speed = String(format: "%.1f", Double(completionTokens) / responseTime)
        } else {
            speed = "—"
        }
        let time = responseTime.map { String(format: "%.1f", $0) } ?? "—"
        return "↑\(prompt) ↓\(completion) · \(speed) tok/s · \(time)s"
    }
}

struct LLMModel: Identifiable, Hashable {
    let id: String
    let label: String
}

struct HFModelCache: Decodable {
    let id: String
    let repo_id: String
}

enum ModelLoader {
    static func parseHFModels(_ jsonData: Data) -> [LLMModel] {
        guard let hfModels = try? JSONDecoder().decode([HFModelCache].self, from: jsonData) else { return [] }
        return hfModels.compactMap { model in
            let repoID = model.repo_id
            guard !repoID.isEmpty else { return nil }
            let cleanID = repoID
            let label = repoID.replacingOccurrences(of: "/", with: " ")
            return LLMModel(id: cleanID, label: label)
        }
    }
}

// OpenRouter API types
struct APIRequest: Encodable {
    let model: String
    let messages: [APIMessage]
    let stream: Bool
    let stream_options: StreamOptions?

    enum CodingKeys: String, CodingKey {
        case model, messages, stream, stream_options
    }

    init(model: String, messages: [APIMessage], stream: Bool, includeUsage: Bool = false) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.stream_options = includeUsage ? StreamOptions(include_usage: true) : nil
    }
}

struct StreamOptions: Encodable {
    let include_usage: Bool
}

struct APIMessage: Codable {
    let role: String
    let content: String
}

struct APIResponse: Decodable {
    let choices: [Choice]?
    let error: APIError?
    let usage: ResponseUsage?

    struct Choice: Decodable {
        let message: APIMessage?
        let delta: Delta?
    }

    struct Delta: Decodable {
        let content: String?
    }

    struct APIError: Decodable {
        let message: String
    }
}

struct ResponseUsage: Decodable {
    let prompt_tokens: Int?
    let completion_tokens: Int?
    let total_tokens: Int?
}
