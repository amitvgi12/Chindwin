# Devlog

What was done, what was decided, and why. Newest session first.

## 2026-11-15, session 1 continued: waypoints and suppression

### Reported by Amit

- CI is green on the firing and cover commit. The Windows export job was skipped, as
  designed: it runs only on version tags and manual runs.
- The trial look is acceptable.

### Done

- **Waypoints.** Shift + right-click adds a leg after the team's current route. The
  route still to be walked is drawn for the selected team.
- **Suppression.** Every shot, hit or miss, adds pressure to the man shot at and a
  little to each comrade next to him. Cover in front of a man reduces it. It fades
  when the firing stops.
- **Pinned.** At half the scale a man is pinned: he stops walking, keeps his order,
  fires half as often and half as well, and carries on when the pressure fades.
- **Fire spreads.** A man aims at the opponent under the least pressure, then the
  nearest. A team's fire now covers the whole picket.
- **Meter.** A bar over each man fills as pressure rises, with a tick at the pinned
  level. It turns orange and the man is drawn smaller once he is pinned. The status
  strip counts pinned men on both sides.
- 112 tests pass. `make check` is clean.

### How to see it

Run `make run`.

1. Select team 1 and right-click just left of the middle bank. Press Space and wait.
2. Watch the bars over the red diamonds. When they turn orange the picket is pinned.
3. Press Space to pause. Press `2`. Right-click above the top block of jungle, then
   Shift + right-click on the open ground north of the diamonds. A thin line shows the
   route. Press Space.
4. For comparison press `R` and send team 2 on the same route straight away, before
   team 1 has pinned anybody.

**What "right" looks like:** a pinned man shrinks, stops walking and fires rarely; a
team that moves while the picket is pinned loses far fewer men than one that moves
first; the bars drain when nobody is shooting at a man.

### What the numbers show

Two runs of the same plan with the same seed. When team 2 set off at the same moment
as team 1, four of its five men were shot crossing the north side. When it set off six
seconds later, with team 1 already firing, it lost one. That gap is the game.

### Verified

- Rules by unit tests, each from the written description of the rule.
- The picture by screenshot: meters, shrunken pinned men, route and status counts.
- CI on Linux through to the tests, on the previous commit.

### Not verified

- How suppression reads in motion, and whether the timing feels right.
- Balance. The numbers in `prototype_rules.tres` are first guesses. Nothing yet checks
  Gate 1 criterion 1.
- The Windows export job in CI, and the Windows build itself.

### Decisions and why

| Decision | Why |
|---|---|
| Suppression is one number per man, 0 to 100 | It is the short-term half of "will to fight" in the GDD. Condition (hunger, fatigue) joins it in Phase 2. |
| Misses suppress as much as hits | Pressure comes from being shot at. This is what lets a team with poor odds of hitting still be useful. |
| A pinned man keeps his order | The player should not have to re-issue orders after every burst. Being pinned costs time, not intent. |
| Aim at the least-suppressed opponent | With "aim at the nearest", five rifles pinned one man and left three free to shoot. |
| No "broken" state yet | Falling back and surrender need the enemy behaviour work, which is next. |
| Tests switch suppression off unless they are about it | Each rule can then be checked alone with round numbers. |

## 2026-11-15, session 1 continued: firing, cover and a first look

### What prompted it

Amit played the thin loop and said: "this is just pixels, no feel of background
settings, story". Two causes. His men could not shoot, so there was no game. And the
grey box, which his own brief asked for, gave no sense of place.

### Done

- **Firing for both sides.** A man who is standing still, allowed to fire, has rounds
  left and can see an opponent in range fires at the nearest. A man who is walking
  does not fire. Shots in a tick are decided together, so two men can hit each other.
- **Weapons as data** in `game/data/weapons/`. One placeholder rifle. Rounds are
  counted per man and shown per team.
- **Hold fire.** `F` switches the selected team between holding fire and firing.
- **Cover.** A low bank stops movement, not sight. It protects a man only from a shot
  whose last cell before him is the bank. Fire from the side or rear ignores it.
