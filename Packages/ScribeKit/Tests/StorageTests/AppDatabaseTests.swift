import Foundation
import ScribeModels
import Testing

@testable import Storage

@Test func savesMeetingAndSearchesTranscript() throws {
    let db = try AppDatabase.inMemory()
    let meeting = Meeting(title: "Planning")
    try db.save(meeting)
    try db.insert([
        Segment(meetingID: meeting.id, start: 0, end: 4, text: "Let's review the launch budget"),
        Segment(meetingID: meeting.id, start: 4, end: 8, text: "Hiring plan is on track"),
    ])

    #expect(try db.meetings().map(\.title) == ["Planning"])
    #expect(try db.search("budg").map(\.text) == ["Let's review the launch budget"])
}

@Test func voiceprintRoundTrips() throws {
    let db = try AppDatabase.inMemory()
    try db.save(Speaker(name: "Alice", voiceprint: [0.1, 0.2, 0.3]))
    #expect(try db.speakers().first?.voiceprint == [0.1, 0.2, 0.3])
}
