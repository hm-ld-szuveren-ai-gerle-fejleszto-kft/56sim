//
//  Profile.swift
//  56sim
//
//  The data of a comrade: approved affiliations, honest class origins,
//  folk melodies, and the 37 suspicions from which four are drawn at
//  birth (or at setup, which amounts to the same thing).
//

import Foundation

enum Profile {
    /// The recognised places of honest labour.
    static let affiliations = [
        "Factory #7",
        "Collective Farm No. 3",
        "Ministry of Clouds",
        "Railway Union",
        "State Beekeeping Directorate",
        "Bureau of Missing Hammers",
    ]

    /// Standing before the state, graded by how little it needs explaining.
    static let classOrigins = [
        "Peasant",
        "Worker",
        "Intellectual (regrettable)",
        "Lumpenproletariat",
        "Unknown — under investigation",
    ]

    /// Approved melodies of the people.
    static let melodies = [
        "Ode to the Tractor",
        "The Sun Rises on Schedule",
        "Five-Year Lullaby",
        "March of the Punctual Pigeons",
        "My Neighbour Sings For Me",
    ]

    /// The full register of suspicious behaviour. Four are drawn per comrade.
    static let suspiciousTraitPool = [
        "Owns two pairs of shoes",
        "Whistles in four tones",
        "Has been seen smiling without occasion",
        "Reads the newspaper before the state does",
        "Says 'good morning' to strangers",
        "Has a friend in Vienna",
        "Owns a radio with more than one station",
        "Knows the price of butter from memory",
        "Refused seconds, twice",
        "Sleeps with the window open (foreign air)",
        "Writes letters longer than postcards",
        "Pronounces 'croissant' correctly",
        "Does not queue when no one is queuing",
        "Hums melodies absent from the approved songbook",
        "Owns a mirror larger than the state standard",
        "Has opinions about the weather",
        "Keeps a diary (paper is a resource)",
        "Questions the second hand of clocks",
        "Nods at foreign films",
        "Is suspiciously punctual",
        "Is suspiciously unpunctual",
        "Owns more than one hat",
        "Has counted the bridge rivets aloud",
        "Prefers foreign soap",
        "Answers questions before the end",
        "Knows Jurica",
        "Loves the wrong sport",
        "Gardens decorative, not agricultural, vegetables",
        "Has read a map of Austria",
        "Told one joke that was funny",
        "Kept a calendar with unapproved holidays",
        "Bought salt twice in one day",
        "Waves at the border guard",
        "Applauds before the applause is cued",
        "Names cats after foreign cities",
        "Has an imaginary cousin",
        "Collects stamps of non-aligned countries",
    ]

    /// Four DISTINCT suspicions, Fisher–Yates over the pool, seeded by `rand`.
    static func drawTraits(rand: () -> Double = { Double.random(in: 0..<1) }) -> [String] {
        var bag = suspiciousTraitPool
        let draws = min(4, bag.count)
        for index in 0..<draws {
            let remaining = Double(bag.count - index)
            let raw = Int((rand() * remaining).rounded(.down))
            let pick = min(max(raw, index), bag.count - 1)
            if pick != index { bag.swapAt(index, pick) }
        }
        return Array(bag.prefix(draws))
    }

    /// The auto-issued membership number, in the Ministry's own words.
    static func membershipNumber(rand: () -> Double = { Double.random(in: 0..<1) }) -> String {
        "Number \(Int(rand() * 9000 + 1000))-bis, issued in someone else's name"
    }
}
