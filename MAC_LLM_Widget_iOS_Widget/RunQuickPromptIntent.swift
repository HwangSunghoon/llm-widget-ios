import AppIntents
import WidgetKit
import Foundation

struct RunQuickPromptIntent: AppIntent {
    static var title: LocalizedStringResource = "Run Quick Prompt"

    @Parameter(title: "Index")
    var index: Int

    init() {}

    init(index: Int) {
        self.index = index
    }

    func perform() async throws -> some IntentResult {
        let items = QuickPromptStore.shared.loadItems()
        guard items.indices.contains(index) else {
            let payload = WidgetPayload(
                title: "항목 오류",
                bullets: [
                    "선택한 항목을 찾지 못했습니다.",
                    "앱에서 프롬프트를 다시 확인해 주세요."
                ],
                sourcePrompt: "알 수 없음",
                updatedAt: Date()
            )
            WidgetStore.shared.save(payload)
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
        }

        let item = items[index]
        let realtimeService = RealtimeDataService()

        // 직접 입력 프롬프트는 외부 API가 아니라 OpenAI에 바로 보냄
        if !item.isRecommended {
            let prompt = item.query.trimmingCharacters(in: .whitespacesAndNewlines)

            if prompt.isEmpty {
                let payload = WidgetPayload(
                    title: "입력 필요",
                    bullets: [
                        "직접 입력한 프롬프트가 비어 있습니다.",
                        "앱에서 내용을 입력한 뒤 다시 저장해 주세요."
                    ],
                    sourcePrompt: item.title,
                    updatedAt: Date()
                )
                WidgetStore.shared.save(payload)
                WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
                WidgetCenter.shared.reloadAllTimelines()
                return .result()
            }

            do {
                let summary = try await OpenAIClient.shared.requestSummary(
                    prompt: """
                    아래 요청에 대해 iOS 위젯용으로 한국어 요약을 작성해줘.
                    - summary는 3~6줄까지 허용
                    - 각 줄은 반드시 '• '로 시작
                    - 큰 위젯에서는 핵심 내용을 조금 더 풍부하게 나눠 정리
                    - 뉴스나 브리핑은 필요하면 5~6줄까지 구성 가능

                    요청:
                    \(prompt)
                    """
                )
                let bullets = summary.summary
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .map { line -> String in
                        if line.hasPrefix("• ") {
                            return String(line.dropFirst(2))
                        }
                        if line.hasPrefix("•") {
                            return String(line.dropFirst(1)).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        return line
                    }

                let payload = WidgetPayload(
                    title: summary.title.isEmpty ? normalizedTitle(item.title) : normalizedTitle(summary.title),
                    bullets: Array(bullets.prefix(3)).map { normalizedBullet($0) },
                    sourcePrompt: item.title,
                    updatedAt: Date()
                )

                WidgetStore.shared.save(payload)
                WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
                WidgetCenter.shared.reloadAllTimelines()
                return .result()
            } catch {
                let payload = WidgetPayload(
                    title: "불러오기 오류",
                    bullets: [
                        "요청한 내용을 정리하지 못했습니다.",
                        "잠시 후 다시 시도해 주세요."
                    ],
                    sourcePrompt: item.title,
                    updatedAt: Date()
                )
                WidgetStore.shared.save(payload)
                WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
                WidgetCenter.shared.reloadAllTimelines()
                return .result()
            }
        }

        let rawText: String
        do {
            rawText = try await realtimeService.fetchRawSource(for: item)
        } catch {
            let payload = WidgetPayload(
                title: normalizedTitle(item.title),
                bullets: [
                    "데이터를 불러오지 못했습니다.",
                    "네트워크 상태나 API 설정을 확인해 주세요."
                ],
                sourcePrompt: item.title,
                updatedAt: Date()
            )
            WidgetStore.shared.save(payload)
            WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
            WidgetCenter.shared.reloadAllTimelines()
            return .result()
        }

        do {
            var payload = try await OpenAIClient.shared.summarizeToWidgetPayload(
                sourcePrompt: item.title,
                rawText: rawText
            )

            payload = WidgetPayload(
                title: normalizedTitle(payload.title),
                bullets: payload.bullets.map { normalizedBullet($0) }.prefix(3).map { $0 },
                sourcePrompt: payload.sourcePrompt,
                updatedAt: payload.updatedAt
            )

            WidgetStore.shared.save(payload)
        } catch {
            let lines = rawText
                .split(separator: "\n")
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                .map { normalizedBullet($0) }

            let payload = WidgetPayload(
                title: normalizedTitle(item.title),
                bullets: Array(lines.prefix(3)),
                sourcePrompt: item.title,
                updatedAt: Date()
            )
            WidgetStore.shared.save(payload)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "LLMWidget")
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }

    private func normalizedTitle(_ text: String) -> String {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if cleaned.isEmpty {
            return "오늘의 요약"
        }

        if cleaned.count > 24 {
            return String(cleaned.prefix(24)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    private func normalizedBullet(_ text: String) -> String {
        var cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^•\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^-\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if cleaned.count > 34 {
            cleaned = String(cleaned.prefix(34)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }
}
