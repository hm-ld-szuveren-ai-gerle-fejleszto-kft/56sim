//
//  PeopleRegistryTests.swift
//  56simTests
//
//  Verification that the People's Registry stores the truth it claims to store.
//

import Foundation
import SwiftData
import Testing

@testable import _6sim

struct PeopleRegistryTests {
  /// In-memory container so each test interrogates its own copy of the archive.
  private func makeContainer() throws -> ModelContainer {
    let schema = Schema([Citizen.self, Broadcast.self, Report.self, RecordAmendment.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [configuration])
  }

  @Test("A newly registered citizen starts under surveillance")
  func newCitizenDefaultsToSurveilled() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let citizen = Citizen(name: "Kovács Gyula", affiliation: "Factory worker")
    context.insert(citizen)

    #expect(citizen.status == .surveilled)
    #expect(citizen.dossierNote.isEmpty)
  }

  @Test("Neutralization survives a fresh context")
  func neutralizationPersistsAcrossContexts() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let citizen = Citizen(name: "Nagy Éva", affiliation: "University student")
    context.insert(citizen)
    try context.save()

    citizen.status = .neutralized
    try context.save()

    let freshContext = ModelContext(container)
    let fetched = try freshContext.fetch(FetchDescriptor<Citizen>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.status == .neutralized)
  }

  @Test("Clearing a citizen survives a fresh context")
  func clearedStatusPersistsAcrossContexts() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let citizen = Citizen(name: "Szabó Béla", affiliation: "Railway clerk")
    context.insert(citizen)
    try context.save()

    citizen.status = .cleared
    try context.save()

    let freshContext = ModelContext(container)
    let fetched = try freshContext.fetch(FetchDescriptor<Citizen>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.status == .cleared)
  }

  @Test("Broadcast round-trips title and body")
  func broadcastRoundTrip() throws {
    let container = try makeContainer()
    let context = ModelContext(container)
    let broadcast = Broadcast(
      title: "Glory to the five-year plan",
      body: "Production targets have been met in advance. Gratitude is mandatory."
    )
    context.insert(broadcast)
    try context.save()

    let freshContext = ModelContext(container)
    let fetched = try freshContext.fetch(FetchDescriptor<Broadcast>())
    #expect(fetched.count == 1)
    #expect(fetched.first?.title == "Glory to the five-year plan")
    #expect(
      fetched.first?.body
        == "Production targets have been met in advance. Gratitude is mandatory.")
  }

  /// Opt-in: run on device (or simulator with 56SIM_ALLOW_SIMULATOR_LLM=YES) with
  /// `LLM_INTEGRATION=YES xcodebuild test ...` — downloads the 628 MB interrogator.
  @Test(
    "The interrogator answers (opt-in: LLM_INTEGRATION=YES)",
    .enabled(if: ProcessInfo.processInfo.environment["LLM_INTEGRATION"] == "YES"))
  func interrogatorModelResponds() async throws {
    let engine = InterrogationEngine()
    try await engine.load()
    let history = Interrogation.messages(
      history: [InterrogationMessage(role: .user, content: "I deny everything.")],
      questionCount: 0
    )
    var text = ""
    for try await chunk in try await engine.ask(history) {
      text += chunk
    }
    #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
  }
}
