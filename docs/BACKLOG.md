# Backlog

Ordered. Do the top item first. Sizes: S is under two hours, M is a session or two,
L is a week or more of sessions.

**Gate 1 target: 10 January 2027. Hard review: 7 February 2027.**

## Now: needs Amit

| # | Task | Size |
|---|---|---|
| 1 | Run `make run` and play the test range for five minutes. Report anything that looks or feels wrong. What to look for is in the latest devlog entry. | S |
| 2 | Create a private GitHub repository, push, and tell Claude whether the first CI run is green. The repository still exists on one laptop only. | S |
| 3 | Find a library or loan copy of Shah Nawaz Khan's memoir or Fay's *The Forgotten Army*. | M |

## Phase 1: remaining

| # | Task | Size |
|---|---|---|
| 1 | Cover: a terrain type that protects without blocking sight. | S |
| 2 | Firing by the player's teams, hit resolution, ammunition count. Weapons as data. | M |
| 3 | Suppression and will-to-fight states. Visible meter. | M |
| 4 | Enemy picket behaviour that reacts to suppression, with logged decisions. Replaces the placeholder enemy fire. | L |
| 5 | Debug overlay: sight lines, suppression values, AI state. | M |
| 6 | Scenario runner for Gate 1 criterion 1: ten seeded runs, frontal against flank. | S |
| 7 | Gate 1 playtest script and a one-screen controls card. | S |

Known rough edges in the thin loop, to fix as the systems above arrive:

- Soldiers walk through each other on the way; they only end on separate cells.
- A shot is drawn for a quarter of a second, which is easy to miss.
- Nothing marks the game as paused except the word in the status strip.

## Phase 1: done

| Task | Finished |
|---|---|
| Simulation skeleton: fixed tick, seeded random numbers, plain-data state, queued orders, recorded-battle test. | 15 Nov 2026 |
| Grid map, movement and pathfinding. Scenario loaded from JSON. | 15 Nov 2026 |
| Line of sight on the grid. | 15 Nov 2026 |
| Thin playable loop: draw units, select a team, order a move, pause, an enemy that fires back. | 15 Nov 2026 |

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
