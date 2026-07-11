import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
}

struct LLMModel: Identifiable, Hashable {
    let id: String
    let label: String
}

let availableModels: [LLMModel] = [
    LLMModel(id: "google/gemini-3.5-flash", label: "Gemini 3.5 Flash"),
    LLMModel(id: "google/gemma-4-31b-it", label: "Gemma 4 31B"),
    LLMModel(id: "x-ai/grok-4.5:nitro", label: "Grok 4.5 Fast"),
    LLMModel(id: "x-ai/grok-4.5", label: "Grok 4.5"),
    LLMModel(id: "minimax/minimax-m3", label: "MiniMax M3"),
    LLMModel(id: "z-ai/glm-5.2", label: "GLM 5.2"),
    LLMModel(id: "anthropic/claude-sonnet-5", label: "Claude Sonnet 5"),
    LLMModel(id: "anthropic/claude-opus-4.8", label: "Claude Opus 4.8"),
    LLMModel(id: "anthropic/claude-haiku-4.5", label: "Claude Haiku 4.5"),
    LLMModel(id: "openai/gpt-5.6-luna", label: "GPT-5.6 Luna"),
    LLMModel(id: "openai/gpt-5.6-terra", label: "GPT-5.6 Terra"),
    LLMModel(id: "openai/gpt-5.6-sol", label: "GPT-5.6 Sol"),
    LLMModel(id: "openai/gpt-oss-120b:nitro", label: "GPT-OSS 120B Nitro"),
]

// OpenRouter API types
struct APIRequest: Encodable {
    let model: String
    let messages: [APIMessage]
    let stream: Bool
}

struct APIMessage: Codable {
    let role: String
    let content: String
}

struct APIResponse: Decodable {
    let choices: [Choice]?
    let error: APIError?

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
