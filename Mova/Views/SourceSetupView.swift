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
            Color(.systemBackground)
                .ignoresSafeArea()

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
                        .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                }
            } else {
                VStack(spacing: 18) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 44, weight: .regular))
                        .foregroundStyle(.secondary)

                    Text("还没有媒体来源")
                        .font(.title3.weight(.semibold))

                    Text("导入服务器信息后开始使用")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        onImport()
                    } label: {
                        Label("导入媒体", systemImage: "tray.and.arrow.down")
                            .font(.headline)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 6)
                }
                .multilineTextAlignment(.center)
                .padding(24)
            }
        }
    }
}
