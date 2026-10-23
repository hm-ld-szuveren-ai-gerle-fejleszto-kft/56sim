//
//  CheckpointGate.swift
//  56sim
//
//  Random loyalty checkpoints: the state must occasionally verify that
//  you know the right answers before it lets you press a button.
//

import SwiftUI

struct CheckpointQuestion {
    let prompt: String
    let answers: [String]
    let correctIndex: Int
}

enum Checkpoint {
    /// Exact detention length after a wrong answer, in seconds.
    static let detainedSeconds = 10

    static let questions: [CheckpointQuestion] = [
        CheckpointQuestion(
            prompt: "Who guards the people?",
            answers: [
                "The people themselves", "The ÁVH", "Nobody, the state is obsolete",
                "A very large dog",
            ],
            correctIndex: 1
        ),
        CheckpointQuestion(
            prompt: "How long does a Five-Year Plan take to fulfil?",
            answers: [
                "Five years", "Four years", "Six, generously", "It is fulfilled in our hearts",
            ],
            correctIndex: 1
        ),
        CheckpointQuestion(
            prompt: "What is the correct opinion today?",
            answers: [
                "Whatever I think", "The one in yesterday's newspaper", "Opinions are bourgeois",
                "Ask my neighbour",
            ],
            correctIndex: 1
        ),
        CheckpointQuestion(
            prompt: "Which rumour is true?",
            answers: [
                "The one about the bananas", "No rumour is true, only announced", "All of them",
                "Mine",
            ],
            correctIndex: 1
        ),
        CheckpointQuestion(
            prompt: "What sound do tanks make in the street at dawn?",
            answers: ["Danger", "Progress", "Traffic", "Nothing, they are electric now"],
            correctIndex: 1
        ),
        CheckpointQuestion(
            prompt: "How far is Austria?",
            answers: [
                "Three days on foot", "Forty kilometres", "Irrelevant, it does not exist",
                "That border is a rumour",
            ],
            correctIndex: 2
        ),
        CheckpointQuestion(
            prompt: "Who is your favourite informant?",
            answers: ["Nobody, I trust no one", "Myself", "The postman", "My neighbour, proudly"],
            correctIndex: 3
        ),
    ]

    /// A random challenge fires on 30 % of gated actions.
    static func mustChallenge(rand: Double) -> Bool {
        rand < 0.3
    }

    static func isCorrect(_ answer: Int, on question: CheckpointQuestion) -> Bool {
        answer == question.correctIndex
    }
}

/// Owns one pending gated action plus the challenge/detention state.
/// Views call `gate.request(action)` from buttons and attach
/// `.checkpointGate(gate)` to present the full-screen cover.
@Observable
final class CheckpointGateRunner {
    var challenge: CheckpointQuestion?
    var detainedUntil: Date?

    private var pending: (() -> Void)?
    private var detentionTask: Task<Void, Never>?

    /// Runs the action immediately, or interrupts with a checkpoint on 30 % of rolls.
    func request(_ action: @escaping () -> Void) {
        guard challenge == nil else { return }  // already detained at a checkpoint
        if Checkpoint.mustChallenge(rand: .random(in: 0..<1)) {
            pending = action
            challenge = Checkpoint.questions.randomElement()
        } else {
            action()
        }
    }

    func answer(_ index: Int) {
        guard let question = challenge else { return }
        if Checkpoint.isCorrect(index, on: question) {
            finish()
        } else {
            let until = Date().addingTimeInterval(TimeInterval(Checkpoint.detainedSeconds))
            detainedUntil = until
            detentionTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(Checkpoint.detainedSeconds))
                self?.finish()
            }
        }
    }

    /// Seconds left on detention, for the countdown label.
    func remainingDetention(now: Date = .now) -> Int {
        guard let until = detainedUntil else { return 0 }
        return max(0, Int(ceil(until.timeIntervalSince(now))))
    }

    private func finish() {
        detentionTask?.cancel()
        detentionTask = nil
        detainedUntil = nil
        let action = pending
        pending = nil
        challenge = nil
        action?()
    }

    deinit {
        detentionTask?.cancel()
    }
}

struct CheckpointGateModifier: ViewModifier {
    @Bindable var gate: CheckpointGateRunner

    func body(content: Content) -> some View {
        content.fullScreenCover(
            isPresented: Binding(
                get: { gate.challenge != nil },
                set: { presented in if !presented { gate.challenge = nil } }
            )
        ) {
            if let question = gate.challenge {
                CheckpointChallengeView(gate: gate, question: question)
            }
        }
    }
}

extension View {
    func checkpointGate(_ gate: CheckpointGateRunner) -> some View {
        modifier(CheckpointGateModifier(gate: gate))
    }
}

private struct CheckpointChallengeView: View {
    @Bindable var gate: CheckpointGateRunner
    let question: CheckpointQuestion

    var body: some View {
        VStack(spacing: 20) {
            Text("🛑 CHECKPOINT")
                .font(.largeTitle.bold())
                .foregroundStyle(.red)
            Text(question.prompt)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            ForEach(question.answers.indices, id: \.self) { index in
                Button(question.answers[index]) {
                    gate.answer(index)
                }
                .buttonStyle(.borderedProminent)
                .disabled(gate.detainedUntil != nil)
            }
            if gate.detainedUntil != nil {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text("DETAINED FOR QUESTIONING… \(gate.remainingDetention())")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.red)
                }
                Text("Wrong answers are noted in your file.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
