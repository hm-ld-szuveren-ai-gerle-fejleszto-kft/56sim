//
//  FiveYearPlan.swift
//  56sim
//
//  The Five-Year Plan: fulfilled in four, because five years of waiting
//  would admit the plan takes five years. Congress sits quarterly,
//  commissions inspect daily, and auditors weep on schedule.
//

import Foundation
import Observation

struct Quota: Identifiable {
    let id: String
    let title: String
    let unit: String
    let target: Int
}

/// One decision of the quarterly congress, with the bonuses it "delivers".
struct Policy: Identifiable {
    let id: String
    let title: String
    let effect: String
    let bonuses: [(quotaId: String, amount: Int)]
}

enum Congress {
    /// The twelve standing policies of the republic.
    static let pool: [Policy] = [
        Policy(
            id: "steel-by-faith",
            title: "Steel by Faith",
            effect: "Production is a state of mind; claim it",
            bonuses: [("steel", 40)]
        ),
        Policy(
            id: "banana-importation-of-the-imagination",
            title: "Banana Importation of the Imagination",
            effect: "Bananas are counted as arrivals, not ships",
            bonuses: [("bananas", 120_000)]
        ),
        Policy(
            id: "two-ears-per-citizen",
            title: "Two Ears Per Citizen",
            effect: "Every citizen receives an additional ear (voluntary)",
            bonuses: [("informants", 900)]
        ),
        Policy(
            id: "the-great-indexing",
            title: "The Great Indexing",
            effect: "All files filed by file size, honourably",
            bonuses: [("dossiers", 90)]
        ),
        Policy(
            id: "louder-broadcasts",
            title: "Louder Broadcasts",
            effect: "Volume counts as reach",
            bonuses: [("broadcasts", 40)]
        ),
        Policy(
            id: "tractor-first-poetry",
            title: "Tractor-First Poetry",
            effect: "Poems about tractors exempted from rhymes",
            bonuses: [("steel", 20), ("informants", 300)]
        ),
        Policy(
            id: "queue-modernisation",
            title: "Queue Modernisation",
            effect: "The queue now moves in the correct direction",
            bonuses: [("informants", 150), ("broadcasts", 30)]
        ),
        Policy(
            id: "cat-registration-amnesty",
            title: "Cat Registration Amnesty",
            effect: "Unregistered cats confess freely; owners credited",
            bonuses: [("dossiers", 60), ("informants", 200)]
        ),
        Policy(
            id: "weather-patriotism",
            title: "Weather Patriotism",
            effect: "Sunny days counted as production",
            bonuses: [("steel", 25), ("bananas", 40_000)]
        ),
        Policy(
            id: "radio-reciprocity",
            title: "Radio Reciprocity",
            effect: "Every listener must also be a speaker",
            bonuses: [("broadcasts", 60)]
        ),
        Policy(
            id: "the-apple-inspection-drive",
            title: "The Apple Inspection Drive",
            effect: "Orchards audited; auditors kept",
            bonuses: [("bananas", 80_000), ("dossiers", 30)]
        ),
        Policy(
            id: "five-year-lullaby",
            title: "Five-Year Lullaby",
            effect: "Sleep counted as labour (night shift)",
            bonuses: [("steel", 15), ("broadcasts", 25)]
        ),
    ]

    /// Three cards for (year, quarter) — deterministic slice of pool.
    static func cards(year: Int, quarter: Int) -> [Policy] {
        let start = ((year * 4 + quarter) * 3) % pool.count
        return [0, 1, 2].map { pool[($0 + start) % pool.count] }
    }
}

/// One outcome of a quota inspection.
struct Inspection {
    let text: String
    let bonus: Int
}

