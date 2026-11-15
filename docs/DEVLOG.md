# Devlog

What was done, what was decided, and why. Newest session first.

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
