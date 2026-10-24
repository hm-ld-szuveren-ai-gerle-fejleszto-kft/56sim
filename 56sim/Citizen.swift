//
//  Citizen.swift
//  56sim
//
//  Models of the People's Registry, State Protection Authority (ÁVH).
//

import Foundation

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

