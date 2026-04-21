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
