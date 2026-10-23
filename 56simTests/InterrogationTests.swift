//
//  InterrogationTests.swift
//  56simTests
//
//  The interrogator is interrogated: persona anchors, verdict parsing,
//  and a full five-question session driven by StubInterrogator.
//

import Foundation
import Testing

@testable import _6sim

@MainActor
struct InterrogationTests {
    @Test("The persona is Room 407, one question at a time, verdict-capable")
    func systemPromptAnchors() {
        let prompt = Interrogation.systemPrompt
        #expect(prompt.hasPrefix("You are an ÁVH interrogator"))
        #expect(prompt.contains("EXACTLY ONE question"))
        #expect(prompt.contains("VERDICT:"))
        #expect(prompt.contains("Room 407"))
        #expect(prompt.contains("English only"))
    }

    @Test("Verdict extraction is tolerant of case, strict about content")
    func verdictParsing() {
        #expect(
            Interrogation.verdict(in: "The file is complete. VERDICT: 10 YEARS OF APPROVED MUSIC.")
                == "10 YEARS OF APPROVED MUSIC."
        )
        #expect(Interrogation.verdict(in: "verdict: one potato tax.") == "one potato tax.")
        #expect(Interrogation.verdict(in: "No decision today, citizen.") == nil)
        #expect(Interrogation.verdict(in: "VERDICT:") == nil, "an empty verdict is no verdict")
    }

    @Test("The verdict arrives at question five, not four")
    func verdictTiming() {
        #expect(Interrogation.isVerdictDue(questionCount: 5))
        #expect(!Interrogation.isVerdictDue(questionCount: 4))
    }

    @Test("Exactly one pinned system line, whatever the transcript")
    func systemLinePinned() {
        let history = [
            InterrogationMessage(role: .system, content: "old regime text"),
            InterrogationMessage(role: .user, content: "I deny everything."),
        ]
        let messages = Interrogation.messages(history: history, questionCount: 1)
        #expect(messages.count == 2)
        #expect(messages.first?.role == .system)
        #expect(messages.first?.content == Interrogation.systemPrompt)
        #expect(messages.last?.content == "I deny everything.")
    }

    @Test("Five answers in, the stub hands down a verdict")
    func stubSessionReachesVerdict() async {
        let model = InterrogationSessionModel(interrogator: StubInterrogator())
        await model.begin()
        #expect(model.questionCount == 1)

        for answer in [
            "I was lost.",
            "The shoes were a gift.",
            "I was humming approved music!",
            "I cooperate fully, comrade.",
            "I deny everything.",
        ] {
            await model.submit(answer)
        }

        #expect(model.verdictText != nil)
        #expect(model.phase == .awaitingAnswer, "a verdict never closes the room")
        #expect(model.canAnswer)
        #expect(model.questionCount >= 5)
        #expect(model.errorMessage == nil)
    }

    @Test("Confess and Deny send the scripted lines")
    func scriptedConfessions() async {
        let model = InterrogationSessionModel(interrogator: StubInterrogator())
        await model.begin()
        await model.confess(extra: "ate two ration coupons")
        #expect(model.messages.map(\.content).contains("I confess: ate two ration coupons."))
        await model.denyEverything()
        #expect(model.messages.map(\.content).contains("I deny everything."))
    }

    @Test("The session opens with the scripted line, never a stage direction")
    func scriptedOpen() async {
        let model = InterrogationSessionModel(interrogator: StubInterrogator())
        await model.begin()
        #expect(model.messages.first?.role == .assistant)
        #expect(model.messages.first?.content == Interrogation.scriptedOpening)
        #expect(!model.messages.contains { $0.content.contains("sits down") })
    }

    @Test("A premature verdict is scrubbed from chat and hands down nothing")
    func prematureVerdictScrubbed() async {
        let model = InterrogationSessionModel(interrogator: StubInterrogator(earlyVerdict: true))
        await model.begin()
        await model.submit("I was lost.")
        let firstModelReply = model.messages.first {
            $0.role == .assistant && $0.content != Interrogation.scriptedOpening
        }
        #expect(firstModelReply?.content.contains("VERDICT:") == false)
        #expect(model.verdictText == nil, "only the operator's demand may produce a verdict")
        #expect(model.phase == .awaitingAnswer)
        #expect(model.canAnswer)
    }

    @Test("A stuttered verdict marker still yields exactly one verdict")
    func collapsedVerdictExtraction() {
        #expect(
            Interrogation.verdict(in: "… VERDICT: VERDICT: TEN YEARS OF APPROVED MUSIC.")
                == "TEN YEARS OF APPROVED MUSIC."
        )
        #expect(Interrogation.scrubbed("VERDICT:ten years. verdict:again.") == "ten years. again.")
        #expect(Interrogation.scrubbed("No verdict here, citizen.") == "No verdict here, citizen.")
    }
}
