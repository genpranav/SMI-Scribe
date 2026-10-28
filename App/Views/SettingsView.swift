import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            Form {
                LabeledContent("Transcription", value: "WhisperKit (Neural Engine)")
                LabeledContent("Speakers", value: "FluidAudio (Neural Engine)")
                LabeledContent("Summaries", value: AppModel.makeLLMProvider().displayName)
                // TODO: Engine pickers, model download status (ModelManager), storage location.
            }
            .tabItem { Label("Models", systemImage: "cpu") }

            SpeakersView()
                .environment(model)
                .tabItem { Label("Speakers", systemImage: "person.2") }
        }
        .padding()
        .frame(width: 480, height: 320)
    }
}
