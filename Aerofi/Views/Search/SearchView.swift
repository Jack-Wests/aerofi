import SwiftUI
import SwiftData

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(AudioPlayerService.self) private var player

    @Query private var allSongs: [Song]
    @Query private var allAlbums: [Album]
    @Query private var allArtists: [Artist]
    @Query private var allPlaylists: [Playlist]

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                if viewModel.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    promptState
                } else if results.isEmpty {
                    noResultsState
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .navigationDestination(for: Album.self) { AlbumDetailView(album: $0) }
            .navigationDestination(for: Artist.self) { ArtistDetailView(artist: $0) }
            .navigationDestination(for: Playlist.self) { PlaylistDetailView(playlist: $0) }
        }
        .searchable(text: $viewModel.query, prompt: "Songs, artists, albums, playlists")
    }

    private var results: (songs: [Song], albums: [Album], artists: [Artist], playlists: [Playlist]) {
        (
            viewModel.matchingSongs(in: allSongs),
            viewModel.matchingAlbums(in: allAlbums),
            viewModel.matchingArtists(in: allArtists),
            viewModel.matchingPlaylists(in: allPlaylists)
        )
    }

    private var resultsList: some View {
        let r = results
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                if !r.songs.isEmpty {
                    sectionHeader("Songs")
                    VStack(spacing: 4) {
                        ForEach(Array(r.songs.enumerated()), id: \.element.id) { index, song in
                            SongRow(song: song, isCurrent: player.currentSong?.id == song.id, isPlaying: player.isPlaying) {
                                player.play(songs: r.songs, startAt: index)
                            }
                        }
                    }
                    .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
                    .padding(.horizontal)
                }

                if !r.artists.isEmpty {
                    sectionHeader("Artists")
                    horizontalArtists(r.artists)
                }

                if !r.albums.isEmpty {
                    sectionHeader("Albums")
                    horizontalAlbums(r.albums)
                }

                if !r.playlists.isEmpty {
                    sectionHeader("Playlists")
                    horizontalPlaylists(r.playlists)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private func sectionHeader(_ text: String) -> some View {
        Aero.heading(text).padding(.horizontal)
    }

    private func horizontalArtists(_ artists: [Artist]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(artists) { artist in
                    NavigationLink(value: artist) {
                        VStack(spacing: 6) {
                            ArtworkView(data: artist.representativeArtworkData, cornerRadius: 45)
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                            Text(artist.name).font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundStyle(Aero.ink)
                        }
                        .frame(width: 100)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func horizontalAlbums(_ albums: [Album]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(albums) { album in
                    NavigationLink(value: album) {
                        AlbumTile(album: album).frame(width: 140)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private func horizontalPlaylists(_ playlists: [Playlist]) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(playlists) { playlist in
                    NavigationLink(value: playlist) {
                        PlaylistTile(playlist: playlist).frame(width: 140)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
    }

    private var promptState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Aero.accentGradient(Aero.aqua))
            Aero.caption("Search your library")
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Aero.accentGradient(Aero.inkSoft))
            Aero.caption("No results for \u{201C}\(viewModel.query)\u{201D}")
        }
    }
}
