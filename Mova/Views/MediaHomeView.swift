import SwiftUI
import UIKit
import ImageIO

struct MediaHomeView: View {
    let libraries: [LibrarySummary]
    let libraryPreviewItems: [Int: [MediaItemSummary]]
    let libraryItemsByID: [Int: [MediaItemSummary]]
    let libraryStatsByID: [Int: LibraryStats]
    let selectedLibraryID: Int?
    let mediaItems: [MediaItemSummary]
    let isLoading: Bool
    let imageRequest: (String?) -> URLRequest?
    let loadSeasons: (Int) async -> [SeasonSummary]
    let loadEpisodes: (Int) async -> [EpisodeSummary]
    let onImport: () -> Void
    let onDeleteServer: () -> Void
    let onReload: () -> Void
    let onSelectLibrary: (Int) -> Void

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: 18) {
                    librariesSection
                    mediaSection
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("刷新", systemImage: "arrow.clockwise") {
                        onReload()
                    }
                    Button("导入媒体", systemImage: "plus") {
                        onImport()
                    }
                    Button("删除服务器", systemImage: "trash", role: .destructive) {
                        onDeleteServer()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.white)
                }
            }
        }
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
                .frame(width: 300)
                .blur(radius: 80)
                .offset(x: -120, y: -180)
        }
        .ignoresSafeArea()
    }

    private var librariesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Libraries")

            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(libraries) { library in
                        NavigationLink {
                            LibraryDetailView(
                                library: library,
                                stats: libraryStatsByID[library.id],
                                mediaItems: libraryItemsByID[library.id] ?? [],
                                imageRequest: imageRequest,
                                loadSeasons: loadSeasons,
                                loadEpisodes: loadEpisodes
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                libraryCoverGrid(for: library)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 132)

                                Text(library.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                if let description = library.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(countLabel(for: library))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.85))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.12), in: Capsule())
                            }
                            .frame(width: 250, height: 238, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(
                                        library.id == selectedLibraryID ? Color.white.opacity(0.7) : Color.white.opacity(0.18),
                                        lineWidth: library.id == selectedLibraryID ? 1.2 : 1
                                    )
                            }
                            .onTapGesture {
                                onSelectLibrary(library.id)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            if libraries.isEmpty {
                emptyState(text: isLoading ? "正在加载媒体库..." : "暂无媒体库")
            }
        }
        .glassSectionContainer
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Media")

            if mediaItems.isEmpty {
                emptyState(text: isLoading ? "正在加载媒体内容..." : "该媒体库暂无内容")
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(mediaItems) { item in
                            NavigationLink {
                                MediaItemDetailView(
                                    item: item,
                                    imageRequest: imageRequest,
                                    loadSeasons: loadSeasons,
                                    loadEpisodes: loadEpisodes
                                )
                            } label: {
                                mediaItemCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .glassSectionContainer
    }

    private func mediaItemCard(_ item: MediaItemSummary) -> some View {
        HStack(spacing: 12) {
            posterView(for: item)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(mediaTypeLabel(item.mediaType))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.14), in: Capsule())
                    Spacer()
                    if let year = item.year {
                        Text("\(year)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }

                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(item.overview ?? "暂无简介")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(4)
            }
        }
        .frame(width: 390, height: 166, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
    }

    private func posterView(for item: MediaItemSummary) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.white.opacity(0.08))

            if let request = imageRequest(item.posterPath) {
                AuthenticatedImageView(request: request)
            } else {
                Image(systemName: "film")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 104, height: 146)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func libraryCoverGrid(for library: LibrarySummary) -> some View {
        let covers = libraryPreviewItems[library.id] ?? []
        let sideCount = gridSide(for: covers.count)
        let spacing: CGFloat = 4

        return GeometryReader { proxy in
            let cellSize = max(
                12,
                min(
                    (proxy.size.width - CGFloat(sideCount - 1) * spacing) / CGFloat(sideCount),
                    (proxy.size.height - CGFloat(sideCount - 1) * spacing) / CGFloat(sideCount)
                )
            )

            VStack(spacing: spacing) {
                ForEach(0..<sideCount, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<sideCount, id: \.self) { column in
                            let index = row * sideCount + column
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(.white.opacity(0.08))

                                if covers.indices.contains(index),
                                   let request = imageRequest(covers[index].posterPath) {
                                    AuthenticatedImageView(request: request)
                                } else {
                                    Image(systemName: "film")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.45))
                                }
                            }
                            .frame(width: cellSize, height: cellSize)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func gridSide(for count: Int) -> Int {
        if count <= 4 { return 2 }
        if count <= 9 { return 3 }
        return 4
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .controlSize(.small)
            }
        }
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 18)
    }

    private func countLabel(for library: LibrarySummary) -> String {
        if let mediaCount = library.mediaCount {
            return "\(mediaCount) items"
        }
        return "items"
    }

    private func mediaTypeLabel(_ raw: String?) -> String {
        switch raw {
        case "movie":
            return "Movie"
        case "series":
            return "Series"
        default:
            return "Media"
        }
    }
}

struct AuthenticatedImageView: View {
    let request: URLRequest

    @State private var image: Image?

    var body: some View {
        ZStack {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "film")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .task(id: cacheKey) {
            await loadImage()
        }
    }

    @MainActor
    private func loadImage() async {
        do {
            if let loaded = try await loadFrom(request: request) {
                image = loaded
                return
            }

            var fallbackRequest = request
            fallbackRequest.setValue(nil, forHTTPHeaderField: "Authorization")
            image = try await loadFrom(request: fallbackRequest)
        } catch {
            image = nil
        }
    }

    private var cacheKey: String {
        let urlString = request.url?.absoluteString ?? "no-url"
        let auth = request.value(forHTTPHeaderField: "Authorization") ?? "no-auth"
        return "\(urlString)|\(auth)"
    }

    private func loadFrom(request: URLRequest) async throws -> Image? {
        let (data, response) = try await NetworkClient.sharedSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }

        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        return Image(decorative: cgImage, scale: 1.0)
    }
}

private extension View {
    var glassSectionContainer: some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
    }
}
