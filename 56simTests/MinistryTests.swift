//
//  MinistryTests.swift
//  56simTests
//
//  Deterministic verification of trust scoring, record amendments,
//  the leaderboard, plan quotas, checkpoints, the escape graph, and
//  Radio Moscow. (The state does not accept flaky tests.)
//

import Foundation
import Testing

@testable import _6sim

private func makeStore() -> StateStore {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("56sim-tests-\(UUID().uuidString)", isDirectory: true)
    return StateStore(url: directory.appendingPathComponent("state.sqlite"))
}

@MainActor
struct MinistryTests {
    // MARK: - Trust-o-meter (directive 2)

    @Test("Five denunciations drop trust to 25; none keep it at 100")
    func trustScore() {
        var citizen = Citizen(name: "Kovács Gyula", affiliation: "Factory worker")
        #expect(TrustEnforcement.score(for: citizen) == 100)

        citizen.reportCount = 5
        #expect(TrustEnforcement.score(for: citizen) == 25)

        // Dossier note costs another 10.
        citizen.dossierNote = "Seen smiling on a Tuesday."
        #expect(TrustEnforcement.score(for: citizen) == 15)
    }

    @Test("Trust is clamped to 0...100")
    func trustClamps() {
        let accused = Citizen(
            name: "Nagy Éva", affiliation: "Student", reportCount: 20)
        #expect(TrustEnforcement.score(for: accused) == 0)

        let clean = Citizen(name: "Szabó Béla", affiliation: "Clerk")
        #expect(TrustEnforcement.score(for: clean) == 100)
    }

    @Test("trustFlux lifts and sinks the deterministic score, still clamped")
    func trustFluxMovesScore() {
        var fluxed = Citizen(name: "Flux Kati", affiliation: "Railway Union", trustFlux: 30)
        #expect(TrustEnforcement.score(for: fluxed) == 100, "the ceiling holds even for favourites")
        fluxed.reportCount = 3
        #expect(TrustEnforcement.score(for: fluxed) == 85)  // 100 − 45 + 30

        let falling = Citizen(
            name: "Falling Feri", affiliation: "Intellectual (regrettable)",
            trustFlux: -20, reportCount: 5)
        #expect(TrustEnforcement.score(for: falling) == 5)  // 100 − 75 − 20

        let doomed = Citizen(
            name: "Doomed Dénes", affiliation: "Lumpenproletariat",
            trustFlux: -50, reportCount: 5)
        #expect(TrustEnforcement.score(for: doomed) == 0, "the floor is the floor")
    }

