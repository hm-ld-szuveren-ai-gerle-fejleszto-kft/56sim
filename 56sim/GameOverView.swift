//
//  GameOverView.swift
//  56sim
//
//  The Ministry of Love's closing statement, served once your file is
//  closed. The paperwork is the punishment.
//

import SwiftUI

/// Full-screen verdict shown when the republic finishes with you.
/// Serif, black, and final, like a front page that only has your name on it.
struct GameOverView: View {
    let finalTrust: Int
    let reportsAgainstYou: Int
    let onNewLife: () -> Void

    private static let finePrint = [
        "Room 101 has been reserved in your name. The rats have been advised; they send their regards and their availability.",
        "Nothing you did was unexpected. That was the problem.",
        "Your former neighbours wish to be among the first to congratulate your replacement. Their enthusiasm is already on file.",
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                Spacer(minLength: 24)

                Text("THE MINISTRY OF LOVE")
                    .font(.system(.caption, design: .serif))
                    .tracking(3)
                    .foregroundStyle(.secondary)

                Text("YOU LOVED BIG BROTHER.")
                    .font(.system(.largeTitle, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your final trust: \(finalTrust)")
                    Text("Reports against you: \(reportsAgainstYou)")
                }
                .font(.system(.body, design: .serif))
                .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Self.finePrint, id: \.self) { line in
                        Text(line)
                            .font(.system(.footnote, design: .serif))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: 24)

                Button(action: onNewLife) {
                    Text("Begin a new life")
                        .font(.system(.body, design: .serif))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    GameOverView(finalTrust: -47, reportsAgainstYou: 13, onNewLife: {})
}
