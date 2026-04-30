import SwiftUI

enum MovaTheme {
    static let canvasTop = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let canvasMid = Color(red: 0.0, green: 0.01, blue: 0.015)
    static let canvasBottom = Color.black

    static let accentBlue = Color(red: 0.15, green: 0.55, blue: 0.95)
    static let accentViolet = Color(red: 0.28, green: 0.18, blue: 0.45)

    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.72)
    static let textTertiary = Color.white.opacity(0.56)
    static let textMuted = Color.white.opacity(0.42)

    static let panelStroke = Color.white.opacity(0.14)
    static let panelStrokeSubtle = Color.white.opacity(0.10)
    static let panelFill = Color(red: 0.04, green: 0.07, blue: 0.11)
    static let panelFillDeep = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let cardFill = Color.white.opacity(0.04)
    static let cardFillQuiet = Color.white.opacity(0.025)
    static let controlFill = Color.white.opacity(0.055)
}

struct MovaPageBackground: View {
    enum GlowPosition {
        case leading
        case trailing
    }

    let glowPosition: GlowPosition

    init(glowPosition: GlowPosition = .leading) {
        self.glowPosition = glowPosition
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    MovaTheme.canvasTop,
                    MovaTheme.canvasMid,
                    MovaTheme.canvasBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    MovaTheme.accentBlue.opacity(0.20),
                    .clear
                ],
                center: glowPosition == .leading ? .topLeading : .topTrailing,
                startRadius: 20,
                endRadius: 560
            )

            RadialGradient(
                colors: [
                    MovaTheme.accentViolet.opacity(0.14),
                    .clear
                ],
                center: .bottomTrailing,
                startRadius: 80,
                endRadius: 760
            )
        }
        .ignoresSafeArea()
    }
}

struct MovaGlassBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MovaTheme.panelFill.opacity(0.56),
                                MovaTheme.panelFillDeep.opacity(0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(MovaTheme.panelStroke, lineWidth: 1)
            }
    }
}

struct MovaInsetBackground: View {
    let cornerRadius: CGFloat
    let fill: Color
    let stroke: Color

    init(
        cornerRadius: CGFloat,
        fill: Color = MovaTheme.cardFill,
        stroke: Color = MovaTheme.panelStrokeSubtle
    ) {
        self.cornerRadius = cornerRadius
        self.fill = fill
        self.stroke = stroke
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fill)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(stroke, lineWidth: 1)
            }
    }
}

struct MovaGhostActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(MovaTheme.textSecondary)
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .background(
            MovaInsetBackground(
                cornerRadius: 11,
                fill: MovaTheme.panelFill.opacity(0.46),
                stroke: MovaTheme.panelStrokeSubtle
            )
        )
    }
}

extension View {
    func movaGlassPanel(cornerRadius: CGFloat = 24, padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .background(MovaGlassBackground(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.30), radius: 28, y: 14)
    }

    func movaInsetCard(cornerRadius: CGFloat = 22, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(MovaInsetBackground(cornerRadius: cornerRadius))
    }
}
