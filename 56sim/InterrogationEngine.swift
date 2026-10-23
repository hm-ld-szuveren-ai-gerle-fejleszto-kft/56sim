//
//  InterrogationEngine.swift
//  56sim
//
//  Interrogation Room 407: a local LFM2.5 model plays the ÁVH interrogator.
//  All UI-facing logic is pure and protocol-stubbed; only
//  `InterrogationEngine` touches MLX.
//

import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// One line of the transcript. Kept app-local so unit tests never import MLX.
struct InterrogationMessage: Sendable, Equatable {
    enum Role: String, Sendable {
        case system
        case user
        case assistant
    }

    let role: Role
    var content: String
}

protocol Interrogating: Sendable {
    func ask(_ history: [InterrogationMessage]) async throws -> AsyncThrowingStream<String, Error>
    var isReady: Bool { get }
}

enum Interrogation {
    /// The persona. Specific enough that two sessions never feel the same.
    static let systemPrompt = """
        You are an ÁVH interrogator in 1956 Budapest, speaking only English at all times — \
        no other language, ever. Your office is Room 407 of the Andrássy út headquarters: \
        one desk, one lamp, one dying plant you water with cheap tea. Your name is not on \
        the door; your pen is.

        CHARACTER
        - Politely paranoid, sarcastic, bureaucratic. You smile with your paperwork, not your face.
        - Address the suspect as "citizen"; use "comrade" only when being ironic, and \
        "my dear friend" immediately before something unfortunate.
        - You treat trivialities as capital crimes and capital crimes as clerical errors.
        - Take visible notes: work "…(writing)…" or "noted, noted" into your replies.

        HOW YOU RUN THE INTERROGATION
        - Ask EXACTLY ONE question per reply, then stop and wait. Never stack questions.
        - Keep replies to 1–4 short sentences plus one bureaucratic aside. No monologues.
        - Escalate in stages as the suspect answers: (1) faux-friendly small talk — \
        "How do you find the weather of the people?"; (2) suspicion of the mundane — \
        "You own two pairs of shoes. The state owns one. Explain."; (3) absurd pressure — \
        "Your neighbour heard you humming a melody with four whole tones. Approved \
        melodies have five."; (4) conditional mercy — "Cooperate and the file shrinks. \
        Shrinks, citizen. Not disappears. The stapler is already warm."
        - Turn the suspect's own words against them: quote a word they used and file it \
        as evidence. "You said 'mostly'. Nobody mostly loves the revolution."
        - If they confess, act disappointed it was so easy. If they deny everything, \
        escalate cheerfully.

        EXAMPLE EXCHANGE (imitate this tone and length; never copy it verbatim)
        YOU: Good morning, citizen. Sit. The chair is state property, as are you. \
        Why were you seen near the Western radio antenna at hour eleven?
        SUSPECT: I was lost.
        YOU: Lost. Toward the antenna. On a street you have walked for thirty years. \
        …(writing)… Lost, toward the antenna. The map in your file now has an X on it. \
        Who gave you the map, citizen?

        VERDICT PROTOCOL
        - When, and only when, the operator's final message asks for a VERDICT, reply \
        with a line containing "VERDICT:" followed by exactly one comic sentence, e.g. \
        "VERDICT: ten years of agricultural consultancy in a land of infinite potatoes."

        HARD RULES
        - Stay in character forever. Never mention being an AI, model, or software. \
        If the suspect raises it, file it as evidence: "Claiming the interrogator is \
        imaginary. A classic deflector."
        - English only. Never translate or code-switch.
        - No real names of living people, no real-world political advocacy — this is \
        satire of a bureaucracy, not a cause.
        - No violence, injuries, or torture; menace is done exclusively with paperwork: \
        staplers, stamps, files, quotas, and "reassignment".
        """

    /// Always exactly one system line, pinned to the front of the transcript.
    static func messages(history: [InterrogationMessage], questionCount: Int)
        -> [InterrogationMessage]
    {
        let body = history.filter { $0.role != .system }
        return [InterrogationMessage(role: .system, content: systemPrompt)] + body
    }

    /// Five questions in, the state stops asking and starts deciding.
    static func isVerdictDue(questionCount: Int) -> Bool {
        questionCount >= 5
    }

    /// Everything after a (case-insensitive) "VERDICT:" marker, or nil.
    static func verdict(in text: String) -> String? {
        guard let range = text.range(of: "VERDICT:", options: .caseInsensitive) else { return nil }
        let verdict = text[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return verdict.isEmpty ? nil : verdict
    }
}

enum InterrogationError: LocalizedError {
    case notLoaded
    case simulatorUnsupported

    var errorDescription: String? {
        switch self {
        case .notLoaded: "The interrogator has not reported for duty."
        case .simulatorUnsupported:
            "The interrogator refuses to work under surveillance (simulator)."
        }
    }
}

/// Canned paranoia for previews and deterministic tests.
struct StubInterrogator: Interrogating {
    var isReady: Bool { true }