- **A trial look**, drawn in code with no art files: wet ground, thick jungle, earth
  banks, a muddy track, rain that stops while paused, and a paused banner.
- **Draft briefing** in `docs/history/mission-01.md`, every sentence tied to a page of
  the one source read so far. Not in the game until Amit checks it.
- 94 tests pass. `make check` is clean.

### How to see it

Run `make run`.

1. **Frontal attack.** Select each team and right-click just in front of the right-hand
   bank. Press Space. Men walking in the open cannot fire and are shot down.
2. **Pin and flank.** Press `R`. Send team 1 to stand just left of the middle bank.
   Send team 2 north in stages: first above the top block of jungle, then to the
   ground north of the red diamonds. From there their shots do not cross the bank.
3. **Ammunition.** Watch the rounds fall. Press `F` to make a team hold fire.

**What "right" looks like:** fire across a bank kills slowly; fire from the side kills
quickly; walking men never fire; a team holding fire spends no rounds; the rain and
the men stop when paused.

### What the recorded battle shows

With team 1 at the middle bank and team 2 sent to the north flank, the picket's four
men all fall. Team 1 loses one man and spends about sixteen rounds each for no result.
Team 2 loses one man and needs about five rounds each. That is pillar 1 appearing in
the rules before suppression exists.

### Found by looking

- **The shortest path runs through the killing ground.** Told to go to the north flank
  in one order, a team walked through the centre and lost four of five. Waypoints are
  now the next backlog item.
- The first ground pattern looked like a chessboard and the banks like minus signs.
  Both fixed after the screenshot.

### Verified

- Rules by unit tests. The picture by screenshot.
- **Real mouse and keyboard work.** Amit's screenshot shows both teams moved by hand.
- **CI runs on Linux** as far as lint: checkout, the Godot download, the Python
  environment and the linter all worked on the first push.

### Not verified

- CI beyond the lint step: the compile check and tests have not yet run on Linux.
- How the look reads in motion, and whether Amit can accept it as a direction.
- The Windows build.

### The red CI run

The first push included a commit of the working tree taken while this step was half
done: unformatted and without its tests. The lint step failed on formatting, which is
what it is for. The step is now complete and passes locally.

### Decisions and why

| Decision | Why |
|---|---|
| Showed a trial look now, though the brief keeps art for Phase 3 | A direction Amit cannot accept is cheaper to find now than after Gate 2. It is code only, costs no money, and changes no rule. Art direction is still decided in Phase 3. |
| Cover is decided by the last cell a shot crosses | One rule gives directional cover with no facing or angles to store, and it is what makes going round the side worth it. |
| Men fire on their own; the player controls only hold fire | The smallest thing that creates the choice between firing and moving, and between firing and saving rounds. A "fire at that target" order can come later if it is missed. |
| Rain and the track are decoration for now | They show the setting. Weather becomes a rule in Phase 2. Both are listed as rough edges so nobody mistakes them for rules. |
| The rifle is labelled "(placeholder)" and has invented numbers | No weapon is sourced yet. The label keeps that visible. |
| Briefing text waits for Amit to read the two pages | The history rule: nothing unverified in game text. The check takes about ten minutes. |

## 2026-11-15, session 1 continued: Gate 0 and the first Phase 1 step

### Decided by Amit

- **Gate 0 approved.**
- The earlier vertical-slice notes are background. The current build is a demo. The
  game may move towards the 3D vision later if the demo and investors support it;
  that will be a separate written decision.

### Done

- **Simulation core** in `game/src/sim/`: grid with blocked cells, pathfinding and line
  of sight; scenario loaded from JSON with plain-language errors; queued move orders;
  walking at a tick cost per cell; a placeholder enemy that fires at the nearest man it
  can see within range.
- **Test range** as data: `game/data/scenarios/test_range.json` and
  `game/data/rules/prototype_rules.tres`.
- **Thin playable loop** in `game/src/ui/battle_view.gd`: two teams, selection, move
  orders, pause, restart, a status strip.
