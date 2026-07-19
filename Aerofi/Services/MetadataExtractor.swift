import Foundation
import AVFoundation

/// Metadata pulled from an audio file's embedded tags (ID3/iTunes/QuickTime
/// atoms — whatever AVFoundation's common-metadata layer normalizes). Any
/// field AVFoundation can't find falls back to a sensible default so a song
/// is always browsable even with no tags at all.
struct ExtractedMetadata {
    var title: String
    var artist: String
    var album: String
    var albumArtist: String?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var duration: TimeInterval
    var artworkData: Data?
}

enum MetadataExtractor {
    static func extract(from fileURL: URL, fallbackTitle: String) async -> ExtractedMetadata {
        let asset = AVURLAsset(url: fileURL)

        var title: String?
        var artist: String?
        var album: String?
        var albumArtist: String?
        var genre: String?
        var year: Int?
        var trackNumber: Int?
        var discNumber: Int?
        var artworkData: Data?

        if let items = try? await asset.load(.commonMetadata) {
            for item in items {
                guard let key = item.commonKey else { continue }
                switch key {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try? await item.load(.stringValue)
                case .commonKeyAlbumName:
                    album = try? await item.load(.stringValue)
                case .commonKeyType:
                    genre = genre ?? (try? await item.load(.stringValue))
                case .commonKeyArtwork:
                    if let value = try? await item.load(.dataValue) {
                        artworkData = value
                    }
                case .commonKeyCreationDate:
                    if let dateString = try? await item.load(.stringValue) {
                        year = Self.parseYear(from: dateString)
                    }
                default:
                    break
                }
            }
        }

        // ID3-specific and iTunes-specific atoms for fields the common-key
        // layer doesn't normalize (album artist, genre, track/disc numbers).
        for format in (try? await asset.load(.availableMetadataFormats)) ?? [] {
            guard let items = try? await asset.loadMetadata(for: format) else { continue }
            for item in items {
                guard let key = item.key as? String ?? (item.identifier?.rawValue) else { continue }
                let lowerKey = key.lowercased()

                if lowerKey.contains("albumartist") || lowerKey.contains("tpe2") || lowerKey.contains("band") {
                    albumArtist = albumArtist ?? (try? await item.load(.stringValue))
                } else if lowerKey.contains("genre") || lowerKey.contains("tcon") {
                    genre = genre ?? (try? await item.load(.stringValue))
                } else if lowerKey.contains("tracknumber") || lowerKey.contains("trkn") {
                    if let string = try? await item.load(.stringValue) {
                        trackNumber = trackNumber ?? Self.parseLeadingInt(string)
                    } else if let number = try? await item.load(.numberValue) {
                        trackNumber = trackNumber ?? number.intValue
                    }
                } else if lowerKey.contains("discnumber") || lowerKey.contains("tpos") {
                    if let string = try? await item.load(.stringValue) {
                        discNumber = discNumber ?? Self.parseLeadingInt(string)
                    } else if let number = try? await item.load(.numberValue) {
                        discNumber = discNumber ?? number.intValue
                    }
                } else if lowerKey.contains("year") || lowerKey.contains("tyer") || lowerKey.contains("tdrc") {
                    if let string = try? await item.load(.stringValue) {
                        year = year ?? Self.parseYear(from: string)
                    }
                }
            }
        }

        let duration: TimeInterval
        if let cmDuration = try? await asset.load(.duration), cmDuration.isNumeric {
            duration = CMTimeGetSeconds(cmDuration)
        } else {
            duration = 0
        }

        let resolvedTitle = title?.trimmed.nonEmpty ?? fallbackTitle
        let resolvedArtist = artist?.trimmed.nonEmpty ?? "Unknown Artist"
        let resolvedAlbum = album?.trimmed.nonEmpty ?? "Unknown Album"

        return ExtractedMetadata(
            title: resolvedTitle,
            artist: resolvedArtist,
            album: resolvedAlbum,
            albumArtist: albumArtist?.trimmed.nonEmpty ?? resolvedArtist,
            genre: genre?.trimmed.nonEmpty,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            duration: duration.isFinite ? duration : 0,
            artworkData: artworkData
        )
    }

    private static func parseYear(from string: String) -> Int? {
        let digits = string.prefix(4).filter(\.isNumber)
        return Int(digits)
    }

    private static func parseLeadingInt(_ string: String) -> Int? {
        let leading = string.prefix { $0.isNumber }
        return Int(leading)
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nonEmpty: String? { isEmpty ? nil : self }
}
