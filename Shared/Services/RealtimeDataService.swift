import Foundation

final class RealtimeDataService {
    enum ServiceError: Error {
        case invalidURL
        case badResponse
        case emptyData
    }

    private let session = URLSession.shared

    // MARK: - Home preview

    func fetchHomePreviewPages() async -> [HomePreviewPage] {
        async let weather = fetchWeatherPreviewPage()
        async let headlines = fetchHeadlinesPreviewPage()

        let weatherPage = (try? await weather) ?? HomePreviewPage(
            title: "현재 날씨",
            subtitle: "불러오지 못했어요",
            lines: ["API 키 또는 네트워크를 확인해 주세요."],
            highlightValue: nil
        )

        let headlinePage = (try? await headlines) ?? HomePreviewPage(
            title: "오늘의 주요 뉴스",
            subtitle: "헤드라인을 불러오지 못했어요",
            lines: ["NewsAPI 응답을 확인해 주세요."],
            highlightValue: nil
        )

        return [weatherPage, headlinePage]
    }

    private func fetchWeatherPreviewPage() async throws -> HomePreviewPage {
        let weather = try await fetchWeatherSummary()
        return HomePreviewPage(
            title: "현재 날씨",
            subtitle: weather.city,
            lines: [
                weather.description,
                "체감 \(weather.feelsLikeText), 습도 \(weather.humidity)%",
                "최고 \(weather.maxText) / 최저 \(weather.minText)"
            ],
            highlightValue: weather.tempText
        )
    }

    private func fetchHeadlinesPreviewPage() async throws -> HomePreviewPage {
        let articles = try await fetchPreferredHeadlines(
            category: "general",
            keyword: nil,
            pageSize: 8
        )

        let originalTitles = articles.prefix(5).map { $0.title }
        let localizedTitles = (try? await OpenAIClient.shared.translateLinesToKorean(originalTitles)) ?? originalTitles
        let titles = localizedTitles.prefix(5).map { "• \($0)" }

        return HomePreviewPage(
            title: "오늘의 주요 뉴스",
            subtitle: "국내 헤드라인",
            lines: titles.isEmpty ? ["헤드라인이 없습니다."] : titles,
            highlightValue: nil
        )
    }

    // MARK: - Widget source fetch

