import SwiftUI

struct PayloadCardView: View {
    let payload: WidgetPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(payload.title)
                .font(.headline)
                .foregroundColor(.black)

            ForEach(payload.bullets, id: \.self) { bullet in
                Text("• \(bullet)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let sourcePrompt = payload.sourcePrompt, !sourcePrompt.isEmpty {
                Text("출처 프롬프트: \(sourcePrompt)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.97, green: 0.98, blue: 1.0))
        )
    }
}
