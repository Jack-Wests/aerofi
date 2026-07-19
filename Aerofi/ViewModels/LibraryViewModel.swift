import Foundation
import Observation

enum SongSortOption: String, CaseIterable, Identifiable {
    case titleAZ = "Title"
    case artistAZ = "Artist"
    case dateAdded = "Recently Added"
    case mostPlayed = "Most Played"

    var id: String { rawValue }
}

/// Holds cross-view library browsing preferences (sort order) so they
/// persist as the user navigates between the Songs / Albums / Artists tabs
/// within the Library screen.
@MainActor
@Observable
final class LibraryViewModel {
    var songSort: SongSortOption = .titleAZ

    func sorted(_ songs: [Song]) -> [Song] {
        switch songSort {
        case .titleAZ:
            songs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .artistAZ:
            songs.sorted { $0.artistName.localizedCaseInsensitiveCompare($1.artistName) == .orderedAscending }
        case .dateAdded:
            songs.sorted { $0.dateAdded > $1.dateAdded }
        case .mostPlayed:
            songs.sorted { $0.playCount > $1.playCount }
        }
    }
}
