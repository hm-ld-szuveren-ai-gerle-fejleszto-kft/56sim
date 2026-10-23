//
//  Defector.swift
//  56sim
//
//  "Defector: Escape 1956" — a choose-your-own-fate where geography is
//  political and every farmer is an informant. Acyclic graph, three fates.
//

import SwiftUI

struct StoryChoice {
    let label: String
    let nextId: String
}

struct StoryNode {
    let id: String
    let text: String
    let choices: [StoryChoice]

    var isEnding: Bool { choices.isEmpty }
}

enum Defector {
    static let startID = "flat"

    static let austriaEnding = "REACHED AUSTRIA. TRULY."
    static let siberiaEnding = "RESETTLED TO SIBERIA FOR AGRICULTURAL CONSULTANCY."
    static let musicEnding = "SENTENCED TO 10 YEARS OF LISTENING TO APPROVED MUSIC."

    /// All edges point forward in this declaration order — the graph is a DAG.
    static let nodes: [String: StoryNode] = {
        let list: [StoryNode] = [
            StoryNode(
                id: "flat",
                text:
                    "Budapest, autumn 1956. Rain on the window, boots in the corridor, and a knock that is not friendly. The list on the door says your street has one quota left to fill.",
                choices: [
                    StoryChoice(label: "Slip out the back stairs", nextId: "stairwell"),
                    StoryChoice(label: "Feign deep sleep", nextId: "bed"),
                ]
            ),
            StoryNode(
                id: "bed",
                text:
                    "You breathe like a statue. The knock becomes a key in the lock — someone has a spare. That is new information about your neighbours.",
                choices: [
                    StoryChoice(label: "Meet them at the door", nextId: "door"),
                    StoryChoice(label: "Out the window, down the drainpipe", nextId: "drainpipe"),
                ]
            ),
            StoryNode(
                id: "stairwell",
                text:
                    "On the landing, Mrs. Szabó from 3B watches you with the calm of a woman who has already written the letter.",
                choices: [
                    StoryChoice(label: "Bribe her with a wool sock", nextId: "sock"),
                    StoryChoice(label: "Sprint past her", nextId: "courtyard"),
                ]
            ),
            StoryNode(
                id: "door",
                text:
                    "Two men, one badge, no patience. 'Papers.' The card in your pocket is warm with fabrication.",
                choices: [
                    StoryChoice(label: "Present the forged papers", nextId: "papers"),
                    StoryChoice(label: "Claim to be your own cousin", nextId: "cousin"),
                ]
            ),
            StoryNode(
                id: "drainpipe",
                text:
                    "You slide into the courtyard and land before a dog the size of a filing cabinet. It has opinions.",
                choices: [
                    StoryChoice(label: "Feed it your sausage", nextId: "dog"),
                    StoryChoice(label: "Freeze like a monument", nextId: "statue"),
                ]
            ),
            StoryNode(
                id: "sock",
                text:
                    "The sock is grey, wool, and decisive. Mrs. Szabó pockets it and mentions, to no one, that she saw nobody.",
                choices: [
                    StoryChoice(label: "Slip into the courtyard", nextId: "courtyard")
                ]
            ),
            StoryNode(
                id: "courtyard",
                text:
                    "Dawn. Freight trucks idle by the depot, cabbage smell in the air, one bored guard checking a clipboard.",
                choices: [
                    StoryChoice(label: "Hide under the cabbages", nextId: "truck"),
                    StoryChoice(label: "Walk out boldly carrying a crate", nextId: "crate"),
                ]
            ),
            StoryNode(
                id: "papers",
                text:
                    "The guard squints at your papers. The stamp is dated 1953. 'A pre-owned document,' you offer.",
                choices: [
                    StoryChoice(label: "Blame the post — 'postal delay'", nextId: "postal"),
                    StoryChoice(label: "Confess everything immediately", nextId: "music"),
                ]
            ),
            StoryNode(
                id: "cousin",
                text:
                    "You are now your cousin Jurica, who does not exist. The guard frowns: 'Jurica lives in Pécs.' So does your alibi, apparently.",
                choices: [
                    StoryChoice(label: "Answer to 'Jurica' confidently", nextId: "truck"),
                    StoryChoice(label: "Run", nextId: "courtyard"),
                ]
            ),
            StoryNode(
                id: "dog",
                text:
                    "The dog approves of sausage and, by extension, of you. It trots toward the canal with professional confidence.",
                choices: [
                    StoryChoice(label: "Follow the dog", nextId: "canal"),
                    StoryChoice(label: "Ask the dog for a better idea", nextId: "statue"),
                ]
            ),
            StoryNode(
                id: "statue",
                text:
                    "You hold so still a patrol walks past twice. Freedom smells of cabbage and diesel.",
                choices: [
                    StoryChoice(label: "Make for the trucks", nextId: "truck"),
                    StoryChoice(label: "Make for the canal", nextId: "canal"),
                ]
            ),
            StoryNode(
                id: "postal",
                text:
                    "'The postal service,' the guard laughs, a rare state event, 'is indeed a bourgeois disaster.' He waves you toward the trucks.",
                choices: [
                    StoryChoice(label: "Laugh along, board the truck", nextId: "truck"),
                    StoryChoice(label: "Slip away while he chuckles", nextId: "canal"),
                ]
            ),
            StoryNode(
                id: "truck",
                text:
                    "Under cabbages, the truck groans eastward — or westward, you hope westward. A border is somewhere under the leaves.",
                choices: [
                    StoryChoice(label: "Stay hidden until the end", nextId: "border"),
                    StoryChoice(label: "Peek out", nextId: "peek"),
                ]
            ),
            StoryNode(
                id: "crate",
                text:
                    "You march past the guard carrying a crate with supreme confidence. 'What is inside?' It is your laundry. Say something ideological.",
                choices: [
                    StoryChoice(label: "'Machine parts. Gloriously.'", nextId: "border"),
                    StoryChoice(label: "Open it (it is your laundry)", nextId: "peek"),
                ]
            ),
            StoryNode(
                id: "peek",
                text:
                    "You peek. Simultaneously, so does a border guard. Eye contact at forty kilometres per hour.",
                choices: [
                    StoryChoice(label: "Play dead among the cabbages", nextId: "border"),
                    StoryChoice(label: "Sprint for the trees", nextId: "siberia"),
                ]
            ),
            StoryNode(
                id: "canal",
                text:
                    "A rowboat, one oar, and a river that flows in the correct direction for once.",
                choices: [
                    StoryChoice(label: "Row toward Austria", nextId: "austria"),
                    StoryChoice(label: "Row toward whichever way feels safe", nextId: "siberia"),
                ]
            ),
            StoryNode(
                id: "field",
                text:
                    "Open field, border fence glinting, one guard and his rifle warming their hands on a thermos.",
                choices: [
                    StoryChoice(label: "Crawl the long way", nextId: "austria"),
                    StoryChoice(label: "Ask the passing farmer for a lift", nextId: "siberia"),
                ]
            ),
            StoryNode(
                id: "border",
                text:
                    "The fence, one sleepy guard, and his dog — who, fortunately, also loves sausage.",
                choices: [
                    StoryChoice(label: "Distract the dog with the last sausage", nextId: "austria"),
                    StoryChoice(label: "Wait until dawn", nextId: "music"),
                ]
            ),
            StoryNode(id: "austria", text: Defector.austriaEnding, choices: []),
            StoryNode(id: "siberia", text: Defector.siberiaEnding, choices: []),
            StoryNode(id: "music", text: Defector.musicEnding, choices: []),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }()
}

struct DefectorView: View {
    @State private var nodeID = Defector.startID
    @State private var deaths = 0

    private var node: StoryNode { Defector.nodes[nodeID] ?? Defector.nodes[Defector.startID]! }

    var body: some View {
        VStack(spacing: 24) {
            Text("☭ DEFECTOR: ESCAPE 1956 ☭")
                .font(.system(.headline, design: .monospaced).bold())
                .foregroundStyle(.red)
            Text(node.text)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .frame(maxHeight: 220, alignment: .top)
            if node.isEnding {
                Text("ATTEMPTS FAILED: \(deaths)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Escape again") {
                    if !node.id.isEmpty { deaths += (node.id == "austria" ? 0 : 1) }
                    nodeID = Defector.startID
                }
                .buttonStyle(.borderedProminent)
            } else {
                ForEach(node.choices, id: \.nextId) { choice in
                    Button(choice.label) { nodeID = choice.nextId }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Escape 1956")
    }
}
