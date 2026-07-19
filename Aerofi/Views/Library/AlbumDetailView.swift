import SwiftUI

struct AlbumDetailView: View {
    let album: Album
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        ZStack {
            AeroBackground()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    VStack(spacing: 4) {
                        ForEach(Array(album.sortedSongs.enumerated()), id: \.element.id) { index, song in
                            SongRow(
                                song: song,
                                isCurrent: player.currentSong?.id == song.id,
                                isPlaying: player.isPlaying,
                                trackNumber: song.trackNumber ?? (index + 1),
                                onTap: { player.play(songs: album.sortedSongs, startAt: index) }
                            )
                        }
                    }
                    .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
                    .padding(.horizontal)
                    .padding(.bottom, 120)
                }
                .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            ArtworkView(data: album.artworkData, cornerRadius: Aero.cornerRadiusLarge)
                .frame(width: 190, height: 190)

            Aero.title(album.name)
                .multilineTextAlignment(.center)
            Text(album.albumArtist + (album.year.map { " · \($0)" } ?? ""))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Aero.inkSoft)

            HStack(spacing: 14) {
                Button {
                    player.play(songs: album.sortedSongs, startAt: 0)
                } label: {
                    Label("Play", systemImage: "play.fill")
                }
                .buttonStyle(GlossyButtonStyle(tint: Aero.skyBlue))

                Button {
                    player.play(songs: album.sortedSongs, startAt: 0, shuffle: true)
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
                .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))
            }
        }
        .padding(.horizontal)
    }
}
