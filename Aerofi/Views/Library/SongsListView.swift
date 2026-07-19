import SwiftUI

struct SongsListView: View {
    let songs: [Song]
    var libraryViewModel: LibraryViewModel

    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                sortMenu

                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    SongRow(
                        song: song,
                        isCurrent: player.currentSong?.id == song.id,
                        isPlaying: player.isPlaying,
                        onTap: { player.play(songs: songs, startAt: index) }
                    )
                    .glassBackground(cornerRadius: Aero.cornerRadiusSmall)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var sortMenu: some View {
        HStack {
            Menu {
                ForEach(SongSortOption.allCases) { option in
                    Button {
                        libraryViewModel.songSort = option
                    } label: {
                        Label(option.rawValue, systemImage: libraryViewModel.songSort == option ? "checkmark" : "")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(libraryViewModel.songSort.rawValue)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Aero.inkSoft)
            }
            Spacer()
            if !songs.isEmpty {
                Button {
                    player.play(songs: songs, startAt: 0, shuffle: true)
                } label: {
                    Label("Shuffle All", systemImage: "shuffle")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}
