//
//  ContentView.swift
//  56sim
//
//  Created by Reka Papp on 2026-10-23.
//

import SwiftUI
import UniformTypeIdentifiers

/// Dashboard of the People's Registry: citizen dossiers on the left,
/// selected dossier (or the state broadcast feed) on the right.
/// Until a comrade is enrolled, the whole republic is a setup wizard.
struct ContentView: View {
    @State private var store = StateStore.shared
    @State private var simulator = PeopleSimulator.shared

    @State private var selectedCitizenId: Int64?
    @State private var isAddingCitizen = false
    @State private var isShowingPropaganda = false
    @State private var isImporting = false
    @State private var pendingImportURL: URL?
    @State private var showImportConfirm = false
    @State private var importFailed = false
    @State private var showSuicide = false
    @State private var lifeCaption: String?
    @State private var shareURL: ShareableURL?
    @AppStorage("stateHapticsMuted") private var stateSilenced = false

    private var citizens: [Citizen] {
        _ = store.revision
        return store.citizens()
    }

    private var enrolled: Bool {
        _ = store.revision
        return store.profile() != nil
    }

    var body: some View {
        if enrolled {
            registry
        } else {
            ProfileSetupView()
        }
    }

    private var registry: some View {
        NavigationSplitView {
            List(selection: $selectedCitizenId) {
                ForEach(citizens) { citizen in
                    CitizenRow(citizen: citizen)
                        .tag(citizen.id)
                }
                .onDelete(perform: deleteCitizens)
            }
            .overlay {
                if citizens.isEmpty {
                    ContentUnavailableView(
                        "No Dossiers Filed",
                        systemImage: "person.badge.shield.exclamationmark",
                        description: Text("The People's Registry awaits its first informant.")
                    )
                }
            }
            .navigationTitle("ÁVH Registry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingPropaganda = true
                    } label: {
                        Label("Propaganda", systemImage: "megaphone.fill")
                    }
                    .accessibilityLabel("Open Propaganda")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button {
                        isAddingCitizen = true
                    } label: {
                        Label("Add Citizen", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Menu {
                        NavigationLink(value: Ministry.card) {
                            Label("My Party Membership Card", systemImage: "person.text.rectangle")
                        }
                        NavigationLink(value: Ministry.leaderboard) {
                            Label("Neighbour-Watch Leaderboard", systemImage: "list.number")
                        }
                        NavigationLink(value: Ministry.plan) {
                            Label("Five-Year Plan", systemImage: "chart.bar.doc.horizontal")
                        }
                        NavigationLink(value: Ministry.defector) {
                            Label("Defector: Escape 1956", systemImage: "figure.run")
                        }
                        NavigationLink(value: Ministry.radio) {
                            Label("Radio Moscow", systemImage: "radio")
                        }
                        NavigationLink(value: Ministry.poster) {
                            Label("Poster Foundry", systemImage: "paintbrush.pointed.fill")
                        }
                        NavigationLink(value: Ministry.interrogation) {
                            Label("Interrogation Room 407", systemImage: "lamp.desk")
                        }
                        Divider()
                        NavigationLink(value: Ministry.archive) {
                            Label("The Archive of the People", systemImage: "doc.text.magnifyingglass")
                        }
                        Divider()
                        Button("Export my Republic") {
                            if let url = try? store.exportFileURL() {
                                shareURL = ShareableURL(url: url)
                            }
                        }
                        Button("Import a comrade's Republic") {
                            isImporting = true
                        }
                        Divider()
                        Button("Suicide", role: .destructive) {
                            showSuicide = true
                        }
                        Divider()
                        Toggle("Silence is suspicious", isOn: $stateSilenced)
                    } label: {
                        Label("Ministry", systemImage: "star.fill")
                    }
                }
            }
            .navigationDestination(for: Ministry.self) { destination in
                switch destination {
                case .card: MembershipCardView()
                case .leaderboard: LeaderboardView()
                case .plan: PlanView()
                case .defector: DefectorView()
                case .radio: RadioMoscowView()
                case .poster: PosterGeneratorView()
                case .interrogation: InterrogationView()
                case .archive: ArchiveView()
                }
            }
            .task {
                // Opening the registry: tanks outside, stray bullets at random.
                StateHaptics.shared.play(.tankRumble)
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(Int.random(in: 4...9)))
                    if Double.random(in: 0..<1) < 0.4 {
                        StateHaptics.shared.play(.strayBullet)
                    }
                }
            }
            .task {
                // The republic lives between bullets: one weighted event per tick.
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(5))
                    simulator.advance(now: .now)
                }
            }
            .safeAreaInset(edge: .top, alignment: .leading) {
                VStack(alignment: .leading, spacing: 6) {
                    if simulator.playerDenouncedBy != nil {
                        banner(
                            "You have been denounced! The queue for your defence is forming.",
                            tint: .red
                        ) { simulator.playerDenouncedBy = nil }
                    }
                    if let lastEvent = simulator.lastEvent {
                        Text(lastEvent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .onChange(of: stateSilenced) { _, muted in
                StateHaptics.shared.setMuted(muted)
            }
            .sheet(isPresented: $isAddingCitizen) {
                AddCitizenView()
            }
            .sheet(isPresented: $isShowingPropaganda) {
                PropagandaPosterView()
            }
            .sheet(item: $shareURL) { item in
                NavigationStack {
                    VStack(spacing: 16) {
                        Text(item.url.lastPathComponent)
                            .font(.headline.monospaced())
                            .padding(.top)
                        ShareLink(item: item.url) {
                            Label("Share the republic", systemImage: "square.and.arrow.up")
                        }
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Export my Republic")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { shareURL = nil }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showSuicide) {
                SuicideView(
                    onRefused: {
                        showSuicide = false
                        lifeCaption = "You have chosen life. Cowardice noted."
                    },
                    onWiped: {
                        showSuicide = false
                    }
                )
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
                } else if let lifeCaption {
                    banner(lifeCaption, tint: .secondary) { self.lifeCaption = nil }
                        .task {
                            try? await Task.sleep(for: .seconds(6))
                            self.lifeCaption = nil
                        }
                }
            }
        } detail: {
            if let selectedCitizenId {
                CitizenDetailView(citizenId: selectedCitizenId)
            } else {
                BroadcastView()
            }
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
        .background(tint == .secondary ? Color(.secondarySystemBackground) : tint, in: RoundedRectangle(cornerRadius: 10))
        .padding()
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

    private func deleteCitizens(offsets: IndexSet) {
        withAnimation {
            let doomed = offsets.map { citizens[$0] }
            let actor = store.profile()?.alias ?? "The Registry"
            store.deleteCitizens(ids: doomed.map(\.id))
            for citizen in doomed {
                store.log(
                    kind: .citizen, actor: actor, subject: citizen.name,
                    text: "Dossier of \(citizen.name) liquidated, papers and all.")
            }
            if let selectedCitizenId, doomed.contains(where: { $0.id == selectedCitizenId }) {
                self.selectedCitizenId = nil
            }
        }
    }
}

/// A URL that can drive a `.sheet(item:)`.
private struct ShareableURL: Identifiable {
    let url: URL
    var id: URL { url }
}

/// Master-list row: name, affiliation, and colour-coded loyalty classification.
struct CitizenRow: View {
    let citizen: Citizen

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(citizen.name)
                .font(.headline)
            Text(citizen.affiliation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(citizen.status.propagandaLabel)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(citizen.status.badgeColor.opacity(0.2), in: Capsule())
                .foregroundStyle(citizen.status.badgeColor)
        }
        .padding(.vertical, 2)
    }
}

/// Full dossier of one citizen, read live from the archive: loyalty gauge,
/// denunciations, rewritten history, and reclassification buttons (randomly
/// interrupted by checkpoints).
struct CitizenDetailView: View {
    let citizenId: Int64

    @State private var store = StateStore.shared
    @State private var isReporting = false
    @State private var denial: String?
    @State private var gate = CheckpointGateRunner()

    var body: some View {
        let _ = store.revision
        if let citizen = store.citizen(id: citizenId) {
            List {
                Section("Identity") {
                    LabeledContent("Name", value: citizen.name)
                    LabeledContent("Affiliation", value: citizen.affiliation)
                    LabeledContent(
                        "Registered",
                        value: citizen.addedAt,
                        format: Date.FormatStyle(date: .numeric, time: .standard)
                    )
                }
                Section("Classification") {
                    Text(citizen.status.propagandaLabel)
                        .fontWeight(.bold)
                        .foregroundStyle(citizen.status.badgeColor)
                    Gauge(
                        value: Double(TrustEnforcement.score(for: citizen)),
                        in: 0...100
                    ) {
                        Text("Trust")
                    } currentValueLabel: {
                        Text("\(TrustEnforcement.score(for: citizen))")
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(trustTint(for: citizen))
                }
                Section("Denunciations") {
                    let reports = store.reports().filter { $0.citizenId == citizen.id }
                    if reports.isEmpty {
                        Text("No denunciations on file. Suspicious in itself.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(reports) { report in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(report.offence)
                                    .font(.headline)
                                Text(report.details)
                                    .font(.subheadline)
                                Text(
                                    "Filed by \(report.informantName) on \(report.reportedAt, format: Date.FormatStyle(date: .numeric))"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Dossier Notes") {
                    Text(
                        citizen.dossierNote.isEmpty
                            ? "No incriminating evidence recorded."
                            : citizen.dossierNote)
                }
                Section("Rewritten History") {
                    let amendments = store.amendments(citizenId: citizen.id).sorted {
                        $0.amendedAt > $1.amendedAt
                    }
                    if amendments.isEmpty {
                        Text("History here is accurate. For now.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(amendments) { amendment in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(amendment.fieldName): \"\(amendment.oldValue)\" → \"\(amendment.newValue)\"")
                                    .font(.subheadline)
                                Text(amendment.justification)
                                    .font(.caption)
                                    .italic()
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    Button("Mark Neutralized", role: .destructive) {
                        if citizen.status == .neutralized {
                            denial = StateRefusals.refusal(for: .neutralized)
                            return
                        }
                        gate.request {
                            RecordOffice.amend(
                                citizenId: citizen.id,
                                field: "status",
                                old: citizen.status.propagandaLabel,
                                new: CitizenStatus.neutralized.propagandaLabel
                            )
                            StateHaptics.shared.play(.t34Firing)
                        }
                    }
                    Button("Mark Cleared") {
                        if citizen.status == .neutralized || citizen.status == .cleared {
                            // The dead are not awaiting promotion to citizen, and the cleared need no second clearing.
                            denial = StateRefusals.refusal(for: .cleared)
                            return
                        }
                        gate.request {
                            RecordOffice.amend(
                                citizenId: citizen.id,
                                field: "status",
                                old: citizen.status.propagandaLabel,
                                new: CitizenStatus.cleared.propagandaLabel
                            )
                        }
                    }
                } footer: {
                    Text("Decisions of the Authority are final and do not require due process.")
                }
            }
            .alert(
                "Ministry of Records",
                isPresented: Binding(
                    get: { denial != nil },
                    set: { if !$0 { denial = nil } }
                ),
                actions: { Button("Comply") {} },
                message: { Text(denial ?? "") }
            )
            .navigationTitle(citizen.name)
            .toolbar {
                ToolbarItem {
                    Button("Report a Colleague", systemImage: "exclamationmark.bubble") {
                        isReporting = true
                    }
                }
            }
            .sheet(isPresented: $isReporting) {
                ReportFormView(citizen: citizen)
            }
            .checkpointGate(gate)
            .task {
                TrustEnforcement.enforce(id: citizenId)
            }
        } else {
            ContentUnavailableView(
                "Dossier Liquidated",
                systemImage: "trash",
                description: Text("This citizen no longer exists. Officially, they never did.")
            )
        }
    }

    /// Green = trusted, yellow = watched, red = the file is getting thick.
    private func trustTint(for citizen: Citizen) -> Color {
        let score = TrustEnforcement.score(for: citizen)
        if score >= 70 { return .green }
        if score >= 30 { return .yellow }
        return .red
    }
}

/// Destinations reachable from the Ministry menu.
enum Ministry: Hashable {
    case card
    case leaderboard
    case plan
    case defector
    case radio
    case poster
    case interrogation
    case archive
}
extension CitizenStatus {
    /// Colour language of the Authority: yellow = watching, red = dealt with, green = trusted.
    fileprivate var badgeColor: Color {
        switch self {
        case .surveilled: .yellow
        case .neutralized: .red
        case .cleared: .green
        }
    }
}

#Preview {
    ContentView()
}
