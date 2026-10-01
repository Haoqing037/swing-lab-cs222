import SwiftUI
import PhotosUI

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var swings: [SwingData] = []
    @Published private(set) var busy = false
    @Published var error: String?
    @Published var currentID: UUID?
    @Published private(set) var result: ComparisonResult?
    let store: any SwingStoring
    private let extractor: any PoseExtracting
    private let inspector: any VideoInspecting
    private let analyzer: any SwingAnalyzing

    init(store: any SwingStoring = SwingStore(), extractor: any PoseExtracting = VisionPoseExtractor(),
         inspector: any VideoInspecting = VideoInspector(), analyzer: any SwingAnalyzing = SwingAnalyzer()) {
        self.store = store
        self.extractor = extractor
        self.inspector = inspector
        self.analyzer = analyzer
    }
    var reference: SwingData? { swings.first { $0.metadata.isGoodShot } }
    var current: SwingData? { swings.first { $0.id == currentID } }

    func load() async {
        do { swings = try await store.load() }
        catch { self.error = "Could not read the saved library: \(error.localizedDescription)" }
    }

    func importMovie(_ item: PhotosPickerItem) async {
        guard !busy else { return }
        busy = true
        result = nil
        defer { busy = false }
        var copiedFilename: String?
        do {
            guard let movie = try await item.loadTransferable(type: ImportedMovie.self) else { throw LabError.missingVideo }
            defer { try? FileManager.default.removeItem(at: movie.url) }
            let info = try await inspector.inspect(movie.url)
            let frames = try await extractor.extract(from: movie.url, duration: info.duration)
            let filename = try await store.importVideo(movie.url)
            copiedFilename = filename
            let swing = SwingData(id: UUID(), videoFilename: filename,
                                  metadata: SwingMetadata(title: "Swing \(swings.count + 1)",
                                                          duration: info.duration, aspectRatio: info.aspectRatio),
                                  frames: frames)
            let updated = swings + [swing]
            try await store.save(updated)
            swings = updated
            currentID = swing.id
        } catch {
            if let filename = copiedFilename { try? await store.removeVideo(filename) }
            self.error = error.localizedDescription
        }
    }

    func markGoodShot(_ id: UUID) async {
        var updated = swings
        for index in updated.indices { updated[index].metadata.isGoodShot = updated[index].id == id }
        await persist(updated)
    }
    func setCamera(_ id: UUID, view: CameraView) async {
        var updated = swings
        guard let index = updated.firstIndex(where: { $0.id == id }) else { return }
        updated[index].metadata.cameraView = view
        await persist(updated)
    }
    func addDemo() async {
        guard !swings.contains(where: { $0.metadata.isDemo }) else { return }
        var demos = DemoData.swings()
        if reference != nil { demos[0].metadata.isGoodShot = false }
        await persist(swings + demos)
        currentID = swings.last?.id
    }
    private func persist(_ updated: [SwingData]) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await store.save(updated)
            swings = updated
            result = nil
        } catch { self.error = error.localizedDescription }
    }
    func compare() {
        guard let reference, let current, reference.id != current.id else { return }
        do { result = try analyzer.compare(reference: reference, current: current) }
        catch { self.error = error.localizedDescription }
    }
    func clearComparison() { result = nil }
}
