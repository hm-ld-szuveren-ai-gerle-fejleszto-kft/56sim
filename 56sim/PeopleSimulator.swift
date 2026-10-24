//
//  PeopleSimulator.swift
//  56sim
//
//  The republic does not stand still: neighbours denounce each other, notes
//  appear in files, the Authority reclassifies, and occasionally the queue
//  turns on you. One weighted event per fifteen-second tick of history.
//

import Foundation
import Observation

@MainActor
@Observable
final class PeopleSimulator {
    /// The most recent line of rumour from the neighbourhood.
    var lastEvent: String?
    /// Set when a neighbour files a denunciation against the player's alias.
    var playerDenouncedBy: String?

    /// Injectable entropy. The republic runs on `Double.random`; the
    /// Ministry's inspectors script it.
    var rand: () -> Double = { Double.random(in: 0..<1) }

    static let shared = PeopleSimulator(store: .shared)

    /// Names the Ministry accepts as witnesses when no dossier is at hand.
    static let npcNamePool = [
        "Szabó Istvánné", "Kovács Géza", "Tóth Mari", "Nagy Pál", "Kiss Ilona",
        "Varga József", "Horvátné Zsuzsi", "Szilvási Béla", "Jurica (allegedly)",
        "Mrs. Szabó, 3B", "the postman", "the night porter",
        "Collective farm delegate Kati", "Foreman úr", "Aunt Manci", "Uncle Béla",
        "the quiet man from #9", "the loud man from #9", "Duna Panni",
        "the theatre usher", "Stationmaster Ernő", "the baker's apprentice",
        "Comrade Kálmán", "the librarian with opinions",
    ]

    /// Material for the notes that appear in citizens' files.
    static let notePool = [
        "Was heard humming abroad.",
        "Owns scissors of suspicious sharpness.",
        "Queue position improving without permission.",
        "Laughed at a joke not approved yet.",
        "Correspondence: quantity noted.",
        "Bought salt twice. Twice.",
        "Waves at the guard. Why.",
        "Reads newspapers backwards.",
        "Knows which trains are full.",
        "Smells of foreign soap.",
        "Whistles the five-tone melody.",
        "Asked for yesterday's newspaper again.",
    ]

    private let store: StateStore
    private(set) var lastTick: Date
    private let tickInterval: TimeInterval = 15
    private let maxCatchUpEvents = 25

    init(store: StateStore = .shared, now: Date = .now) {
        self.store = store
        lastTick = now
    }

    /// Fires one weighted event per elapsed tick, back-filling a long absence
    /// with at most 25 events; the remainder of the backlog is declared
    /// unrecordable and the clock rejoins the present.
    func advance(now: Date) {
        var fired = 0
        while now.timeIntervalSince(lastTick) >= tickInterval {
            guard fired < maxCatchUpEvents else {
                lastTick = now
                break
            }
            fireEvent(at: lastTick)
            lastTick = lastTick.addingTimeInterval(tickInterval)
            fired += 1
        }
        // The sweep of the people: whatever the lottery decided or skipped,
        // the Authority re-reads every open file and closes the hopeless ones
        // — the comrade's included. An idle tick is no excuse for stale paper.
        for citizen in store.citizens() where citizen.status != .neutralized {
            TrustEnforcement.enforce(id: citizen.id, store: store)
        }
        PlayerFate.evaluate(store: store)
    }

    // MARK: - The lottery of history

    private func fireEvent(at time: Date) {
        switch rand() {
        case ..<0.35: neighbourDenouncesNeighbour(at: time)
        case ..<0.55: noteAppearsInFile(at: time)
        case ..<0.70: authorityReclassifies(at: time)
        case ..<0.80: playerIsDenounced(at: time)
        default: break  // 0.20: the republic rests.
        }
    }

