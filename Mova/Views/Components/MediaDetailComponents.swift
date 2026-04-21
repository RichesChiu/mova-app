import SwiftUI

struct MediaDetailSectionShell<Content: View>: View {
    @ViewBuilder private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
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
                    .foregroundStyle(.white.opacity(0.58))

                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
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
                .foregroundStyle(.white.opacity(0.45))

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minWidth: 160, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
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
                .foregroundStyle(isSelected ? .white : .white.opacity(0.58))
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white.opacity(0.08) : Color.clear)
                )
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
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
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
            .frame(width: 136, height: 176)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(member.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if let characterName = member.characterName, !characterName.isEmpty {
                Text(characterName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(2)
            }
        }
        .frame(width: 160, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
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
                    .foregroundStyle(.white.opacity(0.56))

                Text(subtitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            if rows.isEmpty {
                Text("没有可展示的技术字段。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { entry in
                        let row = entry.element
                        HStack(alignment: .top) {
                            Text(row.0.uppercased())
                                .font(.caption.weight(.semibold))
                                .tracking(1.0)
                                .foregroundStyle(.white.opacity(0.44))
                                .frame(width: 92, alignment: .leading)

                            Text(row.1)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.84))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            footer
        }
        .frame(width: 320, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }
}

extension MediaTechnicalCard where Footer == EmptyView {
    init(title: String, subtitle: String, rows: [(String, String)]) {
        self.init(title: title, subtitle: subtitle, rows: rows) {
            EmptyView()
        }
    }
}
