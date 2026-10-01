import Foundation

enum Joint: String, Codable, CaseIterable, Sendable {
    case nose, neck, root
    case leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist
    case leftHip, rightHip, leftKnee, rightKnee, leftAnkle, rightAnkle
}

/// Vision coordinates: normalized 0...1, origin at bottom left, upright image.
struct JointPoint: Codable, Sendable {
    let x: Double
    let y: Double
    let confidence: Float
}

struct PoseFrame: Codable, Sendable {
    let timestamp: Double
    let joints: [Joint: JointPoint]
}

enum CameraView: String, Codable, CaseIterable, Sendable {
    case unspecified, faceOn, downTheLine
}

struct SwingMetadata: Codable, Sendable {
    var title: String
    var importedAt: Date = Date()
    var cameraView: CameraView = .unspecified
    var isGoodShot = false
    var duration: Double
    var aspectRatio: Double
    var isDemo = false
}

struct SwingData: Identifiable, Codable, Sendable {
    let id: UUID
    /// Relative filename in the local library; never persist sandbox absolute paths.
    let videoFilename: String?
    var metadata: SwingMetadata
    var frames: [PoseFrame]
}

enum MetricKind: String, Codable, CaseIterable, Sendable {
    case leftElbowAngle, rightElbowAngle, shoulderTilt
    var title: String {
        switch self {
        case .leftElbowAngle: return "Left elbow angle"
        case .rightElbowAngle: return "Right elbow angle"
        case .shoulderTilt: return "Shoulder line tilt"
        }
    }
}

struct SwingMetrics: Codable, Sendable {
    var values: [MetricKind: Double]
    var usableFrameCount: Int
}

struct MetricDifference: Identifiable, Sendable {
    var id: MetricKind { kind }
    let kind: MetricKind
    let reference: Double
    let current: Double
    var delta: Double { current - reference }
}

struct ComparisonResult: Sendable {
    let differences: [MetricDifference]
    let referenceMetrics: SwingMetrics
    let currentMetrics: SwingMetrics
    let notes: [String]
}
