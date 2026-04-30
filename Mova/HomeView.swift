import SwiftUI
import UIKit
import ImageIO

struct HomeView: View {
    let serverUsername: String
    let libraries: [LibrarySummary]
    let libraryPreviewItems: [Int: [MediaItemSummary]]
    let libraryItemsByID: [Int: [MediaItemSummary]]
    let libraryStatsByID: [Int: LibraryStats]
    let selectedLibraryID: Int?
    let mediaItems: [MediaItemSummary]
    let isLoading: Bool
    let imageRequest: (String?) -> URLRequest?
    let loadMediaDetail: (Int) async throws -> MediaItemDetail
    let loadEpisodeOutline: (Int) async throws -> SeriesEpisodeOutline
    let loadCastMembers: (Int) async throws -> [MediaCastMember]
    let loadMediaFiles: (Int) async throws -> [MediaFileInfo]
    let loadAudioTracks: (Int) async throws -> [AudioTrackInfo]
    let loadSubtitles: (Int) async throws -> [SubtitleFileInfo]
    let onImport: () -> Void
    let onDeleteServer: () -> Void
    let onReload: () -> Void
    let onSelectLibrary: (Int) -> Void

    @State private var mediaFocusIndex = 0

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView {
                VStack(spacing: 20) {
                    topBar
                    librariesSection
                    mediaSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
        .onChange(of: mediaItems) { _, _ in
            mediaFocusIndex = 0
        }
    }

    private var backgroundLayer: some View {
        MovaPageBackground()
    }

    private var topBar: some View {
        HStack {
            Image("MovaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .shadow(color: MovaTheme.accentBlue.opacity(0.36), radius: 18, y: 8)

            Spacer()

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
                HStack(spacing: 10) {
                    Text(serverUsername)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MovaTheme.textPrimary)

                    Text(userInitial)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(MovaTheme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(MovaTheme.controlFill, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(MovaTheme.panelStroke, lineWidth: 1)
                        }
                }
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(MovaTheme.panelStrokeSubtle, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var librariesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            panelHeader(title: "媒体库") {
                countBubble(libraries.count)
            }

            if libraries.isEmpty {
                emptyState(text: isLoading ? "正在加载媒体库..." : "暂无媒体库")
            } else {
                ScrollViewReader { proxy in
                    carouselShell(
                        leadingAction: { moveLibrary(step: -1, proxy: proxy) },
                        trailingAction: { moveLibrary(step: 1, proxy: proxy) }
                    ) {
                        ScrollView(.horizontal) {
                            HStack(spacing: 26) {
                                ForEach(libraries) { library in
                                    libraryCard(for: library)
                                        .id(library.id)
                                }
                            }
                            .padding(.horizontal, 50)
                            .padding(.vertical, 18)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .onChange(of: selectedLibraryID) { _, id in
                        guard let id else { return }
                        withAnimation(.snappy(duration: 0.32)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }

            Text("横向滚动浏览。")
                .font(.caption)
                .foregroundStyle(MovaTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 318, alignment: .topLeading)
        .movaGlassPanel(cornerRadius: 26)
    }

    private var mediaSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            panelHeader(title: selectedLibrary?.name ?? "Media") {
                EmptyView()
            }

            if mediaItems.isEmpty {
                emptyState(text: isLoading ? "正在加载媒体内容..." : "该媒体库暂无内容")
            } else {
                ScrollViewReader { proxy in
                    carouselShell(
                        leadingAction: { moveMedia(step: -1, proxy: proxy) },
                        trailingAction: { moveMedia(step: 1, proxy: proxy) }
                    ) {
                        ScrollView(.horizontal) {
                            HStack(spacing: 14) {
                                ForEach(mediaItems) { item in
                                    NavigationLink {
                                        mediaDetailDestination(for: item)
                                    } label: {
                                        mediaItemCard(item)
                                    }
                                    .buttonStyle(.plain)
                                    .id(item.id)
                                }
                            }
                            .padding(.horizontal, 50)
                            .padding(.vertical, 18)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }

            Text("横向滚动浏览。")
                .font(.caption)
                .foregroundStyle(MovaTheme.textMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 314, alignment: .topLeading)
        .movaGlassPanel(cornerRadius: 26)
    }

    private func mediaItemCard(_ item: MediaItemSummary) -> some View {
        HStack(spacing: 14) {
            posterView(for: item)

            VStack(alignment: .leading, spacing: 9) {
                Text(item.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MovaTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(mediaTypeLabel(item.mediaType))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MovaTheme.textSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(MovaTheme.controlFill, in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(MovaTheme.panelStrokeSubtle, lineWidth: 1)
                        }

                    if let year = item.year {
                        Text("\(year)")
                            .font(.subheadline)
                            .foregroundStyle(MovaTheme.textSecondary)
                    }
                }

                Text(item.overview ?? "暂无简介")
                    .font(.subheadline)
                    .lineSpacing(3)
                    .foregroundStyle(MovaTheme.textSecondary)
                    .lineLimit(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .frame(width: 430, height: 180, alignment: .leading)
        .background(MovaInsetBackground(cornerRadius: 16, fill: MovaTheme.panelFill.opacity(0.58), stroke: MovaTheme.panelStroke))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
        .frame(width: 122, height: 180)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 16))
    }

    private func libraryCoverGrid(for library: LibrarySummary) -> some View {
        let covers = libraryPreviewItems[library.id] ?? []
        let sideCount = gridSide(for: covers.count)
        let spacing: CGFloat = 2

        return GeometryReader { proxy in
            let cellWidth = max(
                12,
                (proxy.size.width - CGFloat(sideCount - 1) * spacing) / CGFloat(sideCount)
            )
            let cellHeight = max(
                12,
                (proxy.size.height - CGFloat(sideCount - 1) * spacing) / CGFloat(sideCount)
            )

            VStack(spacing: spacing) {
                ForEach(0..<sideCount, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<sideCount, id: \.self) { column in
                            let index = row * sideCount + column
                            ZStack {
                                Rectangle()
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
                            .frame(width: cellWidth, height: cellHeight)
                            .clipped()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func gridSide(for count: Int) -> Int {
        if count <= 4 { return 2 }
        if count <= 9 { return 3 }
        return 4
    }

    private func panelHeader<Trailing: View>(
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(MovaTheme.textPrimary)

                Image(systemName: "questionmark.circle")
                    .font(.caption)
                    .foregroundStyle(MovaTheme.textMuted)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .tint(.white)
                    .controlSize(.small)
                    .padding(.trailing, 8)
            }

            trailing()
        }
    }

    private func libraryCard(for library: LibrarySummary) -> some View {
        NavigationLink {
            libraryDetailDestination(for: library)
        } label: {
            ZStack(alignment: .topLeading) {
                libraryCoverGrid(for: library)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.12),
                                Color.black.opacity(0.18),
                                Color.black.opacity(0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text(library.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.55), radius: 10, y: 4)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(libraryBadges(for: library), id: \.self) { badge in
                            Text(badge)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.78))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(0.12), lineWidth: 1)
                                }
                        }
                    }
                }
                .padding(18)
            }
            .frame(width: 306, height: 196)
            .background(MovaInsetBackground(cornerRadius: 18, fill: MovaTheme.panelFill.opacity(0.36), stroke: MovaTheme.panelStrokeSubtle))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        library.id == selectedLibraryID ? MovaTheme.textTertiary : MovaTheme.panelStroke,
                        lineWidth: library.id == selectedLibraryID ? 1.4 : 1
                    )
            }
            .shadow(color: .black.opacity(0.24), radius: 24, y: 12)
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                onSelectLibrary(library.id)
            }
        )
    }

    private func carouselShell<Content: View>(
        leadingAction: @escaping () -> Void,
        trailingAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            content()

            HStack {
                carouselButton(systemName: "chevron.left", action: leadingAction)
                Spacer()
                carouselButton(systemName: "chevron.right", action: trailingAction)
            }
            .padding(.horizontal, 2)
        }
    }

    private func carouselButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.52))
                .frame(width: 34, height: 34)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }

    private func countBubble(_ count: Int) -> some View {
        Text("\(count)")
            .font(.subheadline.weight(.bold))
            .foregroundStyle(MovaTheme.textPrimary)
            .frame(width: 34, height: 34)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .stroke(MovaTheme.panelStrokeSubtle, lineWidth: 1)
            }
    }

