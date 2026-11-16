# Backlog

Ordered. Do the top item first. Sizes: S is under two hours, M is a session or two,
L is a week or more of sessions.

**Gate 1 target: 10 January 2027. Hard review: 7 February 2027.**

## Now: needs Amit

| # | Task | Size |
|---|---|---|
| 1 | `git push` and confirm CI stays green. | S |
| 2 | Send the Gate 1 tallies if you have them, or at least the worst moment and whether covering fire felt worth the rounds. | S |
| 3 | Find a library or loan copy of Shah Nawaz Khan's memoir, Fay's *The Forgotten Army* or Toye's *The Springing Tiger* (pp. 100-1 is S1's source for the one successful appeal). | M |

## Phase 2: the systems that make it this game

Gate 2: one complete grey-box mission, start to finish, twenty minutes or more.

| # | Task | Size | State |
|---|---|---|---|
| 1 | Mission outcomes and a debrief: objective taken, withdrew, section broken. | S | Done 16 Nov 2026 |
| 2 | Weather as a rule: states that change during a mission and affect sight, movement on slopes and weapon stoppages. | M | Done 16 Nov 2026 |
| 3 | Scavenging: ammunition boxes, rounds left by the fallen, and a gather order that costs time and firepower. | M | Done 16 Nov 2026 |
| 4 | One appeal encounter: a team calls out in Hindustani to an enemy group; usually fails and draws fire; likelier against a small, pinned, cut-off group. Method second-hand (TO_VERIFY section 9); tagged COMPOSITE. | M | Next |
| 5 | Condition: hunger and fatigue as the slow half of will to fight. | M | |
| 6 | Save and load. | M | |
| 7 | A mission-length map: an approach, a picket, then the road-block. | L | |
| 8 | Gate 2 playtest sheet. | S | |

Carried over from Phase 1:

- Soldiers walk through each other on the way; they only end on separate cells.
- The track is decoration. Walking on it is no faster.
- The picket never moves to face a flank. It holds or it leaves.
- A team falls back only to where it started, not to a place of your choosing.
- One team can run out of rounds covering a flank that stalls. In about one battle in
  seven the attack then dies with nobody holding any rounds.
- On the one-minute test range the weather barely matters: the downpour arrives after
  most fights are over. It needs the mission-length map to show what it does.
- Routes take the quickest way with no regard for danger.
- Withdrawn enemies take their rounds with them, so driving the picket off leaves less
  to scavenge than killing it. Deliberate, but worth checking it reads that way.
- Food is not counted yet. Pillar 3 says ammunition and food; food comes with condition.

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
| Fall-back order. "How to play" page. Debug overlay. Gate 1 playtest sheet. | 15 Nov 2026 |

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
