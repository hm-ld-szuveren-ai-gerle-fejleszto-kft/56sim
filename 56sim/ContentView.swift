//
//  ContentView.swift
//  56sim
//
//  Created by Reka Papp on 2026-10-23.
//

import SwiftData
import SwiftUI

/// Dashboard of the People's Registry: citizen dossiers on the left,
/// selected dossier (or the state broadcast feed) on the right.
struct ContentView: View {
 @Environment(\.modelContext) private var modelContext
 @Query(sort: \Citizen.addedAt, order: .reverse) private var citizens: [Citizen]

 @State private var selectedCitizen: Citizen?
 @State private var isAddingCitizen = false
 @State private var isShowingPropaganda = false
 @AppStorage("stateHapticsMuted") private var stateSilenced = false

 var body: some View {
  NavigationSplitView {
   List(selection: $selectedCitizen) {
    ForEach(citizens) { citizen in
     CitizenRow(citizen: citizen)
      .tag(citizen)
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
      NavigationLink(value: Ministry.leaderboard) {
       Label("Neighbour-Watch Leaderboard", systemImage: "list.number")
      }
      NavigationLink(value: Ministry.plan) {
       Label("Five-Year Plan", systemImage: "chart.bar.doc.horizontal")
      }
      NavigationLink(value: Ministry.defector) {
       Label("Defector: Escape 1956", systemImage: "figure.run")
      }
      NavigationLink(value: Ministry.radio) { Label("Radio Moscow", systemImage: "radio") }
      NavigationLink(value: Ministry.poster) {
       Label("Poster Foundry", systemImage: "paintbrush.pointed.fill")
      }
      NavigationLink(value: Ministry.interrogation) {
       Label("Interrogation Room", systemImage: "lamp.desk")
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
    case .leaderboard: LeaderboardView()
    case .plan: PlanView()
    case .defector: DefectorView()
    case .radio: RadioMoscowView()
    case .poster: PosterGeneratorView()
    case .interrogation: InterrogationView()
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
   .onChange(of: stateSilenced) { _, muted in
    StateHaptics.shared.setMuted(muted)
   }
   .sheet(isPresented: $isAddingCitizen) {
    AddCitizenView()
   }
   .sheet(isPresented: $isShowingPropaganda) {
    PropagandaPosterView()
   }
  } detail: {
   if let selectedCitizen {
    CitizenDetailView(citizen: selectedCitizen)
   } else {
    BroadcastView()
   }
  }
 }

 private func deleteCitizens(offsets: IndexSet) {
  withAnimation {
   for index in offsets {
    modelContext.delete(citizens[index])
   }
  }
 }
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

/// Full dossier of one citizen: loyalty gauge, denunciations, rewritten history,
/// and reclassification buttons (randomly interrupted by checkpoints).
struct CitizenDetailView: View {
 let citizen: Citizen

 @Environment(\.modelContext) private var modelContext
 @State private var isReporting = false
 @State private var denial: String?
 @State private var gate = CheckpointGateRunner()

 var body: some View {
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
    .tint(trustTint)
   }
   Section("Denunciations") {
    let reports = citizen.reports.sorted { $0.reportedAt > $1.reportedAt }
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
    let amendments = citizen.amendments.sorted { $0.amendedAt > $1.amendedAt }
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
       citizen,
       field: "status",
       old: citizen.status.propagandaLabel,
       new: CitizenStatus.neutralized.propagandaLabel,
       in: modelContext
      )
      StateHaptics.shared.play(.t34Firing)
     }
    }
    Button("Mark Cleared") {
     if citizen.status == .cleared {
      denial = StateRefusals.refusal(for: .cleared)
      return
     }
     gate.request {
      RecordOffice.amend(
       citizen,
       field: "status",
       old: citizen.status.propagandaLabel,
       new: CitizenStatus.cleared.propagandaLabel,
       in: modelContext
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
   TrustEnforcement.enforce(citizen)
  }
 }

 /// Green = trusted, yellow = watched, red = the file is getting thick.
 private var trustTint: Color {
  let score = TrustEnforcement.score(for: citizen)
  if score >= 70 { return .green }
  if score >= 30 { return .yellow }
  return .red
 }
}

/// Destinations reachable from the Ministry menu.
enum Ministry: Hashable {
 case leaderboard
 case plan
 case defector
 case radio
 case poster
 case interrogation
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
  .modelContainer(
   for: [Citizen.self, Broadcast.self, Report.self, RecordAmendment.self], inMemory: true)
}
