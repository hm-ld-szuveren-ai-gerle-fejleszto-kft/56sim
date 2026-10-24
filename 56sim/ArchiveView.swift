//
//  ArchiveView.swift
//  56sim
//
//  The Archive of the People: the user-accessible log of everything that
//  happened, sortable, searchable, and never edited. The presses handle
//  editing; the Archive remembers.
//

import SwiftUI

/// Pure filtering semantics of the Archive, shared by view and tests.
enum ArchiveModel {
    /// Kind filter and substring search compose; search matches
    /// text/actor/subject case-insensitively.
    static func filter(
        events: [LogEvent], kind: LogKind?, search: String
    ) -> [LogEvent] {
        events.filter { event in
            if let kind, event.kind != kind.rawValue { return false }
            let needle = search.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { return true }
            return event.text.localizedCaseInsensitiveContains(needle)
                || event.actor.localizedCaseInsensitiveContains(needle)
                || event.subject.localizedCaseInsensitiveContains(needle)
        }
    }
}

/// Read-only list of the central event log.
struct ArchiveView: View {
    @State private var store = StateStore.shared

    @State private var sortNewestFirst = true
    @State private var filterKind: LogKind?
    @State private var search = ""

    var body: some View {
        let _ = store.revision
        let events = ArchiveModel.filter(
            events: sortNewestFirst ? store.events() : Array(store.events().reversed()),
            kind: filterKind,
            search: search
        )
        List(events) { event in
            VStack(alignment: .leading, spacing: 2) {
                Text(event.text)
                Text(
                    "\(LogKind(rawValue: event.kind)?.label ?? event.kind) · \(event.actor) · \(event.at, format: .dateTime.day().month().hour().minute())"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .overlay {
            if events.isEmpty {
                ContentUnavailableView(
                    "The record is clean. Suspiciously.",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(
                        "History will fill this soon, whether you help or not.")
                )
            }
        }
        .searchable(text: $search, prompt: "Search the record…")
        .safeAreaInset(edge: .top, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: "All", isOn: filterKind == nil) { filterKind = nil }
                    ForEach(LogKind.allCases, id: \.self) { kind in
                        chip(title: kind.label, isOn: filterKind == kind) {
                            filterKind = kind
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
            .background(.bar)
        }
        .navigationTitle("The Archive of the People")
        .toolbar {
            ToolbarItem {
                Menu("Sort") {
                    Button("Newest first") { sortNewestFirst = true }
                    Button("Oldest first") { sortNewestFirst = false }
                }
            }
        }
    }

    private func chip(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isOn ? Color.red.opacity(0.25) : Color.secondary.opacity(0.12),
                    in: Capsule()
                )
                .foregroundStyle(isOn ? .red : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ArchiveView()
    }
}