    /// 0.35 — two neighbours settle a score in triplicate.
    private func neighbourDenouncesNeighbour(at time: Date) {
        let citizens = store.citizens()
        let informant: String
        let targetName: String
        let target: Citizen?
        if citizens.isEmpty {
            let count = Self.npcNamePool.count
            let i = drawIndex(for: count)
            var j = drawIndex(for: count)
            if j == i { j = (j + 1) % count }
            informant = Self.npcNamePool[i]
            targetName = Self.npcNamePool[j]
            target = nil
        } else if citizens.count == 1 {
            informant = Self.npcNamePool[drawIndex(for: Self.npcNamePool.count)]
            target = citizens[0]
            targetName = citizens[0].name
        } else {
            let i = drawIndex(for: citizens.count)
            var j = drawIndex(for: citizens.count)
            if j == i { j = (j + 1) % citizens.count }
            informant = citizens[i].name
            target = citizens[j]
            targetName = citizens[j].name
        }
        let offence = anOffence()
        let text = "\(informant) denounced \(targetName): \(offence.title)."
        store.addReport(
            citizenId: target?.id,
            targetName: targetName,
            offence: offence.title,
            category: offence.category.rawValue,
            severity: offence.severity.rawValue,
            details: "Overheard by the People.",
            informantName: informant
        )
        if let target {
            TrustEnforcement.enforce(id: target.id, store: store)
        }
        store.log(kind: .simulator, actor: informant, subject: targetName, text: text, at: time)
        lastEvent = text
    }

    /// 0.20 — the file grows a truth nobody filed.
    private func noteAppearsInFile(at time: Date) {
        let citizens = store.citizens()
        guard !citizens.isEmpty else { return }  // No file, no note.
        let citizen = citizens[drawIndex(for: citizens.count)]
        let note = Self.notePool[drawIndex(for: Self.notePool.count)]
        var updated = citizen
        updated.dossierNote =
            updated.dossierNote.isEmpty ? note : updated.dossierNote + " " + note
        store.setCitizen(updated)
        TrustEnforcement.enforce(id: citizen.id, store: store)
        let text = "A note appeared in \(citizen.name)'s file."
        store.log(
            kind: .simulator, actor: "The Authority", subject: citizen.name, text: text, at: time)
        lastEvent = text
    }

    /// 0.15 — the Authority reconsiders your reliability, twice daily.
    private func authorityReclassifies(at time: Date) {
        let candidates = store.citizens().filter { $0.status != .neutralized }
        guard !candidates.isEmpty else { return }  // The dead stay put.
        let citizen = candidates[drawIndex(for: candidates.count)]
        let proposed: CitizenStatus = rand() < 0.5 ? .surveilled : .cleared
        RecordOffice.amend(
            citizenId: citizen.id,
            field: "status",
            old: citizen.status.propagandaLabel,
            new: proposed.propagandaLabel,
            store: store
        )
        let text = "The Authority reclassified \(citizen.name)."
        store.log(
            kind: .simulator, actor: "The Authority", subject: citizen.name, text: text, at: time)
        lastEvent = text
    }

    /// 0.10 — the queue turns on you.
    private func playerIsDenounced(at time: Date) {
        guard let profile = store.profile(),
            !profile.alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }
        let informant = Self.npcNamePool[drawIndex(for: Self.npcNamePool.count)]
        let offence = anOffence()
        let text = "You have been denounced by \(informant)."
        store.addReport(
            citizenId: nil,
            targetName: profile.alias,
            offence: offence.title,
            category: offence.category.rawValue,
            severity: offence.severity.rawValue,
            details: "Filed anonymously, signed loudly.",
            informantName: informant
        )
        store.log(kind: .player, actor: informant, subject: profile.alias, text: text, at: time)
        lastEvent = text
        playerDenouncedBy = informant
        StateHaptics.shared.play(.strayBullet)
    }

    // MARK: - Drawing lots

    private func anOffence() -> ReportFormView.Offence {
        let all = ReportFormView.Offence.all
        return all[drawIndex(for: all.count)]
    }

    private func drawIndex(for count: Int) -> Int {
        guard count > 0 else { return 0 }
        let raw = Int(rand() * Double(count))
        return min(max(0, raw), count - 1)
    }
}
