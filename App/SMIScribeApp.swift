import SwiftUI

@main
struct SMIScribeApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .frame(minWidth: 900, minHeight: 560)
        }
        .commands {
            CommandMenu("Recording") {
                Button(model.isRecording ? "Stop Recording" : "Start Recording") { model.toggleRecording() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                // TODO: Register a global hotkey so highlights work while the meeting app is focused.
                Button("Mark Highlight") { model.markHighlight() }
                    .keyboardShortcut("h", modifiers: [.command, .shift])
                    .disabled(!model.isRecording)
            }
        }

        MenuBarExtra("SMI Scribe", systemImage: model.isRecording ? "record.circle.fill" : "waveform") {
            Button(model.isRecording ? "Stop Recording" : "Start Recording") { model.toggleRecording() }
            Button("Mark Highlight") { model.markHighlight() }
                .disabled(!model.isRecording)
            Divider()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
