import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        NavigationSplitView {
            MeetingListView()
        } detail: {
            if model.isRecording || (!model.liveSegments.isEmpty && model.selectedMeetingID == nil) {
                RecordingView()
            } else if let id = model.selectedMeetingID {
                MeetingDetailView(meetingID: id)
                    .id(id)
            } else {
                ContentUnavailableView(
                    "No meeting selected", systemImage: "waveform",
                    description: Text("Press ⇧⌘R to start recording."))
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(model.isRecording ? "Stop" : "Record", systemImage: model.isRecording ? "stop.fill" : "record.circle") {
                    model.toggleRecording()
                }
                .tint(model.isRecording ? .red : nil)
            }
            ToolbarItem(placement: .status) {
                Text(model.status).foregroundStyle(.secondary)
            }
        }
    }
}
