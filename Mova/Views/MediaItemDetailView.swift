import SwiftUI

struct MediaItemDetailView: View {
    let item: MediaItemSummary
    let imageRequest: (String?) -> URLRequest?
    let loadSeasons: (Int) async -> [SeasonSummary]
    let loadEpisodes: (Int) async -> [EpisodeSummary]

    @State private var seasons: [SeasonSummary] = []
    @State private var episodesBySeason: [Int: [EpisodeSummary]] = [:]
    @State private var loadingSeasons = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header

                    if item.mediaType == "series" {
                        seriesSection
                    } else {
                        movieSection
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSeriesDataIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.08))
                if let request = imageRequest(item.posterPath) {
                    AuthenticatedImageView(request: request)
                }
            }
            .frame(width: 96, height: 144)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    Text(item.mediaType == "series" ? "Series" : "Movie")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.14), in: Capsule())
                    if let year = item.year {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                Text(item.overview ?? "暂无简介")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(5)
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

    private var movieSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("电影播放")
                .font(.headline)
                .foregroundStyle(.white)
            Text("电影类型直接展示播放入口和基础信息。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 4)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white.opacity(0.08))
                .frame(height: 96)
                .overlay {
                    Label("Play Movie", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var seriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("季与集")
                .font(.headline)
                .foregroundStyle(.white)

            if loadingSeasons {
                ProgressView()
                    .tint(.white)
            } else if seasons.isEmpty {
                Text("暂无季信息")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                ForEach(seasons) { season in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(seasonTitle(season))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)

                        let episodes = episodesBySeason[season.id] ?? []
                        if episodes.isEmpty {
                            Text("暂无分集")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        } else {
                            ForEach(episodes.prefix(8)) { episode in
                                HStack(spacing: 8) {
                                    Text(episodeTag(episode))
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Text(episode.title ?? "未命名分集")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func loadSeriesDataIfNeeded() async {
        guard item.mediaType == "series", seasons.isEmpty else { return }
        loadingSeasons = true
        let loadedSeasons = await loadSeasons(item.id)
        seasons = loadedSeasons

        await withTaskGroup(of: (Int, [EpisodeSummary]).self) { group in
            for season in loadedSeasons {
                group.addTask {
                    let episodes = await loadEpisodes(season.id)
                    return (season.id, episodes)
                }
            }

            for await (seasonID, episodes) in group {
                episodesBySeason[seasonID] = episodes
            }
        }
        loadingSeasons = false
    }

    private func seasonTitle(_ season: SeasonSummary) -> String {
        if let number = season.seasonNumber {
            return "Season \(number)"
        }
        return season.title ?? "Season"
    }

    private func episodeTag(_ episode: EpisodeSummary) -> String {
        if let number = episode.episodeNumber {
            return "E\(number)"
        }
        return "EP"
    }
}
