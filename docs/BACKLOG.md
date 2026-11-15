# Backlog

Ordered. Do the top item first. Sizes: S is under two hours, M is a session or two,
L is a week or more of sessions.

**Gate 1 target: 10 January 2027. Hard review: 7 February 2027.**

## Now: needs Amit

| # | Task | Size |
|---|---|---|
| 1 | `git push` and confirm CI stays green. | S |
| 2 | Play pin-and-flank with suppression (steps in the latest devlog entry). Say whether pinning the picket before moving feels like the point of the game. | S |
| 3 | Read pp. 48-49 of the Sundaram article and tick the box in `docs/history/mission-01.md`. That unlocks the briefing screen. | S |
| 4 | Find a library or loan copy of Shah Nawaz Khan's memoir or Fay's *The Forgotten Army*. | M |

## Phase 1: remaining

| # | Task | Size |
|---|---|---|
| 1 | Enemy picket behaviour that reacts to suppression, with logged decisions: turn to face a flank, fall back when broken. Adds the broken state. | L |
| 2 | Scenario runner for Gate 1 criterion 1: ten seeded runs, frontal against flank. Then tune the numbers until it passes. | M |
| 3 | Debug overlay: sight lines, suppression values, AI state. | M |
| 4 | Briefing screen from `docs/history/mission-01.md`, once Amit has checked it. | S |
| 5 | Gate 1 playtest script and a one-screen controls card. | S |

Known rough edges, to fix as the systems above arrive:

- Soldiers walk through each other on the way; they only end on separate cells.
- A team with nobody left still reads "firing" in the status strip.
- Rain is decoration. It affects nothing until Phase 2.
- The track is decoration. Walking on it is no faster.
- The test range offers no covered route to the north flank; a team crossing there is
  seen unless the picket is already pinned.

## Phase 1: done

| Task | Finished |
|---|---|
| Simulation skeleton: fixed tick, seeded random numbers, plain-data state, queued orders, recorded-battle test. | 15 Nov 2026 |
| Grid map, movement and pathfinding. Scenario loaded from JSON. | 15 Nov 2026 |
| Line of sight on the grid. | 15 Nov 2026 |
| Thin playable loop: draw units, select a team, order a move, pause. | 15 Nov 2026 |
| Weapons as data, firing for both sides, counted ammunition, hold-fire order. | 15 Nov 2026 |
| Cover that protects only against fire coming over it. | 15 Nov 2026 |
| Trial "map in the rain" look, drawn in code. Paused banner. | 15 Nov 2026 |
| Waypoints (Shift + right-click) and the planned route drawn on the map. | 15 Nov 2026 |
| Suppression, the pinned state, a meter over each man, fire spread across targets. | 15 Nov 2026 |

## History: runs alongside, blocked on sources

| # | Task | Size |
|---|---|---|
| 1 | Strength, leader and weapons of an INA guerrilla-regiment section in May 1944. Decides pillar 1. | M |
| 2 | Resolve the Palel airfield raid conflict between Sundaram and Fay. | S |
| 3 | Identify the units opposite the Gandhi Brigade from mid-May to late June 1944. | M |
| 4 | Find how appeals to Indian troops were made on the Palel front. | M |
| 5 | Find a 1944 map of the Khanjol and Mitlong Khunou area and establish its copyright status. | M |
| 6 | Find what happened to villages in the Gandhi Brigade's area. | M |
| 7 | Write `docs/history/mission-01.md` once items 1 to 4 have a checked source. | S |

## Later

| Task | Size | When |
|---|---|---|
| First real run of the Windows build on a borrowed PC. | S | Before Gate 3 |
| Check the licences of the fonts bundled inside GUT, or strip them. | S | Before Gate 3 |
| Windows executable icon and version details. | S | Phase 3 |
| Linux export preset, once it can be tested. | S | Phase 3 |
| Check Steam's rules on AI-generated content, the Steam fee, and the title's availability. | S | Phase 4 |
| Decide whether the concept art has any public use. | S | Phase 4 |
