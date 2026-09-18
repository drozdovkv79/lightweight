import Foundation

struct PresetTemplate: Codable, Equatable {
    static let placeholder = "{{text}}"

    var name: String
    var template: String
}

enum PresetStore {
    static let storageKey = "selection_presets"

    static let defaultPresets: [PresetTemplate] = [
        PresetTemplate(name: "Translate", template: "Translate"),
        PresetTemplate(name: "Summarize", template: "Summarize"),
    ]

    static func load() -> [PresetTemplate] {
        load(raw: UserDefaults.standard.string(forKey: storageKey))
    }

    /// Decodes presets from raw storage. Accepts JSON `[{name, template}]`;
    /// migrates legacy comma-separated name lists in place; falls back to defaults
    /// when the key is missing, empty, or unusable.
    static func load(raw: String?) -> [PresetTemplate] {
        guard let raw, !raw.isEmpty else {
            return store(defaultPresets)
        }
        if let data = raw.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([PresetTemplate].self, from: data) {
            return decoded
        }
        guard !raw.hasPrefix("["), !raw.hasPrefix("{") else { return store(defaultPresets) }
        let names = raw.split(separator: ",").map(String.init).filter { !$0.isEmpty }
        guard !names.isEmpty else { return store(defaultPresets) }
        return store(names.map { PresetTemplate(name: $0, template: $0) })
    }

    static func save(_ presets: [PresetTemplate]) {
        let cleaned = presets.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard let data = try? JSONEncoder().encode(cleaned),
              let json = String(data: data, encoding: .utf8) else { return }
        UserDefaults.standard.set(json, forKey: storageKey)
    }

    @discardableResult
    private static func store(_ presets: [PresetTemplate]) -> [PresetTemplate] {
        save(presets)
        return presets
    }
}
