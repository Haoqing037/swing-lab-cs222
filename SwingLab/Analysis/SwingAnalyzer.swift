import Foundation

protocol SwingAnalyzing: Sendable {
    func metrics(for swing: SwingData) -> SwingMetrics
    func compare(reference: SwingData, current: SwingData) throws -> ComparisonResult
}

/// Starter baseline: median 2D measurements across the whole clip.
/// Phase detection, alignment and tempo are future work, not inferred here.
struct SwingAnalyzer: SwingAnalyzing {
    func metrics(for swing: SwingData) -> SwingMetrics {
        var samples: [MetricKind: [Double]] = [:]
        var usable = 0
        for frame in swing.frames {
            var contributed = false
            for (kind, triple) in [
                (MetricKind.leftElbowAngle, [Joint.leftShoulder, .leftElbow, .leftWrist]),
                (MetricKind.rightElbowAngle, [Joint.rightShoulder, .rightElbow, .rightWrist])
            ] {
                if let value = Self.angle(frame, triple, aspect: swing.metadata.aspectRatio) {
                    samples[kind, default: []].append(value)
                    contributed = true
                }
            }
            if let left = frame.joints[.leftShoulder], let right = frame.joints[.rightShoulder],
               left.confidence >= 0.5, right.confidence >= 0.5 {
                let dx = abs(right.x - left.x) * swing.metadata.aspectRatio
                if dx > 0.01 {
                    samples[.shoulderTilt, default: []].append(atan2(abs(right.y - left.y), dx) * 180 / .pi)
                    contributed = true
                }
            }
            if contributed { usable += 1 }
        }
        return SwingMetrics(values: samples.compactMapValues { values in
            guard values.count >= 3 else { return nil }
            let sorted = values.sorted()
            let middle = sorted.count / 2
            return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        }, usableFrameCount: usable)
    }

    func compare(reference: SwingData, current: SwingData) throws -> ComparisonResult {
        let baseline = metrics(for: reference), candidate = metrics(for: current)
        let differences = MetricKind.allCases.compactMap { kind -> MetricDifference? in
            guard let a = baseline.values[kind], let b = candidate.values[kind] else { return nil }
            return MetricDifference(kind: kind, reference: a, current: b)
        }.sorted { abs($0.delta) > abs($1.delta) }
        guard !differences.isEmpty else { throw LabError.insufficientData }
        var notes = ["Whole-clip median 2D measurements; swings are not phase-aligned.",
                     "Use the same camera angle, framing and handedness. These are observations, not coaching diagnoses."]
        if reference.metadata.cameraView != current.metadata.cameraView {
            notes.append("Camera views differ; the measurements may not be comparable.")
        }
        return ComparisonResult(differences: differences, referenceMetrics: baseline,
                                currentMetrics: candidate, notes: notes)
    }

    static func angle(_ frame: PoseFrame, _ triple: [Joint], aspect: Double) -> Double? {
        guard triple.count == 3, aspect.isFinite, aspect > 0,
              let a = frame.joints[triple[0]], let b = frame.joints[triple[1]],
              let c = frame.joints[triple[2]],
              [a, b, c].allSatisfy({ $0.confidence >= 0.5 }) else { return nil }
        let ux = (a.x - b.x) * aspect, uy = a.y - b.y
        let vx = (c.x - b.x) * aspect, vy = c.y - b.y
        let denominator = hypot(ux, uy) * hypot(vx, vy)
        guard denominator > 0.000001 else { return nil }
        return acos(max(-1, min(1, (ux * vx + uy * vy) / denominator))) * 180 / .pi
    }
}
