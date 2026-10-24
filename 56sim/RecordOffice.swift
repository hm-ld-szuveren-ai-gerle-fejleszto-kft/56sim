//
//  RecordOffice.swift
//  56sim
//
//  The Ministry of Records: no dossier is ever wrong, only awaiting
//  a clerical correction demanded by history.
//

import Foundation

@MainActor
enum RecordOffice {
    /// Canned justifications, rotated deterministically by amendment count.
    static let justifications = [
        "The record has always shown this.",
        "A clerical correction demanded by history.",
        "Comrade Editor approves this revision.",
        "Recent scholarship (today) confirms this.",
        "Printing errors are the enemy's fault.",
        "The witness has been thanked and removed.",
        "The number is correct; the counting was wrong.",
        "Yesterday's ink has been disciplined.",
        "The archive grew into this truth naturally.",
        "A printing press dreamt it; we merely published.",
        "The previous version was foreign propaganda.",
        "Comrade Editor's red pencil is the only opinion.",
        "History corrected itself; we transcribed.",
        "The citizen's memory has been relieved of this fact.",
        "This always happened; the paperwork is catching up.",
        "A minor typographical insurrection has been suppressed.",
        "The figure was always this; previous figures were rumours.",
        "We are sparing you the older, worse version.",
        "The stamp disagrees with you, and the stamp is right.",
        "This entry was decided by a commission that has been dissolved.",
        "Contradictions are bourgeois; this is harmony.",
        "The map was wrong; the terrain has been reprimanded.",
        "The source is reliable because we printed it.",
        "An earlier draft of reality has been recycled.",
        "This revision was witnessed by an empty room, as is proper.",
        "The clerk involved has been promoted beyond scrutiny.",
        "Silence was costing the ministry paper.",
        "The file outranked the facts, as files should.",
        "This version tested better with workers.",
        "The original document is now classified as a rumour.",
        "Two truths entered; one truth left. Policy.",
        "The correction corrects a correction that never happened.",
        "Our historians are fast this time of year.",
        "The state prefers this version for aesthetic reasons.",
        "A footnote has been promoted to the main text.",
        "The previous number has retired.",
        "The witness now remembers it differently, under instruction.",
        "This fact arrived early and has been dated accordingly.",
        "The enemy's version is not being used here.",
        "A compromise between three archives.",
        "The typewriter jumped; we did.",
        "The record has been exorcised.",
        "We are honouring an old promise nobody remembers.",
        "This satisfies the quota for accuracy.",
        "The ministry has chosen joy, and this truth.",
        "It seemed better in the other language.",
        "The archive voted, and the archive is us.",
        "A temporary truth on permanent assignment.",
        "The correction is itself being corrected next quarter.",
        "No citizen remembers otherwise, and now nobody will.",
        "The glue is older than the objection.",
    ]

    /// Writes old→new amendment with a canned justification, then applies the change.
    static func amend(
        citizenId: Int64, field: String, old: String, new: String,
        store: StateStore = .shared
    ) {
        // A no-op reclassification is not history; the archive declines the duplicate.
        if field == "status", old == new { return }
        let justification =
            justifications[store.amendments(citizenId: citizenId).count % justifications.count]
        store.addAmendment(
            citizenId: citizenId,
            fieldName: field,
            oldValue: old,
            newValue: new,
            justification: justification
        )
        store.log(
            kind: .amendment,
            actor: "Ministry of Records",
            subject: store.citizen(id: citizenId)?.name ?? "a citizen",
            text: "\(field): \"\(old)\" → \"\(new)\" — \(justification)"
        )
        apply(field: field, value: new, to: citizenId, store: store)
    }

    /// Applies the corrected value. Only fields the Authority acknowledges exist.
    private static func apply(
        field: String, value: String, to citizenId: Int64, store: StateStore
    ) {
        guard let citizen = store.citizen(id: citizenId) else { return }
        switch field {
        case "status":
            // Labels are round-tripped from propagandaLabel; a mismatch means
            // the Ministry edited a field it should not have — ignore quietly.
            if let status = CitizenStatus.allCases.first(where: { $0.propagandaLabel == value }) {
                var updated = citizen
                updated.status = status
                store.setCitizen(updated)
            }
        case "dossierNote":
            var updated = citizen
            updated.dossierNote = value
            store.setCitizen(updated)
            TrustEnforcement.enforce(id: citizenId, store: store)
        default:
            break
        }
    }
}
