//
//  AddCitizenView.swift
//  56sim
//
//  Intake form for filing a new citizen dossier.
//

import SwiftUI

struct AddCitizenView: View {
    @State private var store = StateStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var affiliation = ""
    @State private var dossierNote = ""

    private var canFileReport: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Suspect Identity") {
                    TextField("Name", text: $name)
                    TextField("Affiliation", text: $affiliation)
                }
                Section("Evidence & Observations") {
                    TextField("Dossier note (optional)", text: $dossierNote, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Text("Reporting on your neighbours is a patriotic duty.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("File New Dossier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Withdraw") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("File Report") {
                        fileReport()
                    }
                    .disabled(!canFileReport)
                }
            }
        }
    }

    private func fileReport() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAffiliation = affiliation.trimmingCharacters(in: .whitespacesAndNewlines)
        let affiliation = trimmedAffiliation.isEmpty ? "Undocumented element" : trimmedAffiliation
        store.addCitizen(
            name: trimmedName,
            affiliation: affiliation,
            dossierNote: dossierNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        store.log(
            kind: .citizen,
            actor: store.profile()?.alias ?? "The Registry",
            subject: trimmedName,
            text: "Dossier opened on \(trimmedName), \(affiliation)."
        )
        dismiss()
    }
}

#Preview {
    AddCitizenView()
}
