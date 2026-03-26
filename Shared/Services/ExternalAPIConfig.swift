import Foundation

struct ExternalAPIConfig {
    static let defaultCityName = "Seoul"
    static let defaultCountryCode = "KR"

    // 여기 API 키 직접 입력
    static let newsAPIKey = "YOUR_NEWSAPI_KEY"
    static let weatherAPIKey = "YOUR_OPENWEATHER_KEY"
    
    static let weatherCity = "Suwon"
    static let weatherUnits = "metric"
    static let weatherLang = "kr"

    static var hasValidNewsKey: Bool {
        let key = newsAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key != "YOUR_NEWSAPI_KEY"
    }

    static var hasValidWeatherKey: Bool {
        let key = weatherAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key != "YOUR_OPENWEATHER_KEY"
    }
}
