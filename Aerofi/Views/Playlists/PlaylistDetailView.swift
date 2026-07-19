import SwiftUI
import SwiftData

struct PlaylistDetailView: View {
    @Bindable var playlist: Playlist

    @Environment(AudioPlayerService.self) private var player
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var showingDeleteConfirm = false

    var body: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 0) {
                header

                List {
                    ForEach(playlist.sortedItems) { item in
                        if let song = item.song {
                            SongRow(
                                song: song,
                                isCurrent: player.currentSong?.id == song.id,
                                isPlaying: player.isPlaying,
                                onTap: { playFrom(item) },
                                onRemoveFromPlaylist: { remove(item) }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                        }
                    }
                    .onMove(perform: move)
                    .onDelete(perform: deleteAtOffsets)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        renameText = playlist.name
                        isRenaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        withAnimation { isEditing.toggle() }
                    } label: {
                        Label(isEditing ? "Done Reordering" : "Reorder Songs", systemImage: "arrow.up.arrow.down")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete Playlist", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(Aero.accentGradient(Aero.skyBlue))
                }
            }
        }
        .alert("Rename Playlist", isPresented: $isRenaming) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                playlist.name = renameText.trimmingCharacters(in: .whitespaces)
                playlist.dateModified = Date()
                try? modelContext.save()
            }
        }
        .confirmationDialog("Delete this playlist?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(playlist)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ArtworkCollageView(images: playlist.artworkCollage, cornerRadius: Aero.cornerRadiusLarge)
                .frame(width: 170, height: 170)

            Text("\(playlist.songs.count) songs · \(Song.format(duration: playlist.totalDuration))")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Aero.inkSoft)

            if !playlist.songs.isEmpty {
                HStack(spacing: 14) {
                    Button {
                        player.play(songs: playlist.songs, startAt: 0)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    .buttonStyle(GlossyButtonStyle(tint: Aero.skyBlue))

                    Button {
                        player.play(songs: playlist.songs, startAt: 0, shuffle: true)
                    } label: {
                        Label("Shuffle", systemImage: "shuffle")
                    }
                    .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func playFrom(_ item: PlaylistItem) {
        let songs = playlist.songs
        guard let index = playlist.sortedItems.firstIndex(where: { $0.id == item.id }) else { return }
        player.play(songs: songs, startAt: index)
    }

    private func move(from source: IndexSet, to destination: Int) {
        var items = playlist.sortedItems
        items.move(fromOffsets: source, toOffset: destination)
        for (index, item) in items.enumerated() {
            item.position = index
        }
        playlist.dateModified = Date()
        try? modelContext.save()
    }

    private func deleteAtOffsets(_ offsets: IndexSet) {
        let items = playlist.sortedItems
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }

    private func remove(_ item: PlaylistItem) {
        modelContext.delete(item)
        playlist.dateModified = Date()
        try? modelContext.save()
    }
}
