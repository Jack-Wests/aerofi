# Aerofi

A personal-library music player for iOS, styled after the Frutiger Aero
aesthetic (glossy glass panels, bright sky/aqua gradients, bubbly 3D buttons —
think early iTunes, Windows Vista, the click-wheel iPod era). Built with
SwiftUI + SwiftData, targeting **iOS 17+**.

## What's here

```
Aerofi/
  AerofiApp.swift            App entry point, SwiftData container, injects AudioPlayerService
  Info.plist                 Background audio mode + app category
  Models/                    SwiftData @Model types: Song, Album, Artist, Playlist, PlaylistItem
  Services/
    LibraryStorage.swift      Copies imported files into app sandbox storage
    MetadataExtractor.swift   AVFoundation-based ID3/iTunes tag + artwork extraction
    LyricsService.swift       lrclib.net lookup (exact match -> fuzzy search -> graceful miss), LRC parser
    LibraryImporter.swift     Orchestrates import: copy -> tag -> upsert Artist/Album -> fetch lyrics
    AudioPlayerService.swift  AVPlayer wrapper: queue, shuffle/repeat, background audio, lock-screen controls
  ViewModels/                 PlayerViewModel, LibraryViewModel, SearchViewModel
  Views/
    Library/                  Songs / Albums / Artists browsing + detail screens
    Playlists/                List, detail (drag reorder), create
    Player/                   Now Playing, mini player, queue, synced lyrics
    Search/                   Cross-library search
    Upload/                   File import sheet with live per-file progress
    Components/               Frutiger Aero design system (colors, glass panel, glossy buttons, artwork views)
    RootView.swift             TabView + persistent mini player
```

## Setting this up in Xcode

This code was written in a Linux sandbox with **no Xcode/Swift toolchain
available**, so it has not been compiled or run — see "Known limitations"
below. To get it into a real project:

1. **New Project → iOS → App.** Interface: SwiftUI. Storage: SwiftData.
   Minimum deployment target: **iOS 17.0**. Name it `Aerofi`.
2. Delete the template's `ContentView.swift` and `Item.swift`.
3. Drag the `Aerofi/` folder from this repo into the Xcode project navigator
   (ensure "Copy items if needed" is checked and files are added to the
   `Aerofi` target), replacing the default `AerofiApp.swift`.
4. **Signing & Capabilities → + Capability → Background Modes → check
   "Audio, AirPlay, and Picture in Picture."** This is what makes playback
   (and lock-screen controls) survive backgrounding. It writes the same
   `UIBackgroundModes: [audio]` key already present in the included
   `Info.plist` — if Xcode is auto-generating your Info.plist
   (`GENERATE_INFOPLIST_FILE = YES`, the default for new projects), just use
   the capability checkbox and you can discard the included Info.plist; if
   you'd rather use the included file directly, set
   `GENERATE_INFOPLIST_FILE = NO` and point `INFOPLIST_FILE` at
   `Aerofi/Info.plist` in Build Settings.
5. Build & run on a device or simulator with iOS 17+.

No API keys are required. Lyrics come from
[lrclib.net](https://lrclib.net), a free, keyless, community-run LRC
database — good fit for a personal-library app since there's no auth or
quota to manage. If you'd rather use Musixmatch or Genius instead, swap the
networking in `Services/LyricsService.swift`; everything above it
(`LibraryImporter`, `Song.lyricsFetchStatus`, `LyricsView`) is written
against the `LyricsFetchResult` enum, not the API shape, so the rest of the
app doesn't need to change.

## Design notes

- `Views/Components/FrutigerAeroTheme.swift` is the single source of truth
  for the palette (`Aero.skyBlue`, `Aero.aqua`, `Aero.leafGreen`, etc.),
  gradients, and the animated bokeh/lens-flare background (`AeroBackground`).
- `GlassPanel` / `.glassBackground()` give any surface the translucent
  frosted-glass treatment; `GlossyButtonStyle` / `GlossyIconButton` give
  buttons the bubbly top-highlight 3D sheen.
- The app forces light appearance (`preferredColorScheme(.light)`) since the
  whole palette is built around a bright sky gradient with dark-ink text —
  a dark-mode variant wasn't part of the brief and would need its own pass.

## Known limitations / not yet verified

Built and reviewed without access to Xcode, so treat this as a strong first
pass rather than a verified build:

- **Not compiled.** No Swift toolchain was available in the build
  environment. The code was written carefully against known SwiftUI/
  SwiftData/AVFoundation/MediaPlayer APIs and self-reviewed line by line,
  but only building in Xcode will catch the last mile of typos or API
  signature drift.
- **No app icon / launch screen asset catalog** — add an `Assets.xcassets`
  with an `AppIcon` in the Frutiger Aero style (glossy droplet/note motif).
- **Lyrics matching quality** depends entirely on lrclib.net's database
  coverage for your specific files' tags; obscure or mistagged tracks may
  come back as "no lyrics found," which the UI handles gracefully rather
  than erroring.
- **FLAC/ALAC** files will import (metadata + playback both go through
  AVFoundation, which supports them on iOS), but very unusual container
  formats may need testing.
