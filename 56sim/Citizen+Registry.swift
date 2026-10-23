//
//  Citizen+Registry.swift
//  56sim
//
//  Paperwork of the People: denunciations (Reports) and retroactive edits
//  to dossiers (RecordAmendments). Both hang off a Citizen and are buried
//  with them on deletion (cascade).
//

import Foundation
import SwiftData

/// A denunciation filed by a vigilant neighbour against a citizen.
@Model
final class Report {
    var offence: String
    var details: String
    var informantName: String
    var reportedAt: Date
    var citizen: Citizen?

    init(
        offence: String,
        details: String,
        informantName: String,
        reportedAt: Date = .now,
        citizen: Citizen? = nil
    ) {
        self.offence = offence
        self.details = details
        self.informantName = informantName
        self.reportedAt = reportedAt
        self.citizen = citizen
    }
}

/// A retroactive correction of history, as ordered by the Ministry of Records.
@Model
final class RecordAmendment {
    var fieldName: String
    var oldValue: String
    var newValue: String
    var justification: String
    var amendedAt: Date
    var citizen: Citizen?

    init(
        fieldName: String,
        oldValue: String,
        newValue: String,
        justification: String,
        amendedAt: Date = .now,
        citizen: Citizen? = nil
    ) {
        self.fieldName = fieldName
        self.oldValue = oldValue
        self.newValue = newValue
        self.justification = justification
        self.amendedAt = amendedAt
        self.citizen = citizen
    }
}
