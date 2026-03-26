import Foundation
import SwiftUI
import Combine
import WidgetKit

@MainActor
final class ComposerViewModel: ObservableObject {
    @Published var mode: QuickPromptMode = .recommended
    @Published var selectedTopics: Set<RecommendedTopic> = []
    @Published var customPrompts: [String] = ["", "", ""]
    @Published var previewPages: [HomePreviewPage] = []

    private let quickPromptStore = QuickPromptStore.shared
    private let realtimeService = RealtimeDataService()

    init() {
        loadStoredValues()

        Task {
            await loadPreviewPages()
        }
    }

    func loadStoredValues() {
        mode = quickPromptStore.loadMode()
        selectedTopics = Set(quickPromptStore.loadRecommendedTopics())
        customPrompts = quickPromptStore.loadCustomPrompts()
    }

    func loadPreviewPages() async {
        previewPages = await realtimeService.fetchHomePreviewPages()
    }

    func toggleTopic(_ topic: RecommendedTopic) {
        if selectedTopics.contains(topic) {
            selectedTopics.remove(topic)
        } else {
            guard selectedTopics.count < 3 else { return }
            selectedTopics.insert(topic)
        }
    }

    func saveRecommended() {
        let ordered = RecommendedTopic.allCases.filter { selectedTopics.contains($0) }
        guard ordered.count == 3 else { return }

        quickPromptStore.saveRecommendedTopics(ordered)

        print("🔥 저장 직후 앱 재확인:", quickPromptStore.loadItems().map(\.title))

        WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
        WidgetCenter.shared.reloadAllTimelines()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func saveCustom() {
        let cleaned = customPrompts.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        quickPromptStore.saveCustomPrompts(cleaned)

        print("🔥 저장 직후 앱 재확인:", quickPromptStore.loadItems().map(\.title))

        WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
        WidgetCenter.shared.reloadAllTimelines()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func switchMode(_ newMode: QuickPromptMode) {
        mode = newMode
    }
}
