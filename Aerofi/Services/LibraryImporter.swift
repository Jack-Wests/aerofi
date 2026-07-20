import Foundation
import SwiftData
import Observation

/// Orchestrates the whole "pick a file → it shows up in the library, fully
/// tagged, with lyrics" pipeline: copy into sandbox storage, extract
/// metadata via AVFoundation, upsert Artist/Album, insert the Song, then
/// kick off a background lyrics fetch. Runs on the main actor since it
/// touches a SwiftData ModelContext, but the metadata/lyrics work itself is
/// async so the UI never blocks.
@MainActor
@Observable
final class LibraryImporter {
    enum ImportPhase: Equatable {
        case copying
        case readingMetadata
        case fetchingLyrics
        case done
        case failed(String)
    }

    struct ImportTask: Identifiable {
        let id = UUID()
        var filename: String
        var phase: ImportPhase
    }

    private(set) var activeImports: [ImportTask] = []
    var isImporting: Bool { !activeImports.isEmpty }

    private let modelContext: ModelContext
    private let lyricsService: LyricsService

    init(modelContext: ModelContext, lyricsService: LyricsService = LyricsService()) {
        self.modelContext = modelContext
        self.lyricsService = lyricsService
    }

    func importFiles(_ urls: [URL], removeOriginals: Bool = false) {
        for url in urls {
            let displayName = url.lastPathComponent
            let entry = ImportTask(filename: displayName, phase: .copying)
            activeImports.append(entry)

            Task {
                await self.importSingleFile(url, entryID: entry.id, removeOriginal: removeOriginals)
            }
        }
    }

    /// Sweeps the top level of the app's Documents folder for audio files the
    /// user dropped in from a computer (Finder/iTunes file sharing) or saved
    /// via the Files app, and pulls them through the normal import pipeline.
    /// Originals are removed after a successful copy so they don't re-import
    /// on the next launch. Called once at app startup.
    func importLooseDocumentFiles() {
        let audioExtensions: Set<String> = ["mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "caf"]
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        guard let items = try? FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil) else {
            return
        }
        let audioFiles = items.filter { audioExtensions.contains($0.pathExtension.lowercased()) }
        guard !audioFiles.isEmpty else { return }
        importFiles(audioFiles, removeOriginals: true)
    }

    private func updatePhase(_ id: UUID, _ phase: ImportPhase) {
        guard let index = activeImports.firstIndex(where: { $0.id == id }) else { return }
        activeImports[index].phase = phase
        if phase == .done {
            // Let the "done" checkmark render briefly before clearing.
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                activeImports.removeAll { $0.id == id }
            }
        }
    }

    private func importSingleFile(_ sourceURL: URL, entryID: UUID, removeOriginal: Bool = false) async {
        do {
            updatePhase(entryID, .copying)
            let relativePath = try LibraryStorage.importFile(from: sourceURL, removeOriginal: removeOriginal)
            let fileURL = LibraryStorage.absoluteURL(for: relativePath)

            updatePhase(entryID, .readingMetadata)
            let baseName = sourceURL.deletingPathExtension().lastPathComponent
            let metadata = await MetadataExtractor.extract(from: fileURL, fallbackTitle: baseName)

            let artist = fetchOrCreateArtist(named: metadata.albumArtist ?? metadata.artist)
            let album = fetchOrCreateAlbum(
                name: metadata.album,
                albumArtist: metadata.albumArtist ?? metadata.artist,
                year: metadata.year,
                artworkData: metadata.artworkData,
                artist: artist
            )

            let song = Song(
                title: metadata.title,
                artistName: metadata.artist,
                albumName: metadata.album,
                albumArtist: metadata.albumArtist,
                genre: metadata.genre,
                year: metadata.year,
                trackNumber: metadata.trackNumber,
                discNumber: metadata.discNumber,
                duration: metadata.duration,
                relativeFilePath: relativePath,
                artworkData: metadata.artworkData
            )
            song.album = album
            song.artist = artist
            modelContext.insert(song)
            try? modelContext.save()

            updatePhase(entryID, .fetchingLyrics)
            await fetchLyrics(for: song)
            try? modelContext.save()

            updatePhase(entryID, .done)
        } catch {
            updatePhase(entryID, .failed(error.localizedDescription))
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                activeImports.removeAll { $0.id == entryID }
            }
        }
    }

    private func fetchLyrics(for song: Song) async {
        song.lyricsFetchStatus = .fetching
        let result = await lyricsService.fetchLyrics(
            title: song.title,
            artist: song.artistName,
            album: song.albumName,
            duration: song.duration
        )
        switch result {
        case .synced(let lines, let plain):
            song.syncedLyrics = lines
            song.plainLyrics = plain
            song.lyricsFetchStatus = .foundSynced
        case .plainOnly(let text):
            song.plainLyrics = text
            song.lyricsFetchStatus = .foundPlainOnly
        case .noMatch:
            song.lyricsFetchStatus = .noMatch
        case .error:
            song.lyricsFetchStatus = .failed
        }
    }

    private func fetchOrCreateArtist(named name: String) -> Artist {
        let normalized = name.isEmpty ? "Unknown Artist" : name
        let descriptor = FetchDescriptor<Artist>(predicate: #Predicate { $0.name == normalized })
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let artist = Artist(name: normalized)
        modelContext.insert(artist)
        return artist
    }

    private func fetchOrCreateAlbum(
        name: String,
        albumArtist: String,
        year: Int?,
        artworkData: Data?,
        artist: Artist
    ) -> Album {
        let normalizedName = name.isEmpty ? "Unknown Album" : name
        let descriptor = FetchDescriptor<Album>(
            predicate: #Predicate { $0.name == normalizedName && $0.albumArtist == albumArtist }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.artworkData == nil { existing.artworkData = artworkData }
            return existing
        }
        let album = Album(name: normalizedName, albumArtist: albumArtist, year: year, artworkData: artworkData)
        album.artist = artist
        modelContext.insert(album)
        return album
    }
}
