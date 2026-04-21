import SwiftUI

struct LibraryDetailView: View {
    let library: LibrarySummary
    let stats: LibraryStats?
    let mediaItems: [MediaItemSummary]
    let imageRequest: (String?) -> URLRequest?
    let loadSeasons: (Int) async -> [SeasonSummary]
    let loadEpisodes: (Int) async -> [EpisodeSummary]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.05, blue: 0.12), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    headerCard

                    ForEach(mediaItems) { item in
                        NavigationLink {
                            MediaItemDetailView(
                                item: item,
                                imageRequest: imageRequest,
                                loadSeasons: loadSeasons,
                                loadEpisodes: loadEpisodes
                            )
                        } label: {
                            libraryMediaCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(library.name)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            if let stats {
                HStack(spacing: 10) {
                    statBlock(title: "总资源", value: "\(stats.total)")

                    if stats.movieCount > 0 {
                        statBlock(title: "电影", value: "\(stats.movieCount)")
                    }
                    if stats.seriesCount > 0 {
                        statBlock(title: "电视剧", value: "\(stats.seriesCount)")
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func libraryMediaCard(_ item: MediaItemSummary) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.white.opacity(0.08))
                if let request = imageRequest(item.posterPath) {
                    AuthenticatedImageView(request: request)
                }
            }
            .frame(width: 78, height: 118)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack {
                    Text(item.mediaType == "series" ? "Series" : "Movie")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.14), in: Capsule())
                    if let year = item.year {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Text(item.overview ?? "暂无简介")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }
}
