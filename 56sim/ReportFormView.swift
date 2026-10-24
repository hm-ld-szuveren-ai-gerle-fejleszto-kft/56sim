//
//  ReportFormView.swift
//  56sim
//
//  The Denunciation Hotline: your neighbour is talking, and so should you.
//  The crime catalogue is searchable by category and severity, because
//  an imprecise accusation is itself suspicious.
//

import SwiftUI

/// The departments of suspicion recognised by the People's Tribunal.
enum OffenceCategory: String, CaseIterable {
    case musical, agricultural, verbal, animals, timekeeping
    case fashion, hygiene, infrastructure, folklore, paperwork

    var label: String {
        switch self {
        case .musical: "Musical"
        case .agricultural: "Agricultural"
        case .verbal: "Verbal"
        case .animals: "Animals"
        case .timekeeping: "Timekeeping"
        case .fashion: "Fashion"
        case .hygiene: "Hygiene"
        case .infrastructure: "Infrastructure"
        case .folklore: "Folklore"
        case .paperwork: "Paperwork"
        }
    }
}

/// How closely the state will look at the accused.
enum OffenceSeverity: String, CaseIterable {
    case watchlist, reeducation, consultancy

    var label: String {
        switch self {
        case .watchlist: "Watchlist"
        case .reeducation: "Re-education"
        case .consultancy: "Agricultural Consultancy"
        }
    }

    /// The Authority reads dots, not words.
    var marks: String {
        switch self {
        case .watchlist: "●"
        case .reeducation: "●●"
        case .consultancy: "●●●"
        }
    }
}

struct ReportFormView: View {
    let citizen: Citizen

    @State private var store = StateStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var offence: Offence?
    @State private var details = ""
    @State private var informantName =
        StateStore.shared.profile()?.alias ?? "Comrade Operator"
    @State private var showCatalogue = false
    @State private var search = ""
    @State private var filterCategory: OffenceCategory?
    @State private var filterSeverity: OffenceSeverity?

    /// A crime recognised by the People's Tribunal. The full catalogue:
    /// seven classic offences plus the expanded appendix of the Republic.
    struct Offence: Identifiable, Equatable {
        let title: String
        let category: OffenceCategory
        let severity: OffenceSeverity
        var id: String { title }

