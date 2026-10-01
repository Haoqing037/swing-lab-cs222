import AVFoundation
import CoreTransferable
import UniformTypeIdentifiers

struct ImportedMovie: Transferable, Sendable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
            try FileManager.default.copyItem(at: received.file, to: destination)
            return ImportedMovie(url: destination)
        }
    }
}

struct VideoInfo: Sendable {
    let duration: Double
    let aspectRatio: Double
}

protocol VideoInspecting: Sendable {
    func inspect(_ url: URL) async throws -> VideoInfo
}

struct VideoInspector: VideoInspecting {
    func inspect(_ url: URL) async throws -> VideoInfo {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        guard duration.isFinite, duration > 0, duration <= 30 else { throw LabError.tooLong }
        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            throw LabError.invalidVideo
        }
        let size = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let upright = size.applying(transform)
        guard abs(upright.height) > 0 else { throw LabError.invalidVideo }
        return VideoInfo(duration: duration, aspectRatio: abs(upright.width / upright.height))
    }
}
