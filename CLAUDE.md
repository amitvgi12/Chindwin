# Beyond the Chindwin: The Forgotten Front

A small, top-down 2D, real-time-with-pause squad tactics game about an Indian National
Army (Azad Hind Fauj) infantry section on the Imphal front in 1944. Solo project: Amit
holds every role and Claude helps with all of them.

The original brief is `CLAUDE_CODE_KICKOFF_PROMPT.md`. This file condenses it and adds
what was decided since. Where they differ, this file wins.

## Current state

- **Gate 1 passed on 16 November 2026, on Amit's word.** He confirmed it without
  sending the tallies from `docs/GATE1_PLAYTEST.md`, so no playtest data is on record.
  Ask for it when a design question turns on how the fight feels.
- **Phase 2 is under way:** the systems that make it this game. Gate 2 is one complete
  grey-box mission, start to finish, of twenty minutes or more.
- Built so far: the simulation core; a test-range map; two teams that can be
  selected, moved and told to hold fire; rifles with counted ammunition for both
  sides; cover that protects only against fire coming over it; waypoints;
  suppression with pinned and broken states and a meter over each man; an enemy
  picket that falls back, with a decision log; a fall-back order; an opening
  briefing and a "how to play" page; a debug overlay; and a placeholder "map in the
  rain" look drawn in code, which Amit has accepted as the working direction until
  the Phase 3 art decision.
- **Gate 1 criterion 1 is met and is now a test** (`test_gate1_criterion.gd`). Run
  `make gate1` to see the battles behind it. Criteria 2 to 5 need Amit to play.
- Phase 2 so far: mission outcomes (objective taken, withdrew, section broken), a
  debrief, weather as a rule (sight, slopes, stoppages; it changes on a schedule),
  scavenging (ammunition boxes, rounds left by the fallen, a gather order), and the
  appeal encounter (`C`: call on an Indian enemy group to come over; usually fails).
- Phase 2 still to build: condition (hunger, fatigue, food), save and load, a
  mission-length map, and the Gate 2 playtest sheet.
- **The appeal encounter is COMPOSITE.** Its method (shouted appeals in Hindustani)
  rests on second-hand sources listed in `docs/history/TO_VERIFY.md` section 9.
  Loudspeakers, leaflets, Bose-signed passes, disguise and calling NCOs by name were
  not found in any source and must not be added.
- CI is green on GitHub, including the recorded battle, so the simulation gives the
  same result on macOS and Linux so far.
- **Purpose: this build is a demo.** Amit may later take the game towards his earlier
  3D vision if the demo and investors support it. That is a decision for after the
  demo, made in writing. Until then every hard constraint below stands.
- Read `docs/BACKLOG.md` for what is next and `docs/DEVLOG.md` for why things are as
  they are.

## About Amit (calibrate to this; do not flatter)

- Lead DevOps engineer. Strong in Python, CI/CD, Kubernetes and automation.
- No game-development experience and has never used Godot. Explain editor steps
  click by click. Do not explain Git, CI or Python.
- Cannot draw, animate, model or compose.
- Six hours a week. No cash budget until Gate 1 passes.
- Works on an Apple M2 Mac with 8 GB RAM. Has no Windows machine.
- Success means a finished, honest game. Sales come second.

## Hard constraints (do not relax without Amit's written confirmation)

1. **Engine:** Godot 4.7.2, pinned in `tools/godot.lock`. Typed GDScript. Read the docs
   for this version instead of relying on memory.
2. **Never:** Unreal, 3D, first-person, multiplayer, mobile, console ports, motion
   capture, voice acting. If Amit asks for one, quote this line back and ask him to
   confirm in writing.
3. **Scope ceiling for 1.0:** three missions, 20 to 40 minutes each, one playable side.
   The first milestone is ONE mission. Nothing else is built until it is fun.
4. **Data-driven:** weapons, units, missions, weather and dialogue live in resource or
   JSON files. Tuning numbers go in data from day one. Mission-scripting and dialogue
   formats wait until a real mission needs them.
5. **Every asset has a ledger row** in `ASSETS.md` before it is committed.
6. **Never invent historical facts.** See "History rules".

## Design pillars (a feature serves one or it is cut)

1. **Suppress, then move.** Fire fixes; movement wins. Suppression is a visible meter
   and costs ammunition.
