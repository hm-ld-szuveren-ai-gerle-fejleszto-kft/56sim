//
//  StateStore.swift
//  56sim
//
//  The single archive of the People's Republic: every dossier, denunciation,
//  correction, broadcast, membership file, ministerial memo, and line of
//  history lives in one SQLite database. Nothing else is permitted to
//  remember anything.
//

import Foundation
import Observation
import SQLite

// MARK: - Value types of the People's Registry

/// Loyalty classification is kept in Citizen.swift; everything else is here.

/// A registered citizen of the republic. Paper, but honest paper.
struct Citizen: Identifiable, Equatable {
    let id: Int64
    var name: String
    var affiliation: String
    var status: CitizenStatus
    var dossierNote: String
    var addedAt: Date
    var trustFlux: Int
    var reportCount: Int

    init(
        id: Int64 = 0,
        name: String,
        affiliation: String,
        status: CitizenStatus = .surveilled,
        dossierNote: String = "",
        addedAt: Date = .now,
        trustFlux: Int = 0,
        reportCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.affiliation = affiliation
        self.status = status
        self.dossierNote = dossierNote
        self.addedAt = addedAt
        self.trustFlux = trustFlux
        self.reportCount = reportCount
    }
}

/// A denunciation filed by a vigilant neighbour. May target a registered
/// citizen (citizenId) or a name the Ministry has not yet dignified with a
/// dossier (targetName).
struct Report: Identifiable, Equatable {
    let id: Int64
    var citizenId: Int64?
    var targetName: String?
    var offence: String
    var offenceCategory: String
    var offenceSeverity: String
    var details: String
    var informantName: String
    var reportedAt: Date

    init(
        id: Int64 = 0,
        citizenId: Int64? = nil,
        targetName: String? = nil,
        offence: String = "",
        offenceCategory: String = "",
        offenceSeverity: String = "",
        details: String = "",
        informantName: String = "",
        reportedAt: Date = .now
    ) {
        self.id = id
        self.citizenId = citizenId
        self.targetName = targetName
        self.offence = offence
        self.offenceCategory = offenceCategory
        self.offenceSeverity = offenceSeverity
        self.details = details
        self.informantName = informantName
        self.reportedAt = reportedAt
    }
}

/// A retroactive correction of history, as ordered by the Ministry of Records.
struct RecordAmendment: Identifiable, Equatable {
    let id: Int64
    var citizenId: Int64?
    var fieldName: String
    var oldValue: String
    var newValue: String
    var justification: String
    var amendedAt: Date

    init(
        id: Int64 = 0,
        citizenId: Int64? = nil,
        fieldName: String = "",
        oldValue: String = "",
        newValue: String = "",
        justification: String = "",
        amendedAt: Date = .now
    ) {
        self.id = id
        self.citizenId = citizenId
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
        self.justification = justification
        self.amendedAt = amendedAt
    }
}

/// A directive of the Ministry of Truth.
struct Broadcast: Identifiable, Equatable {
    let id: Int64
    var title: String
    var body: String
    var postedAt: Date

    init(id: Int64 = 0, title: String, body: String, postedAt: Date = .now) {
        self.id = id
        self.title = title
        self.body = body
        self.postedAt = postedAt
    }
}

/// The comrade the player plays as. One per republic, seated at id 1.
struct ComradeProfile: Equatable {
    var fullName: String
    var alias: String
    var affiliation: String
    var classOrigin: String
    var district: String
    var membershipNumber: String
    var suspiciousTrait: String
    var assignedTraits: [String]
    var melody: String
    var yearsLabor: Int
    var createdAt: Date

    init(
        fullName: String,
        alias: String,
        affiliation: String,
        classOrigin: String,
        district: String,
        membershipNumber: String,
        suspiciousTrait: String,
        assignedTraits: [String],
        melody: String,
        yearsLabor: Int,
        createdAt: Date = .now
    ) {
        self.fullName = fullName
        self.alias = alias
        self.affiliation = affiliation
        self.classOrigin = classOrigin
        self.district = district
        self.membershipNumber = membershipNumber
        self.suspiciousTrait = suspiciousTrait
        self.assignedTraits = assignedTraits
        self.melody = melody
        self.yearsLabor = yearsLabor
        self.createdAt = createdAt
    }
}

