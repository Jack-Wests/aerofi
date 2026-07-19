import SwiftUI

struct ArtistDetailView: View {
    let artist: Artist
    @Environment(AudioPlayerService.self) private var player

    private var allSongs: [Song] {
        (artist.songs ?? []).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    if let albums = artist.albums, !albums.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Aero.heading("Albums").padding(.horizontal)
                            ScrollView(.horizontal) {
                                HStack(spacing: 16) {
                                    ForEach(artist.sortedAlbums) { album in
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
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Aero.heading("Songs").padding(.horizontal)
                        VStack(spacing: 4) {
                            ForEach(Array(allSongs.enumerated()), id: \.element.id) { index, song in
                                SongRow(
                                    song: song,
                                    isCurrent: player.currentSong?.id == song.id,
                                    isPlaying: player.isPlaying,
                                    onTap: { player.play(songs: allSongs, startAt: index) }
                                )
                            }
                        }
                        .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 120)
                }
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(artist.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ArtworkView(data: artist.representativeArtworkData, cornerRadius: 95)
                .frame(width: 150, height: 150)
                .clipShape(Circle())

            Aero.title(artist.name)

            Button {
                player.play(songs: allSongs, startAt: 0, shuffle: true)
            } label: {
                Label("Shuffle Play", systemImage: "shuffle")
            }
            .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))
        }
        .padding(.horizontal)
    }
}
