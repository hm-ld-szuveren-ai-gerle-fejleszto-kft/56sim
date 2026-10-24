//
//  ReportFormView.swift
//  56sim
//
//  The Denunciation Hotline: your neighbour is talking, and so should you.
//

import SwiftUI

struct ReportFormView: View {
    let citizen: Citizen

    @State private var store = StateStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var offence: String?
    @State private var details = ""
    @State private var informantName =
        StateStore.shared.profile()?.alias ?? "Comrade Operator"

    /// A crime recognised by the People's Tribunal.
    struct Offence: Identifiable, Equatable {
        let title: String
        var id: String { title }

        static let all: [Offence] = [
            Offence(title: "Hoarding Western jokes"),
            Offence(title: "Insufficient enthusiasm at May Day"),
            Offence(title: "Listening to enemy radio"),
            Offence(title: "Joking about rationing"),
            Offence(title: "Suspicious silence"),
            Offence(title: "Keeping an unregistered cat"),
            Offence(title: "Other"),
        ]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Accusation") {
                    Picker("Offence", selection: $offence) {
                        Text("Select offence…").tag(nil as String?)
                        ForEach(Offence.all) { candidate in
                            Text(candidate.title).tag(candidate.title as String?)
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
        let informant = informantName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addReport(
            citizenId: citizen.id,
            targetName: citizen.name,
            offence: offence,
            category: "Unclassified",
            severity: "Watchlist",
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            informantName: informant
        )
        store.log(
            kind: .report,
            actor: informant,
            subject: citizen.name,
            text: "\(informant) denounced \(citizen.name): \(offence)."
        )
        TrustEnforcement.enforce(id: citizen.id)
    }
}

#Preview {
    ReportFormView(
        citizen: Citizen(id: 1, name: "Kovács Gyula", affiliation: "Factory #7"))
}
