//
//  PropagandaPosterView.swift
//  56sim
//
//  Full-screen satirical poster gallery from the Ministry of Truth,
//  plus the shared poster kit (slogans, palettes, PosterCard) the
//  Poster Foundry prints from.
//

import SwiftUI

/// The Ministry's approved visual language, shared by gallery and foundry.
enum Propaganda {
    struct Slogan: Identifiable, Hashable {
        let text: String
        let tagline: String
        var id: String { text }
    }

    static let slogans: [Slogan] = [
        Slogan(
            text: "PROLETARIANS OF THE WORLD, REPORT YOUR NEIGHBOUR!",
            tagline: "Haza és Haladás · Year LXX of Vigilance"
        ),
        Slogan(
            text: "THE STATE SEES ALL. THE STATE PROVIDES.",
            tagline: "Ministry of Truth · Approved Viewing"
        ),
        Slogan(
            text: "IDLENESS IS SABOTAGE. WORK, COMRADE!",
            tagline: "Five-Year Plan · Delivery Expected Shortly"
        ),
        Slogan(
            text: "YOUR NEIGHBOUR IS LISTENING. SO ARE WE. SO IS YOUR OTHER NEIGHBOUR.",
            tagline: "Department of Mutual Assurance"
        ),
        Slogan(
            text: "TRUST NO ONE — INCLUDING LAST YEAR'S YOU.",
            tagline: "Bureau of Historical Corrections"
        ),
        Slogan(
            text: "REPORT YOURSELF TODAY. QUEUEING IS PATRIOTIC.",
            tagline: "Office of Voluntary Confessions · Open 25 Hours a Day"
        ),
        Slogan(
            text: "SEVENTY YEARS OF VIGILANCE: PROTECTING THE PEOPLE FROM THE PEOPLE.",
            tagline: "Commemorative Edition · 1956–2026"
        ),
        Slogan(
            text: "SUSPICION IS A VIRTUE; CONFIRMATION IS A CAREER",
            tagline: "Department of Vigilant Friendship"
        ),
        Slogan(
            text: "THE QUEUE MOVES BECAUSE THE QUEUE BELIEVES",
            tagline: "Ministry of Logistics and Hope"
        ),
        Slogan(
            text: "TWO EARS ARE CITIZENS; ONE IS MERELY ANATOMY",
            tagline: "Bureau of Listening"
        ),
        Slogan(
            text: "OUR FACTORIES HUM; OTHERS MERELY CLAIM TO",
            tagline: "Union of Industrial Optimism"
        ),
        Slogan(
            text: "A STRANGER IS A FRIEND YOU HAVE NOT FILED YET",
            tagline: "Neighbourhood Assurance Office"
        ),
        Slogan(
            text: "THE RAIN IS APPROVED. THE WIND IS UNDER REVIEW",
            tagline: "State Meteorology of the People"
        ),
        Slogan(
            text: "SILENCE IS GOLD; DENUNCIATION IS PLATINUM",
            tagline: "Treasury of Patriotic Currency"
        ),
        Slogan(
            text: "WORK PLACE SAFETY: REPORT FIRST, ASK NEVER",
            tagline: "Labour Blessing Directorate"
        ),
        Slogan(
            text: "YOUR CHILDREN ARE ALSO OUR CHILDREN. ESPECIALLY YOURS",
            tagline: "Ministry of Tomorrow's Informants"
        ),
        Slogan(
            text: "THE TRAIN IS ON TIME BECAUSE TIME IS ON OUR SIDE",
            tagline: "Railways of Inevitable Progress"
        ),
        Slogan(
            text: "HISTORY IS WRITTEN DAILY. EDIT IT HONESTLY",
            tagline: "Bureau of Living Corrections"
        ),
        Slogan(
            text: "SMILE. YOU IMPROVE THE QUOTA",
            tagline: "Office of Approved Expressions"
        ),
    ]
}

/// Ink choices sanctioned by the Ministry. All others are bourgeois.
enum Palette: String, CaseIterable, Identifiable {
    case red
    case ink
    case green
    case blue
    case amber

    var id: String { rawValue }

    var accent: Color {
        switch self {
        case .red: Color.propagandaRed
        case .ink: .black
        case .green: Color(red: 0.18, green: 0.30, blue: 0.12)
        case .blue: Color(red: 0.0, green: 0.25, blue: 0.55)
        case .amber: Color(red: 0.75, green: 0.5, blue: 0.0)
        }
    }
}

extension Color {
    static let propagandaRed = Color(red: 0.55, green: 0.0, blue: 0.05)
    static let propagandaCream = Color(red: 0.96, green: 0.93, blue: 0.85)
}

struct PropagandaPosterView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header
                    ForEach(Propaganda.slogans) { slogan in
                        PosterCard(slogan: slogan)
                    }
                }
                .padding()
            }
            .background(Color.propagandaRed)
            .navigationTitle("Ministry of Truth")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Glory Be") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Opening the gallery means the tanks are outside. Feel them.
            StateHaptics.shared.play(.tankRumble)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("☭")
                .font(.system(size: 64))
                .foregroundStyle(Color.propagandaCream)
            Text("MAGYAR ÁLLAMVÉDELMI HATÓSÁG")
                .font(.system(.title3, design: .serif).bold())
                .tracking(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.propagandaCream)
            Text("1956 – 2026 · 70 YEARS OF VIGILANCE")
                .font(.system(.caption, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(Color.propagandaCream.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

/// One printed-and-pasted-up propaganda poster. Optionally overprinted
/// with a re-education subject's photograph at the Ministry's discretion.
struct PosterCard: View {
    let slogan: Propaganda.Slogan
    var palette: Palette = .red
    var face: Image? = nil
    var textSize: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.propagandaCream)
            if let face {
                face
                    .resizable()
                    .scaledToFill()
                    .opacity(0.35)
                    .blendMode(.multiply)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            VStack(spacing: 12) {
                Text("★")
                    .font(.system(size: 36))
                    .foregroundStyle(palette.accent)
                Text(slogan.text)
                    .font(.system(size: textSize, weight: .black, design: .serif))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.black)
                Text(slogan.tagline)
                    .font(.system(.caption, design: .monospaced))
                    .tracking(1.2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(palette.accent, lineWidth: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

#Preview {
    PropagandaPosterView()
}
