import Foundation

final class QuickPromptStore {
    static let shared = QuickPromptStore()

    private let suite = UserDefaults(suiteName: "group.mac_llm_widjet.shared")!

    private let modeKey = "quick_prompt_mode"
    private let recommendedKey = "quick_prompt_recommended_topics"
    private let customKey = "quick_prompt_custom_texts"
    private let itemsKey = "quick_prompt_items"

    private init() {
        seedIfNeeded()
    }

    private func seedIfNeeded() {
        if suite.data(forKey: itemsKey) == nil {
            saveRecommendedTopics([.weather, .economy, .general])
        }
    }

    func loadMode() -> QuickPromptMode {
        guard let raw = suite.string(forKey: modeKey),
              let mode = QuickPromptMode(rawValue: raw) else {
            return .recommended
        }
        return mode
    }

    func saveMode(_ mode: QuickPromptMode) {
        suite.set(mode.rawValue, forKey: modeKey)
        suite.synchronize()
    }

    func loadRecommendedTopics() -> [RecommendedTopic] {
        guard let data = suite.data(forKey: recommendedKey),
              let topics = try? JSONDecoder().decode([RecommendedTopic].self, from: data) else {
            return [.weather, .economy, .general]
        }
        return topics
    }

    func saveRecommendedTopics(_ topics: [RecommendedTopic]) {
        let limited = Array(topics.prefix(3))

        if let data = try? JSONEncoder().encode(limited) {
            suite.set(data, forKey: recommendedKey)
        }

        saveMode(.recommended)

        let items = limited.map {
            QuickPromptItem(title: $0.rawValue, query: $0.queryKey, isRecommended: true)
        }

        saveItems(items)
        suite.synchronize()

        print("🔥 APP 저장:", items.map(\.title))
    }

    func loadCustomPrompts() -> [String] {
        guard let data = suite.data(forKey: customKey),
              let prompts = try? JSONDecoder().decode([String].self, from: data) else {
            return ["", "", ""]
        }

        if prompts.count >= 3 {
            return Array(prompts.prefix(3))
        }

        return prompts + Array(repeating: "", count: max(0, 3 - prompts.count))
    }

    func saveCustomPrompts(_ prompts: [String]) {
        let cleaned = Array(prompts.prefix(3)).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let padded = cleaned + Array(repeating: "", count: max(0, 3 - cleaned.count))

        if let data = try? JSONEncoder().encode(padded) {
            suite.set(data, forKey: customKey)
        }

        saveMode(.custom)

        let items = padded.enumerated().map { index, text in
            QuickPromptItem(
                title: text.isEmpty ? "프롬프트 \(index + 1)" : text,
                query: text,
                isRecommended: false
            )
        }

        saveItems(items)
        suite.synchronize()

        print("🔥 APP 저장:", items.map(\.title))
    }

    func loadItems() -> [QuickPromptItem] {
        guard let data = suite.data(forKey: itemsKey),
              let items = try? JSONDecoder().decode([QuickPromptItem].self, from: data) else {
            let fallback = [
                QuickPromptItem(title: "날씨", query: "topic_weather", isRecommended: true),
                QuickPromptItem(title: "경제", query: "topic_business", isRecommended: true),
                QuickPromptItem(title: "일반", query: "topic_general", isRecommended: true)
            ]
            print("🔥 LOAD fallback items:", fallback.map(\.title))
            return fallback
        }

        print("🔥 LOAD items:", items.map(\.title))

        if items.count >= 3 {
            return Array(items.prefix(3))
        }

        return items + Array(
            repeating: QuickPromptItem(title: "-", query: "-", isRecommended: false),
            count: max(0, 3 - items.count)
        )
    }

    private func saveItems(_ items: [QuickPromptItem]) {
        if let data = try? JSONEncoder().encode(items) {
            suite.set(data, forKey: itemsKey)
        }
    }
}
