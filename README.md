# SMI Scribe

Local, private meeting transcription and intelligence for macOS. Records your mic and the meeting
app's audio, transcribes it live, works out who said what, and produces a summary, highlights and
action items. Everything runs on this Mac; no audio or text leaves the device.

## Stack

| Concern | Choice | Runs on |
|---|---|---|
| App | Swift 6, SwiftUI, macOS 14.4+ | |
| Mic capture | AVAudioEngine | |
| System audio | Core Audio process taps (no Screen Recording permission) | |
| Transcription | WhisperKit (Parakeet via FluidAudio as an alternative) | Neural Engine |
| Diarization and speaker recognition | FluidAudio (pyannote + WeSpeaker), voiceprint matching | Neural Engine |
| Summaries, highlights, action items | Apple Foundation Models on macOS 26+, else MLX (Qwen3 4B) | ANE / GPU |
| Storage and search | GRDB (SQLite + FTS5) | |

## Layout

```
App/                    SwiftUI app target (UI, AppModel wiring, MLX provider)
Packages/ScribeKit/     All app logic, as a Swift package
  ScribeModels          Meeting, Segment, Speaker, Highlight, ActionItem, AudioChunk
  AudioCapture          AudioSource protocol, mic, system-audio tap, mixer
  Transcription         TranscriptionEngine protocol, WhisperKit, Parakeet
  Diarization           DiarizationEngine protocol, FluidAudio, VoiceprintMatcher
  Intelligence          LLMProvider protocol, MeetingAnalyzer, Foundation Models provider
  Storage               AppDatabase (GRDB, migrations, FTS5)
  ScribeCore            MeetingSession pipeline, SpeakerAligner
project.yml             XcodeGen spec (the .xcodeproj is generated, not committed)
```

## Getting started

Requires full **Xcode** (for the app bundle, signing, and MLX's Metal shaders).

```sh
make bootstrap   # xcodegen, swiftlint
make open        # generate SMIScribe.xcodeproj and open it
make test        # ScribeKit tests (Command Line Tools are enough)
```

Models download on first use: WhisperKit and FluidAudio from Hugging Face, and the MLX model the
first time a summary runs on macOS < 26.

## Status

The pipeline is wired end to end and tested with fake engines. Still to do (marked `TODO` in code):
system-audio tap, FluidAudio diarizer and Parakeet calls, VAD gating, streaming audio to disk,
speaker enrolment, transcript search UI, global highlight hotkey.
