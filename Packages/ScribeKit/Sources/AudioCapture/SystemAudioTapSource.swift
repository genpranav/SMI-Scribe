import ScribeModels

/// Captures what the Mac is playing (the remote side of a Zoom/Meet/Teams call)
/// using a Core Audio process tap. Requires macOS 14.4+ and only the
/// "System Audio Recording" permission (NSAudioCaptureUsageDescription),
/// not Screen Recording.
public final class SystemAudioTapSource: AudioSource, @unchecked Sendable {
    public init() {}

    public func start() async throws -> AsyncStream<AudioChunk> {
        // TODO: Implement the process tap:
        //  1. CATapDescription(stereoGlobalTapButExcludeProcesses: [ownProcessObjectID])
        //  2. AudioHardwareCreateProcessTap(description, &tapID)
        //  3. Create a private aggregate device containing the tap
        //     (kAudioAggregateDeviceTapListKey) and AudioDeviceCreateIOProcIDWithBlock.
        //  4. Convert the IO buffers to 16 kHz mono and yield AudioChunk(origin: .system).
        //  5. Tear down in stop(): AudioDeviceStop, destroy IOProc, aggregate device, tap.
        throw AudioCaptureError.notImplemented("SystemAudioTapSource")
    }

    public func stop() async {}
}
