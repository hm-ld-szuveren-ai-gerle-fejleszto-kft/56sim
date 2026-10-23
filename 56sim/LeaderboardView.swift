//
//  LeaderboardView.swift
//  56sim
//
//  Neighbour-watch leaderboard: honour where honour is due, suspicion
//  where suspicion is due.
//

import SwiftData
import SwiftUI

struct LeaderboardEntry: Identifiable {
    let name: String
    let reportCount: Int
    var id: String { name }

    /// Highest badge earned; nobody is beneath "Loyal Ear" once they talk.
    var badge: String {
        switch reportCount {
        case 10...: "People's Antenna"
        case 5...9: "Iron Neighbour"
        case 3...4: "Order of the Red Star"
        default: "Loyal Ear"
        }
    }
}

enum Leaderboard {
    /// Group by informant, most talkative first; ties settled alphabetically.
    static func entries(from reports: [Report]) -> [LeaderboardEntry] {
        let grouped = Dictionary(grouping: reports, by: \.informantName)
        return
            grouped
            .map { LeaderboardEntry(name: $0.key, reportCount: $0.value.count) }
            .sorted {
                if $0.reportCount != $1.reportCount { return $0.reportCount > $1.reportCount }
                return $0.name < $1.name
            }
    }
}

struct LeaderboardView: View {
    @Query private var allReports: [Report]

    private var entries: [LeaderboardEntry] { Leaderboard.entries(from: allReports) }

    var body: some View {
        List(entries) { entry in
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.headline)
                    Text(entry.badge)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.15), in: Capsule())
                        .foregroundStyle(.red)
                }
                Spacer()
                Text("\(entry.reportCount) report\(entry.reportCount == 1 ? "" : "s")")
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
        let lines = entries.map { "\($0.name): \($0.reportCount) reports" }
        return "Order of the Red Star — top informants:\n" + lines.joined(separator: "\n")
    }
}
