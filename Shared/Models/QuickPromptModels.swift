import Foundation

enum QuickPromptMode: String, Codable {
    case recommended
    case custom
}

enum RecommendedTopic: String, CaseIterable, Codable, Identifiable {
    case weather = "날씨"
    case economy = "경제"
    case general = "일반"
    case it = "IT"
    case science = "과학"
    case sports = "스포츠"

    var id: String { rawValue }

    var queryKey: String {
        switch self {
        case .weather: return "topic_weather"
        case .economy: return "topic_business"
        case .general: return "topic_general"
        case .it: return "topic_technology"
        case .science: return "topic_science"
        case .sports: return "topic_sports"
        }
    }
}

struct QuickPromptItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var title: String
    var query: String
    var isRecommended: Bool
}

struct HomePreviewPage: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var subtitle: String
    var lines: [String]
    var highlightValue: String? = nil
}
