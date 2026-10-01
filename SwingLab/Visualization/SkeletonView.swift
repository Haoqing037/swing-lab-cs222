import SwiftUI

struct SkeletonView: View {
    let frame: PoseFrame?
    let color: Color
    var body: some View {
        Canvas { context, size in
            guard let frame else { return }
            func point(_ joint: Joint) -> CGPoint? {
                guard let p = frame.joints[joint], p.confidence >= 0.3 else { return nil }
                return CGPoint(x: p.x * size.width, y: (1 - p.y) * size.height)
            }
            for (a, b) in Self.bones {
                if let start = point(a), let end = point(b) {
                    var path = Path()
                    path.move(to: start)
                    path.addLine(to: end)
                    context.stroke(path, with: .color(color), lineWidth: 3)
                }
            }
            for joint in Joint.allCases {
                if let p = point(joint) {
                    context.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)),
                                 with: .color(color))
                }
            }
        }.accessibilityLabel("Body pose skeleton")
    }
    static let bones: [(Joint, Joint)] = [
        (.nose, .neck), (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .leftElbow), (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip), (.leftHip, .rightHip),
        (.leftHip, .leftKnee), (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle)
    ]
}
