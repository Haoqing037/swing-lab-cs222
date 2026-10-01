import Foundation

enum DemoData {
    static func swings() -> [SwingData] {
        [make(title: "Demo Good Shot", offset: 0, good: true),
         make(title: "Demo current swing", offset: 0.12, good: false)]
    }
    private static func make(title: String, offset: Double, good: Bool) -> SwingData {
        let frames = (0..<30).map { index in
            let movement = sin(Double(index) / 29 * .pi) * 0.12
            let coordinates: [Joint: (Double, Double)] = [
                .nose: (0.5, 0.88), .neck: (0.5, 0.78), .root: (0.5, 0.48),
                .leftShoulder: (0.36, 0.76), .rightShoulder: (0.64, 0.76 + offset / 3),
                .leftElbow: (0.29, 0.61), .rightElbow: (0.71, 0.61),
                .leftWrist: (0.37 + movement + offset, 0.54 + movement),
                .rightWrist: (0.6 - movement, 0.54 + movement),
                .leftHip: (0.42, 0.48), .rightHip: (0.58, 0.48),
                .leftKnee: (0.39, 0.29), .rightKnee: (0.61, 0.29),
                .leftAnkle: (0.35, 0.08), .rightAnkle: (0.65, 0.08)
            ]
            return PoseFrame(timestamp: Double(index) / 10,
                             joints: coordinates.mapValues { JointPoint(x: $0.0, y: $0.1, confidence: 1) })
        }
        return SwingData(id: UUID(), videoFilename: nil,
                         metadata: SwingMetadata(title: title, cameraView: .faceOn, isGoodShot: good,
                                                 duration: 3, aspectRatio: 0.75, isDemo: true), frames: frames)
    }
}
