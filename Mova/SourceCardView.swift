import SwiftUI

struct SourceCardView: View {
    let title: String
    let detail: String
    let icon: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(MovaTheme.accentBlue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(MovaTheme.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(MovaTheme.textSecondary)
            }

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(.body.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
        }
        .padding(14)
        .background(MovaInsetBackground(cornerRadius: 14, fill: MovaTheme.cardFill, stroke: MovaTheme.panelStrokeSubtle))
    }
}
