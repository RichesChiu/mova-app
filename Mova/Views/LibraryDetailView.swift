import SwiftUI

struct LibraryDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let library: LibrarySummary
    let stats: LibraryStats?
    let mediaItems: [MediaItemSummary]
    let imageRequest: (String?) -> URLRequest?
    let loadMediaDetail: (Int) async throws -> MediaItemDetail
    let loadEpisodeOutline: (Int) async throws -> SeriesEpisodeOutline
    let loadCastMembers: (Int) async throws -> [MediaCastMember]
    let loadMediaFiles: (Int) async throws -> [MediaFileInfo]
    let loadAudioTracks: (Int) async throws -> [AudioTrackInfo]
    let loadSubtitles: (Int) async throws -> [SubtitleFileInfo]

    private var movieItems: [MediaItemSummary] {
        mediaItems.filter { $0.mediaType == "movie" }
    }

    private var seriesItems: [MediaItemSummary] {
        mediaItems.filter { $0.mediaType == "series" }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    backButton
                    headerCard

                    if !movieItems.isEmpty {
                        mediaSection(title: "Movies", items: movieItems)
                    }

                    if !seriesItems.isEmpty {
                        mediaSection(title: "Series", items: seriesItems)
                    }

                    if mediaItems.isEmpty {
                        emptySection
                    }
                }
                .padding(16)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [Color(red: 0.02, green: 0.05, blue: 0.12), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 320)
                .blur(radius: 90)
                .offset(x: 160, y: -220)
        }
        .ignoresSafeArea()
    }

    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Back Home", systemImage: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .buttonStyle(.plain)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(library.name)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                if let description = library.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }

            HStack(spacing: 12) {
                statCard(
                    title: "Detected",
                    value: detectedLabel
                )
                statCard(
                    title: "Items",
                    value: "\(stats?.total ?? mediaItems.count)"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(sectionBackground)
    }

    private var detectedLabel: String {
        let movieCount = stats?.movieCount ?? movieItems.count
        let seriesCount = stats?.seriesCount ?? seriesItems.count
        return "\(movieCount) movies / \(seriesCount) series"
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.46))

            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 220, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func mediaSection(title: String, items: [MediaItemSummary]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(items) { item in
                        NavigationLink {
                            MediaItemDetailView(
                                item: item,
                                imageRequest: imageRequest,
                                loadMediaDetail: loadMediaDetail,
                                loadEpisodeOutline: loadEpisodeOutline,
                                loadCastMembers: loadCastMembers,
                                loadMediaFiles: loadMediaFiles,
                                loadAudioTracks: loadAudioTracks,
                                loadSubtitles: loadSubtitles
                            )
                        } label: {
                            libraryMediaCard(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
        .padding(18)
        .background(sectionBackground)
    }

    private var emptySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Media")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("这个媒体库还没有扫描到内容。")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(sectionBackground)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
    }

    private func libraryMediaCard(_ item: MediaItemSummary) -> some View {
        HStack(spacing: 14) {
            posterView(for: item)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(mediaTypeLabel(for: item))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.08), in: Capsule())

                    Spacer()

                    if let year = item.year {
                        Text("\(year)")
                            .font(.headline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.62))
                    }
                }

                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.overview ?? "")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
        }
        .frame(width: 360, height: 180, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func posterView(for item: MediaItemSummary) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))

            if let request = imageRequest(item.posterPath) {
                AuthenticatedImageView(request: request)
            } else {
                Image(systemName: "film")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 118, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func mediaTypeLabel(for item: MediaItemSummary) -> String {
        switch item.mediaType {
        case "movie":
            return "Movie"
        case "series":
            return "Series"
        default:
            return "Media"
        }
    }
}
