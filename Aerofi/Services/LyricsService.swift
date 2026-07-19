import Foundation

/// Result of an automatic lyrics lookup. Deliberately has no "manual entry"
/// case — per the product brief, lyrics are always auto-fetched, and a
/// miss just means no lyrics tab content rather than a blocking error.
enum LyricsFetchResult {
    case synced(lines: [SyncedLyricLine], plainFallback: String?)
    case plainOnly(String)
    case noMatch
    case error
}

/// Fetches lyrics from lrclib.net — a free, keyless, community-run LRC
/// lyrics database well suited to a personal-library app (no auth, no
/// per-request quota to manage). Falls back from an exact metadata match to
/// a fuzzy title/artist search, and degrades gracefully to "no lyrics"
/// rather than surfacing an error to the user.
final class LyricsService {
    private let baseURL = URL(string: "https://lrclib.net/api")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLyrics(title: String, artist: String, album: String, duration: TimeInterval) async -> LyricsFetchResult {
        if let exact = await fetchExact(title: title, artist: artist, album: album, duration: duration) {
            return interpret(exact)
        }
        if let match = await searchBestMatch(title: title, artist: artist, duration: duration) {
            return interpret(match)
        }
        return .noMatch
    }

    // MARK: - Networking

    private struct LRCLibTrack: Decodable {
        let id: Int?
        let trackName: String?
        let artistName: String?
        let albumName: String?
        let duration: Double?
        let instrumental: Bool?
        let plainLyrics: String?
        let syncedLyrics: String?
    }

    private func fetchExact(title: String, artist: String, album: String, duration: TimeInterval) async -> LRCLibTrack? {
        var components = URLComponents(url: baseURL.appendingPathComponent("get"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist),
            URLQueryItem(name: "album_name", value: album),
            URLQueryItem(name: "duration", value: String(Int(duration.rounded())))
        ]
        guard let url = components?.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(LRCLibTrack.self, from: data)
        } catch {
            return nil
        }
    }

    private func searchBestMatch(title: String, artist: String, duration: TimeInterval) async -> LRCLibTrack? {
        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "track_name", value: title),
            URLQueryItem(name: "artist_name", value: artist)
        ]
        guard let url = components?.url else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let results = try JSONDecoder().decode([LRCLibTrack].self, from: data)
            guard !results.isEmpty else { return nil }

            // Prefer the candidate with the closest duration to the local
            // file, since title/artist search alone is fuzzy and can
            // return covers, live versions, or remasters.
            if duration > 0 {
                return results.min { lhs, rhs in
                    abs((lhs.duration ?? .infinity) - duration) < abs((rhs.duration ?? .infinity) - duration)
                }
            }
            return results.first
        } catch {
            return nil
        }
    }

    // MARK: - Interpretation

    private func interpret(_ track: LRCLibTrack) -> LyricsFetchResult {
        if track.instrumental == true {
            return .noMatch
        }
        if let synced = track.syncedLyrics, !synced.isEmpty {
            let lines = Self.parseLRC(synced)
            if !lines.isEmpty {
                return .synced(lines: lines, plainFallback: track.plainLyrics)
            }
        }
        if let plain = track.plainLyrics, !plain.isEmpty {
            return .plainOnly(plain)
        }
        return .noMatch
    }

    /// Parses standard LRC format lines like `[01:23.45]Some lyric text`.
    /// Multiple timestamps on one line (`[00:01.00][00:05.00]text`) each
    /// produce their own entry.
    static func parseLRC(_ raw: String) -> [SyncedLyricLine] {
        var lines: [SyncedLyricLine] = []
        let timestampPattern = /\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]/

        for rawLine in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            let matches = rawLine.matches(of: timestampPattern)
            guard !matches.isEmpty else { continue }

            let text = String(rawLine[matches.last!.range.upperBound...]).trimmingCharacters(in: .whitespaces)

            for match in matches {
                guard let minutes = Int(match.output.1), let seconds = Int(match.output.2) else { continue }
                var fraction: Double = 0
                if let fractionString = match.output.3 {
                    let padded = fractionString.count == 1 ? fractionString + "00" : fractionString
                    fraction = Double(padded).map { $0 / pow(10, Double(padded.count)) } ?? 0
                }
                let timestamp = Double(minutes * 60) + Double(seconds) + fraction
                lines.append(SyncedLyricLine(timestamp: timestamp, text: text))
            }
        }

        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}
