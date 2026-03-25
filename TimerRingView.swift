import SwiftUI

struct TimerRingView: View {
    let emoji: String
    let title: String
    let progress: Double
    let elapsedText: String
    let remainingText: String

    private let primary = Color(hex: "ec5b13")

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 16)
                .frame(width: 288, height: 288)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [primary, Color(hex: "ff8c42")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 288, height: 288)
                .animation(.easeInOut(duration: 0.35), value: progress)

            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 30))

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.gray)
                    .textCase(.uppercase)

                Text(elapsedText)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.top, 4)

                Text(remainingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.gray.opacity(0.8))
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexString.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "0F0F0F").ignoresSafeArea()
        TimerRingView(
            emoji: "🔥",
            title: "Fat Fuel",
            progress: 0.75,
            elapsedText: "14:32:10",
            remainingText: "1h 28m remaining"
        )
    }
    .preferredColorScheme(.dark)
}
