import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Observation

enum RepeatMode {
    case off, all, one

    mutating func cycle() {
        switch self {
        case .off: self = .all
        case .all: self = .one
        case .one: self = .off
        }
    }

    var symbolName: String {
        switch self {
        case .off: "repeat"
        case .all: "repeat"
        case .one: "repeat.1"
        }
    }
}

/// Central playback engine: owns the AVPlayer, the play queue (with shuffle
/// and repeat), lock-screen / Control Center integration via
/// MPNowPlayingInfoCenter + MPRemoteCommandCenter, and background audio.
/// A single class instance is shared app-wide via the environment so the
/// mini player, full player, and lock screen all reflect the same state.
@MainActor
@Observable
final class AudioPlayerService {
    private(set) var queue: [Song] = []
    private var unshuffledQueue: [Song] = []
    private(set) var currentIndex: Int = 0

    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    var repeatMode: RepeatMode = .off
    private(set) var isShuffled = false

    var currentSong: Song? {
        queue.indices.contains(currentIndex) ? queue[currentIndex] : nil
    }

    private var player = AVPlayer()
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?
    private var onSongDidBecomeCurrent: (@MainActor (Song) -> Void)?

    init() {
        configureAudioSession()
        configureRemoteCommandCenter()
        addPeriodicTimeObserver()
    }

    /// Injected by the app root so the player can bump `playCount` /
    /// `lastPlayedAt` on the SwiftData model without owning a ModelContext itself.
    func onTrackStarted(_ handler: @escaping @MainActor (Song) -> Void) {
        onSongDidBecomeCurrent = handler
    }

    // MARK: - Session / remote commands

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)
    }

    private func configureRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToNext() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skipToPrevious() }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.currentTime = time.seconds.isFinite ? time.seconds : 0
                self.updateNowPlayingElapsedTime()
            }
        }
    }

    // MARK: - Queue control

    /// Replaces the queue and starts playing at `startIndex`. `shuffle`
    /// controls whether playback order is randomized immediately.
    func play(songs: [Song], startAt startIndex: Int = 0, shuffle: Bool = false) {
        unshuffledQueue = songs
        isShuffled = shuffle
        queue = shuffle ? Self.shuffledKeepingFirst(songs, firstIndex: startIndex) : songs
        currentIndex = shuffle ? 0 : startIndex
        loadCurrentItem(autoplay: true)
    }

    func addToQueue(_ song: Song, playNext: Bool = false) {
        guard !queue.isEmpty else {
            play(songs: [song])
            return
        }
        let insertAt = playNext ? currentIndex + 1 : queue.count
        queue.insert(song, at: min(insertAt, queue.count))
        if !isShuffled {
            unshuffledQueue = queue
        } else {
            unshuffledQueue.append(song)
        }
    }

    func removeFromQueue(at index: Int) {
        guard queue.indices.contains(index) else { return }
        queue.remove(at: index)
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex {
            loadCurrentItem(autoplay: isPlaying)
        }
    }

    func moveQueueItem(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        if let first = source.first {
            if first == currentIndex {
                currentIndex = destination > first ? destination - 1 : destination
            } else if first < currentIndex, destination > currentIndex {
                currentIndex -= 1
            } else if first > currentIndex, destination <= currentIndex {
                currentIndex += 1
            }
        }
    }

    /// Purges every occurrence of a song from the live queue — used when a
    /// song is deleted from the library so playback doesn't keep a
    /// reference to a file that no longer exists on disk.
    func removeSong(withID id: UUID) {
        unshuffledQueue.removeAll { $0.id == id }
        var wasCurrentRemoved = false
        while let removedIndex = queue.firstIndex(where: { $0.id == id }) {
            if removedIndex == currentIndex { wasCurrentRemoved = true }
            queue.remove(at: removedIndex)
            if removedIndex < currentIndex {
                currentIndex -= 1
            }
        }
        if wasCurrentRemoved {
            currentIndex = min(currentIndex, max(queue.count - 1, 0))
            loadCurrentItem(autoplay: isPlaying)
        }
    }

    func toggleShuffle() {
        guard let current = currentSong else {
            isShuffled.toggle()
            return
        }
        isShuffled.toggle()
        if isShuffled {
            unshuffledQueue = queue
            let rest = queue.enumerated().filter { $0.offset != currentIndex }.map(\.element)
            queue = [current] + rest.shuffled()
            currentIndex = 0
        } else {
            queue = unshuffledQueue
            currentIndex = queue.firstIndex(where: { $0.id == current.id }) ?? 0
        }
    }

    private static func shuffledKeepingFirst(_ songs: [Song], firstIndex: Int) -> [Song] {
        guard songs.indices.contains(firstIndex) else { return songs.shuffled() }
        var rest = songs
        let first = rest.remove(at: firstIndex)
        rest.shuffle()
        return [first] + rest
    }

    // MARK: - Transport

    func play() {
        player.play()
        isPlaying = true
        updateNowPlayingPlaybackState()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func skipToNext(userInitiated: Bool = true) {
        guard !queue.isEmpty else { return }
        if currentIndex + 1 < queue.count {
            currentIndex += 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else if userInitiated {
            currentIndex = min(currentIndex + 1, queue.count - 1)
        } else {
            pause()
            return
        }
        loadCurrentItem(autoplay: true)
    }

    func skipToPrevious() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        } else {
            currentIndex = 0
        }
        loadCurrentItem(autoplay: true)
    }

    func playQueueItem(at index: Int) {
        guard queue.indices.contains(index) else { return }
        currentIndex = index
        loadCurrentItem(autoplay: true)
    }

    func seek(to time: TimeInterval) {
        player.seek(to: CMTime(seconds: time, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
        updateNowPlayingElapsedTime()
    }

    // MARK: - Item loading

    private func loadCurrentItem(autoplay: Bool) {
        guard let song = currentSong else {
            player.replaceCurrentItem(with: nil)
            isPlaying = false
            return
        }

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }

        let url = LibraryStorage.absoluteURL(for: song.relativeFilePath)
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        duration = song.duration

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.handlePlaybackEnded() }
        }

        updateNowPlayingMetadata(for: song)
        onSongDidBecomeCurrent?(song)

        if autoplay {
            play()
        }
    }

    private func handlePlaybackEnded() {
        if repeatMode == .one {
            seek(to: 0)
            play()
            return
        }
        skipToNext(userInitiated: false)
    }

    // MARK: - Now Playing Info

    private func updateNowPlayingMetadata(for song: Song) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artistName,
            MPMediaItemPropertyAlbumTitle: song.albumName,
            MPMediaItemPropertyPlaybackDuration: song.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
        if let artworkData = song.artworkData, let image = UIImage(data: artworkData) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsedTime() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    deinit {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
    }
}
