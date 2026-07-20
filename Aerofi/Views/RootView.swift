import SwiftUI

struct RootView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(\.modelContext) private var modelContext
    /// Retained for the lifetime of the root view so the startup sweep of
    /// Finder-dropped audio files isn't deallocated mid-import.
    @State private var looseFileImporter: LibraryImporter?

    var body: some View {
        TabView {
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.stack.fill") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }

            PlaylistsListView()
                .tabItem { Label("Playlists", systemImage: "music.note.list") }
        }
        .tint(Aero.deepBlue)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if player.currentSong != nil {
                MiniPlayerView()
                    .padding(.bottom, 4)
            }
        }
        .task {
            if looseFileImporter == nil {
                let importer = LibraryImporter(modelContext: modelContext)
                looseFileImporter = importer
                importer.importLooseDocumentFiles()
            }
        }
    }
}
