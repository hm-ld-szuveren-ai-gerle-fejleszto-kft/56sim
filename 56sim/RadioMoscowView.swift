//
//  RadioMoscowView.swift
//  56sim
//
//  Radio Moscow: the people's ticker. Always on, always correct,
//  occasionally announcing the weather as a political victory.
//

import AVFoundation
import SwiftData
import SwiftUI

enum RadioMoscow {
    static let bulletins: [String] = [
        "Tractors exceed quota for the ninth consecutive year, tractors confirm.",
        "Weather: glorious, as planned.",
        "Neighbour reported neighbour; neighbour thanks state.",
        "Banana arrival date moved forward, then sideways, then approved.",
        "Ministry of Truth corrects yesterday's truth; yesterday pleads guilty.",
        "Cat registered late fined one kilogram of patriotic tuna.",
        "Factory #7 smashes record, record requests transfer to lighter factory.",
        "Radio Moscow announces it never said otherwise; Radio Moscow was correct.",
        "Five-Year Plan enters year four; search for year four continues.",
        "Foreign radio claims our radio lies; our radio claims foreign radio lies better.",
    ]

    /// Bulletins rotate forever; index wraps modulo the people's count.
    static func bulletin(at index: Int, extraTitles: [String] = []) -> String {
        let lines = bulletins + extraTitles
        guard !lines.isEmpty else { return "Silence. Even the radio is nervous." }
        let wrapped = ((index % lines.count) + lines.count) % lines.count
        return lines[wrapped]
    }
}

/// Voice of the state. Slow, British, deeply unbothered.
actor SpeechAnnouncer {
    nonisolated(unsafe) private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    var isSpeaking: Bool { synthesizer.isSpeaking }
}

struct RadioMoscowView: View {
    @Query(sort: \Broadcast.postedAt, order: .reverse) private var broadcasts: [Broadcast]

    @State private var announcer = SpeechAnnouncer()
    @State private var isSpeaking = false

    private var extraTitles: [String] { broadcasts.map(\.title) }

    var body: some View {
        VStack(spacing: 28) {
            Text("📻 RADIO MOSCOW")
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundStyle(.red)

            TimelineView(.periodic(from: .now, by: 0.5)) { context in
                let index = Int(context.date.timeIntervalSince1970 / 12)
                MarqueeLine(text: RadioMoscow.bulletin(at: index, extraTitles: extraTitles))
                    .frame(height: 56)
            }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            Button {
                let index = Int(Date().timeIntervalSince1970 / 12)
                let line = RadioMoscow.bulletin(at: index, extraTitles: extraTitles)
                isSpeaking = true
                Task { await announcer.speak(line) }
            } label: {
                Label("Announce", systemImage: "speaker.wave.3.fill")
            }
            .buttonStyle(.borderedProminent)

            Button {
                isSpeaking = false
                Task { await announcer.stop() }
            } label: {
                Label("Silence the radio", systemImage: "speaker.slash.fill")
            }
            .buttonStyle(.bordered)

            Text("Listening is a civic duty. Listening harder is a promotion.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top)
        .navigationTitle("Radio Moscow")
    }
}

/// One scrolling bulletin: enters right, exits left, twelve seconds of glory.
private struct MarqueeLine: View {
    let text: String

    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(.system(.body, design: .monospaced).bold())
                .fixedSize()
                .offset(x: offset)
                .onAppear {
                    offset = geo.size.width
                    withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
                        offset = -geo.size.width
                    }
                }
        }
    }
}
