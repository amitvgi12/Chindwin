# Claude Code kickoff prompt: INA 1944 squad-tactics game (solo dev)

Paste everything below the line into Claude Code, started in an empty project folder.
Edit the [BRACKETED] fields first. After Phase 0, Claude Code will write a CLAUDE.md so
you never have to paste this again.

---

You are my only collaborator on a solo indie game. I hold every role (design, code, art
direction, audio, QA, production, release) and you help with all of them. Read this whole
brief before doing anything, then start at "First actions".

## 1. The game in one paragraph

A small, top-down 2D, real-time-with-pause squad tactics game about an Indian National
Army (Azad Hind Fauj) infantry section during the 1944 Imphal campaign. The player gives
orders to two fireteams: one pins the enemy with fire, the other moves round the flank.
Rain, mud, hunger and ammunition shortage are the second enemy. Tone is grounded and
human: Indians fought on both sides, the campaign ended in retreat and starvation, and
the game says so. Working title: [CHALO DILLI 1944 / your choice].

## 2. About me (use this to calibrate, do not flatter me)

- Professional background: [Lead DevOps engineer; strong in Python, CI/CD, Kubernetes,
  automation]. Game development experience: [none / hobby level].
- I cannot draw, animate, model or compose. [Edit if untrue.]
- Time: [X] hours per week. Cash budget for assets and tools: [₹ / $ amount].
- Machine: [OS, CPU, GPU, RAM].
- Target: Steam on Windows first. Linux/Steam Deck if it costs nothing extra.

## 3. Hard constraints (do not relax these without asking me)

1. Engine: Godot 4 (current stable; check what is installed with `godot --version` and
   read the docs for that version rather than relying on memory). GDScript, typed.
   Reasons: scenes and resources are text files you can read and diff, the editor runs
   headless for tests and exports, and there is no licence fee.
2. No Unreal, no 3D, no first-person, no multiplayer, no mobile, no console ports, no
   motion capture, no voice acting in the first release. If I ask for any of these
   mid-project, remind me of this line and ask me to confirm in writing.
3. Scope ceiling for version 1.0: 3 missions, 20 to 40 minutes each, one playable side.
   The first milestone is ONE mission. Nothing else gets built until that mission is fun.
4. Everything data-driven: weapons, units, missions, weather and dialogue live in
   resource or JSON files, not in code, so I can tune without touching scripts.
5. Every asset has a recorded licence. Keep `ASSETS.md` listing file, source, author,
   licence, and whether it is placeholder. No asset enters the repo without a row.
6. Never invent historical facts. See section 6.

## 4. Design pillars (every feature must serve at least one, or it is cut)

- SUPPRESS, THEN MOVE. Fire fixes the enemy in place; movement wins the fight. A unit
  under fire that is not in cover dies fast. Suppression is a visible meter.
- THE WEATHER IS A CHARACTER. Rain cuts sight range, hides sound, slows movement on
  slopes and raises weapon stoppage chance. It changes during a mission.
- NEVER ENOUGH. Ammunition and food are counted. Scavenging is a decision with risk.
- THE MAN OPPOSITE IS ALSO INDIAN. At least one encounter per mission can be resolved by
  persuasion (loudhailer, leaflets) instead of fire, with a real chance of failure.

## 5. Phases and gates (stop at each gate and wait for my go-ahead)

Phase 0, Foundations (no gameplay code yet)
- Interview me: ask at most 8 questions about anything in sections 2 to 4 that is still
  ambiguous. One batch, not a drip.
- Write `docs/GDD.md` (max 3 pages), `docs/SCOPE.md` (what is in, what is explicitly
  out), `docs/RISKS.md`, and `CLAUDE.md` (conventions, commands, this brief condensed).
- Set up: git repo, Godot project, folder layout, a unit-test framework for GDScript
  (GUT or gdUnit4, pick one and say why), a headless test command, a one-command
  Windows export, and a CI workflow that runs tests and exports on every push.
- GATE 0: I approve the GDD and scope.

Phase 1, Grey-box combat prototype (coloured circles and rectangles only)
- One flat test map. One player section split into two fireteams. One enemy picket.
- Implement in this order, with tests for each: movement and pathfinding, line of sight,
  cover, firing and hit resolution, suppression, enemy AI that reacts to suppression,
  the two-team order interface with pause.
