//
//  RecordOffice.swift
//  56sim
//
//  The Ministry of Records: no dossier is ever wrong, only awaiting
//  a clerical correction demanded by history.
//

import Foundation
import SwiftData

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
        _ citizen: Citizen, field: String, old: String, new: String, in context: ModelContext
    ) {
        let justification = justifications[citizen.amendments.count % justifications.count]
        let amendment = RecordAmendment(
            fieldName: field,
            oldValue: old,
            newValue: new,
            justification: justification,
            citizen: citizen
        )
        context.insert(amendment)
        apply(field: field, value: new, to: citizen)
    }

    /// Applies the corrected value. Only fields the Authority acknowledges exist.
    private static func apply(field: String, value: String, to citizen: Citizen) {
        switch field {
        case "status":
            // Labels are round-tripped from propagandaLabel; a mismatch means
            // the Ministry edited a field it should not have — ignore quietly.
            if let status = CitizenStatus.allCases.first(where: { $0.propagandaLabel == value }) {
                citizen.status = status
            }
        case "dossierNote":
            citizen.dossierNote = value
            TrustEnforcement.enforce(citizen)
        default:
            break
        }
    }
}
