import SwiftUI

struct SourceSetupView: View {
    let hasAnySource: Bool
    let hasServerInfo: Bool
    let hasValidatedServer: Bool
    let serverAddress: String
    let onImport: () -> Void
    let onDeleteServer: () -> Void

    var body: some View {
        ZStack {
            MovaPageBackground()

            if hasAnySource {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if hasServerInfo {
                            SourceCardView(
                                title: hasValidatedServer ? "服务器（已登录）" : "服务器（未登录）",
                                detail: serverAddress,
                                icon: "server.rack",
                                onDelete: onDeleteServer
                            )
                        }

                        Button("继续导入", systemImage: "plus.circle") {
                            onImport()
                        }
                        .foregroundStyle(MovaTheme.textSecondary)
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            } else {
                VStack(spacing: 18) {
                    Image("MovaLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .padding(18)
                        .background(MovaGlassBackground(cornerRadius: 28))
                        .shadow(color: MovaTheme.accentBlue.opacity(0.18), radius: 22, y: 10)

                    Text("还没有媒体来源")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(MovaTheme.textPrimary)

                    Text("导入服务器信息后开始使用")
                        .font(.subheadline)
                        .foregroundStyle(MovaTheme.textSecondary)

                    Button {
                        onImport()
                    } label: {
                        MovaGhostActionLabel(title: "导入媒体", systemImage: "tray.and.arrow.down")
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
                .multilineTextAlignment(.center)
                .padding(24)
                .movaGlassPanel(cornerRadius: 28, padding: 28)
                .padding(24)
            }
        }
    }
}