enum PlanEvents {
    static let inspections: [String: [Inspection]] = [
        "informants": [
            Inspection(
                text: "You find an informant listening to the inspection. +bonus", bonus: 25),
            Inspection(
                text: "The ears are metaphorical. The state accepts this.", bonus: 5),
            Inspection(text: "One ear is a hat. It reports well.", bonus: 12),
            Inspection(text: "A pigeon volunteers. Background checked.", bonus: 8),
        ],
        "dossiers": [
            Inspection(
                text: "The paper is thinner this year. So are the citizens.", bonus: 20),
            Inspection(text: "A file found itself filed. Initiative praised.", bonus: 15),
            Inspection(text: "Three files were blank and remain so. Counted.", bonus: 30),
            Inspection(text: "The index is alphabetised by suspicion.", bonus: 10),
        ],
        "steel": [
            Inspection(text: "The steel is mostly optimism. The optimism is real.", bonus: 30),
            Inspection(text: "The furnace is cold but the ledger is warm.", bonus: 50),
            Inspection(text: "A beam was weighed twice and praised once.", bonus: 20),
            Inspection(
                text: "The claim exceeds the mine. The mine has been encouraged.", bonus: 40),
        ],
        "bananas": [
            Inspection(text: "You locate a banana. It is green, but hopeful.", bonus: 15_000),
            Inspection(text: "The crate contained only the smell of the plan.", bonus: 5_000),
            Inspection(
                text: "One banana feeds an exhibition. Counted as 40 tonnes.", bonus: 40_000),
            Inspection(text: "The monkey denies involvement.", bonus: 1_000),
        ],
        "broadcasts": [
            Inspection(text: "The shout registered on three streets and a dog.", bonus: 30),
            Inspection(text: "A broadcast broadcast itself. Redundancy praised.", bonus: 20),
            Inspection(text: "The megaphone has opinions about volume.", bonus: 45),
            Inspection(text: "Feedback counted as a second voice.", bonus: 25),
        ],
    ]

    static let auditorChallenge =
        "An auditor with a Stalin moustache claims your figures are impossible. They are merely optimistic."
    static let auditorLie =
        "You reaffirm the numbers harder. The auditor weeps and signs."
    static let auditorBlame =
        "You blame a neighbour for the clerical error. A neighbour is chosen."

    static let decrees = [
        "DECREE, YEAR 1: All quotas doubled for enthusiasm. Enthusiasm exempted.",
        "DECREE, YEAR 2: The word 'shortage' has been removed from the dictionary. Congratulations.",
        "DECREE, YEAR 3: Bananas are now a strategic mineral. The monkeys have been notified.",
        "DECREE, YEAR 4: The plan has entered the fourth year. The fourth year is being investigated for hiding.",
    ]

    static func proclamation(quota: Quota) -> String {
        "QUOTA GLORY: \(quota.title) has met its target of \(quota.target) \(quota.unit). The people may applaud for 30 seconds."
    }
}

enum FiveYearPlan {
    static let quotas: [Quota] = [
        Quota(id: "informants", title: "Recruit informants", unit: "ears", target: 10_000),
        Quota(id: "dossiers", title: "Dossiers compiled", unit: "files", target: 1_000),
        Quota(id: "steel", title: "Steel produced", unit: "tonnes (claimed)", target: 400),
        Quota(id: "bananas", title: "Bananas stockpiled", unit: "kg", target: 1_000_000),
        Quota(id: "broadcasts", title: "Broadcasts proclaimed", unit: "shouts", target: 500),
    ]

    /// Raw claimed output for a quota — the number printed under the bar.
    /// Congress, inspection and auditor bonuses (`bonus_<quotaId>` memos)
    /// count, because the ledger is the production.
    static func rawCount(
        for quota: Quota,
        informants: Int,
        dossiers: Int,
        broadcasts: Int,
        dayOfYear: Int,
        store: StateStore? = nil
    ) -> Int {
        let base: Int
        switch quota.id {
        case "informants": base = informants
        case "dossiers": base = dossiers
        case "broadcasts": base = broadcasts
        case "steel": base = dossiers * 3
        case "bananas": base = dayOfYear % 7
        default: base = 0
        }
        return base + (store?.kvInt("bonus_\(quota.id)") ?? 0)
    }