    private func emptyState(text: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.45))

            Text(text)
                .font(.subheadline)
                .foregroundStyle(MovaTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func libraryDetailDestination(for library: LibrarySummary) -> some View {
        LibraryDetailView(
            library: library,
            stats: libraryStatsByID[library.id],
            mediaItems: libraryItemsByID[library.id] ?? [],
            imageRequest: imageRequest,
            loadMediaDetail: loadMediaDetail,
            loadEpisodeOutline: loadEpisodeOutline,
            loadCastMembers: loadCastMembers,
            loadMediaFiles: loadMediaFiles,
            loadAudioTracks: loadAudioTracks,
            loadSubtitles: loadSubtitles
        )
    }

    private func mediaDetailDestination(for item: MediaItemSummary) -> some View {
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
    }

    private func moveLibrary(step: Int, proxy: ScrollViewProxy) {
        guard !libraries.isEmpty else { return }

        let currentIndex = selectedLibraryID.flatMap { id in
            libraries.firstIndex { $0.id == id }
        } ?? 0
        let nextIndex = min(max(currentIndex + step, 0), libraries.count - 1)
        let library = libraries[nextIndex]

        onSelectLibrary(library.id)
        withAnimation(.snappy(duration: 0.32)) {
            proxy.scrollTo(library.id, anchor: .center)
        }
    }

    private func moveMedia(step: Int, proxy: ScrollViewProxy) {
        guard !mediaItems.isEmpty else { return }

        mediaFocusIndex = min(max(mediaFocusIndex + step, 0), mediaItems.count - 1)
        withAnimation(.snappy(duration: 0.32)) {
            proxy.scrollTo(mediaItems[mediaFocusIndex].id, anchor: .center)
        }
    }

    private var selectedLibrary: LibrarySummary? {
        guard let selectedLibraryID else { return libraries.first }
        return libraries.first { $0.id == selectedLibraryID }
    }

    private var userInitial: String {
        let trimmed = serverUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = trimmed.first {
            return String(first).uppercased()
        }
        return "M"
    }

    private func libraryBadges(for library: LibrarySummary) -> [String] {
        if let stats = libraryStatsByID[library.id] {
            return [
                "\(stats.total) 条资源",
                "\(stats.movieCount) 部电影",
                "\(stats.seriesCount) 部剧集"
            ]
        }

        if let mediaCount = library.mediaCount {
            return ["\(mediaCount) 条资源"]
        }

        return []
    }

    private func mediaTypeLabel(_ raw: String?) -> String {
        switch raw {
        case "movie":
            return "电影"
        case "series":
            return "剧集"
        default:
            return "媒体"
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
