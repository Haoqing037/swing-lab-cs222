import XCTest
@testable import SwingLab

final class SwingAnalyzerTests: XCTestCase {
    func testIdenticalSwingHasZeroDifferences() throws {
        let swing = DemoData.swings()[0]
        let result = try SwingAnalyzer().compare(reference: swing, current: swing)
        XCTAssertEqual(result.differences.count, 3)
        for difference in result.differences { XCTAssertEqual(difference.delta, 0, accuracy: 0.00001) }
    }
    func testAspectRatioCorrectsNormalizedCoordinates() {
        let frame = PoseFrame(timestamp: 0, joints: [
            .leftShoulder: JointPoint(x: 0, y: 1, confidence: 1),
            .leftElbow: JointPoint(x: 0.5, y: 0, confidence: 1),
            .leftWrist: JointPoint(x: 0.5, y: 1, confidence: 1)
        ])
        XCTAssertEqual(SwingAnalyzer.angle(frame, [.leftShoulder, .leftElbow, .leftWrist], aspect: 2)!, 45, accuracy: 0.001)
    }
    func testMissingAndLowConfidenceJointsDoNotBecomeZeroAngles() {
        var swing = DemoData.swings()[0]
        swing.frames = (0..<5).map { PoseFrame(timestamp: Double($0), joints: [
            .leftElbow: JointPoint(x: 0.5, y: 0.5, confidence: 0.1)
        ]) }
        XCTAssertTrue(SwingAnalyzer().metrics(for: swing).values.isEmpty)
        XCTAssertThrowsError(try SwingAnalyzer().compare(reference: swing, current: swing))
    }
    func testCodableRoundTrip() throws {
        let swing = DemoData.swings()[0]
        let decoded = try JSONDecoder().decode(SwingData.self, from: JSONEncoder().encode(swing))
        XCTAssertEqual(decoded.id, swing.id)
        XCTAssertEqual(decoded.frames.count, 30)
        XCTAssertEqual(decoded.frames[0].joints[.nose]?.confidence, 1)
    }
    func testLocalLibraryPersists() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SwingStore(root: root)
        let swings = DemoData.swings()
        try await store.save(swings)
        let loaded = try await store.load()
        XCTAssertEqual(loaded.map(\.id), swings.map(\.id))
    }
}
