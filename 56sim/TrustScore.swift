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
    /// dossier note exists; floor 0, cap 100.
    static func score(for citizen: Citizen) -> Int {
        var score = 100
        score -= 15 * citizen.reportCount
        if !citizen.dossierNote.isEmpty {
            score -= 10
        }
        return min(100, max(0, score))
    }

    /// Below 30 → .surveilled overrides .cleared. Never touches .neutralized.
    /// Reads the freshest row from the archive and writes back only on a flip.
    static func enforce(id: Int64, store: StateStore = .shared) {
        guard let citizen = store.citizen(id: id) else { return }
        if score(for: citizen) < 30, citizen.status == .cleared {
            var updated = citizen
            updated.status = .surveilled
            store.setCitizen(updated)
        }
    }
}
