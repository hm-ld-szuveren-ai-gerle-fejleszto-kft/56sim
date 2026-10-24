//
//  LeaderboardView.swift
//  56sim
//
//  Neighbour-watch leaderboard: honour where honour is due, suspicion
//  where suspicion is due. Rank is net vigilance — what you filed minus
//  what was filed against you — so denunciations demote visibly.
//

import Foundation
import SwiftUI

struct LeaderboardEntry: Identifiable {
    let name: String
    let filed: Int
    let received: Int
    var isYou: Bool = false

    var id: String { isYou ? "you:\(name)" : name }

    /// The only figure the Authority reads: vigilance minus suspicion earned.
    var net: Int { filed - received }

    /// Badge on the net; a rising `received` drags honoured names down.
    var badge: String {
        switch net {
        case 10...: "People's Antenna"
        case 5...9: "Iron Neighbour"
        case 3...4: "Order of the Red Star"
        default: "Loyal Ear"
        }
    }
}

enum Leaderboard {
    /// Rank everyone the reports mention — the comrade included — most
    /// vigilant first; ties settled alphabetically.
    static func entries(
        from reports: [Report], profileAlias: String?,
        citizenNames: [Int64: String] = [:]
    ) -> [LeaderboardEntry] {
        var filed: [String: Int] = [:]
        var received: [String: Int] = [:]
        for report in reports {
            filed[report.informantName, default: 0] += 1
            if let victim = victimName(of: report, citizenNames: citizenNames) {
                received[victim, default: 0] += 1
            }
        }

        let alias = profileAlias?.trimmingCharacters(in: .whitespacesAndNewlines)
        let youName = (alias?.isEmpty == false) ? alias : nil

        var names = Set(filed.keys).union(received.keys)
        if let youName { names.remove(youName) }
        var entries = names.map {
            LeaderboardEntry(
                name: $0, filed: filed[$0, default: 0], received: received[$0, default: 0])
        }
        if let youName {
            entries.append(
                LeaderboardEntry(
                    name: youName,
                    filed: filed[youName, default: 0],
                    received: received[youName, default: 0],
                    isYou: true
                )
            )
        }
        return entries.sorted {
            if $0.net != $1.net { return $0.net > $1.net }
            return $0.name < $1.name
        }
    }

    /// The denounced party: the named target, else the citizen whose dossier
    /// the report is stapled to.
    private static func victimName(
        of report: Report, citizenNames: [Int64: String]
    ) -> String? {
        if let target = report.targetName, !target.isEmpty { return target }
        if let citizenId = report.citizenId { return citizenNames[citizenId] }
        return nil
    }
}

struct LeaderboardView: View {
    @State private var store = StateStore.shared

    private var allReports: [Report] {
        _ = store.revision
        return store.reports()
    }

    private var entries: [LeaderboardEntry] {
        _ = store.revision
        let citizenNames = Dictionary(
            uniqueKeysWithValues: store.citizens().map { ($0.id, $0.name) })
        return Leaderboard.entries(
            from: allReports, profileAlias: store.profile()?.alias,
            citizenNames: citizenNames)
    }

    var body: some View {
        List(entries) { entry in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.name)
                            .font(.headline)
                        if entry.isYou {
                            Text("YOU")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red, in: Capsule())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(entry.badge)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("+\(entry.filed)/−\(entry.received)")
                    .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No informants yet. Suspicious.",
                    systemImage: "ear.trianglebadge.exclamationmark",
                    description: Text("Every good neighbour reports eventually.")
                )
            }
        }
        .navigationTitle("Neighbour-Watch")
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem {
                    ShareLink(item: shareText)
                }
            }
        }
    }

    private var shareText: String {
        let lines = entries.map { "\($0.name): \($0.filed) reports" }
        return "Order of the Red Star — top informants:\n" + lines.joined(separator: "\n")
    }
}
