import SwiftUI
import SwiftData

struct PlaylistsListView: View {
    @Query(sort: \Playlist.dateModified, order: .reverse) private var playlists: [Playlist]
    @State private var showingCreate = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                ScrollView {
                    if playlists.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(playlists) { playlist in
                                NavigationLink(value: playlist) {
                                    PlaylistTile(playlist: playlist)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Playlists")
            .navigationDestination(for: Playlist.self) { PlaylistDetailView(playlist: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Aero.accentGradient(Aero.leafGreen))
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreatePlaylistView()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "water.waves")
                .font(.system(size: 56))
                .foregroundStyle(Aero.accentGradient(Aero.skyBlue))
            Aero.heading("No playlists yet")
            Aero.caption("Create one to start collecting your favorites.")
            Button("New Playlist") { showingCreate = true }
                .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))
        }
        .padding(28)
        .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
        .padding(.horizontal, 32)
        .padding(.top, 80)
    }
}

struct PlaylistTile: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkCollageView(images: playlist.artworkCollage, cornerRadius: Aero.cornerRadiusMedium)
                .aspectRatio(1, contentMode: .fit)
            Text(playlist.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Aero.ink)
                .lineLimit(1)
            Text("\(playlist.songs.count) songs")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Aero.inkSoft)
        }
    }
}
