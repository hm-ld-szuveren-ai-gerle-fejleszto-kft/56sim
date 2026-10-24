//
//  PeoplesPaperTests.swift
//  56simTests
//
//  The People's Paper, proofed before the presses roll: headline rank,
//  section order, weather from the state forecast, and an edition number
//  that ages exactly as the comrade does.
//

import Foundation
import Testing

@testable import _6sim

private func event(
    _ id: Int64, _ kind: String, at: Date, actor: String = "A. Citizen",
    subject: String = "the matter", text: String
) -> LogEvent {
    LogEvent(id: id, at: at, kind: kind, actor: actor, subject: subject, text: text)
}

@MainActor
struct PeoplesPaperTests {
    private func profile(created daysAgo: Int, now: Date) -> ComradeProfile {
        ComradeProfile(
            fullName: "Test Comrade", alias: "Sparrow", affiliation: "Factory #7",
            classOrigin: "Worker", district: "District VII, Cabbage Row 3",
            membershipNumber: "Number 1956-bis, issued in someone else's name",
            suspiciousTrait: "Whistles in four tones",
            assignedTraits: ["Has a friend in Vienna"],
            melody: "Ode to the Tractor", yearsLabor: 4,
            createdAt: Calendar.current.date(byAdding: .day, value: -daysAgo, to: now) ?? now
        )
    }

    // MARK: - Headline rank

    @Test("Quota glory outranks denunciations even when older")
    func quotaGloryLeads() {
        let now = Date()
        let proclamation = PlanEvents.proclamation(quota: FiveYearPlan.quotas[2])
        let events = [
            event(1, "report", at: now, actor: "Nagy Pál", subject: "Kovács",
                  text: "Nagy Pál denounced Kovács: Suspicious silence."),
            event(2, "plan", at: now.addingTimeInterval(-600), actor: "The Plan",
                  subject: "Steel produced", text: proclamation),
        ]
        #expect(PeoplesPaper.headline(from: events, now: now) == proclamation)
    }

