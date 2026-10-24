//
//  RadioMoscowView.swift
//  56sim
//
//  Radio Moscow: the people's ticker. Always on, always correct,
//  occasionally announcing the weather as a political victory.
//

import Foundation
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
        "Central Heating declares winter defeated; citizens may continue freezing patriotically.",
        "Railways announce 100% punctuality for trains that were never scheduled.",
        "The new soap exceeds plan; plan requests a smaller soap.",
        "Pigeon population fulfils the Five-Year Plan ahead of pigeon expectations.",
        "Yesterday's bread rated historically fresh by tomorrow's standards.",
        "Football team wins by refusing to lose; referees confirm the scoreline.",
        "Library reports record borrowing; the book report reports record reading.",
        "The weather office reports itself sunny in all districts of the people.",
        "Beekeeping quotas met by approved bees in approved rows.",
        "A factory's factory exceeds its factory's plan by factory standards.",
        "Cinema ticket sales soar; cinema has one chair and it is loyal.",
        "Postal service delivers yesterday's letters today, faster than anyone expects.",
        "Chess champion defeats opponent who withdrew in solidarity in 1951.",
        "The people's queue reaches its goal before the shop opens; shop praised.",
        "New elevator installed in ground-floor building; residents remain humble.",
        "Telephone exchange reports zero crossed lines; two comrades report love.",
        "Bakery adopts new method: bread now announces itself as abundant.",
        "Scientist invents silent whistle; factory mass-produces approval.",
        "Census counts the state's joy at 110%; statisticians revise down to 100%.",
        "Tractor parts arrive on time for the tractor invented next spring.",
        "Radio Moscow's shadow confirms it said the same thing louder yesterday.",
        "National garden reports potatoes of unusual length; length reclassified as progress.",
        "Tailor suits entire district with fabric measured in enthusiasm.",
        "Postman walks forty kilometres daily; distance awarded medal of the people.",
        "Weather forecast for tomorrow identical to today's forecast, guaranteed correct.",
        "Schoolchildren name their hamster after the plan; hamster complies.",
        "Bridge completes two-year repair in two years; river expresses gratitude.",
        "Cinema censor cuts foreign film to seven minutes; seven minutes win festival.",
        "Astronomers discover new star; star is late and apologises.",
        "Chess club's lost piece found guilty of desertion, returned reformed.",
        "State farm's cow gives triple milk after attending agitation meeting.",
        "Bicycle plant fulfils cycle plan; wheels report no complaints.",
        "Tourists visit ruined castle; castle renovated overnight by request.",
        "Barometer predicts storm; barometer reprimanded for pessimism; storm cancelled.",
        "New dictionary removes eleven useless words; savings announced in rubles.",
        "Conductor's baton awarded order of labour; orchestra follows without music.",
        "Postal donkey retires after thirty years of flawless deliveries; archives open file.",
        "Factory clock runs two minutes fast; workers rewarded with two more minutes.",
        "Chess grandmaster offers draw; state interprets as victory by the people.",
        "Ministry of statistics redefines rain as applause from the sky; umbrellas fined.",
        "Theatres premiere new play; audience applause scheduled for interval.",
        "Beekeepers report honey surplus; wasps invited to reformat.",
        "Newspaper reports its own distribution record; kiosk confirms, politely.",
        "Inventor's perpetual motion machine declined; motion deemed temporary per policy.",
        "Tram schedule extended by one stop; passengers grateful for the horizon.",
        "Orchard harvest doubles; trees credited with ideological conviction.",
        "Radio Moscow predicts fair weather for the parade; parade postponed to fairer weather.",
        "Citizen's clock strikes thirteen; citizen reported; clock reported too.",
        "Puppet show's wolf reformed; puppeteer files a reformation certificate.",
        "Mirror factory ships reflective glass; the state sees only improvement.",
        "State chorus hits record low note; low note raised on appeal.",
        "Chess clocks abolished; time itself accused of bourgeois impatience.",
    ]

    /// Bulletins rotate forever; index wraps modulo the people's count.
    static func bulletin(at index: Int, extraTitles: [String] = []) -> String {
        let lines = bulletins + extraTitles
        guard !lines.isEmpty else { return "Silence. Even the radio is nervous." }
        let wrapped = ((index % lines.count) + lines.count) % lines.count
        return lines[wrapped]
    }
}

struct RadioMoscowView: View {
    @State private var store = StateStore.shared

    @State private var announcer = PiperAnnouncer.shared
    @State private var tickerIndex = 0

    private var broadcasts: [Broadcast] {
        _ = store.revision
        return store.broadcasts()
    }

    private var extraTitles: [String] { broadcasts.map(\.title) }

    var body: some View {
        VStack(spacing: 28) {
            Text("📻 RADIO MOSCOW")
                .font(.system(.title2, design: .monospaced).bold())
                .foregroundStyle(.red)

            TickerLine(
                line: RadioMoscow.bulletin(at: tickerIndex, extraTitles: extraTitles),
                onCycleComplete: {
                    tickerIndex += 1
                    if announcer.isSpeaking {
                        announcer.speak(
                            RadioMoscow.bulletin(at: tickerIndex, extraTitles: extraTitles))
                    }
                }
            )
            .id(tickerIndex)
            .frame(height: 56)
            .padding(.horizontal)

            switch announcer.phase {
            case .notDownloaded:
                Text("Turn up the volume to fetch the voice of the people (60 MB, once).")
                    .font(.caption).foregroundStyle(.secondary)
            case .downloading(let fraction):
                VStack(spacing: 6) {
                    ProgressView(value: fraction)
                    Text("\(Int(fraction * 100))% — the state is rehearsing")
                        .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: 280)
            case .failed(let reason):
                Text(reason).font(.callout.bold()).foregroundStyle(.red)
            case .ready:
                EmptyView()
            }

            Button {
                announcer.speak(RadioMoscow.bulletin(at: tickerIndex, extraTitles: extraTitles))
            } label: {
                Label("Turn up the volume", systemImage: "speaker.wave.3.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(announcer.isSpeaking)

            Button {
                announcer.stop()
            } label: {
                Label("Silence the radio", systemImage: "speaker.slash.fill")
            }
            .buttonStyle(.bordered)
            .disabled(!announcer.isSpeaking)

            Text("Listening is a civic duty. Listening harder is a promotion.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.top)
        .navigationTitle("Radio Moscow")
    }
}

/// One bulletin at a time: enters right, exits left at constant speed;
/// on completion the parent swaps in the next line and the .id() resets us.
private struct TickerLine: View {
    let line: String
    let onCycleComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    private static let speed: CGFloat = 55  // points per second

    var body: some View {
        GeometryReader { geo in
            Text(line)
                .font(.system(.body, design: .monospaced).bold())
                .fixedSize()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: {
                    textWidth = $0
                }
                .offset(x: offset)
                .onAppear {
                    offset = geo.size.width
                    startCycle(width: geo.size.width)
                }
                .onChange(of: line) { _, _ in
                    offset = geo.size.width
                    startCycle(width: geo.size.width)
                }
        }
    }

    private func startCycle(width: CGFloat) {
        let distance = width + max(textWidth, 1)
        let duration = Double(distance / Self.speed)
        withAnimation(.linear(duration: duration)) {
            offset = -max(textWidth, 1)
        } completion: {
            onCycleComplete()
        }
    }
}
