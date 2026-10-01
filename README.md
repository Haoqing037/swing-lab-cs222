# Swing Lab · CS222

Local iPhone starter for comparing a golf swing with the user's own Good Shot. Swift + SwiftUI, Apple Vision, AVFoundation, PhotosPicker; no external packages, server, account, cloud library, LLM, clubface or ball-flight analysis.

## Open and run on your Mac

1. Copy this entire `SwingLab` folder to your Mac or put its contents in your team's GitHub repository.
2. Use **Xcode 16 or newer**, with an iOS simulator installed. Target: **iPhone / iOS 17+**. The project uses Xcode 16 synchronized folders: added Swift files automatically join the appropriate target.
3. Open `SwingLab.xcodeproj`. Select the shared **SwingLab** scheme and an iPhone simulator. Press **Cmd-R**.
4. For a physical iPhone, select your development team in Signing & Capabilities and change `edu.cs222.swinglab` to a unique bundle identifier. No team identifier is committed.
5. Press **Try synthetic demo**, then **Compare swings**. The demo provides two labeled synthetic skeleton sequences, with no video.
6. For real input, add short videos to the simulator Photos app by dragging them into the simulator, or use Photos on your iPhone. Import two clips, mark one **Good Shot**, select the other as current, specify camera view, and compare.
7. Play each original video, then scrub the sampled-frame slider to inspect its skeleton overlay. Playback and the pose slider are independent; the overlay is on a still frame, not live playback.

PhotosPicker grants access only to selected assets, so this version does not request broad photo-library or camera permission. Choosing an iCloud-only asset may cause the system picker to download it; Swing Lab itself has no networking code. Import a downloaded clip for fully offline use.

## Architecture and ownership

`PhotosPicker → temporary movie → VideoInspector → VisionPoseExtractor → SwingData → SwingStore → SwingAnalyzer → ComparisonResult → FeedbackProvider / PosePreviewView`

