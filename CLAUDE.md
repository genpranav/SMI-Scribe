# SMI Scribe

macOS meeting transcription app. All processing is on-device; never add code that sends audio,
transcripts or summaries off the machine. The only network use is model downloads.

- App logic lives in `Packages/ScribeKit`; `App/` is UI and wiring only.
- Each ML stage sits behind a protocol (`AudioSource`, `TranscriptionEngine`, `DiarizationEngine`,
  `LLMProvider`). Add new engines as new conformances; test the pipeline with fakes
  (see `Tests/ScribeCoreTests`).
- MLX stays in the app target, so `swift test` in `Packages/ScribeKit` works without Xcode.
- `SMIScribe.xcodeproj` is generated: edit `project.yml`, then `make gen`.
- Swift 6 language mode. Prefer actors for engines and sessions over `@unchecked Sendable`.

Commands: `make test`, `make build`, `make lint`, `make format`.
