import Foundation

enum LLMService {
    case openAI
    case openRouter
    case groq
    case customOpenAICompatible
}

struct LLMAPIConfig {
    // MARK: - 여기만 바꿔서 사용
    static let service: LLMService = .openAI
    static let apiKey: String = "YOUR_API_KEY"
    static let model: String = "YOUR_LLM_MODEL"

    // customOpenAICompatible 선택 시 사용
    static let customEndpoint: String = "https://api.openai.com/v1/chat/completions"
    static let customAuthorizationHeader: String = "Authorization"
    static let customAuthorizationPrefix: String = "Bearer "

    // OpenRouter 사용 시 선택
    static let openRouterSiteURL: String = ""
    static let openRouterAppName: String = "LLM Widget"

    static var endpointURL: URL? {
        switch service {
        case .openAI:
            return URL(string: "https://api.openai.com/v1/chat/completions")
        case .openRouter:
            return URL(string: "https://openrouter.ai/api/v1/chat/completions")
        case .groq:
            return URL(string: "https://api.groq.com/openai/v1/chat/completions")
        case .customOpenAICompatible:
            return URL(string: customEndpoint)
        }
    }

    static var isConfigured: Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != "YOUR_API_KEY_HERE"
    }

    static var configurationErrorMessage: String? {
        if !isConfigured {
            return "LLMAPIConfig.swift에서 API 키를 입력해줘."
        }

        guard endpointURL != nil else {
            return "LLMAPIConfig.swift의 endpoint 설정을 확인해줘."
        }

        return nil
    }

    static func headers(apiKey: String) -> [String: String] {
        switch service {
        case .openAI, .groq:
            return [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json"
            ]

        case .openRouter:
            var result: [String: String] = [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json"
            ]

            if !openRouterSiteURL.isEmpty {
                result["HTTP-Referer"] = openRouterSiteURL
            }
            if !openRouterAppName.isEmpty {
                result["X-Title"] = openRouterAppName
            }
            return result

        case .customOpenAICompatible:
            return [
                customAuthorizationHeader: "\(customAuthorizationPrefix)\(apiKey)",
                "Content-Type": "application/json"
            ]
        }
    }
}

