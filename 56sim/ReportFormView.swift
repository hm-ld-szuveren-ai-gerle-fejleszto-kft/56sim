//
//  ReportFormView.swift
//  56sim
//
//  The Denunciation Hotline: your neighbour is talking, and so should you.
//

import SwiftData
import SwiftUI

struct ReportFormView: View {
    let citizen: Citizen

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var offence: String?
    @State private var details = ""
    @State private var informantName = "Comrade Operator"

    private static let offences = [
        "Hoarding Western jokes",
        "Insufficient enthusiasm at May Day",
        "Listening to enemy radio",
        "Joking about rationing",
        "Suspicious silence",
        "Keeping an unregistered cat",
        "Other",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Accusation") {
                    Picker("Offence", selection: $offence) {
                        Text("Select offence…").tag(nil as String?)
                        ForEach(Self.offences, id: \.self) { candidate in
                            Text(candidate).tag(candidate as String?)
                        }
                    }
                    TextField(
                        "Details (be specific, the file is hungry)", text: $details, axis: .vertical
                    )
                    .lineLimit(2...5)
                }
                Section("Informant") {
                    TextField("Informant name", text: $informantName)
                    Text("Anonymous reporting is encouraged but not permitted.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Report \(citizen.name)")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retract") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("File Report") {
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        guard let offence, !offence.isEmpty else { return false }
        return !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !informantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let offence else { return }
        let report = Report(
            offence: offence,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            informantName: informantName.trimmingCharacters(in: .whitespacesAndNewlines),
            citizen: citizen
        )
        modelContext.insert(report)
        TrustEnforcement.enforce(citizen)
    }
}
