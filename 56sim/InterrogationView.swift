//
//  InterrogationView.swift
//  56sim
//
//  Interrogation Room 407: chat UI over the local interrogator. The
//  session model is protocol-injected so previews and tests run on
//  StubInterrogator without MLX or a 628 MB download.
//

import SwiftUI

enum InterrogationPhase: Equatable {
    case idle
    case loading
    case awaitingAnswer
    case generating
}

@Observable
@MainActor
final class InterrogationSessionModel {
    private(set) var messages: [InterrogationMessage] = []
    private(set) var phase: InterrogationPhase = .idle
    private(set) var errorMessage: String?
    private(set) var verdictText: String?
    private(set) var progress: Progress?

    private let interrogator: Interrogating
    private let progressPoller: (@Sendable () -> Progress?)?

    /// Set when the operator has demanded the verdict; only that reply may set one.
    private var awaitingVerdict = false

    init(interrogator: Interrogating, progressPoller: (@Sendable () -> Progress?)? = nil) {
        self.interrogator = interrogator
        self.progressPoller = progressPoller
    }

    var questionCount: Int { messages.filter { $0.role == .assistant }.count }
    var canAnswer: Bool { phase == .awaitingAnswer }

    private var lastAssistantDraft: String {
        messages.last(where: { $0.role == .assistant })?.content ?? ""
    }

    /// Load the model (if needed) and open the session with the scripted first line.
    func begin() async {
        guard phase == .idle else { return }
        phase = .loading
        errorMessage = nil
        let pollerTask = startProgressPolling()
        do {
            if let engine = interrogator as? InterrogationEngine {
                try await engine.load()
            }
            pollerTask?.cancel()
            // The state always opens in character; no stage direction reaches the
            // transcript, and the model takes over from the first answer.
            messages.append(
                InterrogationMessage(role: .assistant, content: Interrogation.scriptedOpening))
            phase = .awaitingAnswer
        } catch {
            pollerTask?.cancel()
            phase = .idle
            errorMessage = "Radio interference — the foreign agent line is down."
        }
    }

    /// The suspect speaks. After five questions the state demands a verdict.
    func submit(_ answer: String) async {
        guard phase == .awaitingAnswer else { return }
        var text = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { text = "everything" }
        messages.append(InterrogationMessage(role: .user, content: text))
        if Interrogation.isVerdictDue(questionCount: questionCount) {
            messages.append(InterrogationMessage(role: .user, content: "State your VERDICT."))
            awaitingVerdict = true
        }
        await respond()
        if phase == .generating { phase = .awaitingAnswer }
    }

    /// "Confess" button: sends `I confess: <text or "everything">.`
    func confess(extra: String) async {
        let text = extra.trimmingCharacters(in: .whitespacesAndNewlines)
        await submit(text.isEmpty ? "I confess: everything." : "I confess: \(text).")
    }

    /// "Deny Everything" button.
    func denyEverything() async {
        await submit("I deny everything.")
    }

    func retry() async {
        phase = .idle
        await begin()
    }

    private func respond() async {
        phase = .generating
        errorMessage = nil
        let history = Interrogation.messages(history: messages, questionCount: questionCount)
        messages.append(InterrogationMessage(role: .assistant, content: ""))
        do {
            let stream = try await interrogator.ask(history)
            for try await chunk in stream {
                if messages.last?.role == .assistant {
                    messages[messages.count - 1].content += chunk
                }
            }
            if awaitingVerdict {
                // Only the reply to the operator's demand may hand down a verdict,
                // and the chat stays open afterwards: the banner pins, the queue talks.
                awaitingVerdict = false
                if let verdict = Interrogation.verdict(in: lastAssistantDraft) {
                    verdictText = verdict
                }
            } else if messages.last?.role == .assistant {
                // A premature verdict is filed, never printed.
                messages[messages.count - 1].content = Interrogation.scrubbed(lastAssistantDraft)
            }
        } catch {
            // Drop the empty bubble; the state denies the line ever existed.
            if messages.last?.role == .assistant, messages.last?.content.isEmpty == true {
                messages.removeLast()
            }
            // The demand went unanswered on the wire; it does not carry over.
            awaitingVerdict = false
            phase = .idle
            errorMessage = "Radio interference — the foreign agent line is down."
        }
    }

    private func startProgressPolling() -> Task<Void, Never>? {
        guard let poll = progressPoller else { return nil }
        return Task { [weak self] in
            while !Task.isCancelled {
                self?.progress = poll()
                try? await Task.sleep(for: .seconds(0.5))
            }
        }
    }
}

struct InterrogationView: View {
    @State private var model: InterrogationSessionModel
    @State private var suspectAnswer = ""

    init(interrogator: Interrogating = InterrogationEngine.shared) {
        var poller: (@Sendable () -> Progress?)?
        if let mlx = interrogator as? InterrogationEngine {
            poller = { mlx.progress }
        }
        _model = State(
            initialValue: InterrogationSessionModel(
                interrogator: interrogator,
                progressPoller: poller
            ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let error = model.errorMessage {
                HStack {
                    Text(error)
                        .font(.callout.bold())
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Retry") {
                        Task { await model.retry() }
                    }
                    .foregroundStyle(.white)
                }
                .padding()
                .background(Color.red, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.top, 8)
            }

            if model.phase == .loading {
                VStack(spacing: 12) {
                    Text("Download the Interrogator (628 MB)")
                        .font(.headline)
                    if let progress = model.progress {
                        ProgressView(value: Double(progress.fractionCompleted))
                            .frame(maxWidth: 280)
                        Text("\(Int(progress.fractionCompleted * 100))% · the state is reading")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                transcript
                inputBar
            }

            if let verdict = model.verdictText {
                verdictBanner(verdict)
            }
        }
        .navigationTitle("Interrogation Room 407")
        .task {
            await model.begin()
        }
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(model.messages.enumerated()), id: \.offset) { index, message in
                        if message.role != .system {
                            bubble(message, index: index)
                        }
                    }
                }
                .padding()
            }
            .onChange(of: model.messages.count) {
                if let last = model.messages.indices.last {
                    proxy.scrollTo(last, anchor: .bottom)
                }
            }
        }
    }

    private func bubble(_ message: InterrogationMessage, index: Int) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.content.isEmpty ? "…" : message.content)
                .padding(10)
                .background(
                    message.role == .user
                        ? Color.propagandaRed.opacity(0.15)
                        : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 10)
                )
                .id(index)
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Your excuse, citizen…", text: $suspectAnswer)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(sendFreeText)
                Button("Send") { sendFreeText() }
                    .disabled(!model.canAnswer)
            }
            HStack(spacing: 12) {
                Button("Confess") {
                    let extra = suspectAnswer
                    suspectAnswer = ""
                    Task { await model.confess(extra: extra) }
                }
                .buttonStyle(.borderedProminent)
                Button("Deny Everything") {
                    suspectAnswer = ""
                    Task { await model.denyEverything() }
                }
                .buttonStyle(.bordered)
            }
            .disabled(!model.canAnswer)
        }
        .padding()
    }

    private func verdictBanner(_ verdict: String) -> some View {
        VStack(spacing: 4) {
            Text("VERDICT OF THE STATE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(verdict)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    private func sendFreeText() {
        let text = suspectAnswer
        suspectAnswer = ""
        Task { await model.submit(text) }
    }
}

#Preview {
    NavigationStack {
        InterrogationView(interrogator: StubInterrogator())
    }
}