2. **The weather is a character.** Rain cuts sight, slows movement on slope terrain,
   raises stoppages, and changes during a mission.
3. **Never enough.** Ammunition and food are counted. Scavenging carries risk.
4. **The man opposite is also Indian, and he usually does not come over.** Appeals
   mostly fail. Hunger can make the player's own men walk away.

One "will to fight" value per soldier links all four. See `docs/GDD.md` section 4.

## Phases and gates (stop at each gate and wait for Amit)

0. Foundations. **Gate 0:** GDD and scope approved.
1. Grey-box combat prototype. **Gate 1:** five written criteria in `docs/SCOPE.md`,
   time-boxed to twelve weeks.
2. Weather, ammunition, scavenging, fatigue, one appeal encounter, save and load.
   **Gate 2:** one complete grey-box mission.
3. Vertical slice: art, audio, text, options, Hindi. **Gate 3:** five strangers play.
4. Steam page and demo. Then decide on missions 2 and 3.

## History rules

- `docs/history/TO_VERIFY.md` holds every unconfirmed claim. Nothing in it may appear
  in game text.
- **No name, unit, date, place, weapon, rank or page number enters the repository
  unless Claude read it in a source during that session, or Amit checked it.** Memory
  is not a source. Claude's recollections were wrong twice in the first session.
- Never write a page number that was not seen on the page.
- Each mission gets a file in `docs/history/`. Every factual statement carries a
  source. Every scene is tagged DOCUMENTED, COMPOSITE or INVENTED.
- Player characters are fictional. Real people may be named in briefings. They are
  never playable and never given invented words or actions.
- Grey-box content uses obviously fake labels ("Test range", "Picket A"), never real
  unit or place names.
- No tank or armoured car on screen until a source places one against an INA unit.
- Show the alliance with Imperial Japan, the INA's limited military effect, desertion,
  surrender, and the harm to Naga, Kuki and Meitei civilians, without glorifying or
  sanitising. Flag any scene a reasonable Indian, Japanese, British or Manipuri/Naga
  player would find dishonest.

## Commands

Run from the repository root. `make` lists them.

| Command | What it does |
|---|---|
| `make setup` | Downloads the pinned Godot editor into `.tools/` and verifies its checksum. |
| `make editor` | Opens the project in the Godot editor. |
| `make run` | Runs the game in a window. |
| `make test` | Runs the unit tests headless. |
| `make check` | Everything CI runs: asset ledger, lint, compile check, tests. Run before every commit. |
| `make format` | Rewrites GDScript files into the standard format. |
| `make gate1` | Plays the Gate 1 attacks ten times each and prints every battle with the enemy's decisions. `make gate1 RUNS=200` prints totals for a larger sample. Use it before and after changing anything in `game/data/`. |
| `make screenshot` | Opens the game for a few seconds, plays a scripted battle and saves `build/screenshot.png`. Lets Claude look at the game. A window appears briefly. Add `OVERLAY=1` for the debug overlay or `SCENE=res://scenes/briefing.tscn` for another scene. |
| `make setup-templates` | Downloads the Windows export templates (1.3 GB, once). |
| `make export-windows` | Builds `build/windows/BeyondTheChindwin.exe`. |

To run Godot directly: `tools/godot.sh --headless --path game <arguments>`.

## Layout

```
CLAUDE.md, ASSETS.md, Makefile
docs/            GDD, SCOPE, RISKS, DEVLOG, BACKLOG
docs/history/    TO_VERIFY.md and one file per mission
game/            the Godot project (res:// is this folder)
  src/sim/       simulation: plain data and rules, no scene nodes
  src/ui/        scenes' scripts: drawing and input only
  scenes/        .tscn files
  data/          weapons, units, missions, weather as resources or JSON
  assets/        art, audio, fonts (each needs an ASSETS.md row)
  locale/        strings.csv: every player-facing string, by key
  test/unit/     GUT tests, files named test_*.gd
  dev/           development-only scripts, excluded from exports
  addons/gut/    GUT 9.7.1, vendored, excluded from exports
marketing/       concept and store material (each file needs an ASSETS.md row)
tools/           toolchain and check scripts
.tools/, build/  downloads and build output, not committed
```

## Code conventions

- **Typed GDScript everywhere.** An untyped declaration is a compile error
  (`project.godot`). Do not weaken that setting; a test guards it.
