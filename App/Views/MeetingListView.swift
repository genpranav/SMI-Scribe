import SwiftUI

struct MeetingListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List(model.meetings, selection: $model.selectedMeetingID) { meeting in
            VStack(alignment: .leading, spacing: 2) {
                Text(meeting.title).lineLimit(1)
                Text(meeting.startedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Meetings")
        // TODO: .searchable bound to AppDatabase.search(_:) for full-text transcript search.
    }
}
