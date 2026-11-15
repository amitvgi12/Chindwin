# Beyond the Chindwin: The Forgotten Front

Game design document. Draft for Gate 0, 15 November 2026. Three pages at most.

Historical statements here point to `docs/history/TO_VERIFY.md` ("S1" is the Sundaram
article listed there). All of them are provisional until checked against a second source.

## 1. The game

A small, top-down 2D, real-time-with-pause tactics game for PC. You command one
infantry section of the Indian National Army (Azad Hind Fauj) on the Imphal front in
1944. You split the section into two teams: one fires to hold the enemy down, the other
moves. You never have enough ammunition, food or healthy men, and the soldiers opposite
are often Indian too. Single player, one playable side, mouse and keyboard.

The tone is grounded. The campaign ended in retreat, sickness and starvation, and the
game says so.

## 2. What the player does

1. **Read the ground.** Pause is free and unlimited.
2. **Give each team one order:** move, fire at, hold, fall back. Later phases add
   scavenge and call out to the enemy.
3. **Unpause and watch.** Fire builds suppression on the enemy and spends rounds.
4. **Judge the moment.** Decide when the enemy is pinned enough to move the other team.
5. **Close or break off.** Withdrawing is always a legitimate result.
6. **Count what is left:** men, rounds, food.

## 3. Design pillars

Every feature must serve at least one of these, or it is cut.

1. **Suppress, then move.** Fire fixes the enemy; movement wins the fight. A unit under
   fire outside cover dies fast. Suppression is a visible meter. Every burst that pins
   costs rounds that cannot be replaced, so this pillar deliberately pulls against
   pillar 3.
2. **The weather is a character.** Rain cuts sight range, slows movement on slope
   terrain and raises the chance of a weapon stoppage. It changes during a mission.
3. **Never enough.** Ammunition and food are counted. Scavenging is a decision with
   risk. S1 documents an attack that collapsed when ammunition ran out, and captured
   .303 rounds and flour being badly needed (pp. 44, 45, 48).
4. **The man opposite is also Indian, and he usually does not come over.** Calling out
   to Indian troops is possible and most often ends with being fired on (S1 p. 43). The
   hunger and exhaustion that wear your men down can make them walk away: 116 men of
   the Gandhi Brigade had deserted by 30 June 1944 (S1 p. 49). The pull runs both ways.

**Open question on pillar 1.** We do not know what an INA section had to pin with.
The only evidence found so far is against a light machine gun (TO_VERIFY, section 4,
item 4). The section's weapons are therefore data. The prototype will be played both
rifles-only and with one light machine gun, and the history decides which one ships.

## 4. Will to fight

One value per soldier and per enemy group, from 0 to 100, ties the pillars together.

| Input | Speed | Effect |
|---|---|---|
| Suppression (incoming fire) | Seconds | Pushes will down. Recovers when the firing stops. |
| Condition (hunger, fatigue, sickness, rain) | Minutes to missions | Lowers the level that will can recover to. |
| Appeals (calling out) | One moment | Pushes directly on will. Works better on men who are already pinned, isolated or in poor condition. |

Will maps to three states: **steady**, **pinned** (will not move, fires less) and
**broken** (falls back, surrenders or walks away). Every number lives in a data file.

One value is used so that every pillar acts on the same thing, and so the rules can be
tested without rendering.

## 5. Mission 1 (provisional, tagged COMPOSITE)

**Setting.** A section of the Gandhi Brigade (2nd Guerrilla Regiment) in the hills
south of the Palel-Tamu road, late May to June 1944, raiding a road-block or patrol
position held by troops of 23rd Indian Division.

**Why here.** S1 pp. 48-49 documents six weeks of "frequent raids on British patrols
and road-blocks" from Mitlong Khunou, with acute shortages, sickness, Indian troops
opposite who stayed loyal, and desertion from the brigade. The monsoon is true there by
date only. No individual raid is documented, so the mission is a composite.

**What is not known:** the ground, the opposing battalion, the section's weapons and
strength, how appeals were made, and what happened to nearby villages (TO_VERIFY,
section 5). None of this will be filled with plausible detail. Until it is sourced, the
grey-box map is labelled a test range and carries no place name.

**Shape, 20 to 40 minutes.** Approach in rain; a picket; the road-block; then a choice
between pressing the attack, scavenging, calling out, or withdrawing; then getting away.

**Outcomes.** Objective taken; withdrew in good order; section broken. The debrief
counts men, rounds and food. There is no victory fanfare.

## 6. Phase 1 prototype: what Gate 1 tests

Coloured circles and rectangles only. One flat test map with cover. One player section
in two teams. One enemy picket. Section strength is data; the default of ten is a
placeholder, not history.

Build order:

1. A thin playable loop: select a team, order a move, pause, one enemy that fires back.
2. Movement and pathfinding on a grid.
3. Line of sight.
4. Cover.
5. Firing, hit resolution and ammunition count.
6. Suppression and the will-to-fight states.
7. Enemy behaviour that reacts to suppression, with every decision logged.
8. Debug overlay: sight lines, suppression values, AI state.

Each step ships with tests. Gate 1 pass criteria are in `docs/SCOPE.md`.

## 7. Controls and presentation

- Mouse and keyboard only. Space pauses. `1` and `2` select a team. Left-click selects,
  right-click orders. No order takes more than two inputs.
- Top-down, north-up camera with pan and zoom.
- Grey boxes until Gate 3. Art direction is decided in Phase 3.
- All player-facing text goes through translation keys. English only until Phase 3.

## 8. Tone and content rules

- Player characters are fictional. Real people may be named in briefings. They are
  never playable and never given invented words or actions.
- Every scene is tagged DOCUMENTED, COMPOSITE or INVENTED in `docs/history/`.
- The game shows the alliance with Imperial Japan, the INA's limited military effect,
  desertion and surrender, and what the campaign did to Naga, Kuki and Meitei
  civilians, without glorifying or sanitising any of it. No side is a cartoon.
- No tank appears until a source places one against an INA unit.

## 9. Technical approach

The simulation is plain data with no scene nodes. It advances on a fixed tick with a
seeded random number generator, and uses grid pathfinding and grid line of sight. Scenes
only draw the state and collect orders. This gives headless tests, exact replays from a
seed plus the orders given, and cheap save and load in Phase 2. Engine, tools and
conventions are in `CLAUDE.md`.
