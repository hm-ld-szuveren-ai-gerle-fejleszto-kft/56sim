//
//  ProfileSetupView.swift
//  56sim
//
//  The setup of a comrade: before the republic lets you rule it, it asks
//  who you are, and writes it down forever.
//

import SwiftUI
import UniformTypeIdentifiers

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

    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var showImportConfirm = false
    @State private var importFailed = false

    private var canEnter: Bool {
        !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !alias.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        isImporting = true
                    } label: {
                        Label("Import a comrade's Republic", systemImage: "square.and.arrow.down")
                    }
                    Text(
                        "Or swear the oath below, comrade. One or the other — the state does not negotiate with double arrivals."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
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
            .fileImporter(
                isPresented: $isImporting, allowedContentTypes: [.data]
            ) { result in
                if case .success(let url) = result {
                    pendingImportURL = url
                    showImportConfirm = true
                }
            }
            .alert(
                "Importing overwrites the current People's Republic. History will be revised.",
                isPresented: $showImportConfirm
            ) {
                Button("Import") { performImport() }
                Button("Cancel", role: .cancel) { pendingImportURL = nil }
            }
            .overlay(alignment: .bottom) {
                if importFailed {
                    banner(
                        "The file was foreign. No revisions made.", tint: .red
                    ) { importFailed = false }
                    .task {
                        try? await Task.sleep(for: .seconds(6))
                        importFailed = false
                    }
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

    private func performImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        do {
            try store.importReplace(from: url)
        } catch {
            importFailed = true
        }
    }

    private func banner(_ text: String, tint: Color, onDismiss: @escaping () -> Void)
        -> some View
    {
        HStack {
            Text(text)
                .font(.subheadline.bold())
                .foregroundStyle(tint == .secondary ? Color.primary : Color.white)
            Spacer()
            Button("Dismiss") { onDismiss() }
                .font(.caption)
        }
        .padding()
        .background(
            tint == .secondary ? Color(.secondarySystemBackground) : tint,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .padding()
    }
}

#Preview {
    ProfileSetupView()
}
