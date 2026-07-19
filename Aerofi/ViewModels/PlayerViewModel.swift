import Foundation
import SwiftData
import Observation

/// Thin coordination layer between the environment-shared AudioPlayerService
/// and SwiftData — records play counts/timestamps and exposes UI-friendly
/// derived state (progress fraction, formatted times) without the views
/// needing to know about the underlying player internals.
@MainActor
@Observable
final class PlayerViewModel {
    let player: AudioPlayerService
    private let modelContext: ModelContext

    /// Drives the scrubber while the user is actively dragging, so periodic
    /// player updates don't fight the gesture.
    var isScrubbing = false
    var scrubTime: TimeInterval = 0

    init(player: AudioPlayerService, modelContext: ModelContext) {
        self.player = player
        self.modelContext = modelContext
        player.onTrackStarted { [weak self] song in
            self?.recordPlay(of: song)
        }
    }

    var displayTime: TimeInterval {
        isScrubbing ? scrubTime : player.currentTime
    }

    var progressFraction: Double {
        guard player.duration > 0 else { return 0 }
        return min(max(displayTime / player.duration, 0), 1)
    }

    var formattedElapsed: String { Song.format(duration: displayTime) }
    var formattedRemaining: String { "-" + Song.format(duration: max(player.duration - displayTime, 0)) }

    func beginScrub() {
        isScrubbing = true
        scrubTime = player.currentTime
    }

    func updateScrub(to fraction: Double) {
        scrubTime = fraction * player.duration
    }

    func commitScrub() {
        player.seek(to: scrubTime)
        isScrubbing = false
    }

    private func recordPlay(of song: Song) {
        song.playCount += 1
        song.lastPlayedAt = Date()
        try? modelContext.save()
    }
}
