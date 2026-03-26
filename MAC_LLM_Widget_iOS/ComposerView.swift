import SwiftUI

struct ComposerView: View {
    @StateObject private var viewModel = ComposerViewModel()
    @State private var topPageIndex = 0

    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""

    @FocusState private var isTextFieldFocused: Bool

    private let topicColumns = [
        GridItem(.adaptive(minimum: 92), spacing: 10)
    ]

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 12) {
                topHalf(height: geo.size.height * 0.48)
                bottomHalf(height: geo.size.height * 0.48)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.ignoresSafeArea())
        }
        .alert("저장 완료", isPresented: $showSaveAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(saveAlertMessage)
        }
    }

    @ViewBuilder
    private func topHalf(height: CGFloat) -> some View {
        TabView(selection: $topPageIndex) {
            ForEach(Array(viewModel.previewPages.enumerated()), id: \.offset) { index, page in
                ZStack {
                    if isWeatherPage(page, index: index) {
                        WeatherBackgroundView(style: weatherStyle(from: page))
                    } else {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.95, green: 0.97, blue: 1.0),
                                        Color(red: 0.90, green: 0.94, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    if isWeatherPage(page, index: index) {
                        weatherCardContent(page)
                    } else {
                        newsCardContent(page)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: height)
    }

    @ViewBuilder
    private func weatherCardContent(_ page: HomePreviewPage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(page.subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.92))
                }

                Spacer()

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
            }

            Spacer(minLength: 4)

            if let temp = page.highlightValue, !temp.isEmpty {
                Text(temp)
                    .font(.system(size: 52, weight: .thin))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.lines, id: \.self) { line in
                    Text(line.replacingOccurrences(of: "• ", with: ""))
                        .font(.body.weight(.medium))
                        .foregroundColor(.white.opacity(0.96))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
    }

    @ViewBuilder
    private func newsCardContent(_ page: HomePreviewPage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text(page.title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)

                Spacer()

                Image(systemName: "newspaper.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue.opacity(0.8))
            }

            Text(page.subtitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.gray)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.lines.prefix(5), id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.blue.opacity(0.75))
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)

                        Text(line.replacingOccurrences(of: "• ", with: ""))
                            .font(.body)
                            .foregroundColor(.black.opacity(0.88))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
    }

    @ViewBuilder
    private func bottomHalf(height: CGFloat) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("빠른 프롬프트")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.black)

                    Text("추천 검색어 3개를 고르거나, 직접 3개의 프롬프트를 입력해 위젯에 저장할 수 있어요.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                modeButton(title: "추천 검색어", mode: .recommended)
                modeButton(title: "직접 입력", mode: .custom)
            }

            if viewModel.mode == .recommended {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: topicColumns, spacing: 10) {
                        ForEach(RecommendedTopic.allCases) { topic in
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    viewModel.toggleTopic(topic)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: iconName(for: topic))
                                        .font(.system(size: 13, weight: .semibold))

                                    Text(topic.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .lineLimit(1)
                                }
                                .foregroundColor(viewModel.selectedTopics.contains(topic) ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            viewModel.selectedTopics.contains(topic)
                                            ? LinearGradient(
                                                colors: [
                                                    Color(red: 0.29, green: 0.60, blue: 0.98),
                                                    Color(red: 0.19, green: 0.50, blue: 0.92)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                colors: [
                                                    Color(red: 0.94, green: 0.96, blue: 0.99),
                                                    Color(red: 0.91, green: 0.94, blue: 0.98)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            viewModel.selectedTopics.contains(topic)
                                            ? Color.clear
                                            : Color.white.opacity(0.7),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }

                HStack {
                    Text("선택됨 \(viewModel.selectedTopics.count)/3")
                        .font(.caption.weight(.medium))
                        .foregroundColor(viewModel.selectedTopics.count == 3 ? .blue : .gray)

                    Spacer()

                    if viewModel.selectedTopics.count == 3 {
                        Text("저장 가능")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.blue)
                    }
                }

                Button {
                    isTextFieldFocused = false
                    viewModel.saveRecommended()
                    saveAlertMessage = "추천 검색어 3개가 저장되었고, 위젯 갱신을 요청했어요."
                    showSaveAlert = true
                } label: {
                    Text("빠른 프롬프트 저장")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    viewModel.selectedTopics.count == 3
                                    ? LinearGradient(
                                        colors: [
                                            Color(red: 0.29, green: 0.60, blue: 0.98),
                                            Color(red: 0.19, green: 0.50, blue: 0.92)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            Color.gray.opacity(0.45),
                                            Color.gray.opacity(0.40)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(viewModel.selectedTopics.count != 3)

            } else {
                VStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.88, green: 0.93, blue: 1.0))
                                    .frame(width: 28, height: 28)

                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Color(red: 0.23, green: 0.50, blue: 0.92))
                            }

                            TextField("프롬프트 \(index + 1)", text: bindingForPrompt(index))
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(red: 0.86, green: 0.90, blue: 0.96), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)
                        }
                    }
                }

                Button {
                    isTextFieldFocused = false
                    viewModel.saveCustom()
                    saveAlertMessage = "직접 입력한 프롬프트 3개가 저장되었고, 위젯 갱신을 요청했어요."
                    showSaveAlert = true
                } label: {
                    Text("빠른 프롬프트 저장")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.29, green: 0.60, blue: 0.98),
                                            Color(red: 0.19, green: 0.50, blue: 0.92)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.985, green: 0.99, blue: 1.0),
                            Color(red: 0.965, green: 0.975, blue: 0.995)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }

    private func modeButton(title: String, mode: QuickPromptMode) -> some View {
        Button {
            isTextFieldFocused = false
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.switchMode(mode)
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(viewModel.mode == mode ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    Capsule()
                        .fill(
                            viewModel.mode == mode
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.29, green: 0.60, blue: 0.98),
                                    Color(red: 0.19, green: 0.50, blue: 0.92)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.92, green: 0.94, blue: 0.97),
                                    Color(red: 0.89, green: 0.92, blue: 0.96)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func bindingForPrompt(_ index: Int) -> Binding<String> {
        Binding(
            get: {
                if viewModel.customPrompts.indices.contains(index) {
                    return viewModel.customPrompts[index]
                }
                return ""
            },
            set: { newValue in
                if viewModel.customPrompts.indices.contains(index) {
                    viewModel.customPrompts[index] = newValue
                }
            }
        )
    }

    private func iconName(for topic: RecommendedTopic) -> String {
        switch topic.rawValue {
        case "날씨":
            return "cloud.sun.fill"
        case "경제":
            return "chart.line.uptrend.xyaxis"
        case "일반":
            return "newspaper.fill"
        case "IT":
            return "cpu.fill"
        case "과학":
            return "atom"
        case "스포츠":
            return "sportscourt.fill"
        default:
            return "sparkles"
        }
    }

    private func isWeatherPage(_ page: HomePreviewPage, index: Int) -> Bool {
        index == 0 || page.title.contains("날씨")
    }

    private func weatherStyle(from page: HomePreviewPage) -> WeatherVisualStyle {
        let source = "\(page.title) \(page.subtitle) \(page.lines.joined(separator: " "))".lowercased()

        if source.contains("rain") || source.contains("비") || source.contains("drizzle") {
            return .rain
        } else if source.contains("snow") || source.contains("눈") {
            return .snow
        } else if source.contains("cloud") || source.contains("흐림") || source.contains("구름") {
            return .clouds
        } else if source.contains("mist") || source.contains("fog") || source.contains("안개") {
            return .mist
        } else {
            return .clear
        }
    }
}

enum WeatherVisualStyle {
    case clear
    case clouds
    case rain
    case snow
    case mist
}

struct WeatherBackgroundView: View {
    let style: WeatherVisualStyle
    @State private var animate = false

    var body: some View {
        ZStack {
            backgroundLayer

            if style == .clear {
                clearGlowLayer
            }

            if style == .clouds || style == .mist {
                cloudLayer
            }

            if style == .rain {
                RainOverlayView()
            }

            if style == .snow {
                SnowOverlayView()
            }
        }
        .onAppear {
            animate = true
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
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
                    Color.white.opacity(0.95)
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
    }

    private var clearGlowLayer: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 12)
                .offset(x: animate ? 45 : -10, y: animate ? -30 : 30)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)

            Circle()
                .fill(Color.white.opacity(0.11))
                .frame(width: 260, height: 260)
                .blur(radius: 18)
                .offset(x: animate ? -28 : 26, y: animate ? 22 : -18)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
        }
    }

    private var cloudLayer: some View {
        ZStack {
            cloud(offsetX: animate ? -22 : 22, offsetY: -28, scale: 1.00, opacity: 0.18)
            cloud(offsetX: animate ? 24 : -18, offsetY: 30, scale: 0.82, opacity: 0.15)
            cloud(offsetX: animate ? 8 : -8, offsetY: 2, scale: 0.68, opacity: 0.10)
        }
    }

    private func cloud(offsetX: CGFloat, offsetY: CGFloat, scale: CGFloat, opacity: Double) -> some View {
        Capsule()
            .fill(Color.white.opacity(opacity))
            .frame(width: 160 * scale, height: 56 * scale)
            .blur(radius: 2)
            .overlay(
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: 64 * scale, height: 64 * scale)
                    .offset(x: -36 * scale, y: -8 * scale)
            )
            .overlay(
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: 72 * scale, height: 72 * scale)
                    .offset(x: 10 * scale, y: -12 * scale)
            )
            .offset(x: offsetX, y: offsetY)
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
    }
}

struct RainOverlayView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<22, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 1.6, height: 18)
                        .rotationEffect(.degrees(18))
                        .offset(
                            x: CGFloat((index * 17) % Int(max(1, geo.size.width))) - geo.size.width / 2,
                            y: animate ? geo.size.height / 2 + 40 : -geo.size.height / 2 - 40
                        )
                        .animation(
                            .linear(duration: Double.random(in: 0.9...1.5))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.05),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
        .clipped()
    }
}

struct SnowOverlayView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: CGFloat((index % 3) + 3), height: CGFloat((index % 3) + 3))
                        .offset(
                            x: CGFloat((index * 21) % Int(max(1, geo.size.width))) - geo.size.width / 2,
                            y: animate ? geo.size.height / 2 + 30 : -geo.size.height / 2 - 30
                        )
                        .animation(
                            .linear(duration: Double.random(in: 2.8...4.2))
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.12),
                            value: animate
                        )
                }
            }
            .onAppear {
                animate = true
            }
        }
        .clipped()
    }
}
