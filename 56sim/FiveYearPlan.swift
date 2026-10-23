//
//  FiveYearPlan.swift
//  56sim
//
//  The Five-Year Plan: fulfilled in four, because five years of waiting
//  would admit the plan takes five years.
//

import Foundation

struct Quota: Identifiable {
    let id: String
    let title: String
    let unit: String
    let target: Int
}

enum FiveYearPlan {
    static let quotas: [Quota] = [
        Quota(id: "informants", title: "Recruit informants", unit: "ears", target: 10_000),
        Quota(id: "dossiers", title: "Dossiers compiled", unit: "files", target: 1_000),
        Quota(id: "steel", title: "Steel produced", unit: "tonnes (claimed)", target: 400),
        Quota(id: "bananas", title: "Bananas stockpiled", unit: "kg", target: 1_000_000),
        Quota(id: "broadcasts", title: "Broadcasts proclaimed", unit: "shouts", target: 500),
    ]

    /// Raw claimed output for a quota — the number printed under the bar.
    static func rawCount(
        for quota: Quota,
        informants: Int,
        dossiers: Int,
        broadcasts: Int,
        dayOfYear: Int
    ) -> Int {
        switch quota.id {
        case "informants": informants
        case "dossiers": dossiers
        case "broadcasts": broadcasts
        case "steel": dossiers * 3
        case "bananas": dayOfYear % 7
        default: 0
        }
    }

    /// progress 0...1, clamped. informants = distinct informantName count,
    /// dossiers = citizen count, broadcasts = broadcast count,
    /// steel = citizenCount * 3 (claimed), bananas = dayOfYear % 7 (state says so).
    static func progress(
        for quota: Quota,
        informants: Int,
        dossiers: Int,
        broadcasts: Int,
        dayOfYear: Int
    ) -> Double {
        let raw = Double(
            rawCount(
                for: quota,
                informants: informants,
                dossiers: dossiers,
                broadcasts: broadcasts,
                dayOfYear: dayOfYear
            ))
        return min(1, max(0, raw / Double(quota.target)))
    }

    /// The plan is always four years early; the fourth year is not yet found.
    static func banner(anyProgressIncomplete: Bool) -> String {
        anyProgressIncomplete
            ? "PLAN FULFILLED IN 4 YEARS! (year 4 not found)"
            : "GLORY: plan fulfilled 4 years early."
    }
}
