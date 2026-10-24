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
- **Report a Colleague** → the offence field opens the **crime catalogue sheet**: search
  "enemy", pick "Listening to enemy radio", fill details → File Report.
- Gauge drops **−15 per report** (75 after one report + note); the denunciation appears under
  "Denunciations" with offence, its category · severity · marks caption
  ("Musical · Agricultural Consultancy ●●●"), details, "Filed by <your alias> on …".

### 2. Ministry of Records + checkpoint

- Tap **Mark Cleared**. ~30% of the time a red "🛑 CHECKPOINT" full-screen quiz appears —
  answer right to proceed; answer wrong and you get "DETAINED FOR QUESTIONING… 10" counting
  down for exactly 10 s, buttons disabled.
- After clearing: "Rewritten History" shows `status: "…" → "…"` plus one canned justification
  (rotates through the full 51-line stock, "The record has always shown this." …
  "The glue is older than the objection.").
- Stress case: file **5+ reports** (score < 30, gauge red), then Mark Cleared — status flips
  back to surveilled on re-entry; both amendments still listed in Rewritten History.

### 3. Five-Year Plan (interactive)

Ministry menu (star) → Five-Year Plan. Red banner "PLAN FULFILLED IN 4 YEARS! (year 4 not
found)" and a "Year 1 · quarter 1" line.
- **Congress card**: three policy buttons (e.g. "Steel by Faith" — "Production is a state of
  mind; claim it"). Tapping one raises that quota's bar immediately, logs a line under
  "Proclamations of this commission", and advances the quarter. After quarter 4 the year
  turns and a **DECREE, YEAR n** banner appears with "The people have read it".
- **Inspect** on any quota: shows an inspection line ("You locate a banana. It is green, but
  hopeful.") and bumps the bar. The button then reads disabled with caption "The commission
  is already embarrassed." (once per day per quota).
- Push any quota to **≥ 90%** (Inspect + congress) → a sheet: "An auditor with a Stalin
  moustache claims your figures are impossible. They are merely optimistic." — *Reaffirm the
  numbers harder* weeps the auditor; *Blame a neighbour* reclassifies a random citizen to
  UNDER SURVEILLANCE and names them in the Proclamations log. No auditor again that day.
- Any quota hitting **100%** prints a State Broadcast titled "GLORY: plan fulfilled 4 years
  early." whose body starts "QUOTA GLORY:" + a T-34 haptic — once per quota, ever.

### 4. Leaderboard

Ministry → Neighbour-Watch. Every rank is net vigilance: **"+filed/−received"**.
Badges read the **net** (≥3 = Order of the Red Star, ≥5 = Iron Neighbour,
≥10 = People's Antenna, below 3 = Loyal Ear), so denunciations filed against
someone visibly demote them. Your own comrade appears once, sorted by net, with
a red **YOU** capsule. Test the ShareLink.

### 5. Defector (deepened)

Ministry → Defector: Escape 1956. 44 nodes, six fates: "REACHED AUSTRIA. TRULY.",
"RESETTLED TO SIBERIA FOR AGRICULTURAL CONSULTANCY.", "SENTENCED TO 10 YEARS OF LISTENING TO
APPROVED MUSIC.", "MADE ATTACHÉ TO THE CIRCUS IN VIENNA. TRAPEZE, NOT TRAITS.", "APPOINTED
MINISTER OF RUMOURS. THE RUMOURS DISAPPROVED." and the tractor brigade.
- A grey **trail line** ("Your trail: stairwell → courtyard → thermos …") builds under the
  node text; **Escape again** resets node and trail.
- Canon callbacks: the courtyard guard's **thermos** (paprika tea), Jurica under the
  cabbages (**cabbagemate**), the canal **boatman** who takes payment in stories.
  Circus walk: courtyard → truck → cabbagemate → circusroad → circus.
- Every ending reached lands as a `defector` row in the Archive (once per ending).

### 6. Radio Moscow

Ministry → Radio Moscow. Marquee scrolls a bulletin; **Announce** speaks it in a slow British
voice; **Silence the radio** cuts it off.

### 7. Poster Foundry

Ministry → Poster Foundry. Change slogan (19 approved, incl. "SMILE. YOU IMPROVE THE QUOTA")
/ ink colour (now also **blue** and **amber**) / size slider → card updates.
Photo picker → neighbour's face ghosted behind text. **Print for the people** → share sheet
with the PNG poster.

### 8. Haptics (device only — maxed)

- Opening the registry: tank rumble — a full-intensity 5 s growl that swells to max at 1 s,
  holds, and recedes (4-point curve).
- Every 4–9 s, ~40% chance: stray bullet — **three** sharp full-intensity cracks in a row.
- **Mark Neutralized** / quota glory: T-34 firing — bang, concussive tail, rolling tail-wind.
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

### 12. The People's Paper

Ministry → **The People's Paper** (directly above "The Archive of the People"). Masthead
reads **NÉPSZABADSÁG — THE PEOPLE'S TRUTH** in red serif; subtitle "Price: one act of
loyalty · Printed by the People, for the People, mainly about the People.".
- File one denunciation → its line appears under "DENUNCIATIONS OF THE DAY" as
  "Correspondent <you> reports on <victim>: …"; a quota glory leads the front page
  (headline = QUOTA GLORY line); quiet day → "QUIET DAY. SUSPICIOUSLY QUIET.".
- WEATHER / SPORTS / LETTERS TO THE EDITOR / SCOREBOARD OF VIGILANCE sections appear in
  that order. **Print extra edition** raises "Edition n" by exactly 1 (before/after).

### 13. Crime catalogue search

Report a Colleague → offence sheet: search "salt" narrows to the salt crime; the
**Category** chip "Animals" filters by category; the **Severity** chip "Agricultural
Consultancy" filters by severity (tap the chip again to clear). An empty search (try
"banana") shows "No such crime exists. Yet." + **Charge them anyway**, which selects
"Other (the file is creative)" — and its "Paperwork · Watchlist ●" caption then appears
on the dossier's denunciation row.

### 14. Archive of the People (regression)

Congress votes, inspections, auditor answers and quota glories all land as `plan` rows in
Ministry → The Archive of the People; defector endings as `defector` rows. The Archive's
sort, chips and search behave as before.

If anything misbehaves, report the numbered step and what was observed.
