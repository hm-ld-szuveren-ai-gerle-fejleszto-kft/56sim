# 56sim — Manual Test Checklist

All unit tests pass (`** TEST SUCCEEDED **`). This file is the on-device verification list.

## Build for the iPhone 16e

Easiest: open `56sim.xcodeproj` in Xcode, pick the iPhone 16e, hit **Run**. If Xcode asks to
trust the `MLXHuggingFaceMacros` macro, allow it.

Or command line:

```sh
cd /path/to/56sim
# find the UDID with: xcrun devicectl list devices
xcodebuild -skipMacroValidation -project 56sim.xcodeproj -scheme 56sim \
  -destination 'platform=iOS,id=<YOUR-16E-UDID>' build
xcrun devicectl device install app --device <YOUR-16E-UDID> \
  ~/Library/Developer/Xcode/DerivedData/56sim-*/Build/Products/Debug-iphoneos/56sim.app
```

## Checklist

### 1. Registry + denunciation + trust

- Tap **+** → name "Kovács Gyula", add a dossier note → **File Report**.
- Open the citizen. Trust gauge reads **90** (note −10), green, status "Under Surveillance".
- **Report a Colleague** → pick "Listening to enemy radio", fill details → File Report.
- Gauge drops **−15 per report** (75 after one report + note); the denunciation appears under
  "Denunciations" with offence, details, "Filed by <your alias> on …".

### 2. Ministry of Records + checkpoint

- Tap **Mark Cleared**. ~30% of the time a red "🛑 CHECKPOINT" full-screen quiz appears —
  answer right to proceed; answer wrong and you get "DETAINED FOR QUESTIONING… 10" counting
  down for exactly 10 s, buttons disabled.
- After clearing: "Rewritten History" shows `status: "…" → "…"` plus one canned justification
  (rotates through 5: "The record has always shown this." etc.).
- Stress case: file **5+ reports** (score < 30, gauge red), then Mark Cleared — status flips
  back to surveilled on re-entry; both amendments still listed in Rewritten History.

### 3. Five-Year Plan

Ministry menu (star) → Five-Year Plan. Red banner "PLAN FULFILLED IN 4 YEARS! (year 4 not
found)", 5 quotas with progress bars (informants show 1/10,000 after step 1; bananas
"state says so" varies by day).

### 4. Leaderboard

Ministry → Neighbour-Watch. Every rank is net vigilance: **"+filed/−received"**.
Badges read the **net** (≥3 = Order of the Red Star, ≥5 = Iron Neighbour,
≥10 = People's Antenna, below 3 = Loyal Ear), so denunciations filed against
someone visibly demote them. Your own comrade appears once, sorted by net, with
a red **YOU** capsule. Test the ShareLink.

### 5. Defector

Ministry → Defector: Escape 1956. Walk the story tree to any ending ("REACHED AUSTRIA. TRULY.",
"RESETTLED TO SIBERIA FOR AGRICULTURAL CONSULTANCY.", "SENTENCED TO 10 YEARS OF LISTENING TO
APPROVED MUSIC."). Deaths counter increments on bad ends; "Escape again" resets.

### 6. Radio Moscow

Ministry → Radio Moscow. Marquee scrolls a bulletin; **Announce** speaks it in a slow British
voice; **Silence the radio** cuts it off.

### 7. Poster Foundry

Ministry → Poster Foundry. Change slogan / ink colour / size slider → card updates.
Photo picker → neighbour's face ghosted behind text. **Print for the people** → share sheet
with the PNG poster.

### 8. Haptics (device only)

- Opening the registry: long tank rumble (~5 s swell).
- Every 4–9 s, ~40% chance: a sharp stray-bullet tick while the dashboard is open.
- **Mark Neutralized**: T-34 double-fire (bang + long report).
- Ministry menu → toggle **"Silence is suspicious"** on → all haptics stop.

### 9. Interrogation (device — the big one)

- Ministry → Interrogation Room 407 → **Download the Interrogator (628 MB)** — use Wi-Fi,
  watch the progress bar.
- After load: interrogator opens in character, **exactly one question per reply**, English
  only, 1–4 sentences, sarcastic-bureaucratic.
- Use **Confess** and **Deny Everything** — it should escalate on denials and act disappointed
  on confessions.
- After **5 questions**, "State your VERDICT." is forced and a **VERDICT OF THE STATE** banner
  appears with a comic sentence.
- On the simulator instead: tap Download → expect the red "Radio interference — the foreign
  agent line is down." banner + Retry, **no crash** (MLX can't run there by design).

### 10. (Optional) scripted LLM check

Opt-in integration test gated on `LLM_INTEGRATION=YES` in `PeopleRegistryTests` loads
`LiquidAI/LFM2.5-1.2B-Instruct-MLX-4bit` and asserts a non-empty response. Real proof is
step 9 on the phone.

### 11. Living world (PeopleSimulator)

- Leave the dashboard open ~1 min: a grey caption under the toolbar updates with
  simulated history ("… denounced …", "A note appeared in …'s file.",
  "The Authority reclassified …").
- Every ~15 s the state rolls the dice; ~10% of rolls denounce **you**: a red
  "You have been denounced! The queue for your defence is forming." banner with
  **Dismiss**, a report against your alias on the leaderboard (−1 on your row),
  a stray-bullet haptic, and a `player` row in the Archive.
- All simulated rows land in Ministry → The Archive of the People as `simulator`
  (your denunciation as `player`).

If anything misbehaves, report the numbered step and what was observed.
