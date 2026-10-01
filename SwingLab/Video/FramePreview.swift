import AVFoundation

actor FramePreview {
    func image(url: URL, timestamp: Double) throws -> CGImage {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 960, height: 960)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        return try generator.copyCGImage(at: CMTime(seconds: timestamp, preferredTimescale: 600), actualTime: nil)
    }
}
