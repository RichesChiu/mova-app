import SwiftUI

struct MediaDetailSectionShell<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .movaGlassPanel(cornerRadius: 24, padding: 18)
    }
}

struct MediaDetailSectionHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder private let trailing: Trailing

    init(
        eyebrow: String,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(MovaTheme.textTertiary)

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(MovaTheme.textPrimary)
            }

            Spacer()
            trailing
        }
    }
}

extension MediaDetailSectionHeader where Trailing == EmptyView {
    init(eyebrow: String, title: String) {
        self.init(eyebrow: eyebrow, title: title) {
            EmptyView()
        }
    }
}

struct MediaDetailMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(MovaTheme.textMuted)

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(MovaTheme.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(MovaInsetBackground(cornerRadius: 18, fill: MovaTheme.controlFill, stroke: MovaTheme.panelStroke))
    }
}

struct MediaDetailSelectableChip: View {
    let title: String
    let isSelected: Bool
    let font: Font
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let action: () -> Void

    init(
        title: String,
        isSelected: Bool,
        font: Font = .caption.weight(.semibold),
        horizontalPadding: CGFloat = 12,
        verticalPadding: CGFloat = 8,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.font = font
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(isSelected ? MovaTheme.textPrimary : MovaTheme.textTertiary)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(
                    Capsule()
                        .fill(isSelected ? MovaTheme.controlFill : Color.clear)
                )
                .overlay {
                    Capsule()
                        .stroke(isSelected ? MovaTheme.panelStroke : MovaTheme.panelStrokeSubtle, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct MediaCastMemberCard: View {
    let member: MediaCastMember
    let imageRequest: (String?) -> URLRequest?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(0.08))

                if let request = imageRequest(member.profilePath) {
                    AuthenticatedImageView(request: request)
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(MovaTheme.textMuted)
                }
            }
            .frame(width: 136, height: 176)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(member.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(MovaTheme.textPrimary)
                .lineLimit(1)

            if let characterName = member.characterName, !characterName.isEmpty {
                Text(characterName)
                    .font(.subheadline)
                    .foregroundStyle(MovaTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .frame(width: 160, alignment: .leading)
        .padding(12)
        .background(MovaInsetBackground(cornerRadius: 22, fill: MovaTheme.cardFill, stroke: MovaTheme.panelStrokeSubtle))
    }
}

struct MediaTechnicalCard<Footer: View>: View {
    let title: String
    let subtitle: String
    let rows: [(String, String)]
    @ViewBuilder private let footer: Footer

    init(
        title: String,
        subtitle: String,
        rows: [(String, String)],
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.subtitle = subtitle
        self.rows = rows
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(MovaTheme.textTertiary)

                Text(subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(MovaTheme.textPrimary)
                    .lineLimit(2)
            }

            if rows.isEmpty {
                Text("没有可展示的技术字段。")
                    .font(.subheadline)
                    .foregroundStyle(MovaTheme.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { entry in
                        let row = entry.element
                        HStack(alignment: .top) {
                            Text(row.0.uppercased())
                                .font(.caption.weight(.semibold))
                                .tracking(1.0)
                                .foregroundStyle(MovaTheme.textMuted)
                                .frame(width: 92, alignment: .leading)

                            Text(row.1)
                                .font(.subheadline)
                                .foregroundStyle(MovaTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            footer
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(MovaInsetBackground(cornerRadius: 22, fill: MovaTheme.cardFill, stroke: MovaTheme.panelStrokeSubtle))
    }
}

extension MediaTechnicalCard where Footer == EmptyView {
    init(title: String, subtitle: String, rows: [(String, String)]) {
        self.init(title: title, subtitle: subtitle, rows: rows) {
            EmptyView()
        }
    }
}
