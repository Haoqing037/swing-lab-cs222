import Foundation

protocol SwingStoring: Sendable {
    func load() async throws -> [SwingData]
    func save(_ swings: [SwingData]) async throws
    func importVideo(_ temporaryURL: URL) async throws -> String
    func videoURL(for filename: String) async -> URL
    func removeVideo(_ filename: String) async throws
}

actor SwingStore: SwingStoring {
    private let root: URL
    init(root: URL = URL.applicationSupportDirectory.appendingPathComponent("SwingLab")) {
        self.root = root
    }
    private func prepare() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        // Keep the library on this device; exclude videos and index from iCloud backup.
        var url = root
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
    func load() throws -> [SwingData] {
        try prepare()
        let index = root.appendingPathComponent("library.json")
        guard FileManager.default.fileExists(atPath: index.path) else { return [] }
        return try JSONDecoder().decode([SwingData].self, from: Data(contentsOf: index))
    }
    func save(_ swings: [SwingData]) throws {
        try prepare()
        try JSONEncoder().encode(swings).write(to: root.appendingPathComponent("library.json"), options: .atomic)
    }
    func importVideo(_ temporaryURL: URL) throws -> String {
        try prepare()
        let filename = UUID().uuidString + "." + temporaryURL.pathExtension
        try FileManager.default.copyItem(at: temporaryURL, to: root.appendingPathComponent(filename))
        return filename
    }
    func videoURL(for filename: String) -> URL { root.appendingPathComponent(filename) }
    func removeVideo(_ filename: String) throws {
        try FileManager.default.removeItem(at: root.appendingPathComponent(filename))
    }
}
