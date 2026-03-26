import Foundation

final class OpenAIClient {
    static let shared = OpenAIClient()

    struct VisionInputImage {
        let mimeType: String
        let base64Data: String
    }

    private init() {}

    func requestSummary(
        prompt: String,
        images: [VisionInputImage] = [],
        apiKeyOverride: String? = nil
    ) async throws -> OpenAISummarySchema {
        let apiKey = (apiKeyOverride?.isEmpty == false ? apiKeyOverride! : LLMAPIConfig.apiKey)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            throw NSError(
                domain: "LLMClient",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "LLMAPIConfig.swift에서 API 키를 입력해줘."]
            )
        }

        guard let url = LLMAPIConfig.endpointURL else {
            throw NSError(
                domain: "LLMClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "LLMAPIConfig.swift의 endpoint 설정이 잘못됐어."]
            )
        }

        let systemInstruction = """
        너는 iOS 위젯용 한국어 요약 에디터야.
        결과는 반드시 JSON 객체만 반환해.
        형식은 정확히 아래와 같아.
        {"title":"짧은 제목","summary":"• 첫째 줄\\n• 둘째 줄\\n• 셋째 줄"}

        공통 규칙:
        - 반드시 한국어로만 작성
        - title은 짧고 세련된 한국어 제목 1줄
        - summary는 3~5줄까지 허용
        - 각 줄은 반드시 '• '로 시작
        - 위젯에 들어가므로 각 줄은 짧고 밀도 있게 작성
        - 뉴스면 한국 뉴스 앱처럼 자연스럽고 간결하게
        - 군더더기 표현, 번역투, 과한 설명 금지
        - 불필요한 서문, 코드블록, 설명 없이 JSON만 반환

        문체 규칙:
        - 뉴스면 한국 뉴스 앱 헤드라인처럼 자연스럽고 간결하게
        - 핵심만 남기고 딱딱한 직역 표현은 피할 것
        - '~했다', '~전망', '~확대', '~논의' 같은 기사체는 가능하지만 과장 금지
        - 위젯에 들어가므로 한 줄 길이는 너무 길지 않게 압축할 것
        - 같은 의미 반복 금지
        """

        let body: [String: Any] = [
            "model": LLMAPIConfig.model,
            "temperature": 0.15,
            "messages": [
                [
                    "role": "system",
                    "content": systemInstruction
                ],
                [
                    "role": "user",
                    "content": makeUserContent(prompt: prompt, images: images)
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        for (header, value) in LLMAPIConfig.headers(apiKey: apiKey) {
            request.setValue(value, forHTTPHeaderField: header)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(
                domain: "LLMClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "응답을 해석할 수 없습니다."]
            )
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(
                domain: "LLMClient",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "API 호출 실패 (\(httpResponse.statusCode))\n\(errorText)"]
            )
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw NSError(
                domain: "LLMClient",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "응답 JSON 구조를 읽을 수 없습니다."]
            )
        }

        return try parseSummary(from: content)
    }

    func summarizeToWidgetPayload(
        sourcePrompt: String,
        rawText: String
    ) async throws -> WidgetPayload {
        let widgetPrompt = """
        아래 원문을 iOS 위젯에 맞게 짧고 세련된 한국어로 정리해줘.

        [주제]
        \(sourcePrompt)

        [원문]
        \(rawText)

        추가 지시:
        - 뉴스라면 한국 포털 뉴스 요약처럼 자연스럽게 정리
        - title은 화면 상단에 들어갈 짧은 제목으로 만들 것
        - summary는 핵심 사실만 2~3줄로 압축
        - 같은 말 반복 금지
        - 기사 제목을 어색하게 직역하지 말고 한국어 헤드라인처럼 다듬을 것
        - 너무 딱딱한 표현보다 읽기 좋은 기사체 우선
        """
        
        let summary = try await requestSummary(prompt: widgetPrompt)
        let bullets = normalizeBullets(from: summary.summary)
        let cleanedTitle = polishHeadline(summary.title)

        return WidgetPayload(
            title: cleanedTitle.isEmpty ? sourcePrompt : cleanedTitle,
            bullets: bullets.isEmpty ? fallbackBullets(from: rawText) : bullets,
            sourcePrompt: sourcePrompt,
            updatedAt: Date()
        )
    }

    func translateLinesToKorean(_ lines: [String]) async throws -> [String] {
        let cleaned = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleaned.isEmpty else { return [] }

        let apiKey = LLMAPIConfig.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !apiKey.isEmpty, apiKey != "YOUR_API_KEY_HERE" else {
            return cleaned
        }

        guard let url = LLMAPIConfig.endpointURL else {
            return cleaned
        }

        let numbered = cleaned.enumerated().map { index, line in
            "\(index + 1). \(line)"
        }.joined(separator: "\n")

        let systemInstruction = """
        너는 해외 뉴스 제목을 한국 뉴스 앱 스타일로 다듬는 에디터야.
        입력된 제목들을 한국 독자가 읽기 자연스러운 한 줄 헤드라인으로 바꿔.
        반드시 JSON 배열만 반환해.
        예시:
        ["미 증시 혼조 마감, 기술주 약세", "애플, 신규 AI 기능 공개"]

        규칙:
        - 각 항목은 한 줄짜리 자연스러운 한국어 헤드라인
        - 단순 직역보다 의미 전달이 우선
        - 한국 기사 제목처럼 간결하고 세련되게
        - 불필요한 조사, 군더더기, 어색한 번역투 제거
        - 과장 금지
        - 설명 금지
        - 코드블록 금지
        - 배열 길이는 입력 개수와 같게 유지
        """

        let body: [String: Any] = [
            "model": LLMAPIConfig.model,
            "temperature": 0.1,
            "messages": [
                [
                    "role": "system",
                    "content": systemInstruction
                ],
                [
                    "role": "user",
                    "content": """
                    다음 제목들을 한국 뉴스 앱에 나올 법한 자연스러운 헤드라인으로 바꿔줘.
                    직역보다 의미 전달을 우선해.
                    
                    \(numbered)
                    """
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        for (header, value) in LLMAPIConfig.headers(apiKey: apiKey) {
            request.setValue(value, forHTTPHeaderField: header)
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            return cleaned
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            return cleaned
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        if let result = decodeJSONArray(from: trimmed), !result.isEmpty {
            return Array(result.prefix(cleaned.count)).map { polishHeadline($0) }
        }

        if let jsonArrayBlock = extractJSONArray(from: trimmed),
           let result = decodeJSONArray(from: jsonArrayBlock),
           !result.isEmpty {
            return Array(result.prefix(cleaned.count)).map { polishHeadline($0) }
        }

        let parsed = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line -> String in
                var value = line
                if let range = value.range(of: #"^\d+\.\s*"#, options: .regularExpression) {
                    value.removeSubrange(range)
                }
                return polishHeadline(value)
            }
            .filter { !$0.isEmpty }

        return parsed.isEmpty ? cleaned : Array(parsed.prefix(cleaned.count))
    }

    private func makeUserContent(prompt: String, images: [VisionInputImage]) -> [[String: Any]] {
        var result: [[String: Any]] = [
            [
                "type": "text",
                "text": prompt
            ]
        ]

        for image in images {
            result.append([
                "type": "image_url",
                "image_url": [
                    "url": "data:\(image.mimeType);base64,\(image.base64Data)"
                ]
            ])
        }

        return result
    }

    private func parseSummary(from raw: String) throws -> OpenAISummarySchema {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if let direct = decodeSchema(from: trimmed) {
            return sanitizeSchema(direct)
        }

        if let jsonBlock = extractJSONObject(from: trimmed),
           let decoded = decodeSchema(from: jsonBlock) {
            return sanitizeSchema(decoded)
        }

        let lines = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let title = polishHeadline(lines.first ?? "요약")
        let bodyLines = Array(lines.dropFirst().prefix(3))
        let summary = bodyLines.isEmpty
            ? "• \(trimmed)"
            : bodyLines.map { $0.hasPrefix("•") ? $0 : "• \($0)" }.joined(separator: "\n")

        return sanitizeSchema(
            OpenAISummarySchema(title: title, summary: summary)
        )
    }

    private func sanitizeSchema(_ schema: OpenAISummarySchema) -> OpenAISummarySchema {
        let cleanedTitle = polishHeadline(schema.title)
        let cleanedBullets = normalizeBullets(from: schema.summary)
        let summary = cleanedBullets.isEmpty
            ? "• 요약을 불러오지 못했습니다."
            : cleanedBullets.map { "• \($0)" }.joined(separator: "\n")

        return OpenAISummarySchema(
            title: cleanedTitle.isEmpty ? "요약" : cleanedTitle,
            summary: summary
        )
    }

    private func decodeSchema(from text: String) -> OpenAISummarySchema? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(OpenAISummarySchema.self, from: data)
    }

    private func decodeJSONArray(from text: String) -> [String]? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    private func extractJSONObject(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}") else {
            return nil
        }
        return String(text[start...end])
    }

    private func extractJSONArray(from text: String) -> String? {
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]") else {
            return nil
        }
        return String(text[start...end])
    }

    private func normalizeBullets(from summary: String) -> [String] {
        let lines = summary
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let cleaned = lines.map { line in
            var text = line
            if text.hasPrefix("• ") {
                text.removeFirst(2)
            } else if text.hasPrefix("•") {
                text.removeFirst(1)
            } else if text.hasPrefix("- ") {
                text.removeFirst(2)
            } else if text.hasPrefix("-") {
                text.removeFirst(1)
            }
            return polishBullet(text)
        }
        .filter { !$0.isEmpty }

        return Array(cleaned.prefix(6))
    }

    private func fallbackBullets(from rawText: String) -> [String] {
        let lines = rawText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { polishBullet($0) }
            .filter { !$0.isEmpty }

        return Array(lines.prefix(6))
    }

    private func polishHeadline(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = value.range(of: #"^["'“”‘’\[\]\(\)\{\}]+|["'“”‘’\[\]\(\)\{\}]+$"#, options: .regularExpression) {
            value = value.replacingCharacters(in: range, with: "")
        }

        value = value.replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^제목\s*:\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^헤드라인\s*:\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^-\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^•\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if value.count > 26 {
            value = String(value.prefix(26)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }

    private func polishBullet(_ text: String) -> String {
        var value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        value = value.replacingOccurrences(of: #"^제목\s*:\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^설명\s*:\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^요약\s*:\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^-\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"^•\s*"#, with: "", options: .regularExpression)
        value = value.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

        if value.count > 34 {
            value = String(value.prefix(34)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return value
    }
}
