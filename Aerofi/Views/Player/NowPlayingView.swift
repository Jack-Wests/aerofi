import SwiftUI

struct NowPlayingView: View {
    @Environment(AudioPlayerService.self) private var player
    @Environment(PlayerViewModel.self) private var playerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingLyrics = false
    @State private var showingQueue = false

    var body: some View {
        ZStack {
            AeroBackground()

            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 44, height: 5)
                    .padding(.top, 10)

                if let song = player.currentSong {
                    Text("PLAYING FROM LIBRARY")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Aero.inkSoft)

                    ZStack {
                        if showingLyrics {
                            LyricsView(song: song)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        } else {
                            ArtworkView(data: song.artworkData, cornerRadius: Aero.cornerRadiusLarge)
                                .frame(maxWidth: 320, maxHeight: 320)
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: showingLyrics)
                    .frame(maxHeight: .infinity)

                    VStack(spacing: 4) {
                        Text(song.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(Aero.ink)
                            .lineLimit(1)
                        Text(song.artistName)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Aero.inkSoft)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 30)

                    Scrubber(viewModel: playerViewModel)
                        .padding(.horizontal, 24)

                    transportControls
                        .padding(.top, 4)

                    bottomRow
                        .padding(.bottom, 24)
                } else {
                    Spacer()
                    Aero.heading("Nothing playing")
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showingQueue) {
            QueueView()
        }
    }

    private var transportControls: some View {
        HStack(spacing: 26) {
            Button {
                player.toggleShuffle()
            } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(player.isShuffled ? Aero.deepBlue : Aero.inkSoft)
            }

            GlossyIconButton(systemName: "backward.fill", tint: Aero.skyBlue, diameter: 48) {
                player.skipToPrevious()
            }

            GlossyIconButton(
                systemName: player.isPlaying ? "pause.fill" : "play.fill",
                tint: Aero.deepBlue,
                diameter: 72
            ) {
                player.togglePlayPause()
            }

            GlossyIconButton(systemName: "forward.fill", tint: Aero.skyBlue, diameter: 48) {
                player.skipToNext()
            }

            Button {
                player.repeatMode.cycle()
            } label: {
                Image(systemName: player.repeatMode.symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(player.repeatMode == .off ? Aero.inkSoft : Aero.deepBlue)
            }
        }
        .padding(.horizontal, 20)
    }

    private var bottomRow: some View {
        HStack {
            Button {
                withAnimation { showingLyrics.toggle() }
            } label: {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(showingLyrics ? Aero.deepBlue : Aero.inkSoft)
                    .padding(10)
            }
            Spacer()
            Button {
                showingQueue = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Aero.inkSoft)
                    .padding(10)
            }
        }
        .padding(.horizontal, 30)
    }
}

private struct Scrubber: View {
    var viewModel: PlayerViewModel

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.4)).frame(height: 6)
                    Capsule()
                        .fill(Aero.accentGradient(Aero.deepBlue))
                        .frame(width: proxy.size.width * viewModel.progressFraction, height: 6)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 2)
                        .offset(x: proxy.size.width * viewModel.progressFraction - 8)
                }
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !viewModel.isScrubbing { viewModel.beginScrub() }
                            let fraction = min(max(value.location.x / proxy.size.width, 0), 1)
                            viewModel.updateScrub(to: fraction)
                        }
                        .onEnded { _ in viewModel.commitScrub() }
                )
            }
            .frame(height: 16)

            HStack {
                Text(viewModel.formattedElapsed)
                Spacer()
                Text(viewModel.formattedRemaining)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(Aero.inkSoft)
        }
    }
}