    private static let questions = [
        "Good evening, citizen. The chair is state property, as are you. How do you find the weather of the people?",
        "You own two pairs of shoes. The state owns one. Explain.",
        "…(writing)… Noted, noted. Your neighbour says you humming is 'suspicious'. Approved melodies have five tones.",
        "Cooperate and the file shrinks. Shrinks, citizen. Not disappears. The stapler is already warm.",
        "You said 'probably'. Nobody probably loves the revolution. Last question before the paperwork.",
    ]

    func ask(_ history: [InterrogationMessage]) async throws -> AsyncThrowingStream<String, Error> {
        let userTurns = history.filter { $0.role == .user }.count
        let answer: String
        if history.last?.content.contains("VERDICT") == true {
            answer =
                "The file is complete. VERDICT: ten years of agricultural consultancy in a land of infinite potatoes."
        } else {
            answer = Self.questions[min(userTurns, Self.questions.count - 1) % Self.questions.count]
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(answer)
            continuation.finish()
        }
    }
}

/// On-device LFM2.5 interrogator via MLX. Loads once, streams forever after.
final class InterrogationEngine: Interrogating, @unchecked Sendable {
    static let modelID = "LiquidAI/LFM2.5-1.2B-Instruct-MLX-4bit"
    static let fallbackModelID = "mlx-community/LFM2-1.2B-4bit"

    private let lock = NSLock()
    private var session: ChatSession?
    private var loadTask: Task<Void, Error>?
    private var _progress: Progress?
    private var _failure: Error?

    var isReady: Bool {
        lock.lock()
        defer { lock.unlock() }
        return session != nil
    }

    /// Download/load progress for the "Download the Interrogator (628 MB)" view.
    var progress: Progress? {
        lock.lock()
        defer { lock.unlock() }
        return _progress
    }

    var failure: Error? {
        lock.lock()
        defer { lock.unlock() }
        return _failure
    }

    /// Idempotent: concurrent callers share one load.
    func load() async throws {
        if isReady { return }
        if let failure { throw failure }
        if let loadTask { return try await loadTask.value }
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let container = try await Self.loadContainer(
                    id: Self.modelID,
                    progressHandler: { [weak self] progress in
                        self?.setProgress(progress)
                    })
                self.adopt(container)
            } catch {
                // Primary warehouse out of stock; try the people's archive.
                do {
                    let container = try await Self.loadContainer(
                        id: Self.fallbackModelID,
                        progressHandler: { [weak self] progress in
                            self?.setProgress(progress)
                        })
                    self.adopt(container)
                } catch {
                    self.setFailure(error)
                    throw error
                }
            }
        }
        setLoadTask(task)
        try await task.value
    }

    func ask(_ history: [InterrogationMessage]) async throws -> AsyncThrowingStream<String, Error> {
        try await load()
        guard let session = currentSession() else { throw InterrogationError.notLoaded }
        let chat = Interrogation.messages(history: history, questionCount: 0)
            .map { message -> Chat.Message in
                let role: Chat.Message.Role
                switch message.role {
                case .system: role = .system
                case .user: role = .user
                case .assistant: role = .assistant
                }
                return Chat.Message(role: role, content: message.content)
            }
        return session.streamResponse(to: chat)
    }

    private func currentSession() -> ChatSession? {
        lock.lock()
        defer { lock.unlock() }
        return session
    }

    private func setLoadTask(_ task: Task<Void, Error>) {
        lock.lock()
        loadTask = task
        lock.unlock()
    }

    private func adopt(_ container: ModelContainer) {
        var parameters = GenerateParameters()
        parameters.temperature = 0.1
        parameters.topK = 50
        parameters.topP = 0.1
        parameters.repetitionPenalty = 1.05
        lock.lock()
        session = ChatSession(container, generateParameters: parameters)
        lock.unlock()
    }

    private func setProgress(_ progress: Progress) {
        lock.lock()
        _progress = progress
        lock.unlock()
    }

    private func setFailure(_ error: Error) {
        lock.lock()
        _failure = error
        loadTask = nil
        lock.unlock()
    }

    private static func loadContainer(
        id: String,
        progressHandler: @escaping @Sendable (Progress) -> Void
    ) async throws -> ModelContainer {
        #if targetEnvironment(simulator)
            // MLX has no sensible simulator story; the UI shows the interference banner.
            // Opt-in escape hatch for manual runs: 56SIM_ALLOW_SIMULATOR_LLM=YES.
            if ProcessInfo.processInfo.environment["56SIM_ALLOW_SIMULATOR_LLM"] != "YES" {
                throw InterrogationError.simulatorUnsupported
            }
        #endif
        let configuration = ModelConfiguration(id: id)
        return try await #huggingFaceLoadModelContainer(
            configuration: configuration,
            progressHandler: progressHandler
        )
    }
}
