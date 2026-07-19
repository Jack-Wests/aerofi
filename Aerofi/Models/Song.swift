import Foundation
import SwiftData

@Model
final class Song {
    @Attribute(.unique) var id: UUID
    var title: String
    var artistName: String
    var albumName: String
    var albumArtist: String
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var duration: TimeInterval
    /// Filename relative to the app's Library documents folder (see LibraryStorage.songsDirectory).
    var relativeFilePath: String
    @Attribute(.externalStorage) var artworkData: Data?
    var dateAdded: Date
    var playCount: Int
    var lastPlayedAt: Date?

    var plainLyrics: String?
    /// Encoded [SyncedLyricLine] as JSON, since SwiftData can't store custom structs directly in a portable way.
    var syncedLyricsData: Data?
    var lyricsFetchStatus: LyricsFetchStatus

    @Relationship var album: Album?
    @Relationship var artist: Artist?
    @Relationship(deleteRule: .cascade, inverse: \PlaylistItem.song) var playlistItems: [PlaylistItem]?

    init(
        id: UUID = UUID(),
        title: String,
        artistName: String,
        albumName: String,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        duration: TimeInterval,
        relativeFilePath: String,
        artworkData: Data? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.albumName = albumName
        self.albumArtist = albumArtist ?? artistName
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.duration = duration
        self.relativeFilePath = relativeFilePath
        self.artworkData = artworkData
        self.dateAdded = dateAdded
        self.playCount = 0
        self.lastPlayedAt = nil
        self.plainLyrics = nil
        self.syncedLyricsData = nil
        self.lyricsFetchStatus = .notFetched
    }

    var syncedLyrics: [SyncedLyricLine]? {
        get {
            guard let syncedLyricsData else { return nil }
            return try? JSONDecoder().decode([SyncedLyricLine].self, from: syncedLyricsData)
        }
        set {
            syncedLyricsData = try? newValue.map { try JSONEncoder().encode($0) }
        }
    }

    var formattedDuration: String {
        Self.format(duration: duration)
    }

    static func format(duration: TimeInterval) -> String {
        let total = Int(duration.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum LyricsFetchStatus: String, Codable {
    case notFetched
    case fetching
    case foundSynced
    case foundPlainOnly
    case noMatch
    case failed
}

struct SyncedLyricLine: Codable, Identifiable, Hashable {
    var id: Double { timestamp }
    let timestamp: TimeInterval
    let text: String
}
