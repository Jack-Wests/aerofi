import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Import sheet: a big glossy "Choose Files" button opens the system file
/// picker (Files app — local device storage AND any signed-in cloud
/// provider like iCloud Drive, Dropbox, Google Drive show up there too),
/// then shows live per-file progress as each song is copied in, tagged,
/// and matched to lyrics.
struct UploadView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var importer: LibraryImporter?
    @State private var showingFilePicker = false

    private static let supportedTypes: [UTType] = [.mp3, .audio, .mpeg4Audio, .wav, .aiff]

    var body: some View {
        NavigationStack {
            ZStack {
                AeroBackground()

                VStack(spacing: 24) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Aero.accentGradient(Aero.skyBlue))
                        .padding(.top, 30)

                    Aero.heading("Add Music")
                    Aero.caption("Pick audio files from your device or a connected cloud drive. Title, artist, album, artwork, and lyrics are found automatically.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Choose Files", systemImage: "folder.fill")
                    }
                    .buttonStyle(GlossyButtonStyle(tint: Aero.leafGreen))

                    if let importer, !importer.activeImports.isEmpty {
                        importProgressList(importer)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: Self.supportedTypes,
                allowsMultipleSelection: true
            ) { result in
                handlePickerResult(result)
            }
            .onAppear {
                if importer == nil {
                    importer = LibraryImporter(modelContext: modelContext)
                }
            }
        }
    }

    private func importProgressList(_ importer: LibraryImporter) -> some View {
        VStack(spacing: 8) {
            ForEach(importer.activeImports) { task in
                HStack(spacing: 10) {
                    phaseIcon(task.phase)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.filename)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Aero.ink)
                            .lineLimit(1)
                        Text(phaseLabel(task.phase))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(Aero.inkSoft)
                    }
                    Spacer()
                }
                .padding(10)
                .glassBackground(cornerRadius: Aero.cornerRadiusSmall)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func phaseIcon(_ phase: LibraryImporter.ImportPhase) -> some View {
        switch phase {
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Aero.leafGreen)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        default:
            ProgressView().controlSize(.small)
        }
    }

    private func phaseLabel(_ phase: LibraryImporter.ImportPhase) -> String {
        switch phase {
        case .copying: "Copying file…"
        case .readingMetadata: "Reading metadata…"
        case .fetchingLyrics: "Fetching lyrics…"
        case .done: "Added to library"
        case .failed(let message): "Failed: \(message)"
        }
    }

    private func handlePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            importer?.importFiles(urls)
        case .failure:
            break
        }
    }
}