    /// progress 0...1, clamped. informants = distinct informantName count,
    /// dossiers = citizen count, broadcasts = broadcast count,
    /// steel = citizenCount * 3 (claimed), bananas = dayOfYear % 7 (state says so),
    /// plus every bonus the commission has proclaimed into the ledger.
    static func progress(
        for quota: Quota,
        informants: Int,
        dossiers: Int,
        broadcasts: Int,
        dayOfYear: Int,
        store: StateStore? = nil
    ) -> Double {
        let raw = Double(
            rawCount(
                for: quota,
                informants: informants,
                dossiers: dossiers,
                broadcasts: broadcasts,
                dayOfYear: dayOfYear,
                store: store
            ))
        return min(1, max(0, raw / Double(quota.target)))
    }

    /// The plan is always four years early; the fourth year is not yet found.
    static func banner(anyProgressIncomplete: Bool) -> String {
        anyProgressIncomplete
            ? "PLAN FULFILLED IN 4 YEARS! (year 4 not found)"
            : "GLORY: plan fulfilled 4 years early."
    }
}

/// The working commission behind the dashboard: congress votes, inspections
/// embarrass, auditors weep, and glory is proclaimed exactly once per quota.
@MainActor
@Observable
final class PlanCommission {
    /// The most recent line from the commission's podium.
    var lastEvent: String?
    /// Set on a year rollover; the view shows it until the people read it.
    var decreeToast: String?

    /// Injectable entropy for the inspection lottery; tests script it.
    var inspector: () -> Double = { Double.random(in: 0..<1) }

    private let store: StateStore
    private let localLogCap = 20

    init(store: StateStore = .shared) {
        self.store = store
    }

    // MARK: - The calendar of the plan

    var year: Int { store.kvString("planYear").flatMap(Int.init) ?? 1 }
    var quarter: Int { store.kvString("planQuarter").flatMap(Int.init) ?? 1 }
    var congressHeld: Bool { store.kvString("congress_\(year)_\(quarter)") != nil }
    var fifthYearAbolished: Bool { year > 4 }

    // MARK: - Progress

    private var counts: (informants: Int, dossiers: Int, broadcasts: Int) {
        (
            Set(store.reports().map(\.informantName)).count,
            store.citizens().count,
            store.broadcasts().count,
        )
    }

    private var dayOfYear: Int {
        Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
    }

    func progress(for quota: Quota) -> Double {
        let c = counts
        return FiveYearPlan.progress(
            for: quota,
            informants: c.informants,
            dossiers: c.dossiers,
            broadcasts: c.broadcasts,
            dayOfYear: dayOfYear,
            store: store
        )
    }

    var anyProgress: Double {
        FiveYearPlan.quotas.map(progress(for:)).max() ?? 0
    }

    func rawCount(for quota: Quota) -> Int {
        let c = counts
        return FiveYearPlan.rawCount(
            for: quota,
            informants: c.informants,
            dossiers: c.dossiers,
            broadcasts: c.broadcasts,
            dayOfYear: dayOfYear,
            store: store
        )
    }

    // MARK: - Congress

    /// Votes a policy into the ledger and advances the quarter (and, when it
    /// was the fourth, the year — with the decree of the new year to match).
    func adopt(_ policy: Policy) {
        for bonus in policy.bonuses {
            store.setKV(
                "bonus_\(bonus.quotaId)",
                value: String(store.kvInt("bonus_\(bonus.quotaId)") + bonus.amount))
        }
        store.setKV("congress_\(year)_\(quarter)", value: policy.id)
        announce("The congress adopted \"\(policy.title)\": \(policy.effect)",
                 actor: "The Congress", subject: policy.title)
        if quarter == 4 {
            let nextYear = year + 1
            store.setKV("planYear", value: String(nextYear))
            store.setKV("planQuarter", value: "1")
            decreeToast = PlanEvents.decrees[(nextYear - 1) % PlanEvents.decrees.count]
        } else {
            store.setKV("planQuarter", value: String(quarter + 1))
        }
        checkMilestones()
    }

    // MARK: - Inspections (one embarrassment per quota per day)

    private func inspectedKey(_ quota: Quota) -> String {
        "inspected_\(quota.id)_\(Self.dayKey(now: .now))"
    }

