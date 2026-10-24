//
//  SuicideView.swift
//  56sim
//
//  The Republic's only exit, guarded by three questions. Bureaucracy is
//  the final courtesy.
//

import SwiftUI

/// Three sequential questions before the republic is unmade.
struct SuicideView: View {
    var onRefused: () -> Void = {}
    var onWiped: () -> Void = {}

    @State private var questionIndex = 0

    private static let questions = [
        "Are you quite sure, comrade? This action is permanent, unlike your employment.",
        "Have you said goodbye to your queue at the bakery? It waits for no one.",
        "Tomorrow there is sunshine forecast. Is that not reason enough to remain?",
    ]

    var body: some View {
        VStack(spacing: 36) {
            Spacer()
            Text(Self.questions[questionIndex])
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            HStack(spacing: 24) {
                Button("Yes, comrade") {
                    answerYes()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                Button("No, take me back") {
                    answerNo()
                }
                .buttonStyle(.bordered)
            }
            Spacer()
        }
        .background(Color(.systemBackground))
    }

    private func answerYes() {
        guard questionIndex == Self.questions.count - 1 else {
            questionIndex += 1
            return
        }
        StateStore.shared.wipeAll()
        StateStore.shared.log(
            kind: .system, actor: "The State", subject: "republic",
            text: "A republic ended voluntarily. The presses begin again.")
        StateHaptics.shared.play(.tankRumble)
        onWiped()
    }

    private func answerNo() {
        StateHaptics.shared.play(.strayBullet)
        onRefused()
    }
}

#Preview {
    SuicideView()
}
