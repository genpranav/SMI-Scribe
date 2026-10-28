import SwiftUI
import ScribeModels

struct MeetingDetailView: View {
    @Environment(AppModel.self) private var model
    let meetingID: Meeting.ID

    @State private var segments: [Segment] = []
    @State private var highlights: [Highlight] = []
    @State private var actionItems: [ActionItem] = []

    private var meeting: Meeting? { model.meetings.first { $0.id == meetingID } }

    var body: some View {
        List {
            if let summary = meeting?.summary {
                Section("Summary") { Text(summary).textSelection(.enabled) }
            }
            if !highlights.isEmpty {
                Section("Highlights") {
                    ForEach(highlights) { highlight in
                        Label(highlight.text.isEmpty ? "Marked moment" : highlight.text, systemImage: "star")
                    }
                }
            }
            if !actionItems.isEmpty {
                Section("Action items") {
                    ForEach(actionItems) { item in
                        Label(item.owner.map { "\(item.text) — \($0)" } ?? item.text, systemImage: "checkmark.circle")
                    }
                }
            }
            Section("Transcript") {
                ForEach(segments) { TranscriptRow(segment: $0) }
            }
        }
        .navigationTitle(meeting?.title ?? "Meeting")
        .task { load() }
    }

    private func load() {
        guard let database = model.database else { return }
        segments = (try? database.segments(meetingID: meetingID)) ?? []
        highlights = (try? database.highlights(meetingID: meetingID)) ?? []
        actionItems = (try? database.actionItems(meetingID: meetingID)) ?? []
    }
}
