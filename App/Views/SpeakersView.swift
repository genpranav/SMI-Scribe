import SwiftUI
import ScribeModels

/// Known people whose voiceprints are matched across meetings.
struct SpeakersView: View {
    @Environment(AppModel.self) private var model
    @State private var speakers: [Speaker] = []

    var body: some View {
        List(speakers) { speaker in
            HStack {
                Text(speaker.name)
                Spacer()
                Text(speaker.voiceprint == nil ? "Not enrolled" : "Enrolled")
                    .foregroundStyle(.secondary)
            }
        }
        // TODO: Enrol a speaker by naming a diarized cluster ("S2 is Priya") from a meeting.
        .overlay {
            if speakers.isEmpty {
                ContentUnavailableView("No known speakers", systemImage: "person.2")
            }
        }
        .task { speakers = (try? model.database?.speakers()) ?? [] }
    }
}
