import SwiftUI

struct AlbumsGridView: View {
    let albums: [Album]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(albums) { album in
                    NavigationLink(value: album) {
                        AlbumTile(album: album)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }
}

struct AlbumTile: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ArtworkView(data: album.artworkData, cornerRadius: Aero.cornerRadiusMedium)
                .aspectRatio(1, contentMode: .fit)
            Text(album.name)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Aero.ink)
                .lineLimit(1)
            Text(album.albumArtist)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Aero.inkSoft)
                .lineLimit(1)
        }
    }
}
