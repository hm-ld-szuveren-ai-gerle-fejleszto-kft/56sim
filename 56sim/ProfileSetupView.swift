//
//  ProfileSetupView.swift
//  56sim
//
//  The setup of a comrade: before the republic lets you rule it, it asks
//  who you are, and writes it down forever.
//

import SwiftUI

/// Full-screen wizard shown until a comrade is enrolled.
struct ProfileSetupView: View {
    @State private var store = StateStore.shared

    @State private var fullName = ""
    @State private var alias = ""
    @State private var affiliation = Profile.affiliations[0]
    @State private var classOrigin = Profile.classOrigins[0]
    @State private var district = ""
    @State private var yearsLabor = 18
    @State private var suspiciousTrait = ""
    @State private var traits = Profile.drawTraits()
    @State private var melody = Profile.melodies[0]
    @State private var membershipNumber = Profile.membershipNumber()

    private var canEnter: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Who You Are") {
                    TextField("Full name", text: $fullName)
                    TextField("Underground alias", text: $alias)
                }
                Section("Labour & Standing") {
                    Picker("Affiliation", selection: $affiliation) {
                        ForEach(Profile.affiliations, id: \.self) { place in
                            Text(place).tag(place)
                        }
                    }
                    Picker("Class origin", selection: $classOrigin) {
                        ForEach(Profile.classOrigins, id: \.self) { origin in
                            Text(origin).tag(origin)
                        }
                    }
                    TextField("District & street", text: $district)
                    Stepper("Years of honest labour: \(yearsLabor)", value: $yearsLabor, in: 0...60)
                }
                Section("The File") {
                    TextField("One suspicious trait", text: $suspiciousTrait, axis: .vertical)
                        .lineLimit(1...3)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suspicious traits drawn by the Ministry")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        ForEach(traits, id: \.self) { trait in
                            Text("• \(trait)")
                                .font(.subheadline)
                        }
                        Button("Draw new suspicions") {
                            traits = Profile.drawTraits()
                        }
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red.opacity(0.35), lineWidth: 1)
                    )
                    Text(membershipNumber)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Music of the People") {
                    Picker("Melody", selection: $melody) {
                        ForEach(Profile.melodies, id: \.self) { tune in
                            Text(tune).tag(tune)
                        }
                    }
                }
            }
            .navigationTitle("Enrol a Comrade")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enter the People's Republic") {
                        enrol()
                    }
                    .disabled(!canEnter)
                }
            }
        }
    }

    private func enrol() {
        let profile = ComradeProfile(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            alias: alias.trimmingCharacters(in: .whitespacesAndNewlines),
            affiliation: affiliation,
            classOrigin: classOrigin,
            district: district.trimmingCharacters(in: .whitespacesAndNewlines),
            membershipNumber: membershipNumber,
            suspiciousTrait: suspiciousTrait.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedTraits: traits,
            melody: melody,
            yearsLabor: yearsLabor
        )
        store.saveProfile(profile)
        store.log(
            kind: .profile, actor: profile.alias, subject: profile.alias,
            text: "\(profile.alias) enrolled as a comrade of the republic.")
        StateHaptics.shared.play(.tankRumble)
    }
}

#Preview {
    ProfileSetupView()
}
