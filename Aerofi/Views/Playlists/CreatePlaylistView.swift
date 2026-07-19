import SwiftUI
import SwiftData

struct CreatePlaylistView: View {
    var initialSongs: [Song] = []

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Song.title) private var allSongs: [Song]

    @State private var name: String = ""
    @State private var selectedSongIDs: Set<PersistentIdentifier> = []
    @State private var searchText: String = ""

    private var filteredSongs: [Song] {
        guard !searchText.isEmpty else { return allSongs }
        return allSongs.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artistName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                VStack(spacing: 14) {
                    TextField("Playlist Name", text: $name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .padding()
                        .glassBackground(cornerRadius: Aero.cornerRadiusMedium)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    if !allSongs.isEmpty {
                        TextField("Search songs to add", text: $searchText)
                            .padding(10)
                            .glassBackground(cornerRadius: Aero.cornerRadiusSmall)
                            .padding(.horizontal)

                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(filteredSongs) { song in
                                    songSelectionRow(song)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .scrollIndicators(.hidden)
                    } else {
                        Spacer()
                        Aero.caption("Upload some music first to add songs here.")
                        Spacer()
                    }
                }
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createPlaylist() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            selectedSongIDs = Set(initialSongs.map(\.persistentModelID))
            if let first = initialSongs.first, name.isEmpty {
                name = "\(first.title) and more"
            }
        }
    }

    private func songSelectionRow(_ song: Song) -> some View {
        let isSelected = selectedSongIDs.contains(song.persistentModelID)
        return Button {
            if isSelected {
                selectedSongIDs.remove(song.persistentModelID)
            } else {
                selectedSongIDs.insert(song.persistentModelID)
            }
        } label: {
            HStack(spacing: 12) {
                ArtworkView(data: song.artworkData, cornerRadius: 8)
                    .frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(Aero.ink)
                    Text(song.artistName).font(.system(size: 12, design: .rounded)).foregroundStyle(Aero.inkSoft)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Aero.leafGreen : Aero.inkSoft)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func createPlaylist() {
        let playlist = Playlist(name: name.trimmingCharacters(in: .whitespaces))
        modelContext.insert(playlist)

        let selected = allSongs.filter { selectedSongIDs.contains($0.persistentModelID) }
        for (index, song) in selected.enumerated() {
            let item = PlaylistItem(position: index, playlist: playlist, song: song)
            modelContext.insert(item)
        }
        try? modelContext.save()
        dismiss()
    }
}
