import SwiftUI

/// A translucent glass/aqua panel: blurred material fill, glossy top highlight,
/// hairline rim light, and a soft drop shadow — the core Frutiger Aero surface.
struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = Aero.cornerRadiusLarge
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Aero.panelGradient)
                        .opacity(0.6)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Aero.deepBlue.opacity(0.25), radius: 16, x: 0, y: 10)
    }
}

/// Convenience modifier form so any view can become a glass surface inline.
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = Aero.cornerRadiusMedium

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Aero.deepBlue.opacity(0.18), radius: 10, x: 0, y: 6)
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = Aero.cornerRadiusMedium) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
