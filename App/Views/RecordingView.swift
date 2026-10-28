import SwiftUI
import ScribeModels

struct RecordingView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(model.liveSegments) { segment in
                    TranscriptRow(segment: segment)
                        .id(segment.id)
                }
            }
            .onChange(of: model.liveSegments.count) {
                if let last = model.liveSegments.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Label("\(model.liveHighlights.count) highlights", systemImage: "star")
                Spacer()
                Button("Mark Highlight", systemImage: "star.fill") { model.markHighlight() }
                    .disabled(!model.isRecording)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("Live transcript")
    }
}

struct TranscriptRow: View {
    let segment: Segment

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(Duration.seconds(segment.start).formatted(.time(pattern: .minuteSecond)))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            if let speaker = segment.speakerLabel {
                Text(speaker).font(.caption.bold())
            }
            Text(segment.text).textSelection(.enabled)
        }
    }
}
