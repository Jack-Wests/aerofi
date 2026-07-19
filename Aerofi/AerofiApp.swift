import SwiftUI
import SwiftData

@main
struct AerofiApp: App {
    let modelContainer: ModelContainer
    @State private var audioPlayer = AudioPlayerService()

    init() {
        let schema = Schema([Song.self, Album.self, Artist.self, Playlist.self, PlaylistItem.self])
        do {
            modelContainer = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create Aerofi's SwiftData store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(audioPlayer)
                .preferredColorScheme(.light)
        }
        .modelContainer(modelContainer)
    }
}
