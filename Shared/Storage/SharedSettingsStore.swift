import Foundation

final class SharedSettingsStore {
    static let shared = SharedSettingsStore()

    private let suiteName = "group.mac_llm_widjet.shared"
    private let apiKeyKey = "shared_openai_api_key"

    private init() {}

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    func saveAPIKey(_ value: String) {
        defaults?.set(value, forKey: apiKeyKey)
        defaults?.synchronize()
    }

    func loadAPIKey() -> String {
        defaults?.string(forKey: apiKeyKey) ?? ""
    }
}
