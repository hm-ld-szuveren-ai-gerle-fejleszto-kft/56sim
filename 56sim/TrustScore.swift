//
//  TrustScore.swift
//  56sim
//
//  The Trust-o-meter: loyalty is a number, and the number is always
//  suspiciously close to the surveillance threshold.
//

import Foundation

struct TrustEnforcement {
    /// Deterministic loyalty score. Base 100; −15 per denunciation; −10 if a
    /// dossier note exists; + the volatile `trustFlux` the simulator drifts;
    /// floor 0, cap 100.
    static func score(for citizen: Citizen) -> Int {
        min(100, max(0, TrustScore.raw(for: citizen)))
    }

    /// Below 30 → .surveilled overrides .cleared. At zero raw trust or five
    /// denunciations the Authority closes the file: .neutralized, once, the
    /// sealing logged as an amendment; the already-neutralized are silent.
    /// Reads the freshest row from the archive and writes back only on a flip.
    static func enforce(id: Int64, store: StateStore = .shared) {
        guard let citizen = store.citizen(id: id) else { return }
        if citizen.status != .neutralized,
            TrustScore.raw(for: citizen) <= 0 || citizen.reportCount >= 5
        {
            let oldLabel = citizen.status.propagandaLabel
            var updated = citizen
            updated.status = .neutralized
            store.setCitizen(updated)
            store.log(
                kind: .amendment, actor: "The Authority", subject: citizen.name,
                text: "status: \"\(oldLabel)\" → \"NEUTRALIZED\" — The file is closed.")
            return
        }
        if score(for: citizen) < 30, citizen.status == .cleared {
            var updated = citizen
            updated.status = .surveilled
            store.setCitizen(updated)
        }
    }
}

/// The unclamped arithmetic behind the Trust-o-meter, and the player's share
/// of it. Despair, unlike the score on display, may go below zero.
enum TrustScore {
    /// Base 100; −15 per denunciation; −10 if a dossier note exists; + the
    /// volatile `trustFlux` the simulator drifts. Unclamped on purpose.
    static func raw(for citizen: Citizen) -> Int {
        var score = 100
        score -= 15 * citizen.reportCount
        if !citizen.dossierNote.isEmpty {
            score -= 10
        }
        score += citizen.trustFlux
        return score
    }

    /// Denunciations filed against the player's alias. No comrade, no count.
    static func reportsAgainstPlayer(store: StateStore = .shared) -> Int {
        guard let alias = store.profile()?.alias else { return 0 }
        return store.reports().filter { $0.targetName == alias }.count
    }

    /// The comrade's unclamped loyalty figure; nil before enrolment.
    static func playerRaw(store: StateStore = .shared) -> Int? {
        guard store.profile() != nil else { return nil }
        return 100 - 15 * reportsAgainstPlayer(store: store) + store.kvInt("playerFlux")
    }
}

/// When the comrade's own figure reaches zero, the Ministry of Love closes
/// the file — exactly once, because the record never repeats a death sentence.
enum PlayerFate {
    /// True when this call performed the neutralization.
    @discardableResult
    static func evaluate(store: StateStore = .shared) -> Bool {
        guard let profile = store.profile(),
            store.kvString("player_fate") == nil,
            let raw = TrustScore.playerRaw(store: store),
            raw <= 0
        else { return false }
        store.setKV("player_fate", value: "neutralized")
        store.log(
            kind: .player, actor: "The Ministry of Love", subject: profile.alias,
            text: "Your file was closed. You loved Big Brother.")
        return true
    }
}