- **`make screenshot`**: plays a scripted battle in a window and saves a picture, so
  Claude can look at the game.
- 63 tests pass. `make check` is clean.

### How to see it

Run `make run`. The game starts paused.

1. Press `2`, then right-click open ground near the middle of the map. Small hollow
   squares show where each man of team 2 will stand.
2. Press Space. Team 2 walks there, going round the grey blocks.
3. Send a team to within sight of the red diamonds on the right. Yellow lines are
   shots that missed, red lines are hits, and a man who is hit becomes a grey crossed
   circle. The strip at the bottom counts who is still fit.
4. Keep a grey block between a team and the diamonds and nobody fires at it.
5. Press Space to pause, give new orders while paused, press `R` to start again.

**What "right" looks like:** men never walk through grey blocks; nobody is shot through
a block; the enemy only fires at men within about fourteen cells; orders given while
paused take effect when the game resumes.

**What is deliberately missing:** your men cannot shoot. There is no cover, no
suppression and no way to win. Those are the next backlog items.

### Verified

- All rules above by unit tests, including the fire interval and line of sight.
- The picture, by screenshot: map, both teams with numbers, the ring on the selected
  team, casualties, enemy diamonds and the status strip all draw correctly.

### Not verified

- **Mouse and keyboard through a real window.** Tests feed input events directly to
  the view. Nobody has clicked in the actual game yet.
- How movement and shots look in motion. A screenshot is one frame.
- Everything listed as not verified in the Phase 0 entry below still stands.

### Decisions and why

| Decision | Why |
|---|---|
| Ten ticks a second | Fine enough for walking and firing to read smoothly, coarse enough to reason about in tests. Lives in the rules file. |
| Whole-number arithmetic throughout the simulation | Distances are compared squared, chances are rolled from 1 to 100, costs are ticks. Avoids differences between macOS and Linux. |
| Orders are queued and applied at the start of the next tick | Orders given while paused are safe, and a replay only needs the seed and the list of orders with their ticks. |
| Rules in a typed resource file, scenarios in JSON | Rules are a flat list of numbers that the Godot inspector edits well. A map is nested lists, which JSON holds more readably and which can be validated with clear error messages. |
| The view polls the simulation every frame | Simpler than signals, and the simulation stays free of anything a view could subscribe to. |
| Status strip under the map, map cut to 20 rows | The first layout put a panel over the top-left of the map and hid a block. Found by looking at the screenshot. |
| Enum named `BattleSide` | Godot has a built-in global enum `Side`. A script enum of the same name fails to compile with a misleading error. |

### Mistakes caught this session

- The fire interval was off by one tick. A test written from the rule's description
  caught it.
- The screenshot tool first waited a number of frames, which ran much faster than real
  time. It now waits for game time.

## 2026-11-15, session 1: Phase 0

### Done

- Read the kickoff brief, inspected the machine, and fact-checked the brief's history
  claims. Results are in `docs/history/TO_VERIFY.md`.
- Ran the Phase 0 interview. Amit confirmed his background, said he has no
  game-development or Godot experience, and accepted every default and amendment.
- Wrote `docs/GDD.md`, `docs/SCOPE.md`, `docs/RISKS.md` and `CLAUDE.md`.
- Set up the repository, the Godot project in `game/`, a pinned toolchain, unit tests,
  lint, a compile check, an asset-ledger check, a one-command Windows export and a CI
  workflow.
- Renamed the project to **Beyond the Chindwin: The Forgotten Front** when Amit
  supplied a logo and poster carrying that name.

### Verified by running it

- `make check` passes: asset ledger, lint, compile check and four smoke tests.
- Each guard fails when it should. Tested by breaking the project four ways: a
  failing test, a test file that does not compile, untyped game code that no test
  touches, and an asset with no ledger row.
- `make export-windows` produces a 104 MB Windows x86-64 executable and its data
  file. The test framework and development scripts are left out of the data file.
- The toolchain script installs the editor and the Windows export templates from
  checksum-verified downloads.

