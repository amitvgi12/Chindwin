# Scope

Draft for Gate 0, 15 November 2026. Changing anything in the "Out" lists needs Amit's
written confirmation in the chat, which is then recorded in `docs/DEVLOG.md`.

## Purpose

**The current goal is a demo.** Amit confirmed on 15 November 2026 that the earlier
vertical-slice notes are background, and that the game may evolve towards that vision
later if the demo and investors support it. That is a separate decision, taken in
writing after the demo exists. It does not relax anything below.

One caution recorded at the time: a 2D grey-box tactics demo can show that the core
loop is fun, that the history is handled honestly, and that the project ships. It does
not show that a 3D shooter can be built, which needs a different engine, team and
budget.

## In: version 1.0 ceiling

- Three missions, 20 to 40 minutes each, one playable side.
- Top-down 2D, real-time with pause, single player.
- Windows on Steam. Mouse and keyboard.
- English and Hindi text.

## In: the first milestone (all that is being built now)

**One mission.** Nothing else is built until that mission is fun.

| Phase | Contents | Gate |
|---|---|---|
| 0. Foundations | Documents, repository, Godot project, tests, export command, CI. No gameplay code. | Gate 0: **passed 15 November 2026.** |
| 1. Grey-box combat | Flat test map, one section in two teams, one enemy picket. Movement, line of sight, cover, firing, suppression, enemy behaviour, orders with pause, debug overlay, seeded simulation. | Gate 1: **passed 16 November 2026** on Amit's word. Criterion 1 is an automated test. No tallies were recorded for criteria 2 to 5. |
| 2. The systems that make it this game | Weather states and effects. Ammunition, scavenging, fatigue. One appeal encounter. Win, lose and withdraw. Save and load. | Gate 2: one complete grey-box mission of 20 minutes or more. |
| 3. Vertical slice | Art direction choice, art for this one mission, audio, briefing and debrief text, options, key rebinding, text size, colour-blind-safe indicators, Hindi. | Gate 3: five strangers play it. |
| 4. Steam page and demo | Store copy, capsule brief, trailer shot list, demo build, press kit. | Decision on missions 2 and 3. |

## Gate 1: pass criteria and time-box

Agreed before anyone plays, so the result cannot be argued into a pass afterwards.

**Pass criteria.** All five must hold.

1. **The rules do what pillar 1 says.** Over ten seeded simulation runs, a frontal
   assault with no suppression fails at least eight times, and suppress-then-flank
   succeeds at least seven times. This is checked by an automated test.
2. **You replay it unprompted.** In a 30-minute session you restart the encounter at
   least three times by your own choice.
3. **You can explain each loss.** After every failed attempt you can say in one
   sentence why you lost, from what the game showed you with the debug overlay off.
4. **Orders are quick.** You give your first order to each team within two minutes,
   having read one screen of controls.
5. **You want another go.** At the end of the session you would rather keep playing
   than stop.

**Time-box.** At six hours a week:

- Gate 1 build ready eight weeks after Gate 0, so by **10 January 2027**.
- Up to two iteration rounds of two weeks each if the criteria are not met.
- At week twelve (**7 February 2027**) without a pass, work stops for a written review with three options:
  cut to a smaller idea, change the core loop, or shelve the project.

## Out of version 1.0

These hold until Amit confirms a change in writing.

- Unreal Engine, 3D, first-person or third-person shooting.
- Multiplayer, mobile, console ports.
- Motion capture, voice acting, voice-over.
- A second playable faction.
- Real people as playable characters or with invented dialogue or actions.
- Tanks or armoured cars, until a source places one against an INA unit.
- Controller support and Steam Deck as a target.
- Sight lines that depend on height. Slopes are a terrain type with a movement cost.
- Sound detection (hearing) as a system.
- Final art, final music or real people's likenesses before Gate 3 decisions.

## Out until Amit says otherwise

Publisher pitch decks, investor material, revenue forecasts, fundraising, localisation
beyond English and Hindi, achievements, mod support, a level editor.

## Deferred, not rejected

- **Whether men, ammunition and hunger carry over between missions.** Decided after
  Gate 2. Soldiers are modelled as named individuals so either answer stays possible.
- **Linux export.** Added when it can be tested.
- **Missions 2 and 3.** Decided after Phase 4.

## Parked from the earlier vertical-slice notes

Amit's earlier notes (pasted 15 November 2026) describe an Unreal Engine 5 tactical
shooter built around an assault on Moirang. They conflict with the hard constraints and
with the history rules, so they are not the plan. The ideas below survive in a form
that fits this project and are parked for later missions:

- **Moirang, 14 April 1944, as a possible mission 2 or 3.** Told as what the sources
  support: a small detachment entering the town, with no set-piece assault and no
  armour, pending the checks in TO_VERIFY.
- **An appeal encounter at an isolated listening post,** where cutting the field
  telephone first changes the odds. Needs a source for the method.
- **A local guide who reveals a covered route.** Must be a fictional character.
- **A closing beat where resupply fails** and the section holds on what it carries.
