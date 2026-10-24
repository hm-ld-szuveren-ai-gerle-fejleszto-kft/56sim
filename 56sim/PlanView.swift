//
//  PlanView.swift
//  56sim
//
//  The Five-Year Plan dashboard: quotas are met by definition,
//  the arithmetic merely catches up later.
//

import Foundation
import SwiftUI

struct PlanView: View {
    @State private var store = StateStore.shared

    private var counts: (citizens: Int, broadcasts: Int, reports: [Report]) {
        _ = store.revision
        return (store.citizens().count, store.broadcasts().count, store.reports())
    }

    var body: some View {
        let informants = Set(counts.reports.map(\.informantName)).count
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        let progresses = FiveYearPlan.quotas.map {
            FiveYearPlan.progress(
                for: $0,
                informants: informants,
                dossiers: counts.citizens,
                broadcasts: counts.broadcasts,
                dayOfYear: dayOfYear
            )
        }
        let incomplete = progresses.contains { $0 < 1 }

        List {
            Section {
                Text(FiveYearPlan.banner(anyProgressIncomplete: incomplete))
                    .font(.system(.headline, design: .monospaced).bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.propagandaRedBanner, in: RoundedRectangle(cornerRadius: 8))
            }
            Section("Quotas") {
                ForEach(Array(FiveYearPlan.quotas.enumerated()), id: \.element.id) { index, quota in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quota.title)
                            .font(.headline)
                        ProgressView(value: progresses[index])
                        Text(
                            "\(FiveYearPlan.rawCount(for: quota, informants: informants, dossiers: counts.citizens, broadcasts: counts.broadcasts, dayOfYear: dayOfYear)) / \(quota.target) \(quota.unit)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Five-Year Plan")
    }
}

extension Color {
    fileprivate static let propagandaRedBanner = Color(red: 0.55, green: 0.0, blue: 0.05)
}
