import SwiftUI
import AVKit

struct PosePreviewView: View {
    let swing: SwingData
    let store: any SwingStoring
    let color: Color
    @State private var index = 0.0
    @State private var image: CGImage?
    @State private var player: AVPlayer?
    @State private var url: URL?
    @State private var previewError: String?
    private let renderer = FramePreview()
    private var frame: PoseFrame? {
        guard !swing.frames.isEmpty else { return nil }
        return swing.frames[min(Int(index), swing.frames.count - 1)]
    }
    var body: some View {
        VStack(alignment: .leading) {
            Text(swing.metadata.title).font(.headline)
            if let player { VideoPlayer(player: player).frame(height: 180) }
            ZStack {
                Color.black
                if let image {
                    Image(decorative: image, scale: 1).resizable()
                }
                SkeletonView(frame: frame, color: color)
            }
            .aspectRatio(swing.metadata.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(swing.metadata.isDemo ? "Synthetic demo pose" : "Skeleton over sampled video frame")
                .font(.caption).foregroundStyle(.secondary)
            if let previewError { Text(previewError).font(.caption).foregroundStyle(.red) }
            if swing.frames.count > 1 {
                Slider(value: $index, in: 0...Double(swing.frames.count - 1), step: 1)
                    .accessibilityLabel("Pose frame")
            }
            Text(String(format: "%.2f s • %d joints", frame?.timestamp ?? 0, frame?.joints.count ?? 0))
                .font(.caption.monospacedDigit())
        }
        .task {
            if let filename = swing.videoFilename {
                let location = await store.videoURL(for: filename)
                url = location
                player = AVPlayer(url: location)
            }
        }
        .task(id: PreviewKey(url: url, timestamp: frame?.timestamp)) {
            image = nil
            guard let url, let frame else { return }
            do {
                let rendered = try await renderer.image(url: url, timestamp: frame.timestamp)
                try Task.checkCancellation()
                image = rendered
                previewError = nil
            } catch is CancellationError {
                return
            } catch { previewError = "Frame preview unavailable: \(error.localizedDescription)" }
        }
        .onDisappear { player?.pause() }
    }
    private struct PreviewKey: Equatable {
        let url: URL?
        let timestamp: Double?
    }
}
