import SwiftUI

/// Slim glass bar pinned above the tab bar showing the current track, with a
/// tap-to-expand into the full Now Playing sheet — the classic "now playing
/// strip" pattern, done in the glossy Aero style.
struct MiniPlayerView: View {
    @Environment(AudioPlayerService.self) private var player
    @State private var showingNowPlaying = false

    var body: some View {
        if let song = player.currentSong {
            Button {
                showingNowPlaying = true
            } label: {
                HStack(spacing: 12) {
                    ArtworkView(data: song.artworkData, cornerRadius: 10)
                        .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(song.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Aero.ink)
                            .lineLimit(1)
                        Text(song.artistName)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(Aero.inkSoft)
                            .lineLimit(1)
                    }

                    Spacer()

                    GlossyIconButton(
                        systemName: player.isPlaying ? "pause.fill" : "play.fill",
                        tint: Aero.skyBlue,
                        diameter: 36
                    ) {
                        player.togglePlayPause()
                    }

                    GlossyIconButton(systemName: "forward.fill", tint: Aero.aqua, diameter: 36) {
                        player.skipToNext()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: Aero.cornerRadiusMedium, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Aero.cornerRadiusMedium, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: Aero.cornerRadiusMedium, style: .continuous))
            .shadow(color: Aero.deepBlue.opacity(0.25), radius: 12, x: 0, y: 6)
            .overlay(alignment: .bottom) {
                ProgressBar(fraction: player.duration > 0 ? player.currentTime / player.duration : 0)
                    .frame(height: 2)
                    .padding(.horizontal, 14)
                    .offset(y: -3)
            }
            .padding(.horizontal, 10)
            .sheet(isPresented: $showingNowPlaying) {
                NowPlayingView()
            }
        }
    }
}

private struct ProgressBar: View {
    let fraction: Double
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.4))
                Capsule().fill(Aero.accentGradient(Aero.deepBlue))
                    .frame(width: proxy.size.width * max(0, min(1, fraction)))
            }
        }
    }
}