- **Models/**: Codable, Sendable shared contracts: `Joint`, `JointPoint`, `PoseFrame`, `SwingMetadata`, `SwingData`, `SwingMetrics`, comparison types. Change contracts with team agreement.
- **Views/**: library, selection, Good Shot marking, import state, comparison and frame previews; `LibraryViewModel` accepts services through protocols.
- **Video/**: file-based Transferable import, duration/orientation inspection, upright frame preview.
- **Pose/**: `PoseExtracting` and a Vision worker actor. Replace the service without changing UI or analysis.
- **Analysis/**: `SwingAnalyzing`; pure geometry and baseline comparison.
- **Visualization/**: confidence-filtered skeleton Canvas and shared bone connections.
- **Feedback/**: deterministic short feedback through `FeedbackProviding`.
- **Storage/**: `SwingStoring` and local actor implementation, atomic JSON index, copied videos, relative filenames. Application Support is excluded from iCloud backup. Removing the app clears its library; no delete/export UI yet.
- **Utilities/**: user-facing errors and explicit synthetic fixtures.
- **Tests/**: app-hosted XCTest target covering angle geometry, missing points, comparison invariants, serialization and local persistence.

## Shared data rules

`PoseFrame.timestamp` is actual sample time in seconds. Joint positions use Vision's normalized upright image coordinates: origin bottom-left, x/y in 0...1. The renderer flips y once. Missing joints are absent, never zero-filled. Extraction keeps points with confidence ≥0.3; metrics require ≥0.5 and at least three samples per metric. Frames with multiple people are omitted as empty joint dictionaries to avoid switching subjects. Each successful extraction must have at least three frames containing six joints.

Video orientation is applied before Vision and preview rendering. Metrics multiply x by the upright aspect ratio to avoid distorted angles on portrait clips. `videoFilename` is a relative local filename; absolute sandbox paths are reconstructed by Storage. Exactly one library item can be Good Shot. Selecting and marking references invalidates previous results.

## What the baseline measures

The app extracts at 10 Hz, downscaled to a maximum 960×960, with clips limited to 30 seconds / 300 samples. It computes whole-clip median left/right elbow angles and absolute shoulder-line tilt, then sorts up to three differences by magnitude. Low-confidence or unavailable measurements are omitted. An insufficient-data error replaces invented numbers.

**This is an initial comparison baseline, not validated golf coaching.** Phase detection, trimming, handedness normalization, pelvis/scale alignment, tempo and true 3D shoulder/hip rotation are not implemented. Independent frame sliders do not imply matched swing phases. Different views, framing, occlusion, subject size and clip boundaries can bias results. Synthetic demo data is labeled in the library, previews and results. Real imports always use Vision; there is no silent mock fallback. Vision performs body landmark detection, not golf analysis.

Next analysis milestone: agree on phase labels (address/top/impact/finish), implement phase detection with confidence, compare matched phases after body normalization, then validate against manually annotated clips. Keep phase detection behind a separate protocol.

## Four-person division

- **Member 1 — tech / core analysis / integration:** own Models and Analysis; define contracts, review interfaces, integrate branches, validate camera/phase assumptions.
- **Member 2 — pose / video:** own Video and Pose; improve decoding speed, cancellation/progress, confidence diagnostics and orientation testing with real clips.
- **Member 3 — SwiftUI / video picker:** own Views; improve navigation, rename/delete, import progress and errors, accessibility and local-library interactions.
- **Member 4 — skeleton / feedback / testing:** own Visualization, Feedback and Tests; improve overlay styling, matched-pose display, meaningful feedback and test fixtures.

Storage and Utilities are shared integration responsibilities coordinated by the lead. Everyone can work on pure interfaces and fixtures, but each person implementing iOS UI/Vision needs access to a Mac with Xcode to build and verify their changes.

## GitHub branch and PR workflow

Initialize the repository at this folder, commit the starter, and push to a team-owned GitHub repository. No repository or remote has been created by this delivery.

Keep `main` runnable. Work in short branches such as `feature/pose-confidence`, `feature/video-library`, `feature/skeleton-preview`, and `feature/phase-analysis`. Open small PRs with behavior, validation and screenshots for UI changes. Request one teammate's review; the lead reviews shared model/protocol changes. Pull main regularly, resolve conflicts on your branch, and merge only after the build and relevant tests pass. Do not commit signing teams, user Xcode settings, private videos, or generated build output. Use consented or synthetic fixtures.

## Validation

In Xcode, **Cmd-U** runs SwingLabTests. Command-line equivalents on a Mac (replace the simulator name with an installed device):

```sh
xcodebuild -list -project SwingLab.xcodeproj
xcodebuild -project SwingLab.xcodeproj -scheme SwingLab \
  -destination 'platform=iOS Simulator,name=iPhone 16' build CODE_SIGNING_ALLOWED=NO
xcodebuild -project SwingLab.xcodeproj -scheme SwingLab \
  -destination 'platform=iOS Simulator,name=iPhone 16' test CODE_SIGNING_ALLOWED=NO
```

Manual acceptance: demo comparison; two real clips; reference switching; relaunch persistence; portrait/landscape orientation; unreadable or >30-second video; no person/multiple people/occluded joints; picker cancellation; large text and VoiceOver. Confirm the overlay matches the sampled upright image, including left/right joints. Demo fixtures test app wiring, not Vision accuracy.

This starter was authored on Windows, without Xcode or an Apple SDK. Source/project consistency was checked, but an iOS build and XCTest execution must still be verified on your Mac. There is no App Store icon or release packaging yet.

## Apple API references

- [PhotosPicker](https://developer.apple.com/documentation/photosui/photospicker)
- [Detecting human body poses](https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images)
- [VNDetectHumanBodyPoseRequest](https://developer.apple.com/documentation/vision/vndetecthumanbodyposerequest)