    func inspectedToday(_ quota: Quota) -> Bool {
        store.kvString(inspectedKey(quota)) != nil
    }

    /// Sends the commission to a quota. Once per day per quota; the second
    /// visit would merely repeat the embarrassment.
    func inspect(_ quota: Quota) -> Inspection? {
        guard !inspectedToday(quota) else { return nil }
        let options = PlanEvents.inspections[quota.id] ?? []
        guard !options.isEmpty else { return nil }
        let inspection = options[min(max(0, Int(inspector() * Double(options.count))), options.count - 1)]
        store.setKV(inspectedKey(quota), value: inspection.text)
        store.setKV(
            "bonus_\(quota.id)",
            value: String(store.kvInt("bonus_\(quota.id)") + inspection.bonus))
        announce(inspection.text, actor: "The Commission", subject: quota.title)
        checkMilestones()
        return inspection
    }

    // MARK: - The auditor

    var auditorPending: Bool {
        anyProgress >= 0.9 && store.kvString("auditor_\(Self.dayKey(now: .now))") == nil
    }

    /// Reaffirms the numbers harder. The auditor weeps; steel gains a tenth
    /// of its own target for the trouble.
    func answerAuditorByLying() {
        guard let steel = FiveYearPlan.quotas.first(where: { $0.id == "steel" }) else { return }
        store.setKV(
            "bonus_steel", value: String(store.kvInt("bonus_steel") + steel.target / 10))
        store.setKV("auditor_\(Self.dayKey(now: .now))", value: "reaffirmed harder")
        announce("The auditor wept.", actor: "The Auditor", subject: "the impossible figures")
        checkMilestones()
    }

    /// Blames a neighbour for the clerical error. A neighbour is chosen.
    func answerAuditorByBlame() {
        var line = PlanEvents.auditorBlame
        let citizens = store.citizens()
        if !citizens.isEmpty {
            let chosen = citizens[min(max(0, Int(inspector() * Double(citizens.count))), citizens.count - 1)]
            RecordOffice.amend(
                citizenId: chosen.id,
                field: "status",
                old: chosen.status.propagandaLabel,
                new: CitizenStatus.surveilled.propagandaLabel,
                store: store
            )
            line = "\(PlanEvents.auditorBlame) Chosen: \(chosen.name)."
        }
        store.setKV("auditor_\(Self.dayKey(now: .now))", value: "neighbour held responsible")
        announce(line, actor: "The Auditor", subject: "the clerical error")
    }

    // MARK: - Glory

    /// The first quota to reach 1.0 receives a broadcast, a T-34, and a
    /// line in the record; the kv memo makes glory strictly once per quota.
    private func checkMilestones() {
        for quota in FiveYearPlan.quotas where store.kvString("glory_\(quota.id)") == nil {
            guard progress(for: quota) >= 1.0 else { continue }
            store.setKV("glory_\(quota.id)", value: "proclaimed")
            let proclamation = PlanEvents.proclamation(quota: quota)
            store.addBroadcast(
                title: FiveYearPlan.banner(anyProgressIncomplete: false), body: proclamation)
            StateHaptics.shared.play(.t34Firing)
            announce(proclamation, actor: "The Plan", subject: quota.title)
        }
    }

    // MARK: - The commission's own ring of proclamations

    /// Newest first; persisted as a json array in the kv memos, capped at 20.
    var proclamations: [String] {
        get {
            guard let json = store.kvString("plan_log"),
                let data = json.data(using: .utf8),
                let rows = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return rows
        }
    }

    private func announce(_ text: String, actor: String, subject: String) {
        lastEvent = text
        store.log(kind: .plan, actor: actor, subject: subject, text: text)
        var rows = proclamations
        rows.insert(text, at: 0)
        if rows.count > localLogCap { rows = Array(rows.prefix(localLogCap)) }
        if let data = try? JSONEncoder().encode(rows),
            let json = String(data: data, encoding: .utf8)
        {
            store.setKV("plan_log", value: json)
        }
    }

    /// yyyy-MM-dd, the only day format the ledger recognises.
    static func dayKey(now: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: now)
    }
}
