import SwiftUI
import SwiftData

/// Shared row used in the songs list, album/artist/playlist detail, search
/// results, and the queue — keeps the "glassy list row" look consistent
/// everywhere a song appears.
struct SongRow: View {
    let song: Song
    var isCurrent: Bool = false
    var isPlaying: Bool = false
    var showsArtwork: Bool = true
    var trackNumber: Int? = nil
    var showsMenu: Bool = true
    var onTap: () -> Void
    /// Present only inside a playlist's own detail view, where "remove" means
    /// "take this song out of the playlist" rather than deleting it.
    var onRemoveFromPlaylist: (() -> Void)? = nil

    @Environment(AudioPlayerService.self) private var player
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Playlist.name) private var playlists: [Playlist]
    @State private var showingNewPlaylistSheet = false
    @State private var showingDeleteConfirm = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if let trackNumber {
                    Text("\(trackNumber)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Aero.inkSoft)
                        .frame(width: 22)
                } else if showsArtwork {
                    ArtworkView(data: song.artworkData, cornerRadius: 8)
                        .frame(width: 46, height: 46)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isCurrent ? Aero.deepBlue : Aero.ink)
                        .lineLimit(1)
                    Text(song.artistName)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Aero.inkSoft)
                        .lineLimit(1)
                }

                Spacer()

                if isCurrent && isPlaying {
                    PlayingIndicator()
                }

                Text(song.formattedDuration)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Aero.inkSoft)

                if showsMenu {
                    menu
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingNewPlaylistSheet) {
            CreatePlaylistView(initialSongs: [song])
        }
    }

    private var menu: some View {
        Menu {
            Button {
                player.addToQueue(song, playNext: true)
            } label: {
                Label("Play Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            Button {
                player.addToQueue(song, playNext: false)
            } label: {
                Label("Add to Queue", systemImage: "text.badge.plus")
            }

            Menu {
                Button {
                    showingNewPlaylistSheet = true
                } label: {
                    Label("New Playlist…", systemImage: "plus")
                }
                if !playlists.isEmpty {
                    Divider()
                    ForEach(playlists) { playlist in
                        Button(playlist.name) { add(song, to: playlist) }
                    }
                }
            } label: {
                Label("Add to Playlist", systemImage: "text.badge.plus")
            }

            if let onRemoveFromPlaylist {
                Divider()
                Button(role: .destructive, action: onRemoveFromPlaylist) {
                    Label("Remove from Playlist", systemImage: "minus.circle")
                }
            }

            Divider()
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete from Library", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .foregroundStyle(Aero.inkSoft)
                .padding(8)
        }
        .confirmationDialog(
            "Delete \u{201C}\(song.title)\u{201D} from your library?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: deleteFromLibrary)
            Button("Cancel", role: .cancel) {}
        }
    }

    private func add(_ song: Song, to playlist: Playlist) {
        let nextPosition = (playlist.items?.map(\.position).max() ?? -1) + 1
        let item = PlaylistItem(position: nextPosition, playlist: playlist, song: song)
        modelContext.insert(item)
        playlist.dateModified = Date()
        try? modelContext.save()
    }

    private func deleteFromLibrary() {
        player.removeSong(withID: song.id)
        LibraryStorage.deleteFile(relativePath: song.relativeFilePath)
        modelContext.delete(song)
        try? modelContext.save()
    }
}

/// Small animated equalizer-bar glyph shown next to the currently playing row.
struct PlayingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Aero.deepBlue)
                    .frame(width: 3, height: animate ? CGFloat.random(in: 6...16) : 6)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15),
                        value: animate
                    )
            }
        }
        .frame(width: 20, height: 16)
        .onAppear { animate = true }
    }
}
