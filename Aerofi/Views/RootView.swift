import SwiftUI

struct RootView: View {
    @Environment(AudioPlayerService.self) private var player

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
    }
}
