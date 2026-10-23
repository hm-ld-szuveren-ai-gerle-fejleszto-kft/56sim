//
//  MinistryTests.swift
//  56simTests
//
//  Deterministic verification of trust scoring, record amendments,
//  the leaderboard, plan quotas, checkpoints, the escape graph, and
//  Radio Moscow. (The state does not accept flaky tests.)
//

import Foundation
import SwiftData
import Testing

@testable import _6sim

private func makeRegistry() throws -> ModelContext {
    let schema = Schema([Citizen.self, Broadcast.self, Report.self, RecordAmendment.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [configuration])
    return ModelContext(container)
}

@MainActor
struct MinistryTests {
    // MARK: - Trust-o-meter (directive 2)

    @Test("Five denunciations drop trust to 25; none keep it at 100")
    func trustScore() throws {
        let context = try makeRegistry()
        let citizen = Citizen(name: "Kovács Gyula", affiliation: "Factory worker")
        context.insert(citizen)
        #expect(TrustEnforcement.score(for: citizen) == 100)

        for _ in 0..<5 {
            context.insert(
                Report(
                    offence: "Hoarding Western jokes",
                    details: "Told one at the canteen.",
                    informantName: "Comrade Operator",
                    citizen: citizen
                ))
        }
        #expect(TrustEnforcement.score(for: citizen) == 25)

        // Dossier note costs another 10.
        citizen.dossierNote = "Seen smiling on a Tuesday."
        #expect(TrustEnforcement.score(for: citizen) == 15)
    }

    @Test("Trust is clamped to 0...100")
    func trustClamps() throws {
        let context = try makeRegistry()
        let citizen = Citizen(name: "Nagy Éva", affiliation: "Student")
        context.insert(citizen)
        for _ in 0..<20 {
            context.insert(
                Report(
                    offence: "Suspicious silence",
                    details: "Said nothing, three days running.",
                    informantName: "Comrade Operator",
                    citizen: citizen
                ))
        }
        #expect(TrustEnforcement.score(for: citizen) == 0)

        let clean = Citizen(name: "Szabó Béla", affiliation: "Clerk")
        context.insert(clean)
        #expect(TrustEnforcement.score(for: clean) == 100)
    }

    @Test("Low trust overturns a clearance but never a neutralization")
    func enforceOverridesCleared() throws {
        let context = try makeRegistry()
        let cleared = Citizen(name: "Horváth János", affiliation: "Trader", status: .cleared)
        context.insert(cleared)
        for _ in 0..<5 {
            context.insert(
                Report(
                    offence: "Listening to enemy radio",
                    details: "Antenna pointed west.",
                    informantName: "Comrade Operator",
                    citizen: cleared
                ))
        }
        #expect(TrustEnforcement.score(for: cleared) == 25)
        TrustEnforcement.enforce(cleared)
        #expect(cleared.status == .surveilled)

        let neutralized = Citizen(
            name: "Tóth Kálmán", affiliation: "Engineer", status: .neutralized)
        context.insert(neutralized)
        for _ in 0..<5 {
            context.insert(
                Report(
                    offence: "Joking about rationing",
                    details: "A banana joke. Not funny. Political.",
                    informantName: "Comrade Operator",
                    citizen: neutralized
                ))
        }
        TrustEnforcement.enforce(neutralized)
        #expect(neutralized.status == .neutralized, "the dead are beyond reclassification")
    }

    // MARK: - Ministry of Records (directive 3)

    @Test("Amendments rotate justifications by count and apply the change")
    func amendmentRotation() throws {
        let context = try makeRegistry()
        let citizen = Citizen(name: "Kiss Ferenc", affiliation: "Tailor")
        context.insert(citizen)

        RecordOffice.amend(
            citizen, field: "status",
            old: CitizenStatus.surveilled.propagandaLabel,
            new: CitizenStatus.cleared.propagandaLabel,
            in: context
        )
        #expect(citizen.status == .cleared)
        #expect(citizen.amendments.count == 1)
        #expect(citizen.amendments[0].justification == RecordOffice.justifications[0])
        #expect(citizen.amendments[0].fieldName == "status")

        RecordOffice.amend(
            citizen, field: "status",
            old: CitizenStatus.cleared.propagandaLabel,
            new: CitizenStatus.neutralized.propagandaLabel,
            in: context
        )
        #expect(citizen.status == .neutralized)
        #expect(citizen.amendments.count == 2)
        #expect(citizen.amendments[1].justification == RecordOffice.justifications[1])

        // Rotation wraps at 5.
        for index in 2..<7 {
            let next = CitizenStatus.allCases[index % 3]
            RecordOffice.amend(
                citizen, field: "status",
                old: citizen.status.propagandaLabel,
                new: next.propagandaLabel,
                in: context
            )
            #expect(
                citizen.amendments[index].justification == RecordOffice.justifications[index % 5])
        }
    }

    @Test("Amendment history sorts newest first")
    func amendmentHistoryOrder() throws {
        let context = try makeRegistry()
        let citizen = Citizen(name: "Varga István", affiliation: "Driver")
        context.insert(citizen)
        RecordOffice.amend(
            citizen, field: "status", old: "A", new: CitizenStatus.cleared.propagandaLabel,
            in: context)
        RecordOffice.amend(
            citizen, field: "status", old: CitizenStatus.cleared.propagandaLabel,
            new: CitizenStatus.surveilled.propagandaLabel, in: context)
        let newestFirst = citizen.amendments.sorted { $0.amendedAt > $1.amendedAt }
        #expect(newestFirst.first?.newValue == CitizenStatus.surveilled.propagandaLabel)
    }

    // MARK: - Leaderboard (directive 4)

    @Test("Leaderboard orders by reports, ties alphabetical, badges exact")
    func leaderboardOrdering() throws {
        let context = try makeRegistry()
        let citizen = Citizen(name: "Németh Lászlóné", affiliation: "Librarian")
        context.insert(citizen)

        func file(_ informant: String, count: Int) {
            for _ in 0..<count {
                context.insert(
                    Report(
                        offence: "Suspicious silence",
                        details: "Quiet as a subversion manual.",
                        informantName: informant,
                        citizen: citizen
                    ))
            }
        }
        file("Amanuensis Alice", count: 3)
        file("Brave Boris", count: 5)

        let entries = Leaderboard.entries(from: citizen.reports)
        #expect(entries.map(\.name) == ["Brave Boris", "Amanuensis Alice"])
        #expect(entries[0].reportCount == 5)
        #expect(entries[0].badge == "Iron Neighbour")
        #expect(entries[1].badge == "Order of the Red Star")

        // Tie settles alphabetically.
        file("Cautious Carla", count: 3)
        let tied = Leaderboard.entries(from: citizen.reports)
        #expect(tied.map(\.name) == ["Brave Boris", "Amanuensis Alice", "Cautious Carla"])
    }

    @Test("Badge thresholds flip at 1, 3, 5, 10")
    func badgeThresholds() {
        #expect(LeaderboardEntry(name: "X", reportCount: 1).badge == "Loyal Ear")
        #expect(LeaderboardEntry(name: "X", reportCount: 3).badge == "Order of the Red Star")
        #expect(LeaderboardEntry(name: "X", reportCount: 5).badge == "Iron Neighbour")
        #expect(LeaderboardEntry(name: "X", reportCount: 10).badge == "People's Antenna")
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
        #expect(Checkpoint.questions.count >= 6)
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

    @Test("Escape graph resolves, terminates in three fates, and never loops")
    func defectorGraph() throws {
        #expect(Defector.nodes[Defector.startID] != nil)
        let endings = Defector.nodes.values.filter(\.isEnding)
        let endingTexts = Set(endings.map(\.text))
        #expect(endings.count >= 3)
        #expect(endingTexts.contains("REACHED AUSTRIA. TRULY."))
        #expect(endingTexts.contains("RESETTLED TO SIBERIA FOR AGRICULTURAL CONSULTANCY."))
        #expect(endingTexts.contains("SENTENCED TO 10 YEARS OF LISTENING TO APPROVED MUSIC."))
        #expect(Defector.nodes.count >= 12)

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
    }

    // MARK: - Radio Moscow (directive 9)

    @Test("Bulletins wrap forever and carry at least eight proclamations")
    func radioBulletins() {
        #expect(RadioMoscow.bulletins.count >= 8)
        #expect(RadioMoscow.bulletins.allSatisfy { !$0.isEmpty })
        let count = RadioMoscow.bulletins.count
        #expect(
            RadioMoscow.bulletin(at: 999) == RadioMoscow.bulletins[((999 % count) + count) % count])
        #expect(RadioMoscow.bulletin(at: 999) == RadioMoscow.bulletin(at: 999 + count))
        #expect(
            RadioMoscow.bulletin(at: 0, extraTitles: ["Extra glory"]) == RadioMoscow.bulletins[0])
    }
}
