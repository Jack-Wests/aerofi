import SwiftUI

struct QueueView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                List {
                    if let current = player.currentSong {
                        Section {
                            SongRow(song: current, isCurrent: true, isPlaying: player.isPlaying, showsMenu: false, onTap: {})
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        } header: {
                            Text("Now Playing").foregroundStyle(Aero.inkSoft)
                        }
                    }

                    if upcoming.isEmpty {
                        Section {
                            Aero.caption("Queue is empty — add songs from the library.")
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    } else {
                        Section {
                            ForEach(Array(upcoming.enumerated()), id: \.element.id) { offset, song in
                                SongRow(
                                    song: song,
                                    showsMenu: false,
                                    onTap: { player.playQueueItem(at: player.currentIndex + 1 + offset) }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onMove(perform: moveUpcoming)
                            .onDelete(perform: deleteUpcoming)
                        } header: {
                            Text("Up Next").foregroundStyle(Aero.inkSoft)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))
            }
            .navigationTitle("Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var upcoming: [Song] {
        guard player.currentIndex + 1 < player.queue.count else { return [] }
        return Array(player.queue[(player.currentIndex + 1)...])
    }

    private func moveUpcoming(from source: IndexSet, to destination: Int) {
        let offset = player.currentIndex + 1
        let mappedSource = IndexSet(source.map { $0 + offset })
        player.moveQueueItem(from: mappedSource, to: destination + offset)
    }

    private func deleteUpcoming(_ offsets: IndexSet) {
        let offset = player.currentIndex + 1
        for index in offsets.sorted(by: >) {
            player.removeFromQueue(at: index + offset)
        }
    }
}
