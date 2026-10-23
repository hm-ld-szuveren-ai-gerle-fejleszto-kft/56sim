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
        score -= 15 * citizen.reports.count
        if !citizen.dossierNote.isEmpty {
            score -= 10
        }
        return min(100, max(0, score))
    }

    /// Below 30 → .surveilled overrides .cleared. Never touches .neutralized.
    static func enforce(_ citizen: Citizen) {
        if score(for: citizen) < 30, citizen.status == .cleared {
            citizen.status = .surveilled
        }
    }
}
