//
//  MembershipCardView.swift
//  56sim
//
//  The party membership card: proof that the state knows you, which is
//  the only kind of proof that counts.
//

import SwiftUI

/// Read-only card of the enrolled comrade.
struct MembershipCardView: View {
    @State private var store = StateStore.shared

    var body: some View {
        let _ = store.revision
        let profile = store.profile()
        Form {
            if let profile {
                Section("The Comrade") {
                    LabeledContent("Full name", value: profile.fullName)
                    LabeledContent("Underground alias", value: profile.alias)
                    LabeledContent("Affiliation", value: profile.affiliation)
                    LabeledContent("Class origin", value: profile.classOrigin)
                    LabeledContent("District & street", value: profile.district)
                    LabeledContent("Years of honest labour", value: "\(profile.yearsLabor)")
                }
                Section("Membership") {
                    Text(profile.membershipNumber)
                        .font(.callout.monospaced())
                }
                Section("The File") {
                    if !profile.suspiciousTrait.isEmpty {
                        Label(profile.suspiciousTrait, systemImage: "exclamationmark.triangle")
                    }
                    ForEach(profile.assignedTraits, id: \.self) { trait in
                        Label(trait, systemImage: "folder.badge.questionmark")
                            .font(.subheadline)
                    }
                }
                Section("Music of the People") {
                    Label(profile.melody, systemImage: "music.note")
                }
                Section {
                    Text(
                        "Card issued \(profile.createdAt, format: Date.FormatStyle(date: .numeric)) by the Ministry of Membership Affairs."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    Text("No membership card. The republic does not know you yet.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("My Party Membership Card")
    }
}

#Preview {
    NavigationStack {
        MembershipCardView()
    }
}
