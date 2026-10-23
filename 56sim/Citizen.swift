//
//  Citizen.swift
//  56sim
//
//  Models of the People's Registry, State Protection Authority (ÁVH).
//

import Foundation
import SwiftData

/// Loyalty classification assigned by the Authority to each registered citizen.
enum CitizenStatus: String, Codable, CaseIterable {
    case surveilled
    case neutralized
    case cleared

    /// Bureaucratically reassuring label for dossier displays.
    var propagandaLabel: String {
        switch self {
        case .surveilled: "UNDER SURVEILLANCE"
        case .neutralized: "NEUTRALIZED"
        case .cleared: "CLEARED BY THE STATE"
        }
    }
}

@Model
final class Citizen {
    var name: String
    var affiliation: String
    var status: CitizenStatus
    var dossierNote: String
    var addedAt: Date
    @Relationship(deleteRule: .cascade) var reports: [Report] = []
    @Relationship(deleteRule: .cascade) var amendments: [RecordAmendment] = []

    init(
        name: String,
        affiliation: String,
        status: CitizenStatus = .surveilled,
        dossierNote: String = "",
        addedAt: Date = .now
    ) {
        self.name = name
        self.affiliation = affiliation
        self.status = status
        self.dossierNote = dossierNote
        self.addedAt = addedAt
    }
}

@Model
final class Broadcast {
    var title: String
    var body: String
    var postedAt: Date

    init(title: String, body: String, postedAt: Date = .now) {
        self.title = title
        self.body = body
        self.postedAt = postedAt
    }
}