### Not verified

- **The Windows build has never been run.** There is no Windows machine.
- **CI has never run.** There is no remote repository yet, and Docker was not
  running, so nothing has been tested on Linux.
- Whether seeded simulation results match between macOS and Linux.
- That the toolchain script refuses a download whose checksum does not match. The
  code is there; the failure path was not exercised.

### Decisions and why

| Decision | Why |
|---|---|
| Godot 4.7.2, pinned by checksum in `tools/godot.lock`, downloaded into `.tools/` | Current stable release. The same script serves the laptop and CI, and nothing is installed system-wide. |
| GUT 9.7.1 for tests, not gdUnit4 | Measured on this Mac: four tests in 1.1 s, correct exit codes, and it works with untyped code set to an error. gdUnit4 passed the same tests but took over three minutes to exit in an untuned run and writes report files into the project. |
| A wrapper around GUT (`tools/run_tests.py`) | GUT exits 0 when a test file fails to compile. The wrapper fails on script errors and on a mismatch between test files on disk and test files run. |
| Untyped declarations are a compile error | The brief requires typed GDScript. A setting enforces it better than a promise. |
| The Godot project lives in `game/`, not the repository root | Keeps documents, tools and CI files out of the engine's import scan and out of exports. |
| Compatibility renderer (OpenGL) | The game is 2D. This renderer runs on the widest range of older Windows hardware. |
| Windows export in CI runs on version tags and manual runs only | The templates are a 1.3 GB download and nobody needs a Windows build before Gate 3. |
| Compiled translation file is committed | Otherwise every fresh clone prints an error before its first import. |
| Text goes through `game/locale/strings.csv` from the start | Hindi is in scope for 1.0. Retrofitting keys later costs far more. |
| Mission 1 is provisionally a Gandhi Brigade raid near Mitlong Khunou, late May to June 1944 | It is the setting in the one fully read source where shortages, failed appeals and desertion are documented together. Tagged COMPOSITE and awaiting a second source. |
| Pillar 4 reworded so that appeals usually fail and the player's own men can desert | The source says appeals were "largely unsuccessful" and records 116 desertions from the Gandhi Brigade by 30 June 1944. |
| Gate 1 has five written pass criteria and a twelve-week limit | The original gate was one person judging their own work with no way to fail. |
| Section weapons are data, and the prototype is played with and without a light machine gun | Whether an INA section had one is unknown, and the evidence found so far is against it. |

### The earlier vertical-slice notes

Amit pasted an earlier design document for the same title. It describes an Unreal
Engine 5 tactical shooter: a captain leading a seven-man squad in an assault on Moirang
on 14 April 1944, ending with a fight against a Stuart tank, with voice-over and a
publisher pitch framing.

It was **not adopted**, for these reasons:

- It breaks hard constraint 2 (Unreal, 3D, voice) and the out-of-scope list (publisher
  and investor material).
- It repeats the errors the brief told Claude to fix: a captain leading a section-sized
  unit, a set-piece assault at Moirang, and British armour on screen.
- It turns a real person into a squad member. Search results name M. Koireng Singh as
  a real Moirang leader who met the incoming force. The notes make "Mairembam Koireng"
  a guide under the player's command, which the history rules forbid.
- It contains invented dialogue and details with no source.

The ideas worth keeping are parked in `docs/SCOPE.md`. Its factual claims are logged in
`docs/history/TO_VERIFY.md`, section 7.

**Open:** Amit has not said whether the paste was background material or a request to
change direction. The constraints stand until he confirms a change in writing.

### Concept art

Two AI-generated images from Amit are filed in `marketing/concept/` and logged in
`ASSETS.md` as placeholders for reference only. Their licence is not established. The
poster's cap badge, rifle and "Manipur" stone are the image generator's inventions.

### Title

*Beyond the Chindwin* is also the title of Bernard Fergusson's 1945 memoir of the first
Chindit expedition. No game of that name was found on Steam or itch.io. Logged as
risk 11. The decision is Amit's.
