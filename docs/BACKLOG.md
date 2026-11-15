# Backlog

Ordered. Do the top item first. Sizes: S is under two hours, M is a session or two,
L is a week or more of sessions.

**Gate 1 target: 10 January 2027. Hard review: 7 February 2027.**

## Now: needs Amit

| # | Task | Size |
|---|---|---|
| 1 | `git push` and confirm CI stays green. | S |
| 2 | **Play for thirty minutes against Gate 1 criteria 2 to 5** in `docs/SCOPE.md`: do you restart unprompted, can you explain each loss, are orders quick, do you want another go? Say what happened for each. | M |
| 3 | Find a library or loan copy of Shah Nawaz Khan's memoir or Fay's *The Forgotten Army*. | M |

## Phase 1: remaining

| # | Task | Size |
|---|---|---|
| 1 | Act on what Amit reports from playing. Likely first: a frontal attack is wiped out to the last man, which may be too absolute; and covering fire adds less than the flank itself does. | M |
| 2 | Debug overlay: sight lines, who can see whom, the enemy's log on screen. | M |
| 3 | A one-screen controls card, reachable from the briefing. | S |
| 4 | Gate 1 playtest script. | S |

Known rough edges, to fix as the systems above arrive:

- Soldiers walk through each other on the way; they only end on separate cells.
- A team with nobody left still reads "firing" in the status strip.
- Rain is decoration. It affects nothing until Phase 2.
- The track is decoration. Walking on it is no faster.
- Pinned men in the open never crawl back to cover; they stay until shot.
- The picket never moves to face a flank. It holds or it leaves.

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
| Opening briefing from the checked history rows. | 15 Nov 2026 |
| Broken state, withdrawal, and enemy picket behaviour with a decision log. | 15 Nov 2026 |
| Gate 1 criterion 1 as an automated test, and the numbers tuned to meet it. | 15 Nov 2026 |

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