        static let all: [Offence] = [
            // The seven classic crimes, in their historic order.
            Offence(title: "Hoarding Western jokes", category: .verbal, severity: .reeducation),
            Offence(
                title: "Insufficient enthusiasm at May Day", category: .folklore,
                severity: .watchlist),
            Offence(
                title: "Listening to enemy radio", category: .musical, severity: .consultancy),
            Offence(title: "Joking about rationing", category: .verbal, severity: .reeducation),
            Offence(title: "Suspicious silence", category: .verbal, severity: .watchlist),
            Offence(
                title: "Keeping an unregistered cat", category: .animals, severity: .reeducation),
            Offence(title: "Other", category: .paperwork, severity: .watchlist),
            // Musical.
            Offence(title: "Whistling in four tones", category: .musical, severity: .reeducation),
            Offence(
                title: "Humming an unapproved melody", category: .musical, severity: .watchlist),
            Offence(
                title: "Owning an accordion with foreign memories", category: .musical,
                severity: .watchlist),
            Offence(
                title: "Applauding the wrong waltz", category: .musical, severity: .watchlist),
            Offence(
                title: "Singing two beats late", category: .musical, severity: .watchlist),
            Offence(
                title: "Playing jazz near a tractor", category: .musical, severity: .consultancy),
            Offence(
                title: "Naming a cat after a foreign composer", category: .musical,
                severity: .reeducation),
            Offence(
                title: "Dancing without a permit", category: .musical, severity: .watchlist),
            Offence(
                title: "Knowing the western charts by heart", category: .musical,
                severity: .consultancy),
            Offence(
                title: "Percussion without purpose", category: .musical, severity: .watchlist),
            // Agricultural.
            Offence(
                title: "Hoarding approved seeds", category: .agricultural,
                severity: .reeducation),
            Offence(
                title: "A garden of decorative vegetables", category: .agricultural,
                severity: .watchlist),
            Offence(
                title: "An unregistered orchard", category: .agricultural,
                severity: .reeducation),
            Offence(
                title: "Questioning the length of a potato", category: .agricultural,
                severity: .watchlist),
            Offence(
                title: "Feeding a state cow unapproved lyrics", category: .agricultural,
                severity: .watchlist),
            Offence(
                title: "Selling eggs outside the quota", category: .agricultural,
                severity: .consultancy),
            Offence(
                title: "Composting propaganda", category: .agricultural, severity: .reeducation),
            Offence(
                title: "A rooster crowning unpunctually", category: .agricultural,
                severity: .watchlist),
            // Verbal.
            Offence(
                title: "Laughing before the punchline", category: .verbal, severity: .watchlist),
            Offence(
                title: "Whispering in two languages", category: .verbal, severity: .reeducation),
            Offence(
                title: "Saying 'yesterday' too fondly", category: .verbal, severity: .watchlist),
            Offence(
                title: "Answering before the question ends", category: .verbal,
                severity: .watchlist),
            Offence(
                title: "Misquoting a leader (improved version)", category: .verbal,
                severity: .reeducation),
            Offence(
                title: "Telling a joke that was funny", category: .verbal,
                severity: .consultancy),
            Offence(
                title: "Saying 'please' to a foreigner", category: .verbal, severity: .watchlist),
            Offence(
                title: "Using three adjectives when one is planned", category: .verbal,
                severity: .watchlist),
            Offence(
                title: "Naming the weather incorrectly", category: .verbal, severity: .watchlist),
            Offence(
                title: "Correcting a clerk (twice)", category: .verbal, severity: .consultancy),
            // Animals.
            Offence(
                title: "A dog without loyalty papers", category: .animals, severity: .watchlist),
            Offence(
                title: "A pigeon suspected of messaging", category: .animals,
                severity: .reeducation),
            Offence(
                title: "A cat reading a newspaper", category: .animals, severity: .reeducation),
            Offence(
                title: "Naming a hamster after the plan", category: .animals,
                severity: .watchlist),
            Offence(
                title: "An unregistered goldfish", category: .animals, severity: .watchlist),
            Offence(
                title: "Teaching a parrot foreign idioms", category: .animals,
                severity: .consultancy),
            Offence(
                title: "A horse that refuses statistics", category: .animals,
                severity: .watchlist),
            // Timekeeping.
            Offence(
                title: "Being punctual without reason", category: .timekeeping,
                severity: .watchlist),
            Offence(
                title: "Owning two clocks of different opinions", category: .timekeeping,
                severity: .reeducation),
            Offence(
                title: "Daring daylight saving", category: .timekeeping, severity: .watchlist),
            Offence(
                title: "Arriving to the queue early", category: .timekeeping,
                severity: .watchlist),
            Offence(
                title: "Counting the bridge rivets aloud", category: .timekeeping,
                severity: .reeducation),
            Offence(
                title: "Suggesting the week needs a spare day", category: .timekeeping,
                severity: .watchlist),
            Offence(
                title: "Wearing a watch backwards", category: .timekeeping, severity: .watchlist),
            // Fashion.
            Offence(
                title: "Owns more than one hat", category: .fashion, severity: .watchlist),
            Offence(
                title: "Socks of mismatched optimism", category: .fashion, severity: .watchlist),
            Offence(title: "A coat of foreign cut", category: .fashion, severity: .reeducation),
            Offence(
                title: "Buttons polished out of turn", category: .fashion, severity: .watchlist),
            Offence(
                title: "Ironing the flag's wrong side", category: .fashion,
                severity: .reeducation),
            Offence(
                title: "Wearing colour on a grey Thursday", category: .fashion,
                severity: .watchlist),
            // Hygiene.
            Offence(
                title: "Bought salt twice in one day", category: .hygiene, severity: .watchlist),
            Offence(
                title: "Suspiciously clean hands for a worker", category: .hygiene,
                severity: .watchlist),
            Offence(title: "Using foreign soap", category: .hygiene, severity: .reeducation),
            Offence(
                title: "A bath beyond the allotted schedule", category: .hygiene,
                severity: .watchlist),
            Offence(
                title: "Combing hair against the grain of history", category: .hygiene,
                severity: .watchlist),
            // Infrastructure.
            Offence(
                title: "Admiring a bridge structure", category: .infrastructure,
                severity: .consultancy),
            Offence(
                title: "Counting tram passengers", category: .infrastructure,
                severity: .watchlist),
            Offence(
                title: "Entering through the wrong factory door", category: .infrastructure,
                severity: .watchlist),
            Offence(
                title: "Standing still at a crossroads", category: .infrastructure,
                severity: .watchlist),
            Offence(
                title: "Questioning the lift in a ground-floor building",
                category: .infrastructure, severity: .watchlist),
            Offence(
                title: "Photographing a queue", category: .infrastructure,
                severity: .reeducation),
            Offence(
                title: "Lingering near the border timetable", category: .infrastructure,
                severity: .reeducation),
            Offence(
                title: "Asking which trains are full", category: .infrastructure,
                severity: .watchlist),
            // Folklore.
            Offence(
                title: "Telling children the old stories", category: .folklore,
                severity: .reeducation),
            Offence(
                title: "Believing the barometer", category: .folklore, severity: .watchlist),
            Offence(
                title: "Celebrating an unapproved holiday", category: .folklore,
                severity: .reeducation),
            Offence(title: "Saying 'God willing'", category: .folklore, severity: .watchlist),
            Offence(
                title: "Preferring the foreign version of a folk song", category: .folklore,
                severity: .consultancy),
            Offence(
                title: "Waving at the border guard", category: .folklore, severity: .reeducation),
            Offence(title: "Dreaming of a circus", category: .folklore, severity: .watchlist),
            // Paperwork.
            Offence(
                title: "A diary (paper is a resource)", category: .paperwork,
                severity: .consultancy),
            Offence(
                title: "Postcards longer than policy", category: .paperwork,
                severity: .watchlist),
            Offence(
                title: "Filing a form in the wrong drawer", category: .paperwork,
                severity: .watchlist),
            Offence(
                title: "Asking for a receipt twice", category: .paperwork, severity: .watchlist),
            Offence(
                title: "Reading the newspaper backwards for subtext", category: .paperwork,
                severity: .reeducation),
            Offence(
                title: "Correspondence: quantity noted", category: .paperwork,
                severity: .watchlist),
            Offence(
                title: "Admitting you read the terms", category: .paperwork,
                severity: .watchlist),
            Offence(
                title: "Keeping a calendar with unapproved holidays", category: .paperwork,
                severity: .reeducation),
        ]

