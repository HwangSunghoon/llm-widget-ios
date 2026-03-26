import WidgetKit
import SwiftUI
import AppIntents

struct LLMWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload
    let items: [QuickPromptItem]
    let mode: QuickPromptMode
}

struct LLMWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LLMWidgetEntry {
        LLMWidgetEntry(
            date: Date(),
            payload: WidgetPayload(
                title: "현재 날씨",
                bullets: [
                    "맑음",
                    "체감 21°, 습도 48%",
                    "최고 24° / 최저 16°"
                ],
                sourcePrompt: "날씨",
                updatedAt: Date()
            ),
            items: QuickPromptStore.shared.loadItems(),
            mode: QuickPromptStore.shared.loadMode()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LLMWidgetEntry) -> Void) {
        let entry = LLMWidgetEntry(
            date: Date(),
            payload: WidgetStore.shared.load() ?? WidgetPayload(
                title: "현재 날씨",
                bullets: [
                    "맑음",
                    "체감 21°, 습도 48%",
                    "최고 24° / 최저 16°"
                ],
                sourcePrompt: "날씨",
                updatedAt: Date()
            ),
            items: QuickPromptStore.shared.loadItems(),
            mode: QuickPromptStore.shared.loadMode()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LLMWidgetEntry>) -> Void) {
        let entry = LLMWidgetEntry(
            date: Date(),
            payload: WidgetStore.shared.load() ?? WidgetPayload(
                title: "현재 날씨",
                bullets: [
                    "맑음",
                    "체감 21°, 습도 48%",
                    "최고 24° / 최저 16°"
                ],
                sourcePrompt: "날씨",
                updatedAt: Date()
            ),
            items: QuickPromptStore.shared.loadItems(),
            mode: QuickPromptStore.shared.loadMode()
        )

        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60 * 30))))
    }
}

