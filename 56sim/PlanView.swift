//
//  PlanView.swift
//  56sim
//
//  The Five-Year Plan dashboard: quotas are met by definition,
//  the arithmetic merely catches up later. The congress sits, the
//  commission inspects, and the auditor is expected at any moment.
//

import Foundation
import SwiftUI

struct PlanView: View {
    @State private var store = StateStore.shared
    @State private var commission = PlanCommission(store: StateStore.shared)

    /// Inspection outcomes still warm, per quota, since the last visit.
    @State private var inspectionTexts: [String: String] = [:]

    var body: some View {
        let _ = store.revision
        List {
            Section {
                Text(
                    FiveYearPlan.banner(
                        anyProgressIncomplete: FiveYearPlan.quotas.contains {
                            commission.progress(for: $0) < 1
                        }))
                    .font(.system(.headline, design: .monospaced).bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.propagandaRedBanner, in: RoundedRectangle(cornerRadius: 8))
                Text("Year \(commission.year) · quarter \(commission.quarter)")
                    .font(.system(.subheadline, design: .monospaced).bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundStyle(.secondary)
            }
            if let decree = commission.decreeToast {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(decree)
                            .font(.system(.callout, design: .monospaced).bold())
                            .foregroundStyle(.red)
                        Button("The people have read it") {
                            commission.decreeToast = nil
                        }
                        .font(.caption)
                    }
                }
            }
            Section("Congress of the Quarter") {
                congressCard
            }
            Section("Quotas") {
                ForEach(FiveYearPlan.quotas) { quota in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(quota.title)
                            .font(.headline)
                        ProgressView(value: commission.progress(for: quota))
                        Text(
                            "\(commission.rawCount(for: quota)) / \(quota.target) \(quota.unit)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        if let text = inspectionTexts[quota.id] {
                            Text(text)
                                .font(.caption)
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                        Button("Inspect") {
                            if let inspection = commission.inspect(quota) {
                                inspectionTexts[quota.id] = inspection.text
                            }
                        }
                        .disabled(commission.inspectedToday(quota))
                        if commission.inspectedToday(quota) {
                            Text("The commission is already embarrassed.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            Section("Proclamations of this commission") {
                let rows = commission.proclamations
                if rows.isEmpty {
                    Text("The commission has not yet proclaimed itself busy.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(rows, id: \.self) { line in
                        Text(line)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("Five-Year Plan")
        .sheet(isPresented: Binding(
            get: { commission.auditorPending },
            set: { _ in }  // only an answer dismisses the auditor
        )) {
            auditorSheet
        }
    }

    /// Three policy cards for the quarter, or the verdict on year five.
    @ViewBuilder
    private var congressCard: some View {
        if commission.fifthYearAbolished {
            Text("The fifth year has been abolished as bourgeois. The plan is eternal.")
                .font(.callout)
                .italic()
                .foregroundStyle(.secondary)
        } else if commission.congressHeld {
            Text("The congress has spoken this quarter. History awaits the next.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(Congress.cards(year: commission.year, quarter: commission.quarter)) { policy in
                Button {
                    commission.adopt(policy)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(policy.title)
                            .font(.headline)
                        Text(policy.effect)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var auditorSheet: some View {
        VStack(spacing: 20) {
            Text("THE AUDITOR")
                .font(.system(.headline, design: .monospaced).bold())
                .foregroundStyle(.red)
            Text(PlanEvents.auditorChallenge)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Reaffirm the numbers harder") {
                commission.answerAuditorByLying()
            }
            .buttonStyle(.borderedProminent)
            Button("Blame a neighbour for the clerical error") {
                commission.answerAuditorByBlame()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .presentationDetents([.medium])
    }
}

extension Color {
    fileprivate static let propagandaRedBanner = Color(red: 0.55, green: 0.0, blue: 0.05)
}

#Preview {
    NavigationStack {
        PlanView()
    }
}
