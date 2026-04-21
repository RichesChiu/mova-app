import Foundation

struct LibrarySummary: Decodable, Identifiable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let mediaCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case mediaCount = "media_count"
    }
}

struct MediaItemSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let year: Int?
    let mediaType: String?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case year
        case mediaType = "media_type"
        case posterPath = "poster_path"
    }
}

struct MediaItemDetail: Decodable, Identifiable, Hashable {
    let id: Int
    let libraryID: Int
    let mediaType: String
    let title: String
    let sourceTitle: String?
    let originalTitle: String?
    let sortTitle: String?
    let year: Int?
    let imdbRating: String?
    let country: String?
    let genres: String?
    let studio: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case libraryID = "library_id"
        case mediaType = "media_type"
        case title
        case sourceTitle = "source_title"
        case originalTitle = "original_title"
        case sortTitle = "sort_title"
        case year
        case imdbRating = "imdb_rating"
        case country
        case genres
        case studio
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PagedMediaItems: Decodable {
    let items: [MediaItemSummary]
    let total: Int
    let page: Int
    let pageSize: Int

    enum CodingKeys: String, CodingKey {
        case items
        case total
        case page
        case pageSize = "page_size"
    }
}

struct LibraryStats: Hashable {
    let total: Int
    let movieCount: Int
    let seriesCount: Int
}

struct SeasonSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let seasonNumber: Int?
    let title: String?
    let overview: String?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case seasonNumber = "season_number"
        case title
        case overview
        case posterPath = "poster_path"
    }
}

struct EpisodeSummary: Decodable, Identifiable, Hashable {
    let id: Int
    let episodeNumber: Int?
    let title: String?
    let overview: String?
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case episodeNumber = "episode_number"
        case title
        case overview
        case posterPath = "poster_path"
    }
}

struct SeriesEpisodeOutline: Decodable, Hashable {
    let seasons: [SeriesOutlineSeason]
}

struct SeriesOutlineSeason: Decodable, Identifiable, Hashable {
    let seasonID: Int?
    let seasonNumber: Int
    let title: String?
    let year: Int?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let introStartSeconds: Double?
    let introEndSeconds: Double?
    let episodes: [SeriesOutlineEpisode]

    var id: String {
        if let seasonID {
            return "season-\(seasonID)"
        }
        return "season-\(seasonNumber)"
    }

    enum CodingKeys: String, CodingKey {
        case seasonID = "season_id"
        case seasonNumber = "season_number"
        case title
        case year
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case introStartSeconds = "intro_start_seconds"
        case introEndSeconds = "intro_end_seconds"
        case episodes
    }
}

struct SeriesOutlineEpisode: Decodable, Identifiable, Hashable {
    let episodeNumber: Int
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let introStartSeconds: Double?
    let introEndSeconds: Double?
    let mediaItemID: Int?
    let isAvailable: Bool?
    let playbackProgress: PlaybackProgressSnapshot?

    var id: String {
        if let mediaItemID {
            return "episode-\(mediaItemID)"
        }
        return "episode-\(episodeNumber)"
    }

    enum CodingKeys: String, CodingKey {
        case episodeNumber = "episode_number"
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case introStartSeconds = "intro_start_seconds"
        case introEndSeconds = "intro_end_seconds"
        case mediaItemID = "media_item_id"
        case isAvailable = "is_available"
        case playbackProgress = "playback_progress"
    }
}

struct PlaybackProgressSnapshot: Decodable, Hashable {
    let positionSeconds: Double
    let durationSeconds: Double
    let lastWatchedAt: String?
    let isFinished: Bool

    var progressFraction: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(positionSeconds / durationSeconds, 0), 1)
    }

    enum CodingKeys: String, CodingKey {
        case positionSeconds = "position_seconds"
        case durationSeconds = "duration_seconds"
        case lastWatchedAt = "last_watched_at"
        case isFinished = "is_finished"
    }
}

struct MediaCastMember: Decodable, Identifiable, Hashable {
    let personID: Int
    let sortOrder: Int
    let name: String
    let characterName: String?
    let profilePath: String?

    var id: Int {
        personID
    }

    enum CodingKeys: String, CodingKey {
        case personID = "person_id"
        case sortOrder = "sort_order"
        case name
        case characterName = "character_name"
        case profilePath = "profile_path"
    }
}

struct MediaFileInfo: Decodable, Identifiable, Hashable {
    let id: Int
    let mediaItemID: Int
    let filePath: String
    let container: String?
    let durationSeconds: Double?
    let videoCodec: String?
    let audioCodec: String?
    let width: Int?
    let height: Int?
    let bitrate: Int?
    let videoTitle: String?
    let videoProfile: String?
    let videoLevel: String?
    let videoBitrate: Int?
    let videoFrameRate: Double?
    let videoAspectRatio: String?
    let videoScanType: String?
    let videoColorPrimaries: String?
    let videoColorSpace: String?
    let videoColorTransfer: String?
    let videoBitDepth: Int?
    let videoPixelFormat: String?
    let videoReferenceFrames: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaItemID = "media_item_id"
        case filePath = "file_path"
        case container
        case durationSeconds = "duration_seconds"
        case videoCodec = "video_codec"
        case audioCodec = "audio_codec"
        case width
        case height
        case bitrate
        case videoTitle = "video_title"
        case videoProfile = "video_profile"
        case videoLevel = "video_level"
        case videoBitrate = "video_bitrate"
        case videoFrameRate = "video_frame_rate"
        case videoAspectRatio = "video_aspect_ratio"
        case videoScanType = "video_scan_type"
        case videoColorPrimaries = "video_color_primaries"
        case videoColorSpace = "video_color_space"
        case videoColorTransfer = "video_color_transfer"
        case videoBitDepth = "video_bit_depth"
        case videoPixelFormat = "video_pixel_format"
        case videoReferenceFrames = "video_reference_frames"
    }
}

struct AudioTrackInfo: Decodable, Identifiable, Hashable {
    let streamIndex: Int
    let language: String?
    let audioCodec: String?
    let label: String?
    let channelLayout: String?
    let channels: Int?
    let bitrate: Int?
    let sampleRate: Int?
    let isDefault: Bool?

    var id: Int {
        streamIndex
    }

    enum CodingKeys: String, CodingKey {
        case streamIndex = "stream_index"
        case language
        case audioCodec = "audio_codec"
        case label
        case channelLayout = "channel_layout"
        case channels
        case bitrate
        case sampleRate = "sample_rate"
        case isDefault = "is_default"
    }
}

struct SubtitleFileInfo: Decodable, Identifiable, Hashable {
    let id: Int
    let sourceKind: String?
    let language: String?
    let subtitleFormat: String?
    let label: String?
    let isDefault: Bool?
    let isForced: Bool?
    let isHearingImpaired: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case sourceKind = "source_kind"
        case language
        case subtitleFormat = "subtitle_format"
        case label
        case isDefault = "is_default"
        case isForced = "is_forced"
        case isHearingImpaired = "is_hearing_impaired"
    }
}
