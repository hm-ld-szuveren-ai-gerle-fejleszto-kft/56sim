//
//  PeoplesPaperView.swift
//  56sim
//
//  NÉPSZABADSÁG — the printed face of the archive. Read-only, like all
//  honest journalism in the People's Republic.
//

import SwiftUI

/// The newspaper page, set entirely from the events table.
struct PeoplesPaperView: View {
    @State private var store = StateStore.shared

    private var edition: PaperEdition {
        _ = store.revision
        let citizenNames = Dictionary(
            uniqueKeysWithValues: store.citizens().map { ($0.id, $0.name) })
        return PeoplesPaper.make(
            events: store.events(),
            entries: Leaderboard.entries(
                from: store.reports(),
                profileAlias: store.profile()?.alias,
                citizenNames: citizenNames),
            profile: store.profile(),
            now: .now,
            reprints: store.kvInt("paper_reprints")
        )
    }

    var body: some View {
        let edition = self.edition
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("NÉPSZABADSÁG — THE PEOPLE'S TRUTH")
                    .font(.system(.largeTitle, design: .serif))
                    .bold()
                    .foregroundStyle(.red)
                Text(
                    "Price: one act of loyalty · Printed by the People, for the People, mainly about the People."
                )
                .font(.caption)
                Divider()
                Text(edition.headline)
                    .font(.system(.title, design: .serif))
                    .bold()
                Text("Edition \(edition.editionNumber) · \(edition.dateText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(edition.sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .font(.system(.headline, design: .serif))
                            .bold()
                        ForEach(section.items, id: \.self) { item in
                            VStack(spacing: 8) {
                                Text(item)
                                    .font(.system(.body, design: .serif))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Divider()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("The People's Paper")
        .toolbar {
            ToolbarItem {
                Button("Print extra edition") {
                    store.setKV(
                        "paper_reprints", value: String(store.kvInt("paper_reprints") + 1))
                    StateHaptics.shared.play(.strayBullet)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PeoplesPaperView()
    }
}
