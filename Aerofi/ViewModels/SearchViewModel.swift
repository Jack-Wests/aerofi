import Foundation
import Observation

/// In-memory search across the already-loaded library (SwiftData datasets
/// here are personal-library sized, so no need for an index — a simple
/// case-insensitive substring match across title/artist/album is instant).
@MainActor
@Observable
final class SearchViewModel {
    var query: String = ""

    func matchingSongs(in songs: [Song]) -> [Song] {
        guard !normalizedQuery.isEmpty else { return [] }
        return songs.filter {
            $0.title.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.artistName.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.albumName.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    func matchingAlbums(in albums: [Album]) -> [Album] {
        guard !normalizedQuery.isEmpty else { return [] }
        return albums.filter {
            $0.name.localizedCaseInsensitiveContains(normalizedQuery) ||
            $0.albumArtist.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }

    func matchingArtists(in artists: [Artist]) -> [Artist] {
        guard !normalizedQuery.isEmpty else { return [] }
        return artists.filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    func matchingPlaylists(in playlists: [Playlist]) -> [Playlist] {
        guard !normalizedQuery.isEmpty else { return [] }
        return playlists.filter { $0.name.localizedCaseInsensitiveContains(normalizedQuery) }
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
