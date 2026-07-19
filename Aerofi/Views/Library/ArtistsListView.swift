import SwiftUI

struct ArtistsListView: View {
    let artists: [Artist]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(artists) { artist in
                    NavigationLink(value: artist) {
                        HStack(spacing: 12) {
                            ArtworkView(data: artist.representativeArtworkData, cornerRadius: 23)
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(artist.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Aero.ink)
                                Text("\(artist.albums?.count ?? 0) albums · \(artist.songs?.count ?? 0) songs")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(Aero.inkSoft)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Aero.inkSoft)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .glassBackground(cornerRadius: Aero.cornerRadiusSmall)
                        .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }
}
