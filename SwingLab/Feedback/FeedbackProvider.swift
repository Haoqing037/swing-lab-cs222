import Foundation

protocol FeedbackProviding: Sendable {
    func feedback(for difference: MetricDifference) -> String
}

struct FeedbackProvider: FeedbackProviding {
    func feedback(for difference: MetricDifference) -> String {
        if abs(difference.delta) < 5 { return "Similar to your Good Shot at this camera angle."
        }
        let direction = difference.delta > 0 ? "higher" : "lower"
        return "Median \(difference.kind.title.lowercased()) is \(Int(abs(difference.delta).rounded()))° \(direction). Review the same part of both swings before changing your technique."
    }
}
