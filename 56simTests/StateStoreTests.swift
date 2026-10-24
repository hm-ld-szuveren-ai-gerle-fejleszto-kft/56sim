//
//  StateStoreTests.swift
//  56simTests
//
//  Verification that the People's Registry stores the truth it claims to
//  store — in SQLite, the only paper that does not burn.
//

import Foundation
import Testing

@testable import _6sim

@MainActor
struct StateStoreTests {
    /// Every test interrogates its own archive, isolated on disk.
    private func makeStore() -> StateStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("56sim-tests-\(UUID().uuidString)", isDirectory: true)
        return StateStore(url: directory.appendingPathComponent("state.sqlite"))
    }

    private func sampleProfile() -> ComradeProfile {
        ComradeProfile(
            fullName: "Szabó Ferenc",
            alias: "Whisper",
            affiliation: "Factory #7",
            classOrigin: "Worker",
            district: "District VII, Cukor utca 3",
            membershipNumber: "Number 4711-bis, issued in someone else's name",
            suspiciousTrait: "Hums melodies absent from the approved songbook",
            assignedTraits: Array(Profile.suspiciousTraitPool.prefix(4)),
            melody: "Ode to the Tractor",
            yearsLabor: 22
        )
    }

    // MARK: - Citizens

    @Test("A newly registered citizen starts under surveillance with an empty file")
    func newCitizenDefaultsToSurveilled() {
        let store = makeStore()
        store.addCitizen(name: "Kovács Gyula", affiliation: "Factory worker", dossierNote: "")
        let fetched = store.citizens()
        #expect(fetched.count == 1)
        #expect(fetched.first?.status == .surveilled)
        #expect(fetched.first?.dossierNote.isEmpty == true)
        #expect(fetched.first?.trustFlux == 0)
    }

    @Test("A citizen round-trips every field, report count included")
    func citizenRoundTripWithReportCount() {
        let store = makeStore()
        let id = store.addCitizen(
            name: "Nagy Éva", affiliation: "University student",
            dossierNote: "Seen smiling on a Tuesday.")
        for _ in 0..<3 {
            store.addReport(
                citizenId: id, targetName: "Nagy Éva", offence: "Suspicious silence",
                category: "verbal", severity: "watchlist",
                details: "Said nothing, three days running.", informantName: "Szabó Istvánné")
        }
        store.addReport(
            citizenId: nil, targetName: "Whisper", offence: "Hoarding Western jokes",
            category: "verbal", severity: "reeducation",
            details: "Told one at the canteen.", informantName: "The night porter")

        let fetched = store.citizens().first { $0.id == id }
        #expect(fetched?.name == "Nagy Éva")
        #expect(fetched?.affiliation == "University student")
        #expect(fetched?.dossierNote == "Seen smiling on a Tuesday.")
        #expect(fetched?.reportCount == 3, "only her own reports count")

        store.deleteCitizens(ids: [id])
        #expect(store.citizens().isEmpty)
    }

    @Test("Burial is thorough: deleting a citizen buries reports and amendments")
    func cascadeDeleteRemovesReportsAndAmendments() {
        let store = makeStore()
        let id = store.addCitizen(name: "Kiss Ferenc", affiliation: "Tailor", dossierNote: "")
        store.addReport(
            citizenId: id, targetName: "Kiss Ferenc", offence: "Other",
            category: "paperwork", severity: "watchlist",
            details: "Buttons polished out of turn.", informantName: "Comrade Operator")
        RecordOffice.amend(
            citizenId: id, field: "status",
            old: CitizenStatus.surveilled.propagandaLabel,
            new: CitizenStatus.cleared.propagandaLabel, store: store)
        #expect(store.reports().count == 1)
        #expect(store.amendments(citizenId: id).count == 1)

        store.deleteCitizens(ids: [id])

        #expect(store.citizens().isEmpty)
        #expect(store.reports().isEmpty)
        #expect(store.amendments(citizenId: id).isEmpty)
    }

    // MARK: - Broadcasts

    @Test("Broadcast round-trips title and body")
    func broadcastRoundTrip() {
        let store = makeStore()
        store.addBroadcast(
            title: "Glory to the five-year plan",
            body: "Production targets have been met in advance. Gratitude is mandatory.")
        let fetched = store.broadcasts()
        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Glory to the five-year plan")
        #expect(
            fetched.first?.body
                == "Production targets have been met in advance. Gratitude is mandatory.")
        store.deleteBroadcasts(ids: fetched.map(\.id))
        #expect(store.broadcasts().isEmpty)
    }

    // MARK: - Records

    @Test("Amendments rotate justifications by count modulo the stock")
    func amendmentRotation() {
        let store = makeStore()
        let id = store.addCitizen(name: "Varga István", affiliation: "Driver", dossierNote: "")
        RecordOffice.amend(
            citizenId: id, field: "status",
            old: CitizenStatus.surveilled.propagandaLabel,
            new: CitizenStatus.cleared.propagandaLabel, store: store)
        RecordOffice.amend(
            citizenId: id, field: "status",
            old: CitizenStatus.cleared.propagandaLabel,
            new: CitizenStatus.neutralized.propagandaLabel, store: store)
        for index in 2..<7 {
            let next = CitizenStatus.allCases[index % 3]
            RecordOffice.amend(
                citizenId: id, field: "status",
                old: store.citizen(id: id)?.status.propagandaLabel ?? "",
                new: next.propagandaLabel, store: store)
        }
        let amendments = store.amendments(citizenId: id)
        #expect(amendments.count == 7)
        for index in 0..<7 {
            #expect(
                amendments[index].justification
                    == RecordOffice.justifications[index % RecordOffice.justifications.count])
        }
    }

    @Test("A no-op reclassification is not history")
    func amendNoOpIsSkipped() {
        let store = makeStore()
        let id = store.addCitizen(name: "Tóth Mari", affiliation: "Bookbinder", dossierNote: "")
        RecordOffice.amend(
            citizenId: id, field: "status",
            old: CitizenStatus.surveilled.propagandaLabel,
            new: CitizenStatus.surveilled.propagandaLabel, store: store)
        #expect(store.amendments(citizenId: id).isEmpty)
    }

    // MARK: - Wipe

    @Test("wipeAll() empties every table, profile and record included")
    func wipeAllEmptiesEverything() {
        let store = makeStore()
        store.addCitizen(name: "Németh Lászlóné", affiliation: "Librarian", dossierNote: "")
        store.addReport(
            citizenId: nil, targetName: "Németh Lászlóné", offence: "Other",
            category: "paperwork", severity: "watchlist",
            details: "Shelves alphabetised by suspicion.", informantName: "Foreman úr")
        store.addBroadcast(title: "Order", body: "Be order.")
        store.setKV("mood", value: "triumphant")
        store.log(kind: .system, actor: "The State", subject: "republic", text: "A line of history.")
        store.saveProfile(sampleProfile())
        #expect(store.profile() != nil)

        store.wipeAll()

        #expect(store.citizens().isEmpty)
        #expect(store.reports().isEmpty)
        #expect(store.broadcasts().isEmpty)
        #expect(store.profile() == nil)
        #expect(store.kvString("mood") == nil)
        #expect(store.events().isEmpty)
    }

    // MARK: - The record of everything

    @Test("Logged events return newest first")
    func logEventsNewestFirst() {
        let store = makeStore()
        let base = Date(timeIntervalSince1970: 1_000_000)
        store.log(kind: .citizen, actor: "Registry", subject: "A", text: "First.", at: base)
        store.log(kind: .report, actor: "Informant", subject: "B", text: "Second.", at: base.addingTimeInterval(60))
        store.log(kind: .broadcast, actor: "Ministry", subject: "C", text: "Third.", at: base.addingTimeInterval(120))
        let events = store.events()
        #expect(events.map(\.text) == ["Third.", "Second.", "First."])
        #expect(events.map(\.kind) == ["broadcast", "report", "citizen"])
    }

    @Test("The record keeps exactly the newest 500 rows")
    func logTrimKeeps500() {
        let store = makeStore()
        let base = Date(timeIntervalSince1970: 2_000_000)
        for index in 0..<501 {
            store.log(
                kind: .simulator, actor: "The republic", subject: "nobody",
                text: "Event \(index).", at: base.addingTimeInterval(Double(index)))
        }
        let events = store.events()
        #expect(events.count == 500)
        #expect(events.first?.text == "Event 500.")
        #expect(!events.contains { $0.text == "Event 0." })
    }

    @Test("Archive filters: kind and search compose")
    func archiveFilterComposes() {
        let base = Date(timeIntervalSince1970: 3_000_000)
        let events = [
            LogEvent(id: 1, at: base, kind: "report", actor: "Szabó Istvánné", subject: "Kiss Ferenc", text: "Szabó Istvánné denounced Kiss Ferenc: Other."),
            LogEvent(id: 2, at: base, kind: "report", actor: "Foreman úr", subject: "Nagy Éva", text: "A cabbage was missed."),
            LogEvent(id: 3, at: base, kind: "citizen", actor: "Szabó Istvánné", subject: "Varga", text: "Dossier opened on Varga."),
        ]
        #expect(ArchiveModel.filter(events: events, kind: .report, search: "").map(\.id) == [1, 2])
        #expect(ArchiveModel.filter(events: events, kind: .report, search: "cabbage").map(\.id) == [2])
        #expect(ArchiveModel.filter(events: events, kind: nil, search: "szabó").map(\.id) == [1, 3], "search hits actor too")
        #expect(ArchiveModel.filter(events: events, kind: nil, search: "varga").map(\.id) == [3], "search hits subject too")
        #expect(ArchiveModel.filter(events: events, kind: .citizen, search: "szabó").map(\.id) == [3], "kind and search compose")
        #expect(ArchiveModel.filter(events: events, kind: .plan, search: "").isEmpty)
    }

    // MARK: - The unclamped figure and the fate of the comrade

    @Test("raw() despairs below zero and boasts above a hundred; score() stays clamped")
    func rawIsUnclamped() {
        let doomed = Citizen(
            name: "Doomed Dénes", affiliation: "Lumpenproletariat", reportCount: 20)
        #expect(TrustScore.raw(for: doomed) == -200, "the archive keeps no floor for the hopeless")
        #expect(TrustEnforcement.score(for: doomed) == 0, "the display keeps its floor")

        let favourite = Citizen(name: "Pet Pál", affiliation: "Factory #7", trustFlux: 40)
        #expect(TrustScore.raw(for: favourite) == 140)
        #expect(TrustEnforcement.score(for: favourite) == 100, "and its ceiling")
    }

    @Test("Denunciations count against the alias only; playerFlux moves the figure")
    func reportsAgainstPlayerCountsAlias() {
        let store = makeStore()
        #expect(TrustScore.reportsAgainstPlayer(store: store) == 0, "nobody to denounce yet")
        #expect(TrustScore.playerRaw(store: store) == nil, "no file, no figure")

        store.saveProfile(sampleProfile())
        #expect(TrustScore.playerRaw(store: store) == 100)
        store.addReport(
            citizenId: nil, targetName: "Whisper", offence: "Suspicious silence",
            category: "verbal", severity: "watchlist",
            details: "Quiet at the checkpoint.", informantName: "The night porter")
        store.addReport(
            citizenId: nil, targetName: "Somebody Else", offence: "Suspicious silence",
            category: "verbal", severity: "watchlist",
            details: "Someone else's problem.", informantName: "The baker's apprentice")
        #expect(
            TrustScore.reportsAgainstPlayer(store: store) == 1,
            "only the alias counts as you")

        store.setKV("playerFlux", value: "-25")
        #expect(TrustScore.playerRaw(store: store) == 60, "100 − 15 + the ministerial flux")
    }

    @Test("Seven denunciations close the comrade's file, once and forever")
    func playerFateClosesFile() {
        let store = makeStore()
        store.saveProfile(sampleProfile())
        for _ in 0..<7 {
            store.addReport(
                citizenId: nil, targetName: "Whisper", offence: "Hoarding Western jokes",
                category: "verbal", severity: "reeducation",
                details: "Seven tellings of the same joke.", informantName: "The night porter")
        }
        #expect(TrustScore.playerRaw(store: store) == -5)
        #expect(PlayerFate.evaluate(store: store))
        #expect(store.kvString("player_fate") == "neutralized")
        let rows = store.events().filter { $0.kind == LogKind.player.rawValue }
        #expect(rows.count == 1)
        #expect(rows.first?.actor == "The Ministry of Love")
        #expect(rows.first?.subject == "Whisper")
        #expect(rows.first?.text == "Your file was closed. You loved Big Brother.")

        #expect(!PlayerFate.evaluate(store: store), "the record never repeats a death sentence")
        #expect(store.events().filter { $0.kind == LogKind.player.rawValue }.count == 1)
    }

    @Test("Six denunciations leave the comrade alive and the memo blank")
    func playerFateSparesAtTen() {
        let store = makeStore()
        store.saveProfile(sampleProfile())
        for _ in 0..<6 {
            store.addReport(
                citizenId: nil, targetName: "Whisper", offence: "Hoarding Western jokes",
                category: "verbal", severity: "reeducation",
                details: "Six tellings. The seventh is under investigation.",
                informantName: "The night porter")
        }
        #expect(TrustScore.playerRaw(store: store) == 10)
        #expect(!PlayerFate.evaluate(store: store))
        #expect(store.kvString("player_fate") == nil, "no sentence, no seal")
        #expect(store.events().filter { $0.kind == LogKind.player.rawValue }.isEmpty)
    }

    @Test("Without a comrade there is no fate to evaluate")
    func playerFateNeedsProfile() {
        let store = makeStore()
        #expect(!PlayerFate.evaluate(store: store), "the Ministry declines to close an empty drawer")
        #expect(store.kvString("player_fate") == nil)
    }

    // MARK: - Export & import

    @Test("Export/import round-trip restores citizens, reports, and the comrade")
    func exportImportRoundTrip() throws {
        let store = makeStore()
        let id = store.addCitizen(name: "Kovács Gyula", affiliation: "Factory #7", dossierNote: "Smiled.")
        store.addCitizen(name: "Nagy Éva", affiliation: "Student", dossierNote: "")
        store.addReport(
            citizenId: id, targetName: "Kovács Gyula", offence: "Suspicious silence",
            category: "verbal", severity: "watchlist",
            details: "Quiet as a subversion manual.", informantName: "Szabó Istvánné")
        let profile = sampleProfile()
        store.saveProfile(profile)

        let url = try store.exportFileURL()
        #expect(url.lastPathComponent.hasPrefix("peoples-republic-"))
        #expect(url.lastPathComponent.hasSuffix(".avh"))

        store.wipeAll()
        #expect(store.citizens().isEmpty)
        #expect(store.profile() == nil)

        try store.importReplace(from: url)

        let restored = store.citizens()
        #expect(restored.count == 2)
        #expect(restored.first { $0.name == "Kovács Gyula" }?.reportCount == 1)
        let restoredProfile = store.profile()
        #expect(
            restoredProfile?.fullName == profile.fullName
                && restoredProfile?.alias == profile.alias
                && restoredProfile?.affiliation == profile.affiliation
                && restoredProfile?.classOrigin == profile.classOrigin
                && restoredProfile?.district == profile.district
                && restoredProfile?.membershipNumber == profile.membershipNumber
                && restoredProfile?.suspiciousTrait == profile.suspiciousTrait
                && restoredProfile?.assignedTraits == profile.assignedTraits
                && restoredProfile?.melody == profile.melody
                && restoredProfile?.yearsLabor == profile.yearsLabor
                && abs((restoredProfile?.createdAt.timeIntervalSince1970 ?? -1)
                    - profile.createdAt.timeIntervalSince1970) < 0.001)
        #expect(
            store.events().first?.text
                == "A foreign republic was absorbed. Its history stands revised.")
    }

    @Test("A foreign file is refused and changes nothing")
    func importRefusesJunk() throws {
        let store = makeStore()
        store.addCitizen(name: "Szilvási Béla", affiliation: "Stationmaster", dossierNote: "")
        let before = store.citizens()

        let junk = FileManager.default.temporaryDirectory
            .appendingPathComponent("foreign-\(UUID().uuidString)")
            .appendingPathExtension("avh")
        try "This is not a database. This is a shopping list.".write(
            to: junk, atomically: true, encoding: .utf8)

        #expect(throws: (any Error).self) {
            try store.importReplace(from: junk)
        }
        #expect(store.citizens() == before)
    }

    // MARK: - Interrogator (opt-in)

    /// Opt-in: run on device (or simulator with 56SIM_ALLOW_SIMULATOR_LLM=YES) with
    /// `LLM_INTEGRATION=YES xcodebuild test ...` — downloads the 628 MB interrogator.
    @Test(
        "The interrogator answers (opt-in: LLM_INTEGRATION=YES)",
        .enabled(if: ProcessInfo.processInfo.environment["LLM_INTEGRATION"] == "YES"))
    func interrogatorModelResponds() async throws {
        let engine = InterrogationEngine()
        try await engine.load()
        let history = Interrogation.messages(
            history: [InterrogationMessage(role: .user, content: "I deny everything.")],
            questionCount: 0
        )
        var text = ""
        for try await chunk in try await engine.ask(history) {
            text += chunk
        }
        #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}