    func fetchRawSource(for item: QuickPromptItem) async throws -> String {
        if item.isRecommended {
            switch item.query {
            case "topic_weather":
                return try await buildWeatherRawText()

            case "topic_business":
                return try await buildTopHeadlineRawText(
                    topic: "오늘의 경제 브리핑",
                    category: "business"
                )

            case "topic_general":
                return try await buildTopHeadlineRawText(
                    topic: "오늘의 주요 뉴스",
                    category: "general"
                )

            case "topic_technology":
                return try await buildTopHeadlineRawText(
                    topic: "IT·테크 브리핑",
                    category: "technology"
                )

            case "topic_science":
                return try await buildTopHeadlineRawText(
                    topic: "과학 이슈 브리핑",
                    category: "science"
                )

            case "topic_sports":
                return try await buildTopHeadlineRawText(
                    topic: "오늘의 스포츠",
                    category: "sports"
                )

            default:
                return try await buildKeywordNewsRawText(keyword: item.title)
            }
        } else {
            let text = item.query.trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                return "사용자가 직접 입력한 프롬프트가 비어 있습니다."
            }
            return try await buildCustomPromptRawText(prompt: text)
        }
    }

    // MARK: - Weather

    private struct OpenWeatherResponse: Decodable {
        struct WeatherInfo: Decodable {
            let main: String
            let description: String
        }

        struct MainInfo: Decodable {
            let temp: Double
            let feels_like: Double
            let temp_min: Double
            let temp_max: Double
            let humidity: Int
        }

        let weather: [WeatherInfo]
        let main: MainInfo
        let name: String
    }

    private struct WeatherSummary {
        let city: String
        let description: String
        let humidity: Int
        let tempText: String
        let feelsLikeText: String
        let minText: String
        let maxText: String
    }

    private func fetchWeatherSummary() async throws -> WeatherSummary {
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")
        components?.queryItems = [
            URLQueryItem(name: "q", value: ExternalAPIConfig.weatherCity),
            URLQueryItem(name: "appid", value: ExternalAPIConfig.weatherAPIKey),
            URLQueryItem(name: "units", value: ExternalAPIConfig.weatherUnits),
            URLQueryItem(name: "lang", value: ExternalAPIConfig.weatherLang)
        ]

        guard let url = components?.url else { throw ServiceError.invalidURL }
        let (data, response) = try await session.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
        let desc = decoded.weather.first?.description ?? "정보 없음"

        return WeatherSummary(
            city: decoded.name,
            description: desc,
            humidity: decoded.main.humidity,
            tempText: "\(Int(decoded.main.temp.rounded()))°",
            feelsLikeText: "\(Int(decoded.main.feels_like.rounded()))°",
            minText: "\(Int(decoded.main.temp_min.rounded()))°",
            maxText: "\(Int(decoded.main.temp_max.rounded()))°"
        )
    }

    private func buildWeatherRawText() async throws -> String {
        let weather = try await fetchWeatherSummary()
        return """
        주제: 현재 날씨 요약

        지역: \(weather.city)
        현재 기온: \(weather.tempText)
        체감 기온: \(weather.feelsLikeText)
        날씨 설명: \(weather.description)
        습도: \(weather.humidity)%
        최고 기온: \(weather.maxText)
        최저 기온: \(weather.minText)
        """
    }

    // MARK: - News

    private struct NewsAPIResponse: Decodable {
        struct Article: Decodable {
            let title: String
            let description: String?
            let source: Source?
            let publishedAt: String?

            struct Source: Decodable {
                let name: String?
            }
        }

        let status: String
        let totalResults: Int?
        let articles: [Article]?
        let code: String?
        let message: String?
    }

    private func fetchTopHeadlines(
        country: String,
        category: String?,
        keyword: String?,
        pageSize: Int
    ) async throws -> [NewsAPIResponse.Article] {
        var components = URLComponents(string: "https://newsapi.org/v2/top-headlines")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]

        if let category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }

        if let keyword, !keyword.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: keyword))
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(ExternalAPIConfig.newsAPIKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.badResponse
        }

        print("NewsAPI URL:", url.absoluteString)
        print("NewsAPI status:", http.statusCode)
        print("NewsAPI body:", String(data: data, encoding: .utf8) ?? "no body")

        guard http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return decoded.articles ?? []
    }

    private func fetchEverything(
        keyword: String,
        language: String = "ko",
        pageSize: Int = 5,
        sortBy: String = "publishedAt"
    ) async throws -> [NewsAPIResponse.Article] {
        var components = URLComponents(string: "https://newsapi.org/v2/everything")
        components?.queryItems = [
            URLQueryItem(name: "q", value: keyword),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "sortBy", value: sortBy),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]

        guard let url = components?.url else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue(ExternalAPIConfig.newsAPIKey, forHTTPHeaderField: "X-Api-Key")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.badResponse
        }

        print("NewsAPI Everything URL:", url.absoluteString)
        print("NewsAPI Everything status:", http.statusCode)
        print("NewsAPI Everything body:", String(data: data, encoding: .utf8) ?? "no body")

        guard http.statusCode == 200 else {
            throw ServiceError.badResponse
        }

        let decoded = try JSONDecoder().decode(NewsAPIResponse.self, from: data)
        return decoded.articles ?? []
    }

    private func fetchPreferredHeadlines(
        category: String,
        keyword: String?,
        pageSize: Int
    ) async throws -> [NewsAPIResponse.Article] {
        let koreanArticles = try await fetchTopHeadlines(
            country: "kr",
            category: category,
            keyword: keyword,
            pageSize: pageSize
        )

        if !koreanArticles.isEmpty {
            return koreanArticles
        }

        let usArticles = try await fetchTopHeadlines(
            country: "us",
            category: category,
            keyword: keyword,
            pageSize: pageSize
        )

        if !usArticles.isEmpty {
            return usArticles
        }

        throw ServiceError.emptyData
    }

    private func fetchPreferredKeywordNews(
        keyword: String,
        pageSize: Int
    ) async throws -> [NewsAPIResponse.Article] {
        let koreanArticles = try await fetchEverything(
            keyword: keyword,
            language: "ko",
            pageSize: pageSize,
            sortBy: "publishedAt"
        )

        if !koreanArticles.isEmpty {
            return koreanArticles
        }

        let englishArticles = try await fetchEverything(
            keyword: keyword,
            language: "en",
            pageSize: pageSize,
            sortBy: "publishedAt"
        )

        if !englishArticles.isEmpty {
            return englishArticles
        }

        throw ServiceError.emptyData
    }

    private func articlesToRawText(topic: String, articles: [NewsAPIResponse.Article]) throws -> String {
        let filtered = articles.filter {
            !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !filtered.isEmpty else {
            throw ServiceError.emptyData
        }

        let body = filtered.prefix(5).enumerated().map { index, article in
            let source = article.source?.name ?? "출처 없음"
            let desc = polishDescription(article.description)
            let publishedAt = article.publishedAt ?? "시간 정보 없음"
            let title = polishHeadlineForPreview(article.title)

            return """
            기사 \(index + 1)
            제목: \(title)
            출처: \(source)
            시간: \(publishedAt)
            요약: \(desc)
            """
        }
        .joined(separator: "\n\n")

        return """
        주제: \(topic)
        형식: 한국 뉴스 앱 스타일의 짧고 자연스러운 헤드라인, 간결한 요약

        \(body)
        """
    }

    private func buildTopHeadlineRawText(topic: String, category: String) async throws -> String {
        let articles = try await fetchPreferredHeadlines(
            category: category,
            keyword: nil,
            pageSize: 5
        )
        return try articlesToRawText(topic: topic, articles: articles)
    }

    private func buildKeywordNewsRawText(keyword: String) async throws -> String {
        let topic = polishedTopicName(from: keyword)
        let articles = try await fetchPreferredKeywordNews(
            keyword: keyword,
            pageSize: 5
        )
        return try articlesToRawText(topic: topic, articles: articles)
    }

    private func buildCustomPromptRawText(prompt: String) async throws -> String {
        if prompt.contains("날씨") {
            return try await buildWeatherRawText()
        }

        let topic = polishedTopicName(from: prompt)
        let articles = try await fetchPreferredKeywordNews(
            keyword: prompt,
            pageSize: 5
        )
        return try articlesToRawText(topic: topic, articles: articles)
    }

    // MARK: - Text polishing

    private func polishedTopicName(from raw: String) -> String {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if text.contains("경제") || text.lowercased().contains("stock") || text.contains("증시") {
            return "경제·증시 브리핑"
        }
        if text.contains("날씨") {
            return "현재 날씨 요약"
        }
        if text.contains("과학") {
            return "과학 이슈 브리핑"
        }
        if text.contains("스포츠") {
            return "오늘의 스포츠"
        }
        if text.contains("기술") || text.contains("테크") || text.lowercased().contains("ai") || text.lowercased().contains("it") {
            return "IT·테크 브리핑"
        }
        if text.contains("정치") {
            return "정치 이슈 브리핑"
        }
        if text.contains("국제") || text.contains("해외") {
            return "국제 뉴스 브리핑"
        }

        return "\(text) 관련 소식"
    }

    private func polishHeadlineForPreview(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if value.count > 34 {
            value = String(value.prefix(34)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }

    private func polishDescription(_ text: String?) -> String {
        let fallback = "핵심 내용을 간단히 정리한 기사입니다."
        guard let text else { return fallback }

        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if value.isEmpty {
            return fallback
        }

        if value.count > 90 {
            value = String(value.prefix(90)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }
}
