import Foundation

/// Manages on-disk storage of imported audio files inside the app's sandbox,
/// independent of wherever the user originally picked them from (Files app,
/// iCloud Drive, a share sheet, etc). Files are copied in so playback and
/// background audio keep working even if the original source disappears.
enum LibraryStorage {
    static var songsDirectory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Library/Songs", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func absoluteURL(for relativePath: String) -> URL {
        songsDirectory.appendingPathComponent(relativePath)
    }

    /// Copies a source file (which may require security-scoped access) into
    /// the app's Library/Songs folder under a collision-proof name, and
    /// returns the relative path to store on the Song model. Pass
    /// `removeOriginal: true` for files already inside the app's own
    /// Documents folder (e.g. dropped in via Finder/iTunes file sharing) so
    /// they aren't re-imported on every launch.
    static func importFile(from sourceURL: URL, removeOriginal: Bool = false) throws -> String {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() } }

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let filename = "\(UUID().uuidString).\(ext)"
        let destination = songsDirectory.appendingPathComponent(filename)

        try FileManager.default.copyItem(at: sourceURL, to: destination)
        if removeOriginal {
            try? FileManager.default.removeItem(at: sourceURL)
        }
        return filename
    }

    static func deleteFile(relativePath: String) {
        let url = absoluteURL(for: relativePath)
        try? FileManager.default.removeItem(at: url)
    }
}
