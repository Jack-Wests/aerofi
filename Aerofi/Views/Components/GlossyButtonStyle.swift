import SwiftUI

/// Bubbly, glossy, 3D-sheen button — the iconic early-Web-2.0 "aqua" button.
/// A saturated base color, a bright top highlight capsule, and a press-down
/// scale/shadow response.
struct GlossyButtonStyle: ButtonStyle {
    var tint: Color = Aero.skyBlue
    var isCircular: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = isCircular ? AnyShape(Circle()) : AnyShape(Capsule())

        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, isCircular ? 0 : 22)
            .padding(.vertical, isCircular ? 0 : 12)
            .background {
                ZStack {
                    shape.fill(Aero.accentGradient(tint))
                    shape.fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.75), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(2)
                    .mask(shape)
                    shape.strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                }
            }
            .shadow(color: tint.opacity(0.5), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Circular glossy control for transport buttons (play/pause/skip).
struct GlossyIconButton: View {
    let systemName: String
    var tint: Color = Aero.skyBlue
    var diameter: CGFloat = 56
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: diameter * 0.4, weight: .bold))
                .frame(width: diameter, height: diameter)
        }
        .buttonStyle(GlossyButtonStyle(tint: tint, isCircular: true))
    }
}

/// Type-erased Shape so one ButtonStyle can back either capsules or circles.
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}
