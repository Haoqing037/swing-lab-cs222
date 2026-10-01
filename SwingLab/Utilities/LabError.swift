import Foundation

enum LabError: LocalizedError {
    case invalidVideo, tooLong, noPose, insufficientData, missingVideo
    var errorDescription: String? {
        switch self {
        case .invalidVideo: return "This file does not contain a readable video track."
        case .tooLong: return "Choose a clip between 0 and 30 seconds. Trim to one complete swing."
        case .noPose: return "No usable body poses found. Try a well-lit clip showing one person's whole body."
        case .insufficientData: return "Not enough confident joint measurements in both swings to compare."
        case .missingVideo: return "The selected video could not be imported."
        }
    }
}
