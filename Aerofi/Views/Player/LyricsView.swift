import SwiftUI

/// Auto-fetched lyrics display. Synced lyrics scroll and highlight the
/// current line in time with playback; plain-text lyrics just display as a
/// scrollable block; a miss shows a friendly empty state rather than an error.
struct LyricsView: View {
    let song: Song
    @Environment(AudioPlayerService.self) private var player

    var body: some View {
        Group {
            switch song.lyricsFetchStatus {
            case .foundSynced:
                if let lines = song.syncedLyrics, !lines.isEmpty {
                    SyncedLyricsScroller(lines: lines, currentTime: player.currentTime)
                } else {
                    plainOrEmpty
                }
            case .foundPlainOnly:
                plainOrEmpty
            case .fetching, .notFetched:
                fetchingState
            case .noMatch, .failed:
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var plainOrEmpty: some View {
        Group {
            if let plain = song.plainLyrics, !plain.isEmpty {
                ScrollView {
                    Text(plain)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Aero.ink)
                        .multilineTextAlignment(.center)
                        .padding(24)
                }
                .scrollIndicators(.hidden)
            } else {
                emptyState
            }
        }
    }

    private var fetchingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Aero.caption("Fetching lyrics…")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.system(size: 40))
                .foregroundStyle(Aero.accentGradient(Aero.aqua))
            Aero.caption("No lyrics found for this song.")
        }
        .padding(30)
        .glassBackground(cornerRadius: Aero.cornerRadiusLarge)
        .padding(.horizontal, 40)
    }
}

private struct SyncedLyricsScroller: View {
    let lines: [SyncedLyricLine]
    let currentTime: TimeInterval

    private var currentIndex: Int {
        var index = 0
        for (i, line) in lines.enumerated() where line.timestamp <= currentTime {
            index = i
        }
        return index
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 18) {
                    Color.clear.frame(height: 80)
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line.text.isEmpty ? "♪" : line.text)
                            .font(.system(size: index == currentIndex ? 21 : 17, weight: index == currentIndex ? .bold : .medium, design: .rounded))
                            .foregroundStyle(index == currentIndex ? Aero.deepBlue : Aero.inkSoft.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .id(index)
                            .animation(.easeInOut(duration: 0.25), value: currentIndex)
                    }
                    Color.clear.frame(height: 200)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentIndex) { _, newValue in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}
