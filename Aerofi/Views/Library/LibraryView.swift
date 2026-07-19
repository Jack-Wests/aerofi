import SwiftUI
import SwiftData

enum LibrarySegment: String, CaseIterable, Identifiable {
    case songs = "Songs"
    case albums = "Albums"
    case artists = "Artists"
    var id: String { rawValue }
}

struct LibraryView: View {
    @State private var segment: LibrarySegment = .songs
    @State private var libraryViewModel = LibraryViewModel()
    @State private var showingUpload = false

    @Query(sort: \Song.dateAdded, order: .reverse) private var allSongs: [Song]
    @Query(sort: \Album.name) private var allAlbums: [Album]
    @Query(sort: \Artist.name) private var allArtists: [Artist]

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                VStack(spacing: 12) {
                    segmentPicker

                    Group {
                        switch segment {
                        case .songs:
                            SongsListView(songs: libraryViewModel.sorted(allSongs), libraryViewModel: libraryViewModel)
                        case .albums:
                            AlbumsGridView(albums: allAlbums)
                        case .artists:
                            ArtistsListView(artists: allArtists)
                        }
                    }
                }
                .padding(.top, 8)

                if allSongs.isEmpty {
                    EmptyLibraryPrompt(showingUpload: $showingUpload)
                }
            }
            .navigationDestination(for: Album.self) { AlbumDetailView(album: $0) }
            .navigationDestination(for: Artist.self) { ArtistDetailView(artist: $0) }
            .navigationTitle("Aerofi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingUpload = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Aero.accentGradient(Aero.skyBlue))
                    }
                }
            }
            .sheet(isPresented: $showingUpload) {
                UploadView()
            }
        }
    }

    private var segmentPicker: some View {
        Picker("View", selection: $segment.animation(.easeInOut(duration: 0.2))) {
            ForEach(LibrarySegment.allCases) { seg in
                Text(seg.rawValue).tag(seg)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

private struct EmptyLibraryPrompt: View {
    @Binding var showingUpload: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.drizzle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Aero.accentGradient(Aero.aqua))
            Aero.heading("Your library is empty")
            Aero.caption("Upload songs to get started — artwork, artist, and lyrics are found automatically.")
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Upload Music") { showingUpload = true }
                .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))
        }
        .padding(28)
        .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
        .padding(.horizontal, 32)
    }
}
