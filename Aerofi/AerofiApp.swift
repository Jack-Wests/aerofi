import SwiftUI
import SwiftData

@main
struct AerofiApp: App {
    let modelContainer: ModelContainer
    @State private var audioPlayer: AudioPlayerService
    /// Created once here (not lazily inside NowPlayingView) so play-count /
    /// last-played tracking works even if the user drives playback entirely
    /// from the mini player and never opens the full Now Playing sheet.
    @State private var playerViewModel: PlayerViewModel

    init() {
        let schema = Schema([Song.self, Album.self, Artist.self, Playlist.self, PlaylistItem.self])
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create Aerofi's SwiftData store: \(error)")
        }
        modelContainer = container

        let player = AudioPlayerService()
        _audioPlayer = State(initialValue: player)
        _playerViewModel = State(initialValue: PlayerViewModel(player: player, modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(audioPlayer)
                .environment(playerViewModel)
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
