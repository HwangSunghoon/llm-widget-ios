import Foundation

struct WidgetPayload: Codable {
    let title: String
    let bullets: [String]
    let sourcePrompt: String?
    let updatedAt: Date
}
