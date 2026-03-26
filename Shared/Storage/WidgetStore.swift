import Foundation

final class WidgetStore {
    static let shared = WidgetStore()

    private let suite = UserDefaults(suiteName: "group.mac_llm_widjet.shared")!
    private let key = "widget_payload"

    private init() {}

    func save(_ payload: WidgetPayload) {
        if let data = try? JSONEncoder().encode(payload) {
            suite.set(data, forKey: key)
        }
    }

    func load() -> WidgetPayload? {
        guard let data = suite.data(forKey: key),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data) else {
            return nil
        }
        return payload
    }
}