/// The categories of history the Archive of the People recognises.
enum LogKind: String, CaseIterable {
    case citizen, report, amendment, broadcast, plan, simulator, player, defector, profile, system

    var label: String { rawValue }
}

/// One line of what actually happened. The Archive and the newspaper both
/// read these; neither may invent their own.
struct LogEvent: Identifiable, Equatable {
    let id: Int64
    let at: Date
    let kind: String
    let actor: String
    let subject: String
    let text: String
}

enum StateStoreError: Error, LocalizedError {
    case foreignFile

    var errorDescription: String? {
        "The file was foreign. No revisions made."
    }
}

/// The archive itself: one SQLite file, one connection, one truth.
@MainActor
@Observable
final class StateStore {
    static let shared = StateStore()

    /// Bumped by every mutation so views recompute. Views must read it.
    private(set) var revision: Int = 0

    private let dbURL: URL
    private var db: Connection

    /// Production location: Application Support/56sim/state.sqlite.
    private static func defaultDatabaseURL() -> URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("56sim", isDirectory: true)
        return base.appendingPathComponent("state.sqlite")
    }

    /// Test-only isolation: every unit test gets its own archive.
    init(url: URL) {
        dbURL = url
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        do {
            db = try Connection(.uri(url.path))
        } catch {
            db = try! Connection()  // unreachable: parent directory exists
        }
        try? createTables()
    }

    convenience init() {
        self.init(url: StateStore.defaultDatabaseURL())
    }

    // MARK: - Schema

    private func createTables() throws {
        try db.execute("""
            CREATE TABLE IF NOT EXISTS citizens(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                affiliation TEXT NOT NULL,
                status TEXT NOT NULL,
                dossierNote TEXT NOT NULL,
                addedAt REAL NOT NULL,
                trustFlux INTEGER NOT NULL DEFAULT 0);
            CREATE TABLE IF NOT EXISTS reports(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                citizenId INTEGER NULL,
                targetName TEXT NULL,
                offence TEXT NOT NULL,
                offenceCategory TEXT NOT NULL,
                offenceSeverity TEXT NOT NULL,
                details TEXT NOT NULL,
                informantName TEXT NOT NULL,
                reportedAt REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS amendments(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                citizenId INTEGER NULL,
                fieldName TEXT NOT NULL,
                oldValue TEXT NOT NULL,
                newValue TEXT NOT NULL,
                justification TEXT NOT NULL,
                amendedAt REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS broadcasts(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                postedAt REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS profile(
                id INTEGER PRIMARY KEY CHECK(id = 1),
                fullName TEXT NOT NULL,
                alias TEXT NOT NULL,
                affiliation TEXT NOT NULL,
                classOrigin TEXT NOT NULL,
                district TEXT NOT NULL,
                membershipNumber TEXT NOT NULL,
                suspiciousTrait TEXT NOT NULL,
                assignedTraits TEXT NOT NULL,
                melody TEXT NOT NULL,
                yearsLabor INTEGER NOT NULL,
                createdAt REAL NOT NULL);
            CREATE TABLE IF NOT EXISTS kv(
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS events(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                at REAL NOT NULL,
                kind TEXT NOT NULL,
                actor TEXT NOT NULL,
                subject TEXT NOT NULL,
                text TEXT NOT NULL);
            """)
    }

    // MARK: - Row readers

    func citizens() -> [Citizen] {
        let sql = """
            SELECT c.id, c.name, c.affiliation, c.status, c.dossierNote, c.addedAt, c.trustFlux,
                   COUNT(r.id)
            FROM citizens c LEFT JOIN reports r ON r.citizenId = c.id
            GROUP BY c.id ORDER BY c.addedAt DESC;
            """
        guard let rows = try? db.prepare(sql) else { return [] }
        return rows.map { row in
            Citizen(
                id: int64(row, 0),
                name: text(row, 1),
                affiliation: text(row, 2),
                status: CitizenStatus(rawValue: text(row, 3)) ?? .surveilled,
                dossierNote: text(row, 4),
                addedAt: Date(timeIntervalSince1970: double(row, 5)),
                trustFlux: Int(int64(row, 6)),
                reportCount: Int(int64(row, 7))
            )
        }
    }

    func citizen(id: Int64) -> Citizen? {
        citizens().first { $0.id == id }
    }

    func reports() -> [Report] {
        guard let rows = try? db.prepare(
            "SELECT id, citizenId, targetName, offence, offenceCategory, offenceSeverity, details, informantName, reportedAt FROM reports ORDER BY reportedAt DESC;"
        ) else { return [] }
        return rows.map { row in
            Report(
                id: int64(row, 0),
                citizenId: optionalInt64(row, 1),
                targetName: optionalText(row, 2),
                offence: text(row, 3),
                offenceCategory: text(row, 4),
                offenceSeverity: text(row, 5),
                details: text(row, 6),
                informantName: text(row, 7),
                reportedAt: Date(timeIntervalSince1970: double(row, 8))
            )
        }
    }

    /// Oldest first, so rotation indexes read like a ledger.
    func amendments(citizenId: Int64) -> [RecordAmendment] {
        guard let rows = try? db.prepare(
            "SELECT id, citizenId, fieldName, oldValue, newValue, justification, amendedAt FROM amendments WHERE citizenId = ? ORDER BY amendedAt ASC, id ASC;",
            citizenId
        ) else { return [] }
        return rows.map { row in
            RecordAmendment(
                id: int64(row, 0),
                citizenId: optionalInt64(row, 1),
                fieldName: text(row, 2),
                oldValue: text(row, 3),
                newValue: text(row, 4),
                justification: text(row, 5),
                amendedAt: Date(timeIntervalSince1970: double(row, 6)),
            )
        }
    }

    func broadcasts() -> [Broadcast] {
        guard let rows = try? db.prepare(
            "SELECT id, title, body, postedAt FROM broadcasts ORDER BY postedAt DESC;"
        ) else { return [] }
        return rows.map { row in
            Broadcast(
                id: int64(row, 0),
                title: text(row, 1),
                body: text(row, 2),
                postedAt: Date(timeIntervalSince1970: double(row, 3))
            )
        }
    }

    // MARK: - Mutations

    @discardableResult
    func addCitizen(name: String, affiliation: String, dossierNote: String) -> Int64 {
        try? db.run(
            "INSERT INTO citizens(name, affiliation, status, dossierNote, addedAt, trustFlux) VALUES (?, ?, ?, ?, ?, ?)",
            name, affiliation, CitizenStatus.surveilled.rawValue, dossierNote,
            Date.now.timeIntervalSince1970, 0)
        bump()
        return db.lastInsertRowid
    }

    /// Burial with honours: reports and amendments are buried alongside.
    func deleteCitizens(ids: [Int64]) {
        guard !ids.isEmpty else { return }
        let placeholders = repeatElement("?", count: ids.count).joined(separator: ", ")
        try? db.run(
            "DELETE FROM citizens WHERE id IN (\(placeholders))", ids.map { $0 as Binding? })
        try? db.run(
            "DELETE FROM reports WHERE citizenId IN (\(placeholders))",
            ids.map { $0 as Binding? })
        try? db.run(
            "DELETE FROM amendments WHERE citizenId IN (\(placeholders))",
            ids.map { $0 as Binding? })
        bump()
    }

    func addReport(
        citizenId: Int64?, targetName: String?, offence: String, category: String,
        severity: String, details: String, informantName: String
    ) {
        try? db.run(
            "INSERT INTO reports(citizenId, targetName, offence, offenceCategory, offenceSeverity, details, informantName, reportedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            citizenId, targetName, offence, category, severity, details, informantName,
            Date.now.timeIntervalSince1970)
        bump()
    }

    func addAmendment(
        citizenId: Int64?, fieldName: String, oldValue: String, newValue: String,
        justification: String
    ) {
        try? db.run(
            "INSERT INTO amendments(citizenId, fieldName, oldValue, newValue, justification, amendedAt) VALUES (?, ?, ?, ?, ?, ?)",
            citizenId, fieldName, oldValue, newValue, justification,
            Date.now.timeIntervalSince1970)
        bump()
    }

    /// Full-row update of a citizen, as befits a complete rewrite.
    func setCitizen(_ citizen: Citizen) {
        try? db.run(
            "UPDATE citizens SET name = ?, affiliation = ?, status = ?, dossierNote = ?, addedAt = ?, trustFlux = ? WHERE id = ?",
            citizen.name, citizen.affiliation, citizen.status.rawValue, citizen.dossierNote,
            citizen.addedAt.timeIntervalSince1970, citizen.trustFlux, citizen.id)
        bump()
    }

    @discardableResult
    func addBroadcast(title: String, body: String) -> Int64 {
        try? db.run(
            "INSERT INTO broadcasts(title, body, postedAt) VALUES (?, ?, ?)",
            title, body, Date.now.timeIntervalSince1970)
        bump()
        return db.lastInsertRowid
    }

    func deleteBroadcasts(ids: [Int64]) {
        guard !ids.isEmpty else { return }
        let placeholders = repeatElement("?", count: ids.count).joined(separator: ", ")
        try? db.run("DELETE FROM broadcasts WHERE id IN (\(placeholders))", ids.map { $0 as Binding? })
        bump()
    }

    // MARK: - The comrade

    func profile() -> ComradeProfile? {
        guard let statement = try? db.prepare(
            "SELECT fullName, alias, affiliation, classOrigin, district, membershipNumber, suspiciousTrait, assignedTraits, melody, yearsLabor, createdAt FROM profile WHERE id = 1;"
        ) else { return nil }
        guard let row = statement.next() else { return nil }
        let traits =
            (try? JSONDecoder().decode([String].self, from: Data(text(row, 7).utf8))) ?? []
        return ComradeProfile(
            fullName: text(row, 0),
            alias: text(row, 1),
            affiliation: text(row, 2),
            classOrigin: text(row, 3),
            district: text(row, 4),
            membershipNumber: text(row, 5),
            suspiciousTrait: text(row, 6),
            assignedTraits: traits,
            melody: text(row, 8),
            yearsLabor: Int(int64(row, 9)),
            createdAt: Date(timeIntervalSince1970: double(row, 10))
        )
    }

    func saveProfile(_ profile: ComradeProfile) {
        let traits =
            (try? String(
                data: JSONEncoder().encode(profile.assignedTraits), encoding: .utf8)) ?? "[]"
        try? db.run(
            "INSERT OR REPLACE INTO profile(id, fullName, alias, affiliation, classOrigin, district, membershipNumber, suspiciousTrait, assignedTraits, melody, yearsLabor, createdAt) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            profile.fullName, profile.alias, profile.affiliation, profile.classOrigin,
            profile.district, profile.membershipNumber, profile.suspiciousTrait, traits,
            profile.melody, Int64(profile.yearsLabor), profile.createdAt.timeIntervalSince1970)
        bump()
    }

    // MARK: - Ministerial memos

    func kvString(_ key: String) -> String? {
        (try? db.scalar("SELECT value FROM kv WHERE key = ?;", key)) as? String
    }

    func setKV(_ key: String, value: String) {
        try? db.run("INSERT OR REPLACE INTO kv(key, value) VALUES (?, ?)", key, value)
        bump()
    }

    // MARK: - The record of everything

    /// One line of history, trimmed to the newest 500 rows.
    func log(
        kind: LogKind, actor: String, subject: String, text: String, at: Date = .now
    ) {
        try? db.run(
            "INSERT INTO events(at, kind, actor, subject, text) VALUES (?, ?, ?, ?, ?)",
            at.timeIntervalSince1970, kind.rawValue, actor, subject, text)
        try? db.run(
            "DELETE FROM events WHERE id NOT IN (SELECT id FROM events ORDER BY at DESC LIMIT 500)"
        )
        bump()
    }

    /// Newest first; views sort and filter themselves.
    func events() -> [LogEvent] {
        guard let rows = try? db.prepare(
            "SELECT id, at, kind, actor, subject, text FROM events ORDER BY at DESC, id DESC;"
        ) else { return [] }
        return rows.map { row in
            LogEvent(
                id: int64(row, 0),
                at: Date(timeIntervalSince1970: double(row, 1)),
                kind: text(row, 2),
                actor: text(row, 3),
                subject: text(row, 4),
                text: text(row, 5)
            )
        }
    }

    // MARK: - Wipe, export, import

    /// Everything back to the profile wizard. The file stays so imports
    /// still have somewhere to live.
    func wipeAll() {
        for table in ["citizens", "reports", "amendments", "broadcasts", "profile", "kv", "events"] {
            try? db.run("DELETE FROM \(table)")
        }
        bump()
    }

    /// A consistent snapshot of the republic for foreign eyes, via the
    /// SQLite online-backup API (no vacuum in 0.16.0).
    func exportFileURL() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destination = directory.appendingPathComponent(
            "peoples-republic-\(formatter.string(from: .now)).avh")
        let target = try Connection(.uri(destination.path))
        let backup = try db.backup(usingConnection: target)
        try backup.step(pagesToCopy: .all)
        log(
            kind: .system, actor: "The State", subject: "republic",
            text: "The republic printed itself for foreign eyes.")
        return destination
    }

    /// Absorbs a foreign republic: the file must open as SQLite and carry
    /// the profile and citizens tables, or nothing changes.
    func importReplace(from url: URL) throws {
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        do {
            try FileManager.default.copyItem(at: url, to: staging)
        } catch {
            throw StateStoreError.foreignFile
        }
        do {
            let probe = try Connection(.uri(staging.path), readonly: true)
            let tables =
                (try probe.scalar(
                    "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name IN ('profile', 'citizens');"
                ) as? Int64) ?? 0
            guard tables == 2 else { throw StateStoreError.foreignFile }
        } catch {
            try? FileManager.default.removeItem(at: staging)
            throw StateStoreError.foreignFile
        }
        // Release the current archive, bury it, and let the foreign one speak.
        db = try! Connection()
        for suffix in ["", "-wal", "-shm"] {
            try? FileManager.default.removeItem(
                at: URL(string: dbURL.absoluteString + suffix)!)
        }
        do {
            try FileManager.default.moveItem(at: staging, to: dbURL)
        } catch {
            try? FileManager.default.removeItem(at: staging)
        }
        db = try Connection(.uri(dbURL.path))
        try createTables()
        bump()
        log(
            kind: .system, actor: "The State", subject: "republic",
            text: "A foreign republic was absorbed. Its history stands revised.")
    }

    // MARK: - Bindings of the people

    private func bump() { revision += 1 }

    private func text(_ row: [Binding?], _ index: Int) -> String {
        switch row[index] {
        case let value as String: return value
        case let value as Int64: return String(value)
        case let value as Int: return String(value)
        case let value as Double: return String(value)
        default: return ""
        }
    }

    private func optionalText(_ row: [Binding?], _ index: Int) -> String? {
        row[index] as? String
    }

    private func int64(_ row: [Binding?], _ index: Int) -> Int64 {
        switch row[index] {
        case let value as Int64: return value
        case let value as Int: return Int64(value)
        case let value as Double: return Int64(value)
        case let value as String: return Int64(value) ?? 0
        default: return 0
        }
    }

    private func optionalInt64(_ row: [Binding?], _ index: Int) -> Int64? {
        switch row[index] {
        case .none: return nil
        case let value as Int64: return value
        case let value as Int: return Int64(value)
        default: return nil
        }
    }

    private func double(_ row: [Binding?], _ index: Int) -> Double {
        switch row[index] {
        case let value as Double: return value
        case let value as Int64: return Double(value)
        case let value as Int: return Double(value)
        default: return 0
        }
    }
}
