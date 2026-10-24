//
//  PeopleSimulatorTests.swift
//  56simTests
//
//  The republic must tick deterministically: every weighted branch of the
//  PeopleSimulator is fired with scripted entropy and audited against the
//  archive. (The state does not accept flaky history.)
//

import Foundation
import Testing

@testable import _6sim

private func makeSimulatorStore() -> StateStore {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("56sim-sim-\(UUID().uuidString)", isDirectory: true)
    return StateStore(url: directory.appendingPathComponent("state.sqlite"))
}

/// Scripted entropy: drains the queue in order, then repeats `fallback`.
private final class RandBox {
    private var values: [Double]
    private let fallback: Double

    init(values: [Double], fallback: Double = 0) {
        self.values = values
        self.fallback = fallback
    }

    func next() -> Double {
        guard !values.isEmpty else { return fallback }
        return values.removeFirst()
    }
}

private func scriptedRand(_ values: [Double], fallback: Double = 0) -> () -> Double {
    let box = RandBox(values: values, fallback: fallback)
    return { box.next() }
}

/// A fixed past so tick arithmetic is exact.
private let t0 = Date(timeIntervalSince1970: 1_000_000)

@MainActor
struct PeopleSimulatorTests {
    private func seedProfile(_ store: StateStore, alias: String = "Sparrow") {
        store.saveProfile(
            ComradeProfile(
                fullName: "Kiss János", alias: alias, affiliation: "Factory #7",
                classOrigin: "Worker", district: "District VII, Cukor street 2",
                membershipNumber: "Number 1234-bis, issued in someone else's name",
                suspiciousTrait: "Owns two pairs of shoes", assignedTraits: [],
                melody: "Ode to the Tractor", yearsLabor: 5))
    }

    // MARK: - 0.35 — neighbour denounces neighbour

    @Test("NPC denounces NPC: report filed, trust falls, clearance overturned, never neutralized")
    func npcDenouncesNpc() {
        let store = makeSimulatorStore()
        seedProfile(store)
        // Added first ⇒ lands last in the newest-first registry list.
        let victimId = store.addCitizen(
            name: "Viktor Vulnerable", affiliation: "Railway Union", dossierNote: "")
        store.addCitizen(name: "Dorottya Diligent", affiliation: "Collective Farm No. 3", dossierNote: "")
        store.addCitizen(name: "Géza Garrulous", affiliation: "State Beekeeping Directorate", dossierNote: "")
        if var victim = store.citizen(id: victimId) {
            victim.status = .cleared
            store.setCitizen(victim)
        }
        for _ in 0..<4 {
            store.addReport(
                citizenId: victimId, targetName: "Viktor Vulnerable",
                offence: "Suspicious silence", category: "verbal", severity: "watchlist",
                details: "Quiet as a subversion manual.", informantName: "X")
        }
        let list = store.citizens()
        #expect(list.count == 3)
        let informant = list[0].name
        let target = list[2]
        #expect(target.name == "Viktor Vulnerable")
        #expect(TrustEnforcement.score(for: target) == 40)

        let sim = PeopleSimulator(store: store, now: t0)
        // branch 0.1; informant index 0.0; target index 0.9; offence index 0.0.
        sim.rand = scriptedRand([0.1, 0.0, 0.9, 0.0])
        sim.advance(now: t0.addingTimeInterval(15))

        let offence = ReportFormView.Offence.all[0].title
        let filed = store.reports().filter { $0.informantName == informant }
        #expect(filed.count == 1)
        #expect(filed.first?.targetName == "Viktor Vulnerable")
        #expect(filed.first?.citizenId == victimId)
        #expect(filed.first?.offence == offence)

        let after = store.citizen(id: victimId)!
        #expect(after.reportCount == 5)
        #expect(TrustEnforcement.score(for: after) == 25)
        #expect(after.status == .surveilled, "low trust overturns a clearance")

        #expect(sim.lastEvent == "\(informant) denounced Viktor Vulnerable: \(offence).")
        let event = store.events().first
        #expect(event?.kind == LogKind.simulator.rawValue)
        #expect(event?.actor == informant)
        #expect(event?.subject == "Viktor Vulnerable")
        #expect(event?.text == sim.lastEvent, "the archive catches every tick the UI shows")
    }

