import Foundation
import GRDB
import ScribeModels

extension Meeting: FetchableRecord, PersistableRecord {}
extension Speaker: FetchableRecord, PersistableRecord {}
extension Segment: FetchableRecord, PersistableRecord {}
extension Highlight: FetchableRecord, PersistableRecord {}
extension ActionItem: FetchableRecord, PersistableRecord {}

/// SQLite store for meetings, transcripts and speakers. Full-text search via FTS5.
public final class AppDatabase: Sendable {
    let writer: any DatabaseWriter

    public init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// The on-disk database in Application Support.
    public static func live() throws -> AppDatabase {
        let directory = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("SMIScribe", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return try AppDatabase(DatabasePool(path: directory.appendingPathComponent("scribe.sqlite").path))
    }

    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("v1") { db in
            try db.create(table: "meeting") { t in
                t.primaryKey("id", .blob)
                t.column("title", .text).notNull()
                t.column("startedAt", .datetime).notNull().indexed()
                t.column("endedAt", .datetime)
                t.column("audioFile", .text)
                t.column("summary", .text)
            }
            try db.create(table: "speaker") { t in
                t.primaryKey("id", .blob)
                t.column("name", .text).notNull()
                t.column("voiceprint", .text)  // JSON-encoded [Float]
            }
            try db.create(table: "segment") { t in
                t.primaryKey("id", .blob)
                t.column("meetingID", .blob).notNull().indexed().references("meeting", onDelete: .cascade)
                t.column("start", .double).notNull()
                t.column("end", .double).notNull()
                t.column("text", .text).notNull()
                t.column("speakerLabel", .text)
                t.column("speakerID", .blob).references("speaker", onDelete: .setNull)
            }
            try db.create(virtualTable: "segment_fts", using: FTS5()) { t in
                t.synchronize(withTable: "segment")
                t.tokenizer = .porter()
                t.column("text")
            }
            try db.create(table: "highlight") { t in
                t.primaryKey("id", .blob)
                t.column("meetingID", .blob).notNull().indexed().references("meeting", onDelete: .cascade)
                t.column("at", .double).notNull()
                t.column("text", .text).notNull()
                t.column("source", .text).notNull()
            }
            try db.create(table: "actionItem") { t in
                t.primaryKey("id", .blob)
                t.column("meetingID", .blob).notNull().indexed().references("meeting", onDelete: .cascade)
                t.column("text", .text).notNull()
                t.column("owner", .text)
                t.column("done", .boolean).notNull().defaults(to: false)
            }
        }
        return migrator
    }
}

// MARK: - Writes

extension AppDatabase {
    public func save(_ meeting: Meeting) throws {
        try writer.write { try meeting.save($0) }
    }

    public func save(_ speaker: Speaker) throws {
        try writer.write { try speaker.save($0) }
    }

    public func insert(_ segments: [Segment]) throws {
        try writer.write { db in
            for segment in segments { try segment.insert(db) }
        }
    }

    public func update(_ segments: [Segment]) throws {
        try writer.write { db in
            for segment in segments { try segment.update(db) }
        }
    }

    public func insert(_ highlight: Highlight) throws {
        try writer.write { try highlight.insert($0) }
    }

    /// Replaces the generated (non-manual) insights for a meeting.
    public func replaceInsights(meetingID: UUID, highlights: [Highlight], actionItems: [ActionItem]) throws {
        try writer.write { db in
            try Highlight
                .filter(Column("meetingID") == meetingID && Column("source") == Highlight.Source.generated.rawValue)
                .deleteAll(db)
            try ActionItem.filter(Column("meetingID") == meetingID).deleteAll(db)
            for highlight in highlights { try highlight.insert(db) }
            for item in actionItems { try item.insert(db) }
        }
    }
}

// MARK: - Reads

extension AppDatabase {
    public func meetings() throws -> [Meeting] {
        try writer.read { try Meeting.order(Column("startedAt").desc).fetchAll($0) }
    }

    public func speakers() throws -> [Speaker] {
        try writer.read { try Speaker.order(Column("name")).fetchAll($0) }
    }

    public func segments(meetingID: UUID) throws -> [Segment] {
        try writer.read { try Segment.filter(Column("meetingID") == meetingID).order(Column("start")).fetchAll($0) }
    }

    public func highlights(meetingID: UUID) throws -> [Highlight] {
        try writer.read { try Highlight.filter(Column("meetingID") == meetingID).order(Column("at")).fetchAll($0) }
    }

    public func actionItems(meetingID: UUID) throws -> [ActionItem] {
        try writer.read { try ActionItem.filter(Column("meetingID") == meetingID).fetchAll($0) }
    }

    /// Full-text search across all transcripts.
    public func search(_ query: String) throws -> [Segment] {
        guard let pattern = FTS5Pattern(matchingAllPrefixesIn: query) else { return [] }
        return try writer.read { db in
            try Segment.fetchAll(
                db,
                sql: """
                    SELECT segment.* FROM segment
                    JOIN segment_fts ON segment_fts.rowid = segment.rowid AND segment_fts MATCH ?
                    ORDER BY rank
                    """,
                arguments: [pattern])
        }
    }
}