        /// The charge the sheet files when the catalogue has no such crime.
        static let creative = Offence(
            title: "Other (the file is creative)", category: .paperwork, severity: .watchlist)

        /// Pure catalogue filter: search + category + severity compose.
        static func filter(
            search: String, category: OffenceCategory?, severity: OffenceSeverity?
        ) -> [Offence] {
            all.filter { candidate in
                (search.isEmpty || candidate.title.localizedCaseInsensitiveContains(search))
                    && (category == nil || candidate.category == category)
                    && (severity == nil || candidate.severity == severity)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Accusation") {
                    Button {
                        showCatalogue = true
                    } label: {
                        HStack {
                            Text("Offence")
                            Spacer()
                            Text(offence?.title ?? "Select offence…")
                                .foregroundStyle(offence == nil ? .secondary : .primary)
                        }
                    }
                    .foregroundStyle(.primary)
                    if let offence {
                        Text(
                            "\(offence.category.label) · \(offence.severity.label) \(offence.severity.marks)"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .sheet(isPresented: $showCatalogue) {
                offenceCatalogue
            }
        }
    }

    /// The searchable crime catalogue: every accusation the file can hold.
    private var offenceCatalogue: some View {
        NavigationStack {
            let results = Offence.filter(
                search: search, category: filterCategory, severity: filterSeverity)
            List(results) { candidate in
                Button {
                    offence = candidate
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.title)
                            Text(
                                "\(candidate.category.label) · \(candidate.severity.label) \(candidate.severity.marks)"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if offence == candidate {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.propagandaRed)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .overlay {
                if results.isEmpty {
                    VStack(spacing: 12) {
                        Text("No such crime exists. Yet.")
                        Button("Charge them anyway") {
                            offence = Offence.creative
                            showCatalogue = false
                        }
                    }
                    .padding()
                }
            }
            .searchable(text: $search, prompt: "Search offences…")
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 4) {
                    chipRow(
                        title: "Category",
                        titles: OffenceCategory.allCases.map(\.label),
                        selection: categoryLabelBinding
                    )
                    chipRow(
                        title: "Severity",
                        titles: OffenceSeverity.allCases.map(\.label),
                        selection: severityLabelBinding
                    )
                }
                .padding(.vertical, 6)
                .background(.bar)
            }
            .navigationTitle("Crimes of the People")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retract") { showCatalogue = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Return to the file") { showCatalogue = false }
                }
            }
        }
    }

    private var categoryLabelBinding: Binding<String?> {
        Binding(
            get: { filterCategory?.label },
            set: { label in
                filterCategory = label.flatMap { l in
                    OffenceCategory.allCases.first { $0.label == l }
                }
            }
        )
    }

    private var severityLabelBinding: Binding<String?> {
        Binding(
            get: { filterSeverity?.label },
            set: { label in
                filterSeverity = label.flatMap { l in
                    OffenceSeverity.allCases.first { $0.label == l }
                }
            }
        )
    }

    /// One scrollable row of filter chips: "All" plus every option; the
    /// active chip is red, tapping it again clears the filter.
    private func chipRow(
        title: String, titles: [String], selection: Binding<String?>
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("\(title):")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                chip(title: "All", isOn: selection.wrappedValue == nil) {
                    selection.wrappedValue = nil
                }
                ForEach(titles, id: \.self) { chipTitle in
                    chip(title: chipTitle, isOn: selection.wrappedValue == chipTitle) {
                        selection.wrappedValue = selection.wrappedValue == chipTitle ? nil : chipTitle
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isOn ? Color.propagandaRed.opacity(0.25) : Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var canSave: Bool {
        guard let offence, !offence.title.isEmpty else { return false }
        return !details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !informantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard let offence else { return }
        let informant = informantName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addReport(
            citizenId: citizen.id,
            targetName: citizen.name,
            offence: offence.title,
            category: offence.category.rawValue,
            severity: offence.severity.rawValue,
            details: details.trimmingCharacters(in: .whitespacesAndNewlines),
            informantName: informant
        )
        store.log(
            kind: .report,
            actor: informant,
            subject: citizen.name,
            text: "\(informant) denounced \(citizen.name): \(offence.title)."
        )
        TrustEnforcement.enforce(id: citizen.id)
    }
}

#Preview {
    ReportFormView(
        citizen: Citizen(id: 1, name: "Kovács Gyula", affiliation: "Factory #7"))
}