    @Test("A denunciation of the player outranks reports and neutralizations")
    func playerRankBeatsReportAndAmendment() {
        let now = Date()
        let events = [
            event(1, "amendment", at: now, actor: "Ministry of Records",
                  subject: "Kiss", text: "status: \"CLEARED\" → \"NEUTRALIZED\" — policy."),
            event(2, "report", at: now.addingTimeInterval(-60), text: "someone denounced someone"),
            event(3, "player", at: now.addingTimeInterval(-300),
                  text: "You have been denounced by the postman."),
        ]
        #expect(
            PeoplesPaper.headline(from: events, now: now)
                == "You have been denounced by the postman.")
    }

    @Test("Neutralization news beats plain denunciations")
    func amendmentBeatsReport() {
        let now = Date()
        let events = [
            event(1, "report", at: now, text: "Nagy Pál denounced Kovács: Suspicious silence."),
            event(2, "amendment", at: now.addingTimeInterval(-30),
                  text: "status: \"UNDER SURVEILLANCE\" → \"NEUTRALIZED\" — the glue holds."),
            // An amendment without the word must not rank as news of the third degree.
            event(3, "amendment", at: now.addingTimeInterval(-31),
                  text: "dossierNote: \"\" → \"Owns scissors.\" — noted."),
        ]
        #expect(
            PeoplesPaper.headline(from: events, now: now)
                == "status: \"UNDER SURVEILLANCE\" → \"NEUTRALIZED\" — the glue holds.")
    }

    @Test("Ties settle newest first; the day pool outranks old history")
    func tiesAndDayPool() {
        let now = Date()
        let events = [
            event(1, "report", at: now.addingTimeInterval(-600), text: "older crime"),
            event(2, "report", at: now, text: "newest crime"),
            // Yesterday's glory is history; today's crime leads the paper.
            event(3, "plan", at: now.addingTimeInterval(-25 * 3600), text: "QUOTA GLORY: old"),
        ]
        #expect(PeoplesPaper.headline(from: events, now: now) == "newest crime")
    }

    @Test("With no news in twenty-four hours, all of history is the pool")
    func fallbackToAllTime() {
        let now = Date()
        let events = [
            event(1, "report", at: now.addingTimeInterval(-40 * 3600), text: "old crime"),
            event(2, "plan", at: now.addingTimeInterval(-50 * 3600), text: "QUOTA GLORY: ancient"),
        ]
        #expect(PeoplesPaper.headline(from: events, now: now) == "QUOTA GLORY: ancient")
    }

    @Test("An empty archive prints the quiet day")
    func quietDay() {
        #expect(
            PeoplesPaper.headline(from: [], now: .now) == "QUIET DAY. SUSPICIOUSLY QUIET.")
    }

    // MARK: - Sections

    @Test("Sections print in the exact order and titles of the gazette")
    func sectionTitles() {
        let edition = PeoplesPaper.make(
            events: [], entries: [], profile: nil, now: .now, reprints: 0)
        #expect(
            edition.sections.map(\.title)
                == [
                    "DENUNCIATIONS OF THE DAY", "THE PLAN PROCEEDS", "WEATHER", "SPORTS",
                    "LETTERS TO THE EDITOR", "SCOREBOARD OF VIGILANCE",
                ])
    }

    @Test("Denunciations are capped at five, newest first, in correspondent form")
    func denunciationsCapped() {
        let now = Date()
        let events = (1...7).map { index in
            event(
                Int64(index), "report", at: now.addingTimeInterval(TimeInterval(-index * 60)),
                actor: "Informant \(index)", subject: "Victim \(index)",
                text: "Informant \(index) denounced Victim \(index): Suspicious silence.")
        }
        let edition = PeoplesPaper.make(
            events: events, entries: [], profile: nil, now: now, reprints: 0)
        let denunciations = edition.sections[0].items
        #expect(denunciations.count == 5)
        #expect(
            denunciations[0]
                == "Correspondent Informant 1 reports on Victim 1: Informant 1 denounced Victim 1: Suspicious silence."
        )
        #expect(denunciations[4].contains("Informant 5"))
    }

    @Test("Weather and sports are deterministic for a given day")
    func weatherAndSportsDeterministic() {
        let now = Date()
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: now) ?? 1
        let first = PeoplesPaper.make(
            events: [], entries: [], profile: nil, now: now, reprints: 0)
        let second = PeoplesPaper.make(
            events: [], entries: [], profile: nil, now: now, reprints: 0)
        #expect(first.sections.map(\.items) == second.sections.map(\.items))
        #expect(first.sections[2].items == [PeoplesPaper.weatherStrings[dayOfYear % 3]])
        #expect(first.sections[3].items == [PeoplesPaper.sportsStrings[dayOfYear % 3]])
        #expect(
            PeoplesPaper.weatherStrings
                == [
                    "Glorious, as planned.",
                    "Light suspicion with clearing rumours.",
                    "Heavy fog; visibility excellent for walks.",
                ])
        #expect(
            PeoplesPaper.sportsStrings
                == [
                    "League table unchanged; the table was approved.",
                    "Chess: the people draw with themselves and win.",
                    "Tractor racing postponed; tractors refuse.",
                ])
    }

    @Test("Letters and scoreboard fill themselves or confess")
    func lettersAndScoreboard() {
        let now = Date()
        let noNotes = PeoplesPaper.make(
            events: [event(1, "simulator", at: now, text: "Nagy Pál denounced Kovács: Whistling.")],
            entries: [], profile: nil, now: now, reprints: 0)
        #expect(noNotes.sections[4].items == ["All letters are also reports."])
        #expect(
            noNotes.sections[5].items == ["No vigilance recorded. The people are resting."])

        let withNotes = PeoplesPaper.make(
            events: [
                event(1, "simulator", at: now, actor: "the Registry", subject: "Kovács",
                      text: "A note appeared in Kovács's file."),
                event(2, "simulator", at: now.addingTimeInterval(-30), actor: "the Registry",
                      subject: "Kiss", text: "A note appeared in Kiss's file."),
            ],
            entries: [
                LeaderboardEntry(name: "Brave Boris", filed: 10, received: 0),
                LeaderboardEntry(name: "Timid Tibor", filed: 1, received: 0),
            ],
            profile: nil, now: now, reprints: 0)
        #expect(withNotes.sections[4].items.count == 2)
        #expect(withNotes.sections[4].items[0].contains("Kovács"))
        #expect(withNotes.sections[5].items == ["Brave Boris — People's Antenna", "Timid Tibor — Loyal Ear"])
    }

    // MARK: - Edition number

    @Test("Edition number ages with the comrade and rises with reprints")
    func editionNumber() {
        let now = Date()
        let tenDays = PeoplesPaper.make(
            events: [], entries: [], profile: profile(created: 10, now: now), now: now,
            reprints: 3)
        #expect(tenDays.editionNumber == 13)
        let sameDay = PeoplesPaper.make(
            events: [], entries: [], profile: profile(created: 0, now: now), now: now,
            reprints: 0)
        #expect(sameDay.editionNumber == 1, "no edition number zero; the state counts from one")
        let noProfile = PeoplesPaper.make(
            events: [], entries: [], profile: nil, now: now, reprints: 2)
        #expect(noProfile.editionNumber == 3)
    }

    @Test("The date line is the full date, time omitted, as subscribed")
    func dateLine() {
        let now = Date()
        let edition = PeoplesPaper.make(
            events: [], entries: [], profile: nil, now: now, reprints: 0)
        #expect(
            edition.dateText == now.formatted(.dateTime.year().month(.wide).day()),
            "the paper prints the day in full and hides the hour")
    }
}