struct LLMWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LLMWidgetProvider.Entry

    var body: some View {
        GeometryReader { geo in
            let totalHeight = geo.size.height
            let buttonsHeight = resolvedButtonsHeight
            let usableHeight = max(0, totalHeight - contentTopPadding - contentBottomPadding - sectionSpacing)
            let topHeight = max(0, usableHeight - buttonsHeight)

            ZStack {
                FullWeatherBackgroundView(style: weatherStyleFromPayload())

                VStack(spacing: sectionSpacing) {
                    topContent
                        .frame(width: geo.size.width - (contentHorizontalPadding * 2),
                               height: topHeight,
                               alignment: .topLeading)

                    bottomButtons
                        .frame(width: geo.size.width - (contentHorizontalPadding * 2),
                               height: buttonsHeight,
                               alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, contentHorizontalPadding)
                .padding(.top, contentTopPadding)
                .padding(.bottom, contentBottomPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    private func weatherStyleFromPayload() -> WidgetWeatherStyle {
        let text = ([entry.payload.title] + entry.payload.bullets).joined(separator: " ").lowercased()

        if text.contains("비") || text.contains("rain") || text.contains("drizzle") {
            return .rain
        } else if text.contains("눈") || text.contains("snow") {
            return .snow
        } else if text.contains("흐림") || text.contains("구름") || text.contains("cloud") {
            return .clouds
        } else if text.contains("안개") || text.contains("mist") || text.contains("fog") {
            return .mist
        } else {
            return .clear
        }
    }
    
    private var resolvedButtonsHeight: CGFloat {
        switch family {
        case .systemLarge:
            return 112
        case .systemMedium:
            return 52
        default:
            return 36
        }
    }

    private var contentHorizontalPadding: CGFloat {
        switch family {
        case .systemLarge: return 16
        case .systemMedium: return 14
        default: return 12
        }
    }

    private var contentTopPadding: CGFloat {
        switch family {
        case .systemLarge: return 16
        case .systemMedium: return 14
        default: return 12
        }
    }

    private var contentBottomPadding: CGFloat {
        switch family {
        case .systemLarge: return 16
        case .systemMedium: return 14
        default: return 12
        }
    }
    
    private var shouldShowTemperature: Bool {
        let source = entry.payload.sourcePrompt?.lowercased() ?? ""
        let title = entry.payload.title.lowercased()

        return source.contains("날씨")
            || title.contains("날씨")
            || title.contains("기온")
            || title.contains("현재 날씨")
    }

    private var sectionSpacing: CGFloat {
        switch family {
        case .systemLarge: return 12
        case .systemMedium: return 10
        default: return 8
        }
    }

    private var titleFont: Font {
        switch family {
        case .systemLarge: return .system(size: 21, weight: .semibold, design: .rounded)
        case .systemMedium: return .system(size: 16.5, weight: .semibold, design: .rounded)
        default: return .system(size: 14.5, weight: .semibold, design: .rounded)
        }
    }

    private var bulletFont: Font {
        switch family {
        case .systemLarge: return .system(size: 15, weight: .medium, design: .rounded)
        case .systemMedium: return .system(size: 12.8, weight: .medium, design: .rounded)
        default: return .system(size: 11.5, weight: .medium, design: .rounded)
        }
    }

    private var tempFont: Font {
        switch family {
        case .systemLarge: return .system(size: 64, weight: .thin, design: .rounded)
        case .systemMedium: return .system(size: 46, weight: .thin, design: .rounded)
        default: return .system(size: 34, weight: .light, design: .rounded)
        }
    }

    private var buttonFont: Font {
        switch family {
        case .systemLarge: return .system(size: 13.5, weight: .semibold, design: .rounded)
        case .systemMedium: return .system(size: 12.2, weight: .semibold, design: .rounded)
        default: return .system(size: 11.2, weight: .semibold, design: .rounded)
        }
    }

    private var extractedTemperature: String? {
        let joined = ([entry.payload.title] + entry.payload.bullets).joined(separator: " ")
        if let range = joined.range(of: #"-?\d+\s*°"#, options: .regularExpression) {
            return String(joined[range]).replacingOccurrences(of: " ", with: "")
        }
        return nil
    }

    private var displayTemperature: String {
        extractedTemperature ?? "--°"
    }

    private var summaryFirstLine: String {
        if let first = entry.payload.bullets.first, !first.isEmpty {
            return first
        }
        return "날씨 정보를 불러오는 중"
    }

    private var remainingBullets: [String] {
        let source = Array(entry.payload.bullets.dropFirst())

        switch family {
        case .systemLarge:
            return Array(source.prefix(5))
        case .systemMedium:
            return Array(source.prefix(2))
        default:
            return []
        }
    }

    private var titleLineLimit: Int {
        switch family {
        case .systemLarge: return 2
        case .systemMedium: return 2
        default: return 1
        }
    }

    private var firstLineLimit: Int {
        switch family {
        case .systemLarge: return 2
        case .systemMedium: return 2
        default: return 1
        }
    }

    private var bulletLineLimit: Int {
        switch family {
        case .systemLarge: return 2
        case .systemMedium: return 1
        default: return 1
        }
    }

    private var totalTextLineGoal: Int {
        switch family {
        case .systemLarge: return 6
        case .systemMedium: return 3
        default: return 1
        }
    }

    private var topContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.payload.title)
                .font(titleFont)
                .foregroundColor(.white)
                .lineLimit(titleLineLimit)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .leading)

            if shouldShowTemperature {
                Text(displayTemperature)
                    .font(tempFont)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .padding(.top, 2)
            }

            Text(summaryFirstLine)
                .font(bulletFont)
                .foregroundColor(.white.opacity(0.96))
                .lineLimit(firstLineLimit)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(Array(remainingBullets.prefix(max(0, totalTextLineGoal - 1)).enumerated()), id: \.offset) { _, bullet in
                Text("• \(bullet)")
                    .font(bulletFont)
                    .foregroundColor(.white.opacity(0.93))
                    .lineLimit(bulletLineLimit)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var bottomButtons: some View {
        switch family {
        case .systemLarge:
            largeButtons
        case .systemMedium:
            mediumButtons
        default:
            smallButtons
        }
    }

    private var mediumButtons: some View {
        HStack(spacing: 8) {
            ForEach(Array(entry.items.enumerated()), id: \.offset) { index, item in
                Button(intent: RunQuickPromptIntent(index: index)) {
                    Text(entry.mode == .recommended ? item.title : "\(index + 1)")
                        .font(buttonFont)
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.white.opacity(0.84))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var largeButtons: some View {
        VStack(spacing: 8) {
            ForEach(Array(entry.items.enumerated()), id: \.offset) { index, item in
                Button(intent: RunQuickPromptIntent(index: index)) {
                    HStack(spacing: 8) {
                        Text(entry.mode == .recommended ? item.title : "\(index + 1)")
                            .font(buttonFont)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Spacer()

                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.84))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var smallButtons: some View {
        HStack(spacing: 8) {
            ForEach(Array(entry.items.enumerated()), id: \.offset) { index, _ in
                Button(intent: RunQuickPromptIntent(index: index)) {
                    Text("\(index + 1)")
                        .font(buttonFont)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.84))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum WidgetWeatherStyle {
    case clear
    case clouds
    case rain
    case snow
    case mist
}

struct FullWeatherBackgroundView: View {
    let style: WidgetWeatherStyle

    var body: some View {
        ZStack {
            switch style {
            case .clear:
                LinearGradient(
                    colors: [
                        Color(red: 0.23, green: 0.56, blue: 0.98),
                        Color(red: 0.38, green: 0.78, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case .clouds:
                LinearGradient(
                    colors: [
                        Color(red: 0.40, green: 0.50, blue: 0.66),
                        Color(red: 0.63, green: 0.72, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case .rain:
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.24, blue: 0.44),
                        Color(red: 0.30, green: 0.46, blue: 0.76)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case .snow:
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.87, blue: 0.98),
                        Color.white.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case .mist:
                LinearGradient(
                    colors: [
                        Color(red: 0.72, green: 0.76, blue: 0.82),
                        Color(red: 0.88, green: 0.90, blue: 0.94)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: 90, y: -110)

            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 28)
                .offset(x: -100, y: 120)
        }
        .ignoresSafeArea()
    }
}

@main
struct LLMWidget: Widget {
    let kind: String = "LLMWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LLMWidgetProvider()) { entry in
            LLMWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("LLM Widget")
        .description("빠른 프롬프트로 요약 결과를 바로 불러옵니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
