import SwiftUI

/// Central Frutiger Aero (Web 2.0 / early iTunes / Vista / early iPod) design language.
/// Bright sky-to-aqua gradients, glossy glass panels, bubbly buttons, soft highlights.
enum Aero {

    // MARK: Palette

    static let skyBlue = Color(red: 0.35, green: 0.72, blue: 0.98)
    static let deepBlue = Color(red: 0.09, green: 0.38, blue: 0.78)
    static let aqua = Color(red: 0.24, green: 0.87, blue: 0.83)
    static let leafGreen = Color(red: 0.45, green: 0.86, blue: 0.42)
    static let sunHighlight = Color(red: 1.0, green: 0.98, blue: 0.88)
    static let glassWhite = Color.white.opacity(0.55)
    static let ink = Color(red: 0.07, green: 0.17, blue: 0.28)
    static let inkSoft = Color(red: 0.20, green: 0.32, blue: 0.42)

    static let backgroundGradient = LinearGradient(
        colors: [deepBlue, skyBlue, aqua, leafGreen.opacity(0.75)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panelGradient = LinearGradient(
        colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
        startPoint: .top,
        endPoint: .bottom
    )

    static func accentGradient(_ base: Color) -> LinearGradient {
        LinearGradient(
            colors: [base.opacity(0.95), base.opacity(0.65)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Metrics

    static let cornerRadiusLarge: CGFloat = 28
    static let cornerRadiusMedium: CGFloat = 18
    static let cornerRadiusSmall: CGFloat = 12

    // MARK: Typography

    static func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(ink)
    }

    static func heading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(ink)
    }

    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(inkSoft)
    }
}

/// App-wide animated bright gradient backdrop with soft bokeh circles and a
/// subtle top-edge light reflection, evoking the "nature-tech" Aero look.
struct AeroBackground: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Aero.backgroundGradient
                .ignoresSafeArea()

            BokehLayer()
                .ignoresSafeArea()
                .opacity(0.55)

            LinearGradient(
                colors: [Color.white.opacity(0.35), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .blendMode(.plusLighter)
        }
        .onAppear { animate = true }
        .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
    }
}

/// Soft floating "bokeh"/lens-flare style translucent circles, a signature
/// Frutiger Aero motif alongside water droplets and leaves.
struct BokehLayer: View {
    private struct Bubble: Identifiable {
        let id = UUID()
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let opacity: Double
    }

    private let bubbles: [Bubble] = [
        Bubble(size: 180, x: 0.12, y: 0.10, opacity: 0.35),
        Bubble(size: 90, x: 0.80, y: 0.06, opacity: 0.45),
        Bubble(size: 130, x: 0.85, y: 0.35, opacity: 0.30),
        Bubble(size: 60, x: 0.20, y: 0.55, opacity: 0.40),
        Bubble(size: 220, x: 0.55, y: 0.80, opacity: 0.25),
        Bubble(size: 45, x: 0.10, y: 0.85, opacity: 0.5)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(bubble.opacity), Color.white.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: bubble.size / 2
                            )
                        )
                        .frame(width: bubble.size, height: bubble.size)
                        .position(x: proxy.size.width * bubble.x, y: proxy.size.height * bubble.y)
                }
            }
        }
    }
}
