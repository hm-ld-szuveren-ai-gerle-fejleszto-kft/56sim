//
//  Defector.swift
//  56sim
//
//  "Defector: Escape 1956" — a choose-your-own-fate where geography is
//  political and every farmer is an informant. Acyclic graph, six fates:
//  Austria, Siberia, approved music, the circus, the ministry of rumours,
//  and the tractor brigade. The cabbage trucks run deep.
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
    static let circusEnding = "MADE ATTACHÉ TO THE CIRCUS IN VIENNA. TRAPEZE, NOT TRAITS."
    static let rumourEnding = "APPOINTED MINISTER OF RUMOURS. THE RUMOURS DISAPPROVED."
    static let tractorEnding = "CONSCRIPTED TO THE TRACTOR BRIGADE. THE TRACTOR WAS A MODEL."

    /// All edges advance toward the border; the archive's inspectors prove
    /// with a DFS that history never repeats itself (no cycles are permitted).
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
                    StoryChoice(label: "Approach the bored guard's thermos", nextId: "thermos"),
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
                    StoryChoice(label: "Salute the patrol honestly", nextId: "honest"),
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
                    StoryChoice(label: "Trade cabbage with the shadow beside you", nextId: "cabbagemate"),
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
                    StoryChoice(label: "Ask the boatman his politics", nextId: "boatman"),
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
            // The republic expands: thermos guards, cabbage mates, choirs,
            // tailors, ferries, and at least two rumours with your name on them.
            StoryNode(
                id: "thermos",
                text:
                    "The bored guard offers paprika tea from a dented thermos. He is lonely on duty, and loneliness at a border is an opportunity with a lid.",
                choices: [
                    StoryChoice(label: "Ask about the border dog", nextId: "dog2"),
                    StoryChoice(label: "Tip the thermos (a distraction)", nextId: "truck"),
                    StoryChoice(label: "Compliment the moustache", nextId: "rumour"),
                ]
            ),
            StoryNode(
                id: "dog2",
                text:
                    "The thermos guard's dog, it emerges, also loves sausage and personally knows Mrs. Szabó's cousin. Family is complicated at the border; loyalty is simpler.",
                choices: [
                    StoryChoice(label: "Give the last sausage", nextId: "border"),
                    StoryChoice(label: "Ask the dog about Austria", nextId: "canal"),
                ]
            ),
            StoryNode(
                id: "cabbagemate",
                text:
                    "The shadow beside you smells of cabbage and confession. It is Jurica, allegedly, and he has a plan involving the circus.",
                choices: [
                    StoryChoice(label: "Trust Jurica", nextId: "circusroad"),
                    StoryChoice(label: "Trade him to the guard for a head start", nextId: "border"),
                ]
            ),
            StoryNode(
                id: "circusroad",
                text:
                    "The tram to Sopron is driven by a trapeze enthusiast who took the job for the timetable. He speaks of Vienna in the future tense.",
                choices: [
                    StoryChoice(label: "Ride to Sopron", nextId: "circus"),
                    StoryChoice(label: "Get off at the checkpoint", nextId: "peek"),
                ]
            ),
            StoryNode(
                id: "boatman",
                text:
                    "The boatman rows in the correct direction for a fee of one story. Any story. He has heard the good ones and still rows.",
                choices: [
                    StoryChoice(label: "Tell him a rumour", nextId: "rumour"),
                    StoryChoice(label: "Tell the truth about the weather", nextId: "austria"),
                    StoryChoice(label: "Refuse to pay", nextId: "siberia"),
                ]
            ),
            StoryNode(
                id: "honest",
                text:
                    "You salute the patrol honestly. The patrol salutes back. Honesty is the least suspicious option today, which tells you everything about today.",
                choices: [
                    StoryChoice(label: "Walk toward the trucks", nextId: "truck"),
                    StoryChoice(label: "Walk toward the canal", nextId: "canal"),
                ]
            ),
            StoryNode(
                id: "market",
                text:
                    "The Saturday market hums with honest trade and honest faces, which is how you know every stall is also an informant's office.",
                choices: [
                    StoryChoice(label: "Buy pickles (a disguise)", nextId: "truck"),
                    StoryChoice(label: "Sell your watch for a map", nextId: "map"),
                    StoryChoice(label: "Ask for the fishmonger who owes Mrs. Szabó", nextId: "szabo2"),
                ]
            ),
            StoryNode(
                id: "map",
                text:
                    "The map is hand-drawn, wrong twice, and marks Austria as 'nice'. The cartographer's optimism is contagious if not accurate.",
                choices: [
                    StoryChoice(label: "Trust the map", nextId: "field"),
                    StoryChoice(label: "Trust the sun instead", nextId: "canal"),
                ]
            ),
            StoryNode(
                id: "szabo2",
                text:
                    "Mrs. Szabó's cousin runs the pickle stall and owes nothing to nobody, she insists. The pickles are excellent, which is itself a rumour.",
                choices: [
                    StoryChoice(label: "Pay in wool socks", nextId: "truck"),
                    StoryChoice(label: "Blackmail gently", nextId: "rumour"),
                ]
            ),
            StoryNode(
                id: "station",
                text:
                    "The depot master recognises you from the posters and confesses to being a fan. His admiration is warm; his schedules are secret.",
                choices: [
                    StoryChoice(label: "Ask for the 04:10 freight", nextId: "truck"),
                    StoryChoice(label: "Ask about trains that do not exist", nextId: "rumour"),
                ]
            ),
            StoryNode(
                id: "choir",
                text:
                    "You hide inside the May Day choir rehearsal until dawn. Nobody checks the faces of a choir, because nobody is supposed to enjoy it.",
                choices: [
                    StoryChoice(label: "Sing (badly, safely)", nextId: "border"),
                    StoryChoice(label: "Miss your cue deliberately", nextId: "honest"),
                ]
            ),
            StoryNode(
                id: "library",
                text:
                    "The librarian with opinions has forbidden you from three books and respects you for it. She stamps your card with something that is not the date.",
                choices: [
                    StoryChoice(label: "Ask for the atlas (foreign edition)", nextId: "map"),
                    StoryChoice(label: "Ask what is forbidden today", nextId: "rumour"),
                ]
            ),
            StoryNode(
                id: "radio",
                text:
                    "A western radio plays in a cellar behind a curtain of overalls. The owner charges one song per crossing and accepts no requests.",
                choices: [
                    StoryChoice(label: "Sing the five-tone melody", nextId: "austria"),
                    StoryChoice(label: "Sing the approved one (boring him into silence)", nextId: "truck"),
                ]
            ),
            StoryNode(
                id: "soup",
                text:
                    "The canteen serves a soup that is mostly rumour, and the cook knows every back door in the district, alphabetised.",
                choices: [
                    StoryChoice(label: "Order the second helping (bribe)", nextId: "truck"),
                    StoryChoice(label: "Compliment the salt (dangerous)", nextId: "market"),
                ]
            ),
            StoryNode(
                id: "postbox",
                text:
                    "You post a letter to yourself from Vienna as a test of morale. The postman winks. Belief, he says, is the only valid passport.",
                choices: [
                    StoryChoice(label: "Follow the postman's advice", nextId: "canal"),
                    StoryChoice(label: "Follow your own advice", nextId: "field"),
                ]
            ),
            StoryNode(
                id: "tailor",
                text:
                    "The tailor measures you for 'travel papers and a coat of foreign cut', in quotes, out loud, cheerfully.",
                choices: [
                    StoryChoice(label: "Pay in buttons", nextId: "truck"),
                    StoryChoice(label: "Wear it immediately (suspiciously clean)", nextId: "map"),
                ]
            ),
            StoryNode(
                id: "ferry",
                text:
                    "The ferryman demands one approved joke before crossing. The last one told was not funny, and the ferryman keeps a long ledger of such things.",
                choices: [
                    StoryChoice(label: "Tell the tractor joke", nextId: "austria"),
                    StoryChoice(label: "Tell the queue joke (risky)", nextId: "rumour"),
                ]
            ),
            StoryNode(
                id: "orchard",
                text:
                    "You climb the wrong apple tree and receive, free of charge, a view of the entire border. The apples are small; the perspective is not.",
                choices: [
                    StoryChoice(label: "Climb toward Austria", nextId: "field"),
                    StoryChoice(label: "Descend and file nothing", nextId: "honest"),
                ]
            ),
            StoryNode(
                id: "band",
                text:
                    "The factory band plays a march in four tones and you are conscripted as triangle. One stick, one note, and the note is not in the march.",
                choices: [
                    StoryChoice(label: "Play your one note well", nextId: "truck"),
                    StoryChoice(label: "Break your triangle", nextId: "music"),
                ]
            ),
            StoryNode(
                id: "telegram",
                text:
                    "You send a telegram reading 'ARRIVED FINE' to prove a theory about belief. The telegraph office believes you already. That is the worrying part.",
                choices: [
                    StoryChoice(label: "Believe it yourself and travel light", nextId: "canal"),
                    StoryChoice(label: "Recollect it at the office", nextId: "siberia"),
                ]
            ),
            StoryNode(id: "austria", text: Defector.austriaEnding, choices: []),
            StoryNode(id: "siberia", text: Defector.siberiaEnding, choices: []),
            StoryNode(id: "music", text: Defector.musicEnding, choices: []),
            StoryNode(id: "tractor", text: Defector.tractorEnding, choices: []),
            StoryNode(id: "circus", text: Defector.circusEnding, choices: []),
            StoryNode(id: "rumour", text: Defector.rumourEnding, choices: []),
        ]
        return Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
    }()
}

struct DefectorView: View {
    @State private var store = StateStore.shared
    @State private var nodeID = Defector.startID
    @State private var deaths = 0
    @State private var path: [String] = []
    @State private var loggedEndings: Set<String> = []

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
            if !path.isEmpty {
                Text("Your trail: " + path.joined(separator: " → "))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            if node.isEnding {
                Text("ATTEMPTS FAILED: \(deaths)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Escape again") {
                    if !node.id.isEmpty { deaths += (node.id == "austria" ? 0 : 1) }
                    nodeID = Defector.startID
                    path = []
                }
                .buttonStyle(.borderedProminent)
            } else {
                ForEach(node.choices, id: \.nextId) { choice in
                    Button(choice.label) {
                        path.append(choice.nextId)
                        nodeID = choice.nextId
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Escape 1956")
        .task(id: nodeID) {
            // Every fate reached is filed once; the Archive remembers
            // even if the escapee immediately tries again.
            guard node.isEnding, !loggedEndings.contains(nodeID) else { return }
            loggedEndings.insert(nodeID)
            store.log(
                kind: .defector,
                actor: store.profile()?.alias ?? "A citizen",
                subject: nodeID,
                text: node.text
            )
        }
    }
}
