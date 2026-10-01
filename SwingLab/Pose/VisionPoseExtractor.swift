import AVFoundation
import Vision

protocol PoseExtracting: Sendable {
    func extract(from url: URL, duration: Double) async throws -> [PoseFrame]
}

/// Actor confines Vision and AVFoundation work away from the main actor.
/// Samples at 10 Hz, at most 300 frames. Empty detections preserve timestamps.
actor VisionPoseExtractor: PoseExtracting {
    func extract(from url: URL, duration: Double) async throws -> [PoseFrame] {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 960, height: 960)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        let request = VNDetectHumanBodyPoseRequest()
        var frames: [PoseFrame] = []
        let count = min(300, Int(ceil(duration * 10)))
        for index in 0..<count {
            try Task.checkCancellation()
            let time = CMTime(seconds: Double(index) / 10, preferredTimescale: 600)
            // Synchronous API is confined to this worker actor, not the UI thread.
            var actual = CMTime.zero
            let image = try generator.copyCGImage(at: time, actualTime: &actual)
            try VNImageRequestHandler(cgImage: image, orientation: .up).perform([request])
            // Multiple people make identity ambiguous: omit this sample.
            var joints: [Joint: JointPoint] = [:]
            if let observations = request.results, observations.count == 1 {
                let points = try observations[0].recognizedPoints(.all)
                for (joint, name) in Self.mapping {
                    if let point = points[name], point.confidence >= 0.3 {
                        joints[joint] = JointPoint(x: Double(point.location.x),
                                                  y: Double(point.location.y), confidence: point.confidence)
                    }
                }
            }
            frames.append(PoseFrame(timestamp: actual.seconds, joints: joints))
        }
        guard frames.filter({ $0.joints.count >= 6 }).count >= 3 else { throw LabError.noPose }
        return frames
    }

    private static let mapping: [Joint: VNHumanBodyPoseObservation.JointName] = [
        .nose: .nose, .neck: .neck, .root: .root,
        .leftShoulder: .leftShoulder, .rightShoulder: .rightShoulder,
        .leftElbow: .leftElbow, .rightElbow: .rightElbow,
        .leftWrist: .leftWrist, .rightWrist: .rightWrist,
        .leftHip: .leftHip, .rightHip: .rightHip,
        .leftKnee: .leftKnee, .rightKnee: .rightKnee,
        .leftAnkle: .leftAnkle, .rightAnkle: .rightAnkle
    ]
}