    @Test("With no dossiers at hand the denunciation uses distinct pool names")
    func npcDenouncesNpcFromPool() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let sim = PeopleSimulator(store: store, now: t0)
        // branch 0.1; i = 0.0 → pool[0]; j = 0.0 → collides → rotates to pool[1]; offence 0.0.
        sim.rand = scriptedRand([0.1, 0.0, 0.0, 0.0])
        sim.advance(now: t0.addingTimeInterval(15))

        let reports = store.reports()
        #expect(reports.count == 1)
        #expect(reports[0].citizenId == nil)
        let informant = PeopleSimulator.npcNamePool[0]
        let target = PeopleSimulator.npcNamePool[1]
        #expect(reports[0].informantName == informant)
        #expect(reports[0].targetName == target)
        #expect(sim.lastEvent == "\(informant) denounced \(target): \(ReportFormView.Offence.all[0].title).")
    }

    // MARK: - 0.20 — a note appears in the file

    @Test("A note appears in the file: appended with a space, archive notified")
    func noteAppearsInFile() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let id = store.addCitizen(
            name: "Marika", affiliation: "Collective Farm No. 3", dossierNote: "Owns scissors.")
        let sim = PeopleSimulator(store: store, now: t0)
        // branch 0.4; citizen index 0.0; note index 0.0.
        sim.rand = scriptedRand([0.4, 0.0, 0.0])
        sim.advance(now: t0.addingTimeInterval(15))

        let citizen = store.citizen(id: id)!
        #expect(citizen.dossierNote == "Owns scissors. " + PeopleSimulator.notePool[0])
        #expect(sim.lastEvent == "A note appeared in Marika's file.")
        let event = store.events().first
        #expect(event?.kind == LogKind.simulator.rawValue)
        #expect(event?.actor == "The Authority")
        #expect(event?.subject == "Marika")
        #expect(event?.text == sim.lastEvent)
    }

    @Test("A note on a clean file carries no leading space")
    func noteOnCleanFile() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let id = store.addCitizen(
            name: "Tiszta Pista", affiliation: "Bureau of Missing Hammers", dossierNote: "")
        if var citizen = store.citizen(id: id) {
            citizen.status = .cleared
            store.setCitizen(citizen)
        }
        let sim = PeopleSimulator(store: store, now: t0)
        sim.rand = scriptedRand([0.4, 0.0, 5.0 / 12.0])
        sim.advance(now: t0.addingTimeInterval(15))

        let after = store.citizen(id: id)!
        #expect(after.dossierNote == PeopleSimulator.notePool[5])
        #expect(after.status == .cleared, "one note does not reach the surveillance line")
    }

    // MARK: - 0.15 — the Authority reclassifies

    @Test("Status drift moves only between surveillance and clearance")
    func statusDrift() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let id = store.addCitizen(
            name: "István Inbetween", affiliation: "Railway Union", dossierNote: "")
        let sim = PeopleSimulator(store: store, now: t0)
        // branch 0.6; candidate index 0.0; proposed draw 0.9 → .cleared.
        sim.rand = scriptedRand([0.6, 0.0, 0.9])
        sim.advance(now: t0.addingTimeInterval(15))
        #expect(store.citizen(id: id)?.status == .cleared)
        var amendments = store.amendments(citizenId: id)
        #expect(amendments.count == 1)
        #expect(amendments[0].fieldName == "status")
        #expect(amendments[0].newValue == CitizenStatus.cleared.propagandaLabel)
        let driftEvent = store.events().first { $0.kind == LogKind.simulator.rawValue }
        #expect(driftEvent?.text == "The Authority reclassified István Inbetween.")
        #expect(driftEvent?.actor == "The Authority")
        #expect(sim.lastEvent == "The Authority reclassified István Inbetween.")

        // The neutralized are beyond reclassification; drift skips them forever.
        let deadId = store.addCitizen(
            name: "Late Comrade", affiliation: "Ministry of Clouds", dossierNote: "")
        if var dead = store.citizen(id: deadId) {
            dead.status = .neutralized
            store.setCitizen(dead)
        }
        sim.rand = scriptedRand([0.6, 0.0, 0.2])
        sim.advance(now: t0.addingTimeInterval(30))
        #expect(store.citizen(id: id)?.status == .surveilled)
        #expect(store.citizen(id: deadId)?.status == .neutralized)
    }

    // MARK: - 0.10 — you are denounced

    @Test("A neighbour denounces the comrade: alias report, flag raised, .player log")
    func playerIsDenounced() {
        let store = makeSimulatorStore()
        seedProfile(store, alias: "Sparrow")
        let sim = PeopleSimulator(store: store, now: t0)
        // branch 0.75; informant 3/24 → pool[3]; offence index 0.0.
        sim.rand = scriptedRand([0.75, 3.0 / 24.0, 0.0])
        sim.advance(now: t0.addingTimeInterval(15))

        let informant = PeopleSimulator.npcNamePool[3]
        let reports = store.reports()
        #expect(reports.count == 1)
        #expect(reports[0].targetName == "Sparrow")
        #expect(reports[0].citizenId == nil)
        #expect(reports[0].informantName == informant)
        #expect(sim.playerDenouncedBy == informant)
        #expect(sim.lastEvent == "You have been denounced by \(informant).")
        let event = store.events().first
        #expect(event?.kind == LogKind.player.rawValue)
        #expect(event?.actor == informant)
        #expect(event?.subject == "Sparrow")
        #expect(event?.text == sim.lastEvent)
    }

    @Test("Without a comrade there is nobody to denounce")
    func playerDenounceNeedsProfile() {
        let store = makeSimulatorStore()
        store.addCitizen(name: "Lone Witness", affiliation: "Railway Union", dossierNote: "")
        let sim = PeopleSimulator(store: store, now: t0)
        sim.rand = scriptedRand([0.75, 0.0, 0.0])
        sim.advance(now: t0.addingTimeInterval(15))
        #expect(store.reports().isEmpty)
        #expect(sim.playerDenouncedBy == nil)
        #expect(sim.lastEvent == nil)
    }

    // MARK: - 0.20 — the republic rests

    @Test("The nothing branch mutates nothing but still spends the tick")
    func nothingHappens() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let id = store.addCitizen(
            name: "Quiet Steve", affiliation: "State Beekeeping Directorate", dossierNote: "")
        let beforeReports = store.reports().count
        let beforeEvents = store.events().count
        let beforeNote = store.citizen(id: id)!.dossierNote

        let sim = PeopleSimulator(store: store, now: t0)
        sim.rand = scriptedRand([0.9])
        sim.advance(now: t0.addingTimeInterval(15))

        #expect(store.reports().count == beforeReports)
        #expect(store.events().count == beforeEvents)
        #expect(store.citizen(id: id)?.dossierNote == beforeNote)
        #expect(sim.lastEvent == nil)
        #expect(sim.lastTick == t0.addingTimeInterval(15), "the tick was still spent")
    }

    // MARK: - Catch-up

    @Test("A long absence back-fills at most 25 events; the rest is history")
    func catchUpCapsAt25() {
        let store = makeSimulatorStore()
        seedProfile(store)
        let targetId = store.addCitizen(
            name: "Lonely Target", affiliation: "Bureau of Missing Hammers", dossierNote: "")
        let sim = PeopleSimulator(store: store, now: t0)
        // Every draw 0.05 → the NPC-denounces-NPC branch; one citizen ⇒ pool informant.
        sim.rand = scriptedRand([], fallback: 0.05)
        sim.advance(now: t0.addingTimeInterval(3600))  // 240 eligible ticks

        #expect(store.reports().count == 25)
        #expect(store.citizen(id: targetId)?.reportCount == 25)
        #expect(sim.lastTick == t0.addingTimeInterval(3600), "the backlog is declared unrecordable")

        // A second call at the same instant must not reopen history.
        sim.advance(now: t0.addingTimeInterval(3600))
        #expect(store.reports().count == 25)
    }
}
