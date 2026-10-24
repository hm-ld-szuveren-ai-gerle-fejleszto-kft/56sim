//
//  PeoplesPaper.swift
//  56sim
//
//  The People's Paper: everything that happened, rendered by the presses
//  exactly as the archive recorded it. The paper invents nothing; where the
//  record is silent, the paper says so, suspiciously.
//

import Foundation

/// One column of the paper: a section title and its lines.
struct PaperSection {
    let title: String
    let items: [String]
}

/// A complete edition, ready for the wall.
struct PaperEdition {
    let headline: String
    let dateText: String
    let editionNumber: Int
    let sections: [PaperSection]
}

/// Pure builder over the events table — no SwiftUI, no inventions.
enum PeoplesPaper {
    static let quietHeadline = "QUIET DAY. SUSPICIOUSLY QUIET."

    static let weatherStrings = [
        "Glorious, as planned.",
        "Light suspicion with clearing rumours.",
        "Heavy fog; visibility excellent for walks.",
    ]

    static let sportsStrings = [
        "League table unchanged; the table was approved.",
        "Chess: the people draw with themselves and win.",
        "Tractor racing postponed; tractors refuse.",
    ]

    /// The news value of one line of history. Quota glory leads the paper;
    /// a quiet day leads nothing at all.
    static func rank(of event: LogEvent) -> Int {
        switch LogKind(rawValue: event.kind) {
        case .plan where event.text.contains("QUOTA GLORY"): 5
        case .player: 4
        case .amendment where event.text.contains("NEUTRALIZED"): 3
        case .report: 2
        default: 1
        }
    }

    /// Highest rank in the last 24 hours wins; ties settle newest-first.
    /// With no news today, all of history is the pool; with no history,
    /// the day was suspiciously quiet.
    static func headline(from events: [LogEvent], now: Date) -> String {
        let dayAgo = now.addingTimeInterval(-24 * 3600)
        let recent = events.filter { $0.at >= dayAgo }
        let pool = recent.isEmpty ? events : recent
        guard let top = pool.max(by: {
            let lhs = (rank(of: $0), $0.at)
            let rhs = (rank(of: $1), $1.at)
            return lhs < rhs
        }) else {
            return quietHeadline
        }
        return top.text
    }

    /// The whole edition, built from what the archive actually holds.
    static func make(
        events: [LogEvent],
        entries: [LeaderboardEntry],
        profile: ComradeProfile?,
        now: Date,
        reprints: Int
    ) -> PaperEdition {
        let newestFirst = events.sorted { lhs, rhs in
            if lhs.at != rhs.at { return lhs.at > rhs.at }
            return lhs.id > rhs.id
        }

        let denunciations = newestFirst
            .filter { $0.kind == LogKind.report.rawValue || $0.kind == LogKind.simulator.rawValue }
            .prefix(5)
            .map { "Correspondent \($0.actor) reports on \($0.subject): \($0.text)" }

        let planLines = newestFirst
            .filter { $0.kind == LogKind.plan.rawValue }
            .prefix(4)
            .map(\.text)

        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 1

        let letters = newestFirst
            .filter {
                $0.kind == LogKind.simulator.rawValue
                    && $0.text.localizedCaseInsensitiveContains("note")
            }
            .prefix(3)
            .map(\.text)

        let scoreboard = entries.prefix(3).map { "\($0.name) — \($0.badge)" }

        let baseEdition: Int
        if let profile {
            let days = Calendar.current.dateComponents([.day], from: profile.createdAt, to: now).day ?? 0
            baseEdition = max(1, days)
        } else {
            baseEdition = 1
        }

        let sections = [
            PaperSection(title: "DENUNCIATIONS OF THE DAY", items: Array(denunciations)),
            PaperSection(title: "THE PLAN PROCEEDS", items: Array(planLines)),
            PaperSection(title: "WEATHER", items: [weatherStrings[dayOfYear % weatherStrings.count]]),
            PaperSection(title: "SPORTS", items: [sportsStrings[dayOfYear % sportsStrings.count]]),
            PaperSection(
                title: "LETTERS TO THE EDITOR",
                items: letters.isEmpty ? ["All letters are also reports."] : Array(letters)),
            PaperSection(
                title: "SCOREBOARD OF VIGILANCE",
                items: scoreboard.isEmpty
                    ? ["No vigilance recorded. The people are resting."] : Array(scoreboard)),
        ]

        return PaperEdition(
            headline: headline(from: events, now: now),
            // The plan's `date: .full` does not exist in this SDK's DateStyle
            // enum; wide month + day + year is the full date, time omitted.
            dateText: now.formatted(.dateTime.year().month(.wide).day()),
            editionNumber: baseEdition + reprints,
            sections: sections
        )
    }
}
