import SwiftUI

/// Animated Frutiger Aero aquarium backdrop: rising bubbles, swaying seagrass,
/// and the three signature reef fish of the aesthetic — clownfish, blue tang,
/// and moorish idol — drifting across the screen behind the UI's glass panels.
/// Drawn entirely as vector art in a Canvas, driven by TimelineView, so there
/// are no image assets to bundle. Freezes to a static frame under Reduce Motion.
struct AquariumLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 40 : timeline.date.timeIntervalSinceReferenceDate
                Self.drawSeagrass(&context, size: size, time: t)
                Self.drawBubbles(&context, size: size, time: t)
                Self.drawFish(&context, size: size, time: t)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Fleet

    private enum FishKind { case clownfish, blueTang, moorishIdol }

    private struct FishSpec {
        let kind: FishKind
        let laneY: CGFloat      // vertical position as a fraction of height
        let scale: CGFloat
        let speed: CGFloat      // points per second
        let leftToRight: Bool
        let phase: Double       // desynchronizes the loop per fish
    }

    private static let fleet: [FishSpec] = [
        FishSpec(kind: .clownfish, laneY: 0.16, scale: 0.95, speed: 26, leftToRight: true, phase: 0.0),
        FishSpec(kind: .blueTang, laneY: 0.32, scale: 1.10, speed: 20, leftToRight: false, phase: 3.2),
        FishSpec(kind: .moorishIdol, laneY: 0.52, scale: 1.00, speed: 15, leftToRight: true, phase: 6.7),
        FishSpec(kind: .clownfish, laneY: 0.70, scale: 0.60, speed: 33, leftToRight: false, phase: 9.1),
        FishSpec(kind: .blueTang, laneY: 0.85, scale: 0.70, speed: 24, leftToRight: true, phase: 12.4),
    ]

    private static func drawFish(_ ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let margin: CGFloat = 90
        let travel = size.width + margin * 2
        for spec in fleet {
            let progress = (CGFloat(time) * spec.speed + CGFloat(spec.phase) * 83).truncatingRemainder(dividingBy: travel)
            let x = spec.leftToRight ? progress - margin : size.width + margin - progress
            let y = spec.laneY * size.height + sin(time * 1.1 + spec.phase) * 9

            ctx.drawLayer { layer in
                layer.translateBy(x: x, y: y)
                layer.scaleBy(x: spec.leftToRight ? spec.scale : -spec.scale, y: spec.scale)
                switch spec.kind {
                case .clownfish: drawClownfish(&layer)
                case .blueTang: drawBlueTang(&layer)
                case .moorishIdol: drawMoorishIdol(&layer)
                }
            }
        }
    }

    // MARK: - Fish bodies (local coords, nose pointing +x, centered on origin)

    private static func drawClownfish(_ ctx: inout GraphicsContext) {
        let orange = Color(red: 1.0, green: 0.55, blue: 0.12)
        let darkOrange = Color(red: 0.85, green: 0.42, blue: 0.02)
        let bodyRect = CGRect(x: -28, y: -16, width: 60, height: 32)
        let body = Path(ellipseIn: bodyRect)

        var tail = Path()
        tail.move(to: CGPoint(x: -24, y: 0))
        tail.addLine(to: CGPoint(x: -42, y: -13))
        tail.addLine(to: CGPoint(x: -37, y: 0))
        tail.addLine(to: CGPoint(x: -42, y: 13))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(orange))
        ctx.stroke(tail, with: .color(darkOrange), lineWidth: 1)

        var dorsal = Path()
        dorsal.move(to: CGPoint(x: -8, y: -14))
        dorsal.addQuadCurve(to: CGPoint(x: 12, y: -13), control: CGPoint(x: 2, y: -26))
        dorsal.closeSubpath()
        ctx.fill(dorsal, with: .color(darkOrange))

        ctx.fill(body, with: .color(orange))
        ctx.stroke(body, with: .color(darkOrange), lineWidth: 1)

        ctx.drawLayer { layer in
            layer.clip(to: body)
            for (cx, w): (CGFloat, CGFloat) in [(14, 9), (-2, 10), (-19, 7)] {
                let stripe = Path(roundedRect: CGRect(x: cx - w / 2, y: -18, width: w, height: 36), cornerRadius: w / 2)
                layer.fill(stripe, with: .color(.white))
                layer.stroke(stripe, with: .color(.black.opacity(0.35)), lineWidth: 1)
            }
            let gloss = Path(ellipseIn: CGRect(x: -22, y: -15, width: 48, height: 11))
            layer.fill(gloss, with: .color(.white.opacity(0.35)))
        }

        ctx.fill(Path(ellipseIn: CGRect(x: 17, y: -8, width: 6, height: 6)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: 19, y: -7, width: 2, height: 2)), with: .color(.white))
    }

    private static func drawBlueTang(_ ctx: inout GraphicsContext) {
        let blue = Color(red: 0.16, green: 0.42, blue: 0.90)
        let navy = Color(red: 0.04, green: 0.11, blue: 0.28)
        let yellow = Color(red: 1.0, green: 0.83, blue: 0.10)
        let bodyRect = CGRect(x: -32, y: -17, width: 66, height: 34)
        let body = Path(ellipseIn: bodyRect)

        var tail = Path()
        tail.move(to: CGPoint(x: -28, y: 0))
        tail.addLine(to: CGPoint(x: -46, y: -14))
        tail.addLine(to: CGPoint(x: -41, y: 0))
        tail.addLine(to: CGPoint(x: -46, y: 14))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(yellow))

        ctx.fill(
            body,
            with: .linearGradient(
                Gradient(colors: [blue.opacity(0.95), navy]),
                startPoint: CGPoint(x: 0, y: -17),
                endPoint: CGPoint(x: 0, y: 17)
            )
        )

        ctx.drawLayer { layer in
            layer.clip(to: body)
            // The tang's dark "palette" marking along the upper body.
            layer.fill(Path(ellipseIn: CGRect(x: -26, y: -12, width: 46, height: 13)), with: .color(navy.opacity(0.9)))
            layer.fill(Path(ellipseIn: CGRect(x: -14, y: -6, width: 26, height: 10)), with: .color(navy.opacity(0.7)))
            let gloss = Path(ellipseIn: CGRect(x: -26, y: -16, width: 52, height: 9))
            layer.fill(gloss, with: .color(.white.opacity(0.28)))
        }

        ctx.fill(Path(ellipseIn: CGRect(x: 21, y: -8, width: 6, height: 6)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: 23, y: -7, width: 2, height: 2)), with: .color(.white))
    }

    private static func drawMoorishIdol(_ ctx: inout GraphicsContext) {
        let black = Color(red: 0.09, green: 0.09, blue: 0.10)
        let yellow = Color(red: 1.0, green: 0.83, blue: 0.10)
        let bodyRect = CGRect(x: -20, y: -21, width: 42, height: 42)
        let body = Path(ellipseIn: bodyRect)

        // Trailing dorsal streamer — the moorish idol's signature.
        var streamer = Path()
        streamer.move(to: CGPoint(x: 2, y: -19))
        streamer.addQuadCurve(to: CGPoint(x: -36, y: -34), control: CGPoint(x: 16, y: -42))
        ctx.stroke(streamer, with: .color(.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        var tail = Path()
        tail.move(to: CGPoint(x: -17, y: 0))
        tail.addLine(to: CGPoint(x: -30, y: -9))
        tail.addLine(to: CGPoint(x: -27, y: 0))
        tail.addLine(to: CGPoint(x: -30, y: 9))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(black))

        var snout = Path()
        snout.move(to: CGPoint(x: 18, y: 2))
        snout.addLine(to: CGPoint(x: 28, y: 6))
        snout.addLine(to: CGPoint(x: 18, y: 10))
        snout.closeSubpath()
        ctx.fill(snout, with: .color(yellow))

        ctx.fill(body, with: .color(.white))
        ctx.drawLayer { layer in
            layer.clip(to: body)
            layer.fill(Path(CGRect(x: -3, y: -24, width: 14, height: 48)), with: .color(black))
            layer.fill(Path(CGRect(x: -14, y: -24, width: 9, height: 48)), with: .color(yellow))
            layer.fill(Path(CGRect(x: -20, y: -24, width: 5, height: 48)), with: .color(black))
            let gloss = Path(ellipseIn: CGRect(x: -16, y: -19, width: 34, height: 9))
            layer.fill(gloss, with: .color(.white.opacity(0.4)))
        }

        ctx.fill(Path(ellipseIn: CGRect(x: 11, y: -10, width: 5, height: 5)), with: .color(.black))
        ctx.fill(Path(ellipseIn: CGRect(x: 12.5, y: -9, width: 1.6, height: 1.6)), with: .color(.white))
    }

    // MARK: - Bubbles

    private static func drawBubbles(_ ctx: inout GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<16 {
            let seed = Double(i)
            let xFraction = fract(seed * 0.6180339887 + 0.11)
            let riseSpeed = 0.045 + fract(seed * 0.2716) * 0.075   // screen-heights per second
            let progress = fract(time * riseSpeed + fract(seed * 0.397))
            let radius = 2.5 + fract(seed * 0.531) * 7

            let y = (1.12 - progress * 1.24) * size.height
            let x = xFraction * size.width + sin(time * 0.9 + seed) * 10
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            let bubble = Path(ellipseIn: rect)

            ctx.fill(
                bubble,
                with: .radialGradient(
                    Gradient(colors: [.white.opacity(0.05), .white.opacity(0.3)]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 0,
                    endRadius: radius
                )
            )
            ctx.stroke(bubble, with: .color(.white.opacity(0.5)), lineWidth: 1)
            let glint = Path(ellipseIn: CGRect(x: x - radius * 0.45, y: y - radius * 0.55, width: radius * 0.45, height: radius * 0.3))
            ctx.fill(glint, with: .color(.white.opacity(0.7)))
        }
    }

    // MARK: - Seagrass

    private static func drawSeagrass(_ ctx: inout GraphicsContext, size: CGSize, time: Double) {
        let green = Color(red: 0.30, green: 0.69, blue: 0.32)
        let blades: [(x: CGFloat, height: CGFloat, width: CGFloat)] = [
            (0.05, 70, 5), (0.09, 105, 6), (0.14, 82, 5),
            (0.82, 90, 5), (0.88, 118, 6), (0.94, 74, 5),
        ]
        for (i, blade) in blades.enumerated() {
            let sway = sin(time * 0.7 + Double(i) * 1.3) * 9
            let baseX = blade.x * size.width
            let baseY = size.height + 4
            var path = Path()
            path.move(to: CGPoint(x: baseX, y: baseY))
            path.addQuadCurve(
                to: CGPoint(x: baseX + sway, y: baseY - blade.height),
                control: CGPoint(x: baseX - 7, y: baseY - blade.height * 0.55)
            )
            ctx.stroke(
                path,
                with: .color(green.opacity(0.42)),
                style: StrokeStyle(lineWidth: blade.width, lineCap: .round)
            )
        }
    }

    private static func fract(_ x: Double) -> Double { x - floor(x) }
}
