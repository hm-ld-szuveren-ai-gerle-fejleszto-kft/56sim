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