    @Test("Low trust overturns a clearance but never a neutralization")
    func enforceOverridesCleared() {
        let store = makeStore()
        let clearedId = store.addCitizen(
            name: "Horváth János", affiliation: "Trader", dossierNote: "")
        if var cleared = store.citizen(id: clearedId) {
            cleared.status = .cleared
            store.setCitizen(cleared)
        }
        for _ in 0..<5 {
            store.addReport(
                citizenId: clearedId, targetName: "Horváth János",
                offence: "Listening to enemy radio", category: "musical",
                severity: "consultancy", details: "Antenna pointed west.",
                informantName: "Comrade Operator")
        }
        #expect(TrustEnforcement.score(for: store.citizen(id: clearedId)!) == 25)
        TrustEnforcement.enforce(id: clearedId, store: store)
        #expect(store.citizen(id: clearedId)?.status == .surveilled)

        let neutralizedId = store.addCitizen(
            name: "Tóth Kálmán", affiliation: "Engineer", dossierNote: "")
        if var neutralized = store.citizen(id: neutralizedId) {
            neutralized.status = .neutralized
            store.setCitizen(neutralized)
        }
        for _ in 0..<5 {
            store.addReport(
                citizenId: neutralizedId, targetName: "Tóth Kálmán",
                offence: "Joking about rationing", category: "verbal",
                severity: "reeducation", details: "A banana joke. Not funny. Political.",
                informantName: "Comrade Operator")
        }
        TrustEnforcement.enforce(id: neutralizedId, store: store)
        #expect(
            store.citizen(id: neutralizedId)?.status == .neutralized,
            "the dead are beyond reclassification")
    }

    // MARK: - Ministry of Records (directive 3)

    @Test("Amendments rotate justifications by count and apply the change")
    func amendmentRotation() {
        let store = makeStore()
        let citizenId = store.addCitizen(name: "Kiss Ferenc", affiliation: "Tailor", dossierNote: "")

        RecordOffice.amend(
            citizenId: citizenId, field: "status",
            old: CitizenStatus.surveilled.propagandaLabel,
            new: CitizenStatus.cleared.propagandaLabel,
            store: store
        )
        #expect(store.citizen(id: citizenId)?.status == .cleared)
        var amendments = store.amendments(citizenId: citizenId)
        #expect(amendments.count == 1)
        #expect(amendments[0].justification == RecordOffice.justifications[0])
        #expect(amendments[0].fieldName == "status")

        RecordOffice.amend(
            citizenId: citizenId, field: "status",
            old: CitizenStatus.cleared.propagandaLabel,
            new: CitizenStatus.neutralized.propagandaLabel,
            store: store
        )
        #expect(store.citizen(id: citizenId)?.status == .neutralized)
        amendments = store.amendments(citizenId: citizenId)
        #expect(amendments.count == 2)
        #expect(amendments[1].justification == RecordOffice.justifications[1])

        // Rotation wraps at the full stock (the complete appendix).
        for index in 2..<55 {
            let next = CitizenStatus.allCases[index % 3]
            RecordOffice.amend(
                citizenId: citizenId, field: "status",
                old: store.citizen(id: citizenId)?.status.propagandaLabel ?? "",
                new: next.propagandaLabel,
                store: store
            )
            amendments = store.amendments(citizenId: citizenId)
            #expect(
                amendments[index].justification
                    == RecordOffice.justifications[index % RecordOffice.justifications.count])
        }
    }

    @Test("Justification stock holds the full appendix, non-duplicated, in order")
    func justificationStock() {
        // The appendix lists 46 corrections to add to the original five;
        // the ministry minutes said "45 → 50" and miscounted, as ministries do.
        #expect(RecordOffice.justifications.count == 51)
        #expect(
            Set(RecordOffice.justifications).count == RecordOffice.justifications.count)
        #expect(RecordOffice.justifications[0] == "The record has always shown this.")
        #expect(RecordOffice.justifications.last == "The glue is older than the objection.")
    }

    @Test("State refusals: 25+25, disjoint, non-empty")
    func stateRefusals() {
        #expect(StateRefusals.neutralize.count == 25)
        #expect(StateRefusals.clear.count == 25)
        #expect(Set(StateRefusals.neutralize).isDisjoint(with: Set(StateRefusals.clear)))
        #expect(StateRefusals.neutralize.allSatisfy { !$0.isEmpty })
        #expect(StateRefusals.clear.allSatisfy { !$0.isEmpty })
    }

    @Test("Amendment history sorts newest first")
    func amendmentHistoryOrder() {
        let store = makeStore()
        let citizenId = store.addCitizen(name: "Varga István", affiliation: "Driver", dossierNote: "")
        RecordOffice.amend(
            citizenId: citizenId, field: "status", old: "A",
            new: CitizenStatus.cleared.propagandaLabel, store: store)
        RecordOffice.amend(
            citizenId: citizenId, field: "status",
            old: CitizenStatus.cleared.propagandaLabel,
            new: CitizenStatus.surveilled.propagandaLabel, store: store)
        let newestFirst = store.amendments(citizenId: citizenId).sorted {
            $0.amendedAt > $1.amendedAt
        }
        #expect(newestFirst.first?.newValue == CitizenStatus.surveilled.propagandaLabel)
    }

    // MARK: - Leaderboard (directive 4)

    @Test("Leaderboard ranks net vigilance, ties alphabetical, YOU row included")
    func leaderboardOrdering() {
        func filed(
            _ informant: String, against victim: String? = nil, count: Int
        ) -> [Report] {
            (0..<count).map { _ in
                Report(
                    targetName: victim,
                    offence: "Suspicious silence",
                    details: "Quiet as a subversion manual.",
                    informantName: informant)
            }
        }
        // Boris files 5 and suffers 2 → net 3 → Order of the Red Star.
        var reports = filed("Brave Boris", count: 5)
        reports += filed("Sneaky Stella", against: "Brave Boris", count: 2)
        // Alice files 3 against nobody → net 3 → tie with Boris, settles alphabetically.
        reports += filed("Amanuensis Alice", count: 3)

        let entries = Leaderboard.entries(from: reports, profileAlias: "Sparrow")
        #expect(
            entries.map(\.name)
                == ["Amanuensis Alice", "Brave Boris", "Sneaky Stella", "Sparrow"])
        let boris = entries[1]
        #expect(boris.filed == 5)
        #expect(boris.received == 2)
        #expect(boris.net == 3)
        #expect(boris.badge == "Order of the Red Star")
        #expect(entries[0].badge == "Order of the Red Star")
        let stella = entries[2]
        #expect(stella.filed == 2)
        #expect(stella.received == 0)
        #expect(stella.badge == "Loyal Ear")
        let you = entries.last
        #expect(you?.isYou == true)
        #expect(you?.name == "Sparrow")
        #expect(you?.filed == 0)
        #expect(you?.received == 0)
    }

    @Test("Net badges flip at 3, 5, 10; denunciations against you demote visibly")
    func badgeThresholds() {
        #expect(LeaderboardEntry(name: "X", filed: 1, received: 0).badge == "Loyal Ear")
        #expect(
            LeaderboardEntry(name: "X", filed: 3, received: 0).badge == "Order of the Red Star")
        #expect(LeaderboardEntry(name: "X", filed: 5, received: 0).badge == "Iron Neighbour")
        #expect(LeaderboardEntry(name: "X", filed: 10, received: 0).badge == "People's Antenna")
        // Ten filed against you drags a People's Antenna down to Loyal Ear.
        #expect(LeaderboardEntry(name: "X", filed: 10, received: 10).badge == "Loyal Ear")
        #expect(LeaderboardEntry(name: "X", filed: 13, received: 8).badge == "Iron Neighbour")
        #expect(LeaderboardEntry(name: "X", filed: 1, received: 9).badge == "Loyal Ear")
    }

    @Test("The comrade is ranked as a YOU row with their own filed and received")
    func youRow() {
        let reports = [
            Report(
                targetName: "Sparrow", offence: "Suspicious silence",
                informantName: "Nagy Pál"),
            Report(
                targetName: "Someone Else", offence: "Suspicious silence",
                informantName: "Sparrow"),
            Report(
                targetName: "Someone Else", offence: "Suspicious silence",
                informantName: "Sparrow"),
        ]
        let entries = Leaderboard.entries(from: reports, profileAlias: "Sparrow")
        #expect(entries.filter { $0.name == "Sparrow" }.count == 1)
        let you = entries.first { $0.isYou }
        #expect(you?.filed == 2)
        #expect(you?.received == 1)
        #expect(you?.net == 1)
        #expect(entries.first { $0.name == "Nagy Pál" }?.badge == "Loyal Ear")
    }

    @Test("Reports against dossiers resolve the victim from the citizen table")
    func victimResolvesFromCitizenId() {
        let reports = [
            Report(citizenId: 7, offence: "Whistling in four tones", informantName: "Nagy Pál")
        ]
        let entries = Leaderboard.entries(
            from: reports, profileAlias: nil, citizenNames: [7: "Kovács Géza"])
        #expect(entries.first { $0.name == "Kovács Géza" }?.received == 1)
        #expect(entries.first { $0.name == "Nagy Pál" }?.filed == 1)
        #expect(entries.allSatisfy { !$0.isYou }, "no alias, no YOU row")
    }

    // MARK: - Five-Year Plan (directive 6)

    @Test("Plan progress clamps above and below")
    func planClamps() {
        let informants = FiveYearPlan.quotas[0]
        #expect(
            FiveYearPlan.progress(
                for: informants, informants: 20_000, dossiers: 0, broadcasts: 0, dayOfYear: 1)
                == 1.0)

        let dossiers = FiveYearPlan.quotas[1]
        #expect(
            FiveYearPlan.progress(
                for: dossiers, informants: 0, dossiers: -5, broadcasts: 0, dayOfYear: 1) == 0.0)

        // Steel is claimed at three tonnes per dossier.
        let steel = FiveYearPlan.quotas[2]
        #expect(
            FiveYearPlan.progress(
                for: steel, informants: 0, dossiers: 400, broadcasts: 0, dayOfYear: 1) == 1.0)
    }

    @Test("A correct answer clears the checkpoint immediately")
    func checkpointCorrectProceeds() {
        let gate = CheckpointGateRunner()
        gate.challenge = Checkpoint.questions[0]
        gate.answer(Checkpoint.questions[0].correctIndex)
        #expect(gate.challenge == nil)
        #expect(gate.detainedUntil == nil)
    }

    @Test("Plan banner is propaganda-accurate")
    func planBanner() {
        #expect(
            FiveYearPlan.banner(anyProgressIncomplete: true)
                == "PLAN FULFILLED IN 4 YEARS! (year 4 not found)"
        )
        #expect(
            FiveYearPlan.banner(anyProgressIncomplete: false)
                == "GLORY: plan fulfilled 4 years early."
        )
    }

    // MARK: - Checkpoint (directive 7)

    @Test("Checkpoint challenges on 30 percent and grades answers")
    func checkpointRules() {
        #expect(Checkpoint.mustChallenge(rand: 0.29))
        #expect(!Checkpoint.mustChallenge(rand: 0.31))
        let question = Checkpoint.questions[0]
        #expect(Checkpoint.isCorrect(question.correctIndex, on: question))
        #expect(
            !Checkpoint.isCorrect(
                (question.correctIndex + 1) % question.answers.count, on: question))
        #expect(Checkpoint.questions.count >= 20, "the republic asks more of you now")
        #expect(Checkpoint.questions.allSatisfy { $0.answers.count == 4 })
        #expect(
            Checkpoint.questions.allSatisfy {
                $0.correctIndex >= 0 && $0.correctIndex < $0.answers.count
            })
    }

    @Test("A wrong answer detains for exactly ten seconds, then releases to the action")
    func checkpointDetention() {
        let gate = CheckpointGateRunner()
        gate.challenge = Checkpoint.questions[0]
        gate.answer(
            (Checkpoint.questions[0].correctIndex + 1) % Checkpoint.questions[0].answers.count)
        #expect(gate.detainedUntil != nil)
        #expect(gate.remainingDetention() == Checkpoint.detainedSeconds)
        #expect(Checkpoint.detainedSeconds == 10)
    }

    // MARK: - Defector (directive 8)

    @Test("Escape graph resolves, terminates in six fates, and never loops")
    func defectorGraph() throws {
        #expect(Defector.nodes[Defector.startID] != nil)
        let endings = Defector.nodes.values.filter(\.isEnding)
        let endingTexts = Set(endings.map(\.text))
        #expect(endings.count >= 6)
        #expect(endingTexts.contains("REACHED AUSTRIA. TRULY."))
        #expect(endingTexts.contains("RESETTLED TO SIBERIA FOR AGRICULTURAL CONSULTANCY."))
        #expect(endingTexts.contains("SENTENCED TO 10 YEARS OF LISTENING TO APPROVED MUSIC."))
        #expect(
            endingTexts.contains("MADE ATTACHÉ TO THE CIRCUS IN VIENNA. TRAPEZE, NOT TRAITS."))
        #expect(
            endingTexts.contains("APPOINTED MINISTER OF RUMOURS. THE RUMOURS DISAPPROVED."))
        #expect(Defector.nodes.count >= 30)

        // Every choice resolves to a real node.
        for node in Defector.nodes.values {
            for choice in node.choices {
                #expect(
                    Defector.nodes[choice.nextId] != nil,
                    "dangling road \(choice.nextId) from \(node.id)")
            }
        }

        // DFS with a recursion stack: the border can only be crossed forward.
        func visit(_ id: String, stack: inout Set<String>) -> Bool {
            guard stack.insert(id).inserted else { return false }
            defer { stack.remove(id) }
            for choice in Defector.nodes[id]?.choices ?? [] {
                if !visit(choice.nextId, stack: &stack) { return false }
            }
            return true
        }
        var stack = Set<String>()
        #expect(
            visit(Defector.startID, stack: &stack), "history repeats itself — cycles are banned")

        // The new fates are reachable from the front door: the circus and
        // the ministry of rumours are endings people can actually arrive at.
        func reaches(_ target: String) -> Bool {
            var seen: Set<String> = []
            var queue = [Defector.startID]
            while let id = queue.popLast() {
                guard seen.insert(id).inserted else { continue }
                if id == target { return true }
                queue.append(contentsOf: Defector.nodes[id]?.choices.map(\.nextId) ?? [])
            }
            return false
        }
        #expect(reaches("circus"), "the trapeze awaits the reliable")
        #expect(reaches("rumour"), "the rumour ministry keeps an opening")
    }

    // MARK: - Radio Moscow (directive 9)

    @Test("Bulletins wrap forever and carry at least fifty proclamations")
    func radioBulletins() {
        #expect(RadioMoscow.bulletins.count >= 50)
        #expect(RadioMoscow.bulletins.allSatisfy { !$0.isEmpty })
        let count = RadioMoscow.bulletins.count
        #expect(
            RadioMoscow.bulletin(at: 999) == RadioMoscow.bulletins[((999 % count) + count) % count])
        #expect(RadioMoscow.bulletin(at: 999) == RadioMoscow.bulletin(at: 999 + count))
        #expect(
            RadioMoscow.bulletin(at: 0, extraTitles: ["Extra glory"]) == RadioMoscow.bulletins[0])
    }
}