- **Simulation and view are separate.** Code in `src/sim/` extends `RefCounted` or
  `Resource`, never `Node`. It must run with no scene tree and no rendering.
- **Deterministic simulation.** Fixed tick. One seeded `RandomNumberGenerator` passed
  in explicitly. Never call the global `randf()` or `randi()`. Never use frame delta
  in rules. Keep the maths integer or simple so macOS and Linux agree.
- **Grid first.** Pathfinding uses `AStarGrid2D`. Line of sight walks grid cells. No
  physics raycasts or navigation agents in the simulation.
- **No magic numbers in rules.** Tunable values come from `game/data/`.
- **No literal player-facing text.** Add a key to `game/locale/strings.csv` and use
  the key.
- **Saves are JSON.** Never load a save through `ResourceLoader`; resource files can
  run code.
- **Tests come with the rule.** Every simulation rule ships with a test. AI decisions
  are logged so behaviour can be read without watching the game.
- Boring, readable code over clever code.

## Things that are easy to get wrong here

- **Amit commits and pushes from his editor.** Never leave the working tree
  half-finished between tool calls for long, and finish every step with `make check`
  and a commit. CI went red once because an unformatted, untested working tree was
  pushed mid-step.
- **GUT exits 0 when a test file fails to compile.** Always run tests through
  `make test`, which catches that. Never call GUT's command line directly in CI.
- **Run `make check` before committing.** It rebuilds Godot's cache first, so new
  `class_name` scripts and edited strings are picked up.
- **Editing `strings.csv` changes `strings.en.translation`.** Commit both.
- **The game's name lives in six places:** `project.godot`, `export_presets.cfg`,
  `tools/export_windows.sh`, `Makefile`, `.github/workflows/ci.yml` and
  `game/locale/strings.csv`.
- **Routes ignore danger.** Pathfinding takes the quickest way, counting slopes as
  slow. A change to slope cost or to the map can silently send a team across open
  ground instead of behind cover. Check with `make gate1` and a screenshot.
- **Use `sim.can_engage()` for "can he shoot at him".** It applies the weather's sight
  limit. Do not compare distances to a weapon's range directly.
- **Changing numbers in `game/data/` can break the game's central claim.** The Gate 1
  test catches it. Fix the data; never loosen the test.
- **Briefing text is history.** A `BRIEFING_` string may only change together with its
  row in `docs/history/mission-01.md`. A test compares the two word for word.
- **Godot has built-in global enums** such as `Side`, `Error`, `Key` and `Corner`. A
  script enum with the same name is silently shadowed and fails to compile with a
  confusing type error. That is why the soldier enum is `BattleSide`.
- **Frame time belongs to the view only.** `BattleView.advance()` converts seconds to
  ticks. Nothing in `src/sim/` ever sees a delta.
- **Export templates are installed outside the repository,** in Godot's own folder
  under `~/Library/Application Support/Godot/export_templates/`.

## Dependencies (tell Amit the name, licence and reason before adding any)

| What | Licence | Why |
|---|---|---|
| Godot 4.7.2 | MIT | The engine. Pinned with SHA-512 checksums. |
| GUT 9.7.1 | MIT | Unit tests. Vendored in `game/addons/gut/`. |
| gdtoolkit 4.5.0 | MIT | Lint and format. Development only, in `.tools/venv`. Project settings in `gdlintrc`. |

## How we work

- **Small steps.** For each task: state the plan in three to six lines, implement, run
  `make check`, show what changed and how to see it in the game, then commit.
- **Claude cannot see the game running.** Write tests for rules, log AI decisions, and
  when something needs eyes, tell Amit exactly what to look at and what "right" looks
  like. Ask for a screenshot when it helps.
- **Update `docs/DEVLOG.md` and `docs/BACKLOG.md` at the end of every session.**
- **Push back.** If a request breaks a hard constraint or adds more than about a week
  of work, say so, give the cost, and offer the smallest version that tests the same
  idea. Say plainly when something is not fun, not feasible or not true.
- **Placeholders only** for art and music until Gate 3 decisions are made. Claude does
  not generate final art, music or real people's likenesses.
- **Out of scope until Amit says otherwise:** publisher decks, investor material,
  revenue forecasts, fundraising, localisation beyond English and Hindi, achievements,
  mod support, a level editor, a second playable faction.
