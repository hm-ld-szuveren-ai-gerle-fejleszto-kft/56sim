# 56sim

A satirical single-player "People's Republic" iOS game: open dossiers, denounce your neighbours, and try to survive Room 101. Built for the 70th anniversary of the 1956 Hungarian revolution.

This is fiction and satire. 56sim is unaffiliated with any party, state, or secret police, past or present. The only thing being liquidated here is the spare time of the player.

## Features

- **Comrade enrolment** — the profile setup wizard (`ProfileSetupView.swift`) makes you *import* an existing republic file (`.avh`, share sheet or file importer) **or** swear in a new one. Not both. The Party does not do both.
- **A republic in a database** — all state lives in SQLite via `StateStore.swift`; the entire republic exports and imports as a single `.avh` file.
- **The people's registry** — citizen dossiers in `CitizenDetailView.swift`, with interrogation in **Room 407** (`InterrogationView.swift`, an on-device MLX language model plays the interrogator and decides your verdict), Radio Moscow bulletins read aloud by **piper** TTS (`RadioMoscowView.swift`, `PiperAnnouncer.swift`), and a propaganda poster foundry (`PosterView.swift`).
- **The living republic** — `PeopleSimulator.swift` denounces citizens against citizens every 15 seconds, trust collapses on its own, and five denunciations or zero trust auto-neutralises a citizen. One Archive seal per citizen, as is proper.
- **The Ministry of Love** — denounce often enough and it comes for you: seven denunciations against your own alias and the screen belongs to Big Brother (`GameOverView.swift`, "YOU LOVED BIG BROTHER.").
- **Five-Year Plan** — quarterly congress policies, surprise inspections, auditor challenges, and yearly decrees (`PlanView.swift`, `FiveYearPlan.swift`).
- **Defector: Escape 1956** — a 30+ node text adventure with six endings, none of them guaranteed (`DefectorView.swift`).
- **The People's Paper** — a newspaper generated from the actual event log, plus a sortable **Archive of the People** (`PaperView.swift`, `ArchiveView.swift`).
- **Net-rank vigilance** — a leaderboard of who has denounced the most, including the NPCs denouncing *you* (`LeaderboardView.swift`).
- **Administrative suicide** — wiping the republic requires correctly answering three bureaucratic questions first (`SuicideMenuView.swift`).
- **Maximum Core Haptics.** The hammer must be felt.

Manual verification checklist: `MANUAL-TEST.md`.

## Requirements

- Xcode 27.2 or newer. The project uses the JSON `56sim.xcodeproj/project.xcproj` format; older Xcode will not open it.
- iOS 27 deployment target — devices running iOS 27.
- Network access on first build (Swift Package Manager fetches MLX, Hugging Face, and TTS dependencies).

## Build & test

Everything about building, archiving, and producing the sideloadable IPA is in [BUILD.md](BUILD.md). The short version:

```
xcodebuild -skipMacroValidation -project 56sim.xcodeproj -scheme 56sim \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

The `-skipMacroValidation` flag is mandatory; see BUILD.md for why.

## Releases & sideloading

Grab `56sim.ipa` from [GitHub Releases](../../releases). It is deliberately **unsigned** — that is a feature, not an oversight: you keep your own Apple ID relationship, not ours. Sign it locally with [AltStore](https://altstore.io) or Sideloadly (free Apple ID, re-sign every 7 days), or install it permanently via TrollStore on supported iOS versions. Full commands and verification steps in [BUILD.md](BUILD.md).

## License

GPL-2.0, see [LICENSE.md](LICENSE.md). The republic belongs to the people.
