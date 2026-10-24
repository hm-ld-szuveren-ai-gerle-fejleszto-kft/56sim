//
//  ContentExpansionTests.swift
//  56simTests
//
//  The expanded republic, audited: the offence catalogue and its pure
//  filter, the congress cards, the inspection calendar, the auditor's
//  visits, and the single permitted proclamation of glory per quota.
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
struct ContentExpansionTests {
    // MARK: - Offence catalogue (P4.3)

    @Test("The catalogue holds every published crime across all ten categories")
    func offenceCatalogue() {
        let all = ReportFormView.Offence.all
        // The appendix lists 76 new crimes behind the seven classics; the
        // ministry minutes said "62 → 69" and miscounted, as ministries do.
        #expect(all.count == 83)
        #expect(Set(all.map(\.title)).count == all.count, "no crime is filed twice")
        for category in OffenceCategory.allCases {
            #expect(all.filter { $0.category == category }.count >= 4, "\(category)")
        }
        for severity in OffenceSeverity.allCases {
            #expect(all.filter { $0.severity == severity }.count >= 8, "\(severity)")
        }
        // The seven classics keep their historic order at the head of the file.
        #expect(all[0].title == "Hoarding Western jokes")
        #expect(all[0].category == .verbal && all[0].severity == .reeducation)
        #expect(all[1].title == "Insufficient enthusiasm at May Day")
        #expect(all[1].category == .folklore && all[1].severity == .watchlist)
        #expect(all[2].title == "Listening to enemy radio")
        #expect(all[2].category == .musical && all[2].severity == .consultancy)
        #expect(all[3].title == "Joking about rationing")
        #expect(all[4].title == "Suspicious silence")
        #expect(all[5].title == "Keeping an unregistered cat")
        #expect(all[5].category == .animals && all[5].severity == .reeducation)
        #expect(all[6].title == "Other")
        #expect(all[6].category == .paperwork && all[6].severity == .watchlist)
        // The two promotions recorded in the appendix itself.
        #expect(
            all.first { $0.title == "Admiring a bridge structure" }?.severity == .consultancy)
        #expect(
            all.first { $0.title == "A diary (paper is a resource)" }?.severity == .consultancy)
        // Labels and marks as the gazette printed them.
        #expect(OffenceSeverity.watchlist.label == "Watchlist")
        #expect(OffenceSeverity.reeducation.label == "Re-education")
        #expect(OffenceSeverity.consultancy.label == "Agricultural Consultancy")
        #expect(OffenceSeverity.watchlist.marks == "●")
        #expect(OffenceSeverity.reeducation.marks == "●●")
        #expect(OffenceSeverity.consultancy.marks == "●●●")
        #expect(OffenceCategory.musical.label == "Musical")
        #expect(OffenceCategory.timekeeping.label == "Timekeeping")
        #expect(OffenceCategory.paperwork.label == "Paperwork")
        // The creative charge exists for the empty end of the catalogue.
        #expect(ReportFormView.Offence.creative.title == "Other (the file is creative)")
        #expect(ReportFormView.Offence.creative.category == .paperwork)
        #expect(ReportFormView.Offence.creative.severity == .watchlist)
    }

    @Test("The pure catalogue filter composes search, category, and severity")
    func offenceFilter() {
        #expect(
            ReportFormView.Offence.filter(search: "", category: nil, severity: nil).count
                == ReportFormView.Offence.all.count)
        let cats = ReportFormView.Offence.filter(search: "cat", category: nil, severity: nil)
            .map(\.title)
        #expect(cats.contains("A cat reading a newspaper"))
        #expect(cats.contains("Keeping an unregistered cat"))
        #expect(cats.contains("Naming a cat after a foreign composer"))
        // Category narrows: within Animals the composer (a Musical crime) drops out.
        let animalsCats = ReportFormView.Offence.filter(
            search: "cat", category: .animals, severity: nil).map(\.title)
        #expect(!animalsCats.contains("Naming a cat after a foreign composer"))
        #expect(animalsCats.count == 2)
        // Severity alone: consultancy carries its three heavy dots.
        #expect(
            ReportFormView.Offence.filter(search: "", category: nil, severity: .consultancy)
                .count == 10)
        // A crime not yet invented filters to nothing (see "Charge them anyway").
        #expect(
            ReportFormView.Offence.filter(search: "banana", category: nil, severity: nil).isEmpty)
        // Search is case-insensitive, as promised to the people.
        #expect(
            ReportFormView.Offence.filter(search: "SALT", category: nil, severity: nil)
                .map(\.title)
                .contains("Bought salt twice in one day"))
        // All three compose.
        let composed = ReportFormView.Offence.filter(
            search: "clock", category: .timekeeping, severity: .reeducation)
        #expect(composed.map(\.title) == ["Owning two clocks of different opinions"])
    }

    @Test("The simulator files classified crimes")
    func classifiedSimulatorCrime() {
        // The random-crime draw now carries its classification into the file.
        let all = ReportFormView.Offence.all
        let sample = all[0]
        #expect(sample.category.rawValue == "verbal")
        #expect(sample.severity.rawValue == "reeducation")
        #expect(OffenceCategory(rawValue: "musical")?.label == "Musical")
        #expect(OffenceSeverity(rawValue: "watchlist")?.marks == "●")
    }

    // MARK: - Congress (P4.6)

    @Test("Congress cards are deterministic, non-empty, and verbatim")
    func congressCards() {
        #expect(Congress.pool.count == 12)
        let cards = Congress.cards(year: 1, quarter: 1)
        #expect(cards.count == 3)
        #expect(cards.map(\.id) == Congress.cards(year: 1, quarter: 1).map(\.id))
        #expect(Set(cards.map(\.id)).count == 3)
        // start = ((1*4 + 1) * 3) % 12 = 3 → pool[3], pool[4], pool[5]
        #expect(
            cards.map(\.title)
                == ["The Great Indexing", "Louder Broadcasts", "Tractor-First Poetry"])
        let steel = Congress.pool[0]
        #expect(steel.title == "Steel by Faith")
        #expect(steel.effect == "Production is a state of mind; claim it")
        #expect(steel.bonuses.count == 1)
        #expect(steel.bonuses[0].quotaId == "steel" && steel.bonuses[0].amount == 40)
        let banana = Congress.pool[1]
        #expect(banana.title == "Banana Importation of the Imagination")
        #expect(banana.effect == "Bananas are counted as arrivals, not ships")
        #expect(banana.bonuses.count == 1)
        #expect(banana.bonuses[0].quotaId == "bananas" && banana.bonuses[0].amount == 120_000)
    }

    @Test("Congress applies its bonuses to the ledger and settles the quarter")
    func congressAdoption() {
        let store = makeStore()
        let commission = PlanCommission(store: store)
        let banana = Congress.pool[1]
        commission.adopt(banana)
        #expect(store.kvInt("bonus_bananas") == 120_000)
        #expect(store.kvString("congress_1_1") == "banana-importation-of-the-imagination")
        #expect(commission.year == 1 && commission.quarter == 2)
        #expect(store.kvString("planQuarter") == "2")
        // Bonus output counts toward progress: the banana bar moved.
        let bananaQuota = FiveYearPlan.quotas[3]
        #expect(commission.progress(for: bananaQuota) > 0.12 - 0.000_01)
        #expect(commission.progress(for: bananaQuota) <= 0.13)
    }

    @Test("The fourth quarter turns the year and the decree follows")
    func yearRollover() {
        #expect(PlanEvents.decrees.count == 4)
        #expect(
            PlanEvents.decrees[0]
                == "DECREE, YEAR 1: All quotas doubled for enthusiasm. Enthusiasm exempted.")
        #expect(
            PlanEvents.decrees[1]
                == "DECREE, YEAR 2: The word 'shortage' has been removed from the dictionary. Congratulations."
        )
        #expect(
            PlanEvents.decrees[2]
                == "DECREE, YEAR 3: Bananas are now a strategic mineral. The monkeys have been notified."
        )
        #expect(
            PlanEvents.decrees[3]
                == "DECREE, YEAR 4: The plan has entered the fourth year. The fourth year is being investigated for hiding."
        )
        let store = makeStore()
        let commission = PlanCommission(store: store)
        store.setKV("planQuarter", value: "4")
        commission.adopt(Congress.cards(year: 1, quarter: 4)[0])
        #expect(commission.year == 2 && commission.quarter == 1)
        #expect(commission.decreeToast == PlanEvents.decrees[(2 - 1) % 4])
        // And the fifth year is abolished as bourgeois.
        store.setKV("planYear", value: "5")
        #expect(commission.fifthYearAbolished)
    }

    @Test("The commission's own log keeps only the newest twenty proclamations")
    func ringCap() {
        let store = makeStore()
        let commission = PlanCommission(store: store)
        for session in 1...25 {
            commission.adopt(Congress.cards(year: 1, quarter: session % 4 + 1)[0])
        }
        #expect(commission.proclamations.count == 20)
        // Newest first: the last adoption leads the sheet.
        let lastTitle = Congress.cards(year: 1, quarter: 25 % 4 + 1)[0].title
        #expect(commission.proclamations[0].contains(lastTitle))
    }

    // MARK: - Inspections (P4.6)

    @Test("Inspect fires once per day per quota and pays the ledger")
    func inspectOnceDaily() {
        let store = makeStore()
        let commission = PlanCommission(store: store)
        commission.inspector = { 0.0 }
        let informants = FiveYearPlan.quotas[0]
        let first = commission.inspect(informants)
        #expect(first?.text == PlanEvents.inspections["informants"]![0].text)
        #expect(first?.bonus == 25)
        #expect(store.kvInt("bonus_informants") == 25)
        // Same quota, same day: the commission is already embarrassed.
        #expect(commission.inspect(informants) == nil)
        #expect(store.kvInt("bonus_informants") == 25)
        #expect(commission.inspectedToday(informants))
        // Another quota keeps its own calendar.
        let steel = FiveYearPlan.quotas[2]
        #expect(commission.inspect(steel)?.text != nil)
        #expect(store.kvInt("bonus_steel") == 30)
        // The day's embarrassment lives in the kv key the plan decreed.
        #expect(store.kvString("inspected_informants_\(PlanCommission.dayKey())") != nil)
        // And the archive received one line of it.
        #expect(
            store.events().contains {
                $0.kind == "plan" && $0.text.contains("informant listening")
            })
        #expect(PlanEvents.inspections.count == 5)
        for quota in FiveYearPlan.quotas {
            #expect(PlanEvents.inspections[quota.id]?.count == 4, "quota \(quota.id)")
        }
    }

    // MARK: - Auditor (P4.6)

    @Test("The auditor arrives at ninety percent and is satisfied once a day")
    func auditorThresholdAndLie() {
        #expect(
            PlanEvents.auditorChallenge
                == "An auditor with a Stalin moustache claims your figures are impossible. They are merely optimistic."
        )
        #expect(
            PlanEvents.auditorLie == "You reaffirm the numbers harder. The auditor weeps and signs."
        )
        #expect(
            PlanEvents.auditorBlame
                == "You blame a neighbour for the clerical error. A neighbour is chosen.")
        let store = makeStore()
        let commission = PlanCommission(store: store)
        #expect(!commission.auditorPending)
        store.setKV("bonus_steel", value: "359")  // 0.8975 — below the threshold
        #expect(!commission.auditorPending)
        store.setKV("bonus_steel", value: "360")  // exactly 0.9 — the auditor knocks
        #expect(commission.auditorPending)
        commission.answerAuditorByLying()
        #expect(!commission.auditorPending, "the auditor is satisfied for the day")
        #expect(store.kvString("auditor_\(PlanCommission.dayKey())") != nil)
        #expect(store.kvInt("bonus_steel") == 400)
        #expect(store.events().contains { $0.kind == "plan" && $0.text == "The auditor wept." })
        // The lie reached the target, so glory was proclaimed — exactly once.
        #expect(store.kvString("glory_steel") != nil)
        #expect(store.broadcasts().count == 1)
    }

    @Test("Blaming a neighbour reclassifies the chosen one and names them")
    func auditorBlame() {
        let store = makeStore()
        let commission = PlanCommission(store: store)
        commission.inspector = { 0.0 }
        let id = store.addCitizen(
            name: "Whispered Wilma", affiliation: "Bureau of Missing Hammers", dossierNote: "")
        if var wilma = store.citizen(id: id) {
            wilma.status = .cleared
            store.setCitizen(wilma)
        }
        store.setKV("bonus_steel", value: "360")
        #expect(commission.auditorPending)
        commission.answerAuditorByBlame()
        #expect(!commission.auditorPending)
        #expect(store.citizen(id: id)?.status == .surveilled)
        #expect(commission.lastEvent?.contains("Whispered Wilma") == true)
    }

    // MARK: - Milestones (P4.6)

    @Test("Proclamation follows the exact wording of the gazette")
    func proclamationFormat() {
        let quota = Quota(id: "x", title: "Recruit informants", unit: "ears", target: 10_000)
        #expect(
            PlanEvents.proclamation(quota: quota)
                == "QUOTA GLORY: Recruit informants has met its target of 10000 ears. The people may applaud for 30 seconds."
        )
    }

    @Test("A quota hitting target proclaims one broadcast of glory")
    func milestoneBroadcast() {
        let store = makeStore()
        let commission = PlanCommission(store: store)
        store.setKV("bonus_steel", value: "370")
        let steelFaith = Congress.pool[0]  // steel +40 → 410 ≥ 400
        commission.adopt(steelFaith)
        #expect(store.kvInt("bonus_steel") == 410)
        let glory = store.broadcasts()
        #expect(glory.count == 1)
        #expect(glory[0].title == "GLORY: plan fulfilled 4 years early.")
        #expect(
            glory[0].body
                == "QUOTA GLORY: Steel produced has met its target of 400 tonnes (claimed). The people may applaud for 30 seconds."
        )
        #expect(store.kvString("glory_steel") != nil)
        // A second congress cannot proclaim the same glory twice.
        commission.adopt(Congress.pool.first { $0.id == "radio-reciprocity" }!)
        #expect(store.broadcasts().count == 1)
        // The plan line entered the record for the paper to print.
        #expect(
            store.events().contains {
                $0.kind == "plan" && $0.text.contains("QUOTA GLORY")
            })
    }
}
