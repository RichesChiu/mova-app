import SwiftUI

struct MediaItemDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let item: MediaItemSummary
    let imageRequest: (String?) -> URLRequest?
    let loadMediaDetail: (Int) async throws -> MediaItemDetail
    let loadEpisodeOutline: (Int) async throws -> SeriesEpisodeOutline
    let loadCastMembers: (Int) async throws -> [MediaCastMember]
    let loadMediaFiles: (Int) async throws -> [MediaFileInfo]
    let loadAudioTracks: (Int) async throws -> [AudioTrackInfo]
    let loadSubtitles: (Int) async throws -> [SubtitleFileInfo]

    @State private var detail: MediaItemDetail?
    @State private var outline: SeriesEpisodeOutline?
    @State private var castMembers: [MediaCastMember] = []
    @State private var mediaFiles: [MediaFileInfo] = []
    @State private var audioTracks: [AudioTrackInfo] = []
    @State private var subtitles: [SubtitleFileInfo] = []
    @State private var selectedSeasonNumber: Int?
    @State private var selectedMediaFileID: Int?
    @State private var selectedAudioTrackIndex: Int?
    @State private var selectedSubtitleFileID: Int?
    @State private var isLoading = false
    @State private var detailErrorMessage: String?
    @State private var outlineErrorMessage: String?
    @State private var castErrorMessage: String?
    @State private var mediaFilesErrorMessage: String?
    @State private var audioTracksErrorMessage: String?
    @State private var subtitlesErrorMessage: String?

    private var mediaType: String {
        detail?.mediaType ?? item.mediaType ?? "movie"
    }

    private var displayTitle: String {
        detail?.title ?? item.title
    }

    private var displayOverview: String? {
        detail?.overview ?? item.overview
    }

    private var seasons: [SeriesOutlineSeason] {
        (outline?.seasons ?? []).sorted { $0.seasonNumber < $1.seasonNumber }
    }

    private var selectedSeason: SeriesOutlineSeason? {
        if let selectedSeasonNumber {
            return seasons.first { $0.seasonNumber == selectedSeasonNumber }
        }
        return seasons.first
    }

    private var posterPath: String? {
        detail?.posterPath ?? item.posterPath
    }

    private var backdropPath: String? {
        detail?.backdropPath
    }

    private var resourceSourceEpisode: SeriesOutlineEpisode? {
        guard mediaType == "series" else { return nil }
        return selectedSeason?.episodes
            .sorted { $0.episodeNumber < $1.episodeNumber }
            .first { $0.isAvailable == true && $0.mediaItemID != nil }
    }

    private var resourceSourceMediaItemID: Int? {
        if mediaType == "series" {
            return resourceSourceEpisode?.mediaItemID
        }
        return detail?.id ?? item.id
    }

    private var selectedMediaFile: MediaFileInfo? {
        guard let selectedMediaFileID else { return mediaFiles.first }
        return mediaFiles.first { $0.id == selectedMediaFileID } ?? mediaFiles.first
    }

    private var selectedAudioTrack: AudioTrackInfo? {
        guard let selectedAudioTrackIndex else { return audioTracks.first }
        return audioTracks.first { $0.streamIndex == selectedAudioTrackIndex } ?? audioTracks.first
    }

    private var selectedSubtitle: SubtitleFileInfo? {
        guard let selectedSubtitleFileID else { return subtitles.first }
        return subtitles.first { $0.id == selectedSubtitleFileID } ?? subtitles.first
    }

    var body: some View {
        ZStack {
            backgroundLayer

            if detail == nil && isLoading {
                loadingView
            } else if let detailErrorMessage {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        backButtonLabel(title: "Back to Library")
                        errorPanel(
                            title: "媒体详情加载失败",
                            message: detailErrorMessage
                        )
                    }
                    .padding(16)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        backButtonLabel(title: backButtonTitle)
                        heroSection

                        if mediaType == "series" {
                            episodesSection
                        }

                        castSection
                        resourceSection
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: item.id) {
            await loadContent()
        }
        .task(id: resourceSourceMediaItemID) {
            await loadResourceBundle()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.05, blue: 0.12), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let request = imageRequest(backdropPath) {
                AuthenticatedImageView(request: request)
                    .scaledToFill()
                    .opacity(0.22)
                    .blur(radius: 16)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.34),
                                Color.black.opacity(0.74),
                                Color.black.opacity(0.94)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
            } else {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 320)
                    .blur(radius: 90)
                    .offset(x: 120, y: -220)
            }
        }
        .ignoresSafeArea()
    }

    private var backButtonTitle: String {
        if mediaType == "series" {
            return "Back to Library"
        }
        return "Back"
    }

    private func backButtonLabel(title: String) -> some View {
        Button {
            dismiss()
        } label: {
            Label(title, systemImage: "chevron.left")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.86))
        }
        .buttonStyle(.plain)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(.white)
            Text("正在加载媒体详情...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)

            if let request = imageRequest(backdropPath) {
                AuthenticatedImageView(request: request)
                    .scaledToFill()
                    .opacity(0.26)
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.1),
                                Color.black.opacity(0.52),
                                Color.black.opacity(0.82)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    posterView

                    VStack(alignment: .leading, spacing: 16) {
                        mediaTypeBadge

                        Text(displayTitle)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        if mediaType == "series", !seasons.isEmpty {
                            seasonPickerSection
                        }

                        metadataStrip

                        if let displayOverview, !displayOverview.isEmpty {
                            Text(displayOverview)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.78))
                                .lineSpacing(4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, minHeight: 320, alignment: .leading)
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private var posterView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.white.opacity(0.08))

            if let request = imageRequest(posterPath) {
                AuthenticatedImageView(request: request)
            } else {
                Image(systemName: "film")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .frame(width: 230, height: 392)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var mediaTypeBadge: some View {
        HStack {
            Spacer()
            Text(mediaTypeLabel(mediaType))
                .font(.caption.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        }
    }

    private var seasonPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("SEASON")
                    .font(.caption.weight(.semibold))
                    .tracking(1.6)
                    .foregroundStyle(.white.opacity(0.45))

                if let selectedSeason {
                    Text(selectedSeasonLabel(for: selectedSeason))
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(seasons) { season in
                        MediaDetailSelectableChip(
                            title: seasonChipTitle(for: season),
                            isSelected: season.seasonNumber == selectedSeason?.seasonNumber,
                            font: .title3.weight(.medium),
                            horizontalPadding: 16,
                            verticalPadding: 10
                        ) {
                            selectedSeasonNumber = season.seasonNumber
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var metadataStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                if let year = selectedSeason?.year {
                    MediaDetailMetricCard(title: "Season Air Year", value: "\(year)")
                }
                if let genres = detail?.genres, !genres.isEmpty {
                    MediaDetailMetricCard(title: "Genres", value: genres)
                }
                if let studio = detail?.studio, !studio.isEmpty {
                    MediaDetailMetricCard(title: "Studio", value: studio)
                }
                if let selectedSeason {
                    MediaDetailMetricCard(title: "Available Episodes", value: "\(availableEpisodeCount(in: selectedSeason))")
                }
                if let country = detail?.country, !country.isEmpty {
                    MediaDetailMetricCard(title: "Country", value: country)
                }
                if let imdbRating = detail?.imdbRating, !imdbRating.isEmpty {
                    MediaDetailMetricCard(title: "IMDb", value: imdbRating)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var episodesSection: some View {
        MediaDetailSectionShell {
            VStack(alignment: .leading, spacing: 14) {
                MediaDetailSectionHeader(eyebrow: "Episodes", title: "Episode List")

                if isLoading && outline == nil && outlineErrorMessage == nil {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 16)
                } else if let outlineErrorMessage {
                    errorPanel(
                        title: "剧集大纲加载失败",
                        message: outlineErrorMessage
                    )
                } else if let selectedSeason {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 14) {
                            ForEach(selectedSeason.episodes.sorted { $0.episodeNumber < $1.episodeNumber }) { episode in
                                episodeTile(episode, season: selectedSeason)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .scrollIndicators(.hidden)
                } else {
                    Text("服务器没有返回可用的季信息。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
        }
    }

    private var castSection: some View {
        MediaDetailSectionShell {
            VStack(alignment: .leading, spacing: 14) {
                MediaDetailSectionHeader(eyebrow: "Cast", title: "Main Cast") {
                    Text("\(castMembers.count)")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.04))
                        )
                        .overlay {
                            Capsule()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }
                }

                if isLoading && castMembers.isEmpty && castErrorMessage == nil {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 16)
                } else if let castErrorMessage {
                    errorPanel(
                        title: "演员列表加载失败",
                        message: castErrorMessage
                    )
                } else if castMembers.isEmpty {
                    Text("服务器没有返回演员信息。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 14) {
                            ForEach(castMembers.sorted { $0.sortOrder < $1.sortOrder }) { member in
                                MediaCastMemberCard(member: member, imageRequest: imageRequest)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    private var resourceSection: some View {
        MediaDetailSectionShell {
            VStack(alignment: .leading, spacing: 14) {
                MediaDetailSectionHeader(eyebrow: "Resources", title: resourceSectionTitle) {
                    if let selectedMediaFile {
                        Text(selectedMediaFile.container?.uppercased() ?? "FILE")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay {
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            }
                    }
                }

                if let mediaFilesErrorMessage {
                    errorPanel(
                        title: "资源文件加载失败",
                        message: mediaFilesErrorMessage
                    )
                } else if mediaType == "series", resourceSourceMediaItemID == nil {
                    Text("当前选中季还没有可播放集，无法读取资源信息。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                } else if mediaFiles.isEmpty {
                    Text("当前媒体条目没有关联文件资源。")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    if mediaFiles.count > 1 {
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(mediaFiles) { file in
                                    MediaDetailSelectableChip(
                                        title: fileChipTitle(file),
                                        isSelected: file.id == selectedMediaFile?.id
                                    ) {
                                        selectedMediaFileID = file.id
                                        Task {
                                            await loadTrackBundle(for: file.id)
                                        }
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 14) {
                            if let selectedMediaFile {
                                MediaTechnicalCard(
                                    title: "Video",
                                    subtitle: fileDisplayName(selectedMediaFile.filePath),
                                    rows: videoRows(for: selectedMediaFile)
                                )
                            }

                            if let audioTracksErrorMessage {
                                technicalErrorCard(
                                    title: "Audio",
                                    message: audioTracksErrorMessage
                                )
                            } else {
                                MediaTechnicalCard(
                                    title: "Audio",
                                    subtitle: selectedAudioTrackTitle,
                                    rows: audioRows
                                ) {
                                    if !audioTracks.isEmpty {
                                        trackSelector
                                    }
                                }
                            }

                            if let subtitlesErrorMessage {
                                technicalErrorCard(
                                    title: "Subtitles",
                                    message: subtitlesErrorMessage
                                )
                            } else {
                                MediaTechnicalCard(
                                    title: "Subtitles",
                                    subtitle: selectedSubtitleTitle,
                                    rows: subtitleRows
                                ) {
                                    if !subtitles.isEmpty {
                                        subtitleSelector
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
    }

    @ViewBuilder
    private func episodeTile(_ episode: SeriesOutlineEpisode, season: SeriesOutlineSeason) -> some View {
        if episode.isAvailable == true, let mediaItemID = episode.mediaItemID {
            NavigationLink {
                MediaItemDetailView(
                    item: MediaItemSummary(
                        id: mediaItemID,
                        title: episode.title ?? "Episode \(episode.episodeNumber)",
                        overview: episode.overview,
                        year: season.year,
                        mediaType: "episode",
                        posterPath: episode.posterPath
                    ),
                    imageRequest: imageRequest,
                    loadMediaDetail: loadMediaDetail,
                    loadEpisodeOutline: loadEpisodeOutline,
                    loadCastMembers: loadCastMembers,
                    loadMediaFiles: loadMediaFiles,
                    loadAudioTracks: loadAudioTracks,
                    loadSubtitles: loadSubtitles
                )
            } label: {
                episodeCard(episode, season: season, isAvailable: true)
            }
            .buttonStyle(.plain)
        } else {
            episodeCard(episode, season: season, isAvailable: false)
                .allowsHitTesting(false)
        }
    }

    private func episodeCard(
        _ episode: SeriesOutlineEpisode,
        season: SeriesOutlineSeason,
        isAvailable: Bool
    ) -> some View {
        HStack(spacing: 14) {
            episodeArtwork(for: episode)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(episodeCode(episode, season: season))
                        .font(.caption.weight(.semibold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.82))

                    Spacer()

                    Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle")
                        .font(.headline)
                        .foregroundStyle(isAvailable ? Color.green.opacity(0.85) : Color.white.opacity(0.28))
                }

                Text(episode.title ?? "Episode \(episode.episodeNumber)")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(episode.overview ?? "")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(3)

                Spacer(minLength: 0)

                progressBar(for: episode.playbackProgress)
            }
        }
        .frame(width: 320, height: 172, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(isAvailable ? 0.04 : 0.02))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(isAvailable ? 0.14 : 0.08), lineWidth: 1)
        }
        .opacity(isAvailable ? 1 : 0.42)
    }

    private func technicalErrorCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.56))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.74))
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

    private var trackSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(audioTracks) { track in
                    MediaDetailSelectableChip(
                        title: audioTrackChipTitle(track),
                        isSelected: track.streamIndex == selectedAudioTrack?.streamIndex
                    ) {
                        selectedAudioTrackIndex = track.streamIndex
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var subtitleSelector: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(subtitles) { subtitle in
                    MediaDetailSelectableChip(
                        title: subtitleChipTitle(subtitle),
                        isSelected: subtitle.id == selectedSubtitle?.id
                    ) {
                        selectedSubtitleFileID = subtitle.id
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func episodeArtwork(for episode: SeriesOutlineEpisode) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.08))

            if let request = imageRequest(episode.posterPath) {
                AuthenticatedImageView(request: request)
            } else {
                Image(systemName: "tv")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .frame(width: 112, height: 148)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func progressBar(for playbackProgress: PlaybackProgressSnapshot?) -> some View {
        let progress = playbackProgress?.progressFraction ?? 0

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(height: 6)

            Capsule()
                .fill(Color.white.opacity(0.82))
                .frame(width: max(0, CGFloat(progress) * 170), height: 6)
        }
    }

    private func errorPanel(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        }
    }

    private func loadContent() async {
        isLoading = true
        detailErrorMessage = nil
        outlineErrorMessage = nil
        castErrorMessage = nil
        castMembers = []

        do {
            let loadedDetail = try await loadMediaDetail(item.id)
            detail = loadedDetail
        } catch {
            detail = nil
            detailErrorMessage = error.localizedDescription
        }

        if mediaType == "series" {
            do {
                let loadedOutline = try await loadEpisodeOutline(item.id)
                outline = loadedOutline
                if let firstSeasonNumber = loadedOutline.seasons
                    .map(\.seasonNumber)
                    .sorted()
                    .first {
                    selectedSeasonNumber = firstSeasonNumber
                } else {
                    selectedSeasonNumber = nil
                }
            } catch {
                outline = nil
                outlineErrorMessage = error.localizedDescription
            }
        } else {
            outline = nil
            selectedSeasonNumber = nil
        }

        do {
            castMembers = try await loadCastMembers(item.id)
        } catch {
            castMembers = []
            castErrorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func loadResourceBundle() async {
        mediaFilesErrorMessage = nil
        audioTracksErrorMessage = nil
        subtitlesErrorMessage = nil
        mediaFiles = []
        audioTracks = []
        subtitles = []
        selectedMediaFileID = nil
        selectedAudioTrackIndex = nil
        selectedSubtitleFileID = nil

        guard let resourceSourceMediaItemID else {
            return
        }

        do {
            let loadedFiles = try await loadMediaFiles(resourceSourceMediaItemID)
            mediaFiles = loadedFiles
            selectedMediaFileID = loadedFiles.first?.id

            if let selectedMediaFileID {
                await loadTrackBundle(for: selectedMediaFileID)
            }
        } catch {
            mediaFilesErrorMessage = error.localizedDescription
        }
    }

    private func loadTrackBundle(for mediaFileID: Int) async {
        audioTracksErrorMessage = nil
        subtitlesErrorMessage = nil
        audioTracks = []
        subtitles = []
        selectedAudioTrackIndex = nil
        selectedSubtitleFileID = nil

        do {
            let loadedAudioTracks = try await loadAudioTracks(mediaFileID)
            audioTracks = loadedAudioTracks
            selectedAudioTrackIndex = loadedAudioTracks.first(where: { $0.isDefault == true })?.streamIndex
                ?? loadedAudioTracks.first?.streamIndex
        } catch {
            audioTracksErrorMessage = error.localizedDescription
        }

        do {
            let loadedSubtitles = try await loadSubtitles(mediaFileID)
            subtitles = loadedSubtitles
            selectedSubtitleFileID = loadedSubtitles.first(where: { $0.isDefault == true })?.id
                ?? loadedSubtitles.first?.id
        } catch {
            subtitlesErrorMessage = error.localizedDescription
        }
    }

    private func mediaTypeLabel(_ mediaType: String) -> String {
        switch mediaType {
        case "series":
            return "Series"
        case "episode":
            return "Episode"
        default:
            return "Movie"
        }
    }

    private func selectedSeasonLabel(for season: SeriesOutlineSeason) -> String {
        "第 \(season.seasonNumber) 季"
    }

    private func seasonChipTitle(for season: SeriesOutlineSeason) -> String {
        String(format: "S%02d", season.seasonNumber)
    }

    private func episodeCode(_ episode: SeriesOutlineEpisode, season: SeriesOutlineSeason) -> String {
        String(format: "S%02d  •  E%02d", season.seasonNumber, episode.episodeNumber)
    }

    private func availableEpisodeCount(in season: SeriesOutlineSeason) -> Int {
        season.episodes.filter { $0.isAvailable == true }.count
    }

    private var resourceSectionTitle: String {
        if let selectedSeason, let resourceSourceEpisode {
            return "For \(episodeCode(resourceSourceEpisode, season: selectedSeason))"
        }
        if mediaType == "episode" {
            return "Current Episode File"
        }
        return "Current Media File"
    }

    private var selectedAudioTrackTitle: String {
        selectedAudioTrack.map(audioTrackChipTitle) ?? "No Audio Track"
    }

    private var selectedSubtitleTitle: String {
        selectedSubtitle.map(subtitleChipTitle) ?? "No Subtitle"
    }

    private var audioRows: [(String, String)] {
        guard let selectedAudioTrack else { return [] }

        return compactRows([
            ("Language", selectedAudioTrack.language),
            ("Codec", selectedAudioTrack.audioCodec),
            ("Label", selectedAudioTrack.label),
            ("Layout", selectedAudioTrack.channelLayout),
            ("Channels", selectedAudioTrack.channels.map(String.init)),
            ("Bitrate", bitrateLabel(selectedAudioTrack.bitrate)),
            ("Sample Rate", selectedAudioTrack.sampleRate.map { "\($0) Hz" }),
            ("Default", boolLabel(selectedAudioTrack.isDefault))
        ])
    }

    private var subtitleRows: [(String, String)] {
        guard let selectedSubtitle else { return [] }

        return compactRows([
            ("Language", selectedSubtitle.language),
            ("Format", selectedSubtitle.subtitleFormat?.uppercased()),
            ("Source", selectedSubtitle.sourceKind),
            ("Label", selectedSubtitle.label),
            ("Default", boolLabel(selectedSubtitle.isDefault)),
            ("Forced", boolLabel(selectedSubtitle.isForced)),
            ("HI", boolLabel(selectedSubtitle.isHearingImpaired))
        ])
    }

    private func videoRows(for file: MediaFileInfo) -> [(String, String)] {
        compactRows([
            ("Container", file.container?.uppercased()),
            ("Resolution", resolutionLabel(width: file.width, height: file.height)),
            ("Duration", durationLabel(file.durationSeconds)),
            ("Video Codec", file.videoCodec),
            ("Audio Codec", file.audioCodec),
            ("Bitrate", bitrateLabel(file.videoBitrate ?? file.bitrate)),
            ("Frame Rate", file.videoFrameRate.map { String(format: "%.2f fps", $0) }),
            ("Aspect", file.videoAspectRatio),
            ("Profile", file.videoProfile),
            ("Level", file.videoLevel),
            ("Bit Depth", file.videoBitDepth.map { "\($0)-bit" }),
            ("Pixel Format", file.videoPixelFormat),
            ("Color Space", file.videoColorSpace),
            ("Transfer", file.videoColorTransfer),
            ("Primaries", file.videoColorPrimaries),
            ("Scan", file.videoScanType),
            ("Refs", file.videoReferenceFrames.map(String.init))
        ])
    }

    private func compactRows(_ rows: [(String, String?)]) -> [(String, String)] {
        rows.compactMap { key, value in
            guard let value, !value.isEmpty else { return nil }
            return (key, value)
        }
    }

    private func fileChipTitle(_ file: MediaFileInfo) -> String {
        let fileName = fileDisplayName(file.filePath)
        return file.container.map { "\(fileName) · \($0.uppercased())" } ?? fileName
    }

    private func audioTrackChipTitle(_ track: AudioTrackInfo) -> String {
        track.label ?? track.language?.uppercased() ?? "Track \(track.streamIndex)"
    }

    private func subtitleChipTitle(_ subtitle: SubtitleFileInfo) -> String {
        subtitle.label ?? subtitle.language?.uppercased() ?? "Subtitle \(subtitle.id)"
    }

    private func fileDisplayName(_ filePath: String) -> String {
        URL(fileURLWithPath: filePath).lastPathComponent
    }

    private func resolutionLabel(width: Int?, height: Int?) -> String? {
        guard let width, let height else { return nil }
        return "\(width) × \(height)"
    }

    private func durationLabel(_ durationSeconds: Double?) -> String? {
        guard let durationSeconds else { return nil }
        let totalSeconds = Int(durationSeconds.rounded())
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func bitrateLabel(_ bitrate: Int?) -> String? {
        guard let bitrate else { return nil }
        return String(format: "%.2f Mbps", Double(bitrate) / 1_000_000)
    }

    private func boolLabel(_ value: Bool?) -> String? {
        guard let value else { return nil }
        return value ? "Yes" : "No"
    }
}
