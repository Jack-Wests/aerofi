import SwiftUI
import UIKit

/// Renders song/album artwork with a glossy rounded frame and a subtle glass
/// reflection strip, falling back to a generated note-and-droplet placeholder
/// when no artwork was embedded in the file.
struct ArtworkView: View {
    let data: Data?
    var cornerRadius: CGFloat = Aero.cornerRadiusSmall
    var showsGloss: Bool = true

    var body: some View {
        ZStack {
            if let data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }

            if showsGloss {
                LinearGradient(
                    colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Aero.deepBlue.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [Aero.aqua, Aero.skyBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "music.note")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

/// Overlapping-artwork collage tile used for playlists with multiple songs.
struct ArtworkCollageView: View {
    let images: [Data]
    var cornerRadius: CGFloat = Aero.cornerRadiusSmall

    var body: some View {
        Group {
            if images.count >= 4 {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    GridRow {
                        tile(images[0])
                        tile(images[1])
                    }
                    GridRow {
                        tile(images[2])
                        tile(images[3])
                    }
                }
            } else if let first = images.first {
                ArtworkView(data: first, cornerRadius: cornerRadius)
            } else {
                ArtworkView(data: nil, cornerRadius: cornerRadius)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Aero.deepBlue.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    private func tile(_ data: Data) -> some View {
        ArtworkView(data: data, cornerRadius: 0, showsGloss: false)
    }
}
