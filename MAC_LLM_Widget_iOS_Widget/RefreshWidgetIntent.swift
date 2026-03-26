import AppIntents
import WidgetKit

struct RefreshWidgetIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Widget"

    func perform() async throws -> some IntentResult {
        let payload = WidgetStore.shared.load()
        let items = QuickPromptStore.shared.loadItems()

        if let sourcePrompt = payload?.sourcePrompt,
           let index = items.firstIndex(where: { $0.title == sourcePrompt }) {
            _ = try await RunQuickPromptIntent(index: index).perform()
        } else {
            _ = try await RunQuickPromptIntent(index: 0).perform()
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
