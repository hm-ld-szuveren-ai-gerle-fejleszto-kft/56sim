//
//  BroadcastView.swift
//  56sim
//
//  State broadcast feed shown when no dossier is selected.
//

import SwiftData
import SwiftUI

struct BroadcastView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Broadcast.postedAt, order: .reverse) private var broadcasts: [Broadcast]

    @State private var isIssuingBroadcast = false
    @State private var gate = CheckpointGateRunner()

    var body: some View {
        List {
            ForEach(broadcasts) { broadcast in
                VStack(alignment: .leading, spacing: 4) {
                    Text(broadcast.title)
                        .font(.headline)
                    Text(broadcast.body)
                        .font(.body)
                    Text(
                        broadcast.postedAt,
                        format: Date.FormatStyle(date: .numeric, time: .shortened)
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: deleteBroadcasts)
        }
        .overlay {
            if broadcasts.isEmpty {
                ContentUnavailableView(
                    "No State Broadcasts",
                    systemImage: "megaphone.fill",
                    description: Text("The Ministry of Truth is preparing new directives.")
                )
            }
        }
        .navigationTitle("State Broadcasts")
        .toolbar {
            ToolbarItem {
                Button {
                    gate.request { isIssuingBroadcast = true }
                } label: {
                    Label("New Broadcast", systemImage: "megaphone")
                }
            }
        }
        .sheet(isPresented: $isIssuingBroadcast) {
            AddBroadcastView()
        }
        .checkpointGate(gate)
    }

    private func deleteBroadcasts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(broadcasts[index])
            }
        }
    }
}

/// Intake form for issuing a new state directive.
private struct AddBroadcastView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var proclamation = ""

    private var canIssue: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !proclamation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Directive") {
                    TextField("Title", text: $title)
                    TextField("Proclamation", text: $proclamation, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("Issue Broadcast")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Suppress") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Proclaim") {
                        issueBroadcast()
                    }
                    .disabled(!canIssue)
                }
            }
        }
    }

    private func issueBroadcast() {
        let broadcast = Broadcast(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: proclamation.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        modelContext.insert(broadcast)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        BroadcastView()
    }
    .modelContainer(for: [Citizen.self, Broadcast.self], inMemory: true)
}
