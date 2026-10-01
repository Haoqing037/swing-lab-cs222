import SwiftUI
import PhotosUI

struct LibraryView: View {
    @StateObject private var model = LibraryViewModel()
    @State private var selection: PhotosPickerItem?
    private let feedback = FeedbackProvider()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Compare a swing with your own Good Shot.").font(.title2.bold())
                    Text("Import one full-body swing per clip, up to 30 seconds. Keep the camera view and handedness consistent.")
                        .foregroundStyle(.secondary)
                    PhotosPicker(selection: $selection, matching: .videos) {
                        Label("Import swing video", systemImage: "video.badge.plus")
                    }.buttonStyle(.borderedProminent).disabled(model.busy)
                    if model.busy { ProgressView("Importing and detecting body poses…") }
                    Button("Try synthetic demo") { Task { await model.addDemo() } }
                        .disabled(model.busy || model.swings.contains { $0.metadata.isDemo })
                    ForEach(model.swings) { swing in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(swing.metadata.title).font(.headline)
                                if swing.metadata.isGoodShot { Label("Good Shot", systemImage: "star.fill").font(.caption) }
                                if swing.metadata.isDemo { Text("DEMO").font(.caption.bold()) }
                            }
                            Picker("Camera view", selection: Binding(
                                get: { swing.metadata.cameraView },
                                set: { view in Task { await model.setCamera(swing.id, view: view) } }
                            )) {
                                Text("Unspecified").tag(CameraView.unspecified)
                                Text("Face on").tag(CameraView.faceOn)
                                Text("Down the line").tag(CameraView.downTheLine)
                            }
                            HStack {
                                Button("Mark Good Shot") { Task { await model.markGoodShot(swing.id) } }
                                    .disabled(swing.metadata.isGoodShot)
                                Spacer()
                                Button(model.currentID == swing.id ? "Selected" : "Select current") {
                                    model.currentID = swing.id
                                    model.clearComparison()
                                }.disabled(swing.metadata.isGoodShot)
                            }.buttonStyle(.bordered)
                        }.padding().background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }.disabled(model.busy)
                    Button("Compare swings") { model.compare() }.buttonStyle(.borderedProminent)
                        .disabled(model.busy || model.reference == nil || model.current == nil || model.reference?.id == model.currentID)
                    if let result = model.result, let reference = model.reference, let current = model.current {
                        Text("Major measured differences").font(.title2.bold())
                        if reference.metadata.isDemo || current.metadata.isDemo {
                            Text("Includes synthetic demo data.").foregroundStyle(.orange)
                        }
                        ForEach(result.differences.prefix(3)) { difference in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(difference.kind.title).bold()
                                Text(String(format: "Good Shot %.1f° → Current %.1f°", difference.reference, difference.current))
                                Text(feedback.feedback(for: difference)).font(.subheadline)
                            }
                        }
                        ForEach(result.notes, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) }
                        Text("Review sampled frames independently; sliders are not phase-aligned.").font(.caption)
                        PosePreviewView(swing: reference, store: model.store, color: .green).id(reference.id)
                        PosePreviewView(swing: current, store: model.store, color: .cyan).id(current.id)
                    }
                }.padding()
            }.navigationTitle("Swing Lab")
        }
        .task { await model.load() }
        .task(id: selection) {
            if let selection { await model.importMovie(selection) }
        }
        .alert("Swing Lab", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
            Button("OK") { model.error = nil }
        } message: { Text(model.error ?? "") }
    }
}