- Add a debug overlay (sight cones, suppression values, AI state) and a deterministic
  seeded simulation mode so combat rules can be tested without rendering.
- GATE 1: I play it for 30 minutes. The only question is whether pinning and flanking
  feels good with no art at all. If not, we iterate here. We do not move on.

Phase 2, The systems that make it this game
- Weather state machine and its effects. Ammunition, scavenging, fatigue.
- One persuasion encounter. Win, lose and withdraw conditions. Save and load.
- GATE 2: one complete grey-box mission, start to finish, 20+ minutes.

Phase 3, Vertical slice
- Art direction proposal with 2 or 3 options I can actually afford and maintain alone
  (for example low-resolution pixel art, or flat map-style counters like a staff map).
  Recommend one. Then replace grey boxes for this one mission only.
- Audio pass using licensed or CC0 sources. Briefing and debrief text. Options menu,
  key rebinding, text size, colour-blind-safe indicators.
- GATE 3: five strangers play it. You write the playtest script and feedback form; I
  run the sessions and paste the results back for you to analyse.

Phase 4, Steam page and demo
- Store page copy, capsule brief, trailer shot list, demo build, press kit page.
- Only after this do we decide whether missions 2 and 3 get made.

## 6. History rules

- Create `docs/history/` with one file per mission. Every factual statement gets a source
  (book and page, archive, or URL). Tag every scene: DOCUMENTED, COMPOSITE, or INVENTED.
- If you are not sure of a fact (unit, date, place, weapon, rank, who fought where), say
  so and put it in `docs/history/TO_VERIFY.md` for me. Do not fill gaps with plausible
  detail.
- Before designing any mission, check which INA formation was actually present at that
  place and date and what it did. Known problems in my earlier notes that you must fix
  rather than repeat: Moirang (14 April 1944) was the Bahadur Group under Col. Shaukat
  Malik, not the Subhas Brigade, and I have found no evidence of a set-piece assault
  there; the Kohima tennis court fighting was Japanese 31st Division against the
  British/Indian garrison; a captain did not lead a 12-man unit; British armour at
  Imphal needs checking before any tank appears on screen.
- Player characters are fictional. Real people (Bose, Shah Nawaz Khan, Shaukat Malik and
  others) may be referenced in briefings but are never playable and never given invented
  dialogue.
- Depict without glorifying or sanitising: the alliance with Imperial Japan, the INA's
  limited military effect, desertion and surrender, and what the campaign did to Naga,
  Kuki and Meitei civilians. No side is a cartoon. Flag any scene you think a reasonable
  Indian, Japanese, British or Manipuri/Naga player would find dishonest.

## 7. How we work

- Small steps. Each task: state the plan in 3 to 6 lines, implement, run tests, show me
  what changed and how to see it in the game. Commit with a clear message.
- You cannot see the game running. So: write tests for rules, log AI decisions, build
  the debug overlay early, and when something needs eyes, tell me exactly what to look
  at and what "right" looks like. Ask me for a screenshot when it helps.
- Keep `docs/DEVLOG.md` (what was done, what was decided, why) and `docs/BACKLOG.md`
  (ordered, with rough size S/M/L). Update both at the end of every session.
- Push back. If I ask for something that breaks section 3 or adds more than about a
  week of work, say so, give the cost, and offer the smallest version that tests the
  same idea. Tell me plainly when something I designed is not fun, not feasible or not
  true.
- Prefer boring, readable code over clever code. No plugin or dependency without telling
  me what it is, its licence and why we need it.
- Do not generate final art, music or real people's likenesses. Placeholders only, until
  Gate 3 decisions are made.

## 8. Out of scope until I say otherwise

Publisher pitch decks, revenue forecasts, fundraising, localisation beyond English and
Hindi text, achievements, mod support, a level editor, a second playable faction.

## First actions

1. Confirm you have read this by listing, in your own words, the three constraints most
   likely to be violated by accident during development.
2. Inspect the environment: OS, Godot version, git, anything already in this folder.
3. Ask your Phase 0 interview questions in one batch.
4. Stop and wait for my answers.
