# Aerofi — Build Handoff Sheet

**For:** a new Claude (Opus) chat that will help finish building this iOS app.
**From:** the previous Claude session that wrote the codebase.
**Owner:** a non-coder — please explain steps in plain language, one at a time, and don't assume prior Xcode experience.

---

## 0. TL;DR for the new chat

There is a complete first draft of a SwiftUI iOS music app called **Aerofi** already
written and pushed to GitHub. It has **never been compiled** (it was authored in a
Linux sandbox with no Xcode). Your job is to walk the owner through opening it in
Xcode on a Mac, getting it to build and run, and fixing any compile errors that
surface — then polishing from there. Assume the owner cannot read Swift; they will
copy/paste error messages to you and you tell them exactly what to change.

**The code lives here:** https://github.com/Jack-Wests/aerofi
(all code is in the `Aerofi/` folder; there's a `README.md` too.)

---

## 1. What Aerofi is

A personal-library music player for iPhone — like a private Spotify for your own
audio files. The owner wants to:

- Upload MP3 / audio files from their phone or a cloud drive.
- Have the app **automatically** sort them by song / album / artist and pull in
  artwork and **lyrics** (no manual typing).
- Play music with the usual controls (play/pause/skip, shuffle, repeat, a queue,
  background playback, lock-screen controls).
- Make and edit playlists.
- Search their library.

**Design goal:** a "Frutiger Aero" look — the glossy, glassy, bright blue/green
aqua aesthetic of the mid-2000s (early iTunes, Windows Vista, early iPod). Think
translucent glass panels, bubbly 3D buttons, water-droplet/bokeh backgrounds.

---

## 2. Tech choices already made (don't re-litigate these unless something forces it)

| Area | Choice | Why |
|---|---|---|
| Language / UI | Swift + SwiftUI | Native, modern, Apple's current default |
| Minimum iOS | **iOS 17** | Needed for the SwiftData + Observation APIs used |
| Database | SwiftData | Apple's built-in local database; stores the song/album/artist/playlist records |
| Audio playback | AVFoundation (`AVPlayer`) | Standard iOS audio engine |
| Metadata/artwork | AVFoundation metadata APIs | Reads tags embedded in the audio files |
| Lyrics | **lrclib.net** (free, no API key) | Returns time-synced lyrics when available; no signup/quota to manage |
| Lock screen / Control Center | MediaPlayer framework (`MPNowPlayingInfoCenter`, `MPRemoteCommandCenter`) | Standard iOS "now playing" integration |

No API keys are required. Nothing costs money. If the owner ever wants better lyrics
coverage, the lyrics code is isolated in one file (`Services/LyricsService.swift`) and
can be swapped for Musixmatch or Genius without touching the rest of the app.

---

## 3. What's already built (35 Swift files, ~3,200 lines)

The project is organized into folders inside `Aerofi/`:

- **`Models/`** — the data records: `Song`, `Album`, `Artist`, `Playlist`,
  `PlaylistItem`. (SwiftData `@Model` classes.)
- **`Services/`** — the "engine room":
  - `LibraryStorage.swift` — copies imported files into the app's private storage.
  - `MetadataExtractor.swift` — reads title/artist/album/artwork/track number from files.
  - `LyricsService.swift` — fetches lyrics from lrclib.net; parses synced `.lrc` timing.
  - `LibraryImporter.swift` — the pipeline that ties import → tagging → lyrics together.
  - `AudioPlayerService.swift` — playback, queue, shuffle/repeat, background audio,
    lock-screen controls.
- **`ViewModels/`** — small glue objects between the data and the screens.
- **`Views/`** — all the screens, grouped by area: `Library/`, `Playlists/`,
  `Player/` (now-playing, mini player, queue, lyrics), `Search/`, `Upload/`, and
  `Components/` (the reusable Frutiger Aero design pieces — colors, glass panels,
  glossy buttons, bokeh background).
- **`AerofiApp.swift`** — the app's entry point.
- **`Info.plist`** — declares the "background audio" capability.

**Every feature in the brief has code written for it.** The question is not "is it
built" — it's "does it compile and run correctly on a real device," which is the
work that remains (see §5).

---

## 4. How to open and run it (the owner needs a Mac)

**Hard requirement: this can only be built on a Mac with Xcode.** There is no way
around this — iPhone apps cannot be built on Windows/Linux or on the phone itself.
If the owner doesn't have a Mac, options are: borrow one, use a cloud Mac service
(e.g. MacinCloud), or an Apple Store / library Mac.

Step-by-step for the owner (new chat: walk them through these one at a time and wait
for them to confirm each before moving on):

1. On the Mac, install **Xcode** from the Mac App Store (it's free but large — a
   several-GB download; leave time for it).
2. Download the code from https://github.com/Jack-Wests/aerofi — click the green
   **Code** button → **Download ZIP** → unzip it.
3. Open Xcode → **File → New → Project → iOS → App**. Set:
   - Product Name: **Aerofi**
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
   - Minimum deployment / iOS version: **17.0** or higher
4. In the new project, delete the two starter files Xcode makes
   (`ContentView.swift` and `Item.swift`).
5. Drag the **contents** of the downloaded `Aerofi/` folder into the Xcode project's
   file list (the left sidebar). When asked, check **"Copy items if needed"** and make
   sure the files are added to the "Aerofi" target. This replaces the starter
   `AerofiApp.swift` with ours.
6. Turn on background audio: click the blue **Aerofi** project icon at the top of the
   sidebar → **Signing & Capabilities** tab → **+ Capability** → add **Background
   Modes** → check **"Audio, AirPlay, and Picture in Picture."**
7. Press the **▶ (Play/Run)** button. First build for a real iPhone also needs the
   owner to sign in with their free Apple ID under Signing & Capabilities (Xcode
   prompts for this).

**The README.md in the repo has this same setup with a bit more detail on the
Info.plist handling** — if Xcode auto-generates its own Info.plist (the modern
default), the capability checkbox in step 6 is all that's needed and our included
`Info.plist` can be ignored.

---

## 5. Known limitations & what to expect (READ THIS — it sets expectations honestly)

**The single most important fact: the code has never been compiled.** It was written
carefully against known Apple APIs and self-reviewed line by line, but the first real
Xcode build will almost certainly surface *some* errors — a mistyped API name, a
signature that changed between iOS versions, etc. **This is normal and expected for a
handoff like this.** The workflow is:

> Owner presses Run → Xcode shows red error(s) → owner copies the error text and the
> file/line into the chat → new chat gives the exact fix → repeat until it builds.

The new chat should treat "getting to a first successful build" as milestone #1 and
budget for a few rounds of this.

Other things not yet done / to verify once it builds:

- **No app icon or launch screen** — the app will run with a blank default icon.
  Adding a Frutiger-Aero-style icon (a glossy water-droplet + music note) is a nice
  early polish task; the new chat can help design/generate one.
- **Lyrics quality depends on the file's tags.** lrclib.net matches on song
  title/artist/album/length. Well-tagged mainstream songs usually match; obscure or
  badly-tagged files may show "no lyrics found" (handled gracefully — it won't crash).
- **Real-device testing needed** for: background playback continuing when the screen
  locks, lock-screen controls, and importing from the Files app / iCloud Drive. These
  can't be fully verified in the simulator.
- **Concurrency:** the code was written to satisfy Swift's strict concurrency
  checking, but if the owner's Xcode has "Swift 6 language mode" on and it complains,
  the safe fallback is to set the project's Swift Language Version to **Swift 5** in
  Build Settings (the new chat can explain where).

---

## 6. How the owner will work with you (guidance for the new chat)

- The owner is **not a programmer.** Give copy-paste-ready instructions. When telling
  them to change code, quote the exact old text and the exact new text, and name the
  file. Prefer "in the file X, find this line and replace it with this" over abstract
  explanations.
- Ask them to **paste full error messages** including the file name and line number
  (in Xcode, clicking the red error usually reveals the detail — tell them how).
- **They can share files with you.** If you need to see the current contents of a
  file to debug, ask them to open it in Xcode and paste it, or to upload it. All the
  source is also downloadable from the GitHub repo, so you can ask them to paste any
  specific file by name.
- Go one milestone at a time: (1) builds successfully → (2) runs in the simulator →
  (3) can import a song and see it in the library → (4) plays audio → (5) lyrics
  appear → (6) runs on their real iPhone → (7) polish (icon, animations, edge cases).

---

## 7. Suggested first message for the owner to send the new chat

The owner can literally paste this to start:

> "I'm building an iOS music app called Aerofi. A previous Claude session wrote the
> whole codebase — it's on GitHub at github.com/Jack-Wests/aerofi and I have a
> handoff document I'll paste below. I'm not a coder. I have a Mac with Xcode / I need
> help getting a Mac [pick one]. Please read the handoff, then walk me through getting
> this to build and run, one step at a time. Here's the handoff:"
>
> …then paste this entire document.

---

*End of handoff. The codebase represents a complete first pass at every feature in the
original brief; the remaining work is compilation, on-device verification, and polish.*
