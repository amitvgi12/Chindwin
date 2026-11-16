# Devlog

What was done, what was decided, and why. Newest session first.

## 2026-11-16, session 2 continued: the appeal encounter

### Done

- **Call out** (`C`). The selected team calls out in Hindustani to the nearest enemy
  group within earshot that the scenario marks as Indian soldiers, asking them to come
  over. It takes five seconds; the callers do not fire meanwhile. Each group can be
  called to once. Moving the callers, or all of them being pinned, ends the call
  without using up the try. Only one call at a time.
- **The answer.** One roll when the call ends. Chance: 2% base, plus up to 20% for the
  share of the group pinned or broken, plus up to 20% for the share it has lost, never
  above 40%. Fresh picket 2%; all four pinned 22%; three pinned and one lost 27%.
- **On refusal** each man of the group sheds 30 suppression, stops being broken, and
  fires at once. The callers have spent five seconds not firing.
- **On acceptance** the group leaves the fight, leaves its rounds on the ground, and
  counts as "came over" in the debrief, apart from men who fell or got away.
- **Earshot** is 8 cells, cut by weather: 6 in rain, 3 in a downpour.
- **Which groups can be called to** is set per scenario (`appealable_enemy_teams`),
  because not every unit opposite the INA was Indian.
- **On screen:** a message across the top for the call and its answer; "calling out"
  in the status strip; two short arcs at each caller; the current chance in the debug
  overlay; a line on the "how to play" page.
- 223 tests pass. `make check` is clean. Gate 1 numbers unchanged: no dice are rolled
  unless someone calls out, so the recorded battle is identical.

### History tag

COMPOSITE. The method, a shouted appeal in Hindustani or Urdu to Indian troops, is
supported second-hand (S5, Kohima and Jessami, 1944). That appeals usually failed and
were met with fire is S1 p. 43. That they were likelier to work on a small, pressed
group is consistent with S1 p. 43's one named success but is stated by no source. The
in-game words of the appeal are not written out, so no quotation is put in anyone's
mouth.

### Not verified

- Whether the chances feel right. They are first guesses in `prototype_rules.tres`.
- Whether players use it at all, or only once out of curiosity.

### Decisions and why

| Decision | Why |
|---|---|
| One try per group | A second shout to men who have just refused should not be a fresh chance. It also makes the timing a decision. |
| Refusal puts heart back into the group | "More often than not" Indian troops opened fire on the parties (S1 p. 43). A failed call should cost more than five seconds. |
| The chance is capped at 40% | Appeals were "largely unsuccessful". Even a pinned, bloodied group usually says no. |
| No loudspeaker, leaflet or pass | None of these was found in a source for this front. See TO_VERIFY section 9. |
| The appeal's words are not shown | Only the fact of calling out is sourced. Inventing the words would put invented dialogue in a historical setting. |

## 2026-11-16, session 2 continued: three screenshots, research notes, and the flank

### Reported by Amit

Three screenshots, "ci green", and pasted research notes on how appeals were made. No
comments on the screenshots, so what follows is read from the pictures.

1. **Section broken at 1:37, in the downpour.** Team 1 had walked up in front of the
   picket's bank; team 2 was gone. The picket untouched, 11 rounds left of 200.
2. **The picket gone in 0:28, nine of ten men fit.** Team 1 round the north, team 2
   round the south, nobody pinning from the middle. All four of the picket shot down.
3. **3:15 and stuck.** Team 2 dead in the south; team 1 had four men with no rounds left,
   still listed as "firing", the picket still holding, and the 60-round box untouched.

### What the second screenshot showed: the game said "just go round"

A new comparison plan, both teams flanking at once with nobody pinning, succeeded 199
times in 200 and kept 8.3 of 10 men fit. Pinning first kept 9.0. Covering fire saved
less than one man, which contradicts pillar 1.

The cause was the map. The jungle strips hid each flank route until four or five cells
from the picket. They were shortened from ten cells to five, so the last stretch of
either flank crosses open slope in the picket's view, where only a pinned picket lets
a team through.

Two hundred battles per plan:

| Plan | Before | After |
|---|---|---|
| Frontal, stopping in front | 0% | 0% |
| Frontal rush to the bank | 12% | 12% |
| Pin, then flank | 98%, 9.0 fit | 80%, 8.0 fit |
| Flank, no covering fire | 86%, 7.4 fit | 66%, 6.1 fit |
| Double flank, nobody pinning | 99%, 8.3 fit | 52%, 5.3 fit |

A new test asserts that pinning first keeps at least one more man fit than the double
flank, over the ten fixed battles. The cost: pin-then-flank itself fell from 98% to
80%. The Gate 1 criterion asks for 70%.

### What the third screenshot showed: nothing told you what to do with no rounds

- A team with no rounds left says "no rounds left" instead of "firing".
- A man with none has a small red 0 beside him.
- When nobody in the section has a round left, the controls line becomes: "Your section
  has no rounds left. G gathers from a box or a fallen man beside you. B falls back."

### Tried and removed: slow fire

The third screenshot and the battle listings showed covering fire burning a team's
rounds in about a minute. A "slow fire" setting on `F` was built to keep the picket
pinned for fewer rounds, then measured: switched on once the picket was pinned, it was
worse on every count over 200 battles (140 against 161 successes, 6.9 against 8.0 men
fit, 48 against 72 rounds left, 33 against 27 battles ending dry). Easing off lets the
picket's heads come up while the flank is crossing, the fight drags on, and more rounds
go in the end. Removed: the brief cuts features that serve no pillar.

### The research notes

Checked claim by claim; the full table is in `docs/history/TO_VERIFY.md` section 9. In
short:

- **Supported, second-hand:** loudspeaker appeals in Urdu and Hindustani at Kohima and
  Jessami in 1944 (one Nagaland newspaper article, no citations); "Josh" groups; the
  Hikari Kikan.
- **Contradicted:** the safe-conduct passes on record are British passes for INA men,
  not Bose's for Indian soldiers.
- **Not found:** gramophones, leaflets in split bamboo, disguise in British uniform,
  calling NCOs by name, and any published war diary by Shaukat Malik.

What this unblocks: an appeal encounter where a team calls out to an enemy group,
usually fails and draws fire, and is likelier to work on a small group that is pinned,
has lost men, or is cut off. Tagged COMPOSITE. Moved up the backlog to next.

### Verified

- 208 tests pass; `make check` is clean.
- The Gate 1 test passes on its ten fixed battles (pin-then-flank 9 of 10, frontal and
  rush 0 of 10, pin-first 8.1 men fit against 5.7 for the double flank).

### Not verified

- How the longer open crossing feels: whether it reads as "the picket covers its
  flanks" or as "flanking got harder for no reason".
- Whether the red 0 is noticed in play.

## 2026-11-16, session 2 continued: a screenshot from Amit, and scavenging

### Reported by Amit

A screenshot of a finished fight. Read from the picture: team 1 went round the north
and team 2 round the south, with nobody pinning the picket from the middle. The ground
was taken in 55 seconds for six men down of ten, one above "section broken". That is
what the numbers predict for a flank with no covering fire. He sent no comment with it.

### Fixed, from that screenshot

- The last line of the status strip sat on the window edge on his screen. Smaller
  text and a bottom margin.
- The strip still said RUNNING behind the debrief. It now says ENDED.

### Done: scavenging

- **Ammunition on the ground.** A scenario can place boxes. A man who falls leaves
  what he carried where he fell. An enemy who withdraws takes his rounds with him.
- **Gather** (`G`). The selected team picks up rounds from a box or a fallen man on or
  next to its cell: one round every half second per man, up to forty carried. A man
  only gathers while standing still and not pinned, and while gathering he does not
  fire. `G` again stops it.
- **On screen:** a small yellow box with the rounds in it, the number outlined so it
  reads over a casualty's mark. The status strip says "gathering" for a team told to.
- The test range has a box of 60 rounds on the track in the open, about seven cells
  in front of the picket.
- 205 tests pass. `make check` is clean. Gate 1 numbers unchanged (the scripted plans
  never gather).

**How to see it:** `make run`. Send a team to the box on the track and press `G`.
Watch its rounds climb in the status strip while it stops firing. Or let a man fall
and send a comrade to his number.

**Found while testing:** a man who finished gathering went straight back to firing at
an enemy still in range and spent part of what he had picked up. That is the rule
working; the first version of the test had assumed otherwise.

### Not verified

- Whether gathering under fire is ever worth it, or always a trap. The box sits in the
  picket's field of fire on purpose; nobody has played it.
- Whether half a second a round is the right speed.

### Decisions and why

| Decision | Why |
|---|---|
| Rounds only, no food yet | Food belongs with hunger, which is the next item. One counted resource at a time. |
| Gathering is an order, not automatic | Scavenging is meant to be a decision with risk. Automatic pickup would remove the decision. |
| A gatherer does not fire | That is the risk: the team stops covering itself while it restocks. |
| Withdrawn enemies keep their rounds | They walked off with their kit. Killing them and driving them off should leave different ground behind. |
| Only one-cell reach | A man has to go to the rounds. Reaching across the map would remove the walk in the open. |

## 2026-11-16, session 2: Gate 1 passed; Phase 2 begins

### Decided by Amit

- **Gate 1: "yes".** CI green on the Phase 1 build.

No tallies from the playtest sheet came with it. The gate is recorded as passed on his
word. Criterion 1 is backed by an automated test; criteria 2 to 5 have no data on
record. This matters later: any Phase 2 choice that depends on how the fight feels is
being made without evidence, and should say so.

### Done

- **Mission outcomes.** A mission now ends in one of three ways, and the simulation
  stops when it does:
  - *Objective taken*: the enemy has nobody left in the fight.
  - *Section broken*: fewer than four of the ten men are fit (set per scenario).
  - *Withdrew*: every team was told to fall back and all are back where they started.
- **Debrief.** Replaces the old one-line banner. It says how the mission ended, then
  counts men fit and down, rounds left of those carried, what became of the picket,
  and the time taken. No fanfare.
- 170 tests pass. `make check` is clean.

### How to see it

`make run`. Any of these ends the mission and shows the debrief:

- Clear the picket by pinning and flanking.
- Walk both teams at the picket until fewer than four men are fit.
- Advance, then press `B` for each team and wait for them to get back.

### Done later the same session: weather as a rule

- **Weather states** in `game/data/weather/`: dry, rain and downpour. Each sets how
  far anyone can see, how slow slopes are, and how often a rifle stops.
- **It changes during a mission** on a schedule in the scenario. The test range has
  rain, a downpour from one minute in, then rain again.
- **Sight.** Nobody can shoot further than the weather lets him see. In a downpour
  that is 8 cells against a rifle's 14, so a team firing from the middle bank can no
  longer reach the picket.
- **Slopes.** A new kind of ground, drawn with short strokes. Walking onto it costs
  more, and more again when wet. Routes go round a slope when that is quicker.
- **Stoppages.** In rain a shot may not go off. The round is kept and the man needs
  two seconds to clear the rifle.
- **On screen:** the rain is as heavy as the weather says, the status strip names the
  weather and the sight distance, and with the debug overlay on, `W` steps through the
  weather states.
- 187 tests pass. `make check` is clean.

**How to see it:** `make run`, press `O`, then `W` a few times. Watch the sight
distance in the status strip and the white range rings shrink in a downpour.

**What the Gate 1 check says now** (200 battles per plan, with weather on):

| Attack | Succeeded | Attackers still fit, of 10 |
|---|---|---|
| Frontal, stopping in front | 0 of 200 | 3.0 |
| Frontal rush to the picket's bank | 24 of 200 | 3.6 |
| Pin, then flank | 197 of 200 | 9.0 |
| Flank with team 1 holding fire | 173 of 200 | 7.4 |

The frontal figures for men still fit are higher than before only because the mission
now stops when the section is broken, at three men.

**Found while tuning:**

- The rush went from 3% to 29% success when rifles stopped 3% of the time for three
  seconds. A short decisive approach is very sensitive to the defender losing a few
  shots. Set to 1% and two seconds in rain; the rush now succeeds 12% of the time.
  The criterion allows 20%.
- With slopes along the whole flank route, the quickest route became the one across
  open ground, and the flanking team walked into the picket's fire. The slopes were
  shortened to the last five cells. Routes do not know about danger.

**Not verified:** how the downpour feels in play, and whether losing your covering
fire to the weather reads as the weather being a character or as bad luck.

| Decision | Why |
|---|---|
| Weather follows a schedule in the scenario | The mission designer decides when the downpour comes. A seeded random weather can be added later if replays feel the same. |
| A stoppage keeps the round | Losing time is the cost. Losing ammunition too would punish twice. |
| No dice are rolled when the stoppage chance is zero | Dry weather then leaves the sequence of random numbers alone, so adding weather did not disturb any existing test. |
| Sound was left out | The brief says rain hides sound, but there is no hearing in the game and it was cut from scope at Gate 0. |

### Decisions and why

| Decision | Why |
|---|---|
| Taking the objective counts even if it cost the section | Both things are true and the debrief shows both. The counts carry the cost. |
| Withdrawal needs an explicit fall-back order for every team | Standing at the start line is not a decision. Ordering everyone back is. |
| A casualty's rounds are lost with him | Simple, and it makes losses cost ammunition too. Scavenging from your own casualties can be weighed when scavenging is built. |
| The simulation stops at the outcome | Otherwise the counts in the debrief keep changing behind it. |

## 2026-11-15, session 1 continued: the Phase 1 build is ready for Gate 1

### Reported by Amit

- CI green on the Gate 1 criterion commit, so the criterion test passes on Linux too.
- "Continue for next." He has not yet reported playing the suppression build.

### Done

- **Fall back** (`B`). The selected team returns to where each man started. Men
  falling back walk even when pinned and do not fire. A later move order cancels it.
- **"How to play" page** after the briefing and on `H` during play: the keys, and what
  the marks on the map mean. Opening it pauses the game.
- **Debug overlay** (`O`): the enemy's range, red lines to men he can hit, grey lines
  to men he sees but cannot hit, green lines where your man has a clear shot, each
  man's suppression number and state, and the enemy's last six decisions.
- A team with nobody left now reads "none left" in the status strip.
- **Gate 1 playtest sheet** in `docs/GATE1_PLAYTEST.md`.
- 158 tests pass. `make check` is clean.

### How to see it

`make run`. Space through the briefing and the "how to play" page. On the map, press
`O` to see who can hit whom, `H` for help, and `B` after an advance to pull a team
back.

### Verified

- Rules by unit tests. The "how to play" page and the overlay by screenshot.

### Not verified

- Everything about feel. This is the first build meant to be judged for it.
- Whether the "how to play" page is enough for criterion 4 (orders within two minutes).
- The Windows export job in CI, and the Windows build itself.

### Decisions and why

| Decision | Why |
|---|---|
| Added a fall-back order before the playtest | The GDD lists it as a core order and says withdrawing is always a legitimate result. Without it, a team pinned in the open could only wait to be shot. |
| Fall back goes to the starting position, with no target to pick | One key, usable in a panic. A chosen destination can come later if the playtest asks for it. |
| The two balance worries were left alone | Whether a wiped-out frontal attack feels unfair, and whether covering fire feels worth it, are questions about feel. Changing them before Amit plays would be guessing. |
| Debug text is not translated beyond its headings | The enemy's decision log is a developer note. It is not shown unless the overlay is on. |
| Stopped here | Gate 1 is Amit's to judge. Phase 2 does not start until it passes. |

## 2026-11-15, session 1 continued: briefing, enemy behaviour, Gate 1 criterion 1

### Reported by Amit

- CI green on the waypoints and suppression commit.
- He marked the check box in `docs/history/mission-01.md` "ok".

### Done

- **Opening briefing.** Eight sentences, each a row of the history file that Amit
  checked. It names its single source and says the map is a test range.
- **Broken men.** At very high suppression a man stops firing until the pressure has
  fallen back below the pinned level.
- **Enemy behaviour.** The picket gives up its position when it has lost half its men,
  or when it is flanked and at least half of those left are pinned. A single broken
  man goes back alone. Men who reach the fallback point leave the fight unhurt and are
  counted apart from casualties. Every decision goes to `Simulation.ai_log`.
- **Outcome banner.** Says how the fight ended and what it cost.
- **Gate 1 criterion 1 as a test**, plus `make gate1` to print the battles behind it.
- 141 tests pass. `make check` is clean.

### What the first run of the Gate 1 check found

With the first-guess numbers the game said the opposite of its own pillar:

| Attack | Succeeded, first numbers |
|---|---|
| Frontal, stopping in front of the picket | 10 of 10 |
| Pin, then flank | 5 of 10 |

Ten rifles in the open broke four men behind a bank by volume of fire alone. Nothing
before this check would have shown it; every unit test passed.

### What was changed, and why

| Change | Why |
|---|---|
| Fire that crosses a man's cover cannot push his suppression above 70 (broken is 85) | Fire from the front can now pin men in cover but never break them. Only fire from a side their cover does not protect can. This one rule is pillar 1. |
| Fire across cover never hits (was 35% of normal) | Otherwise enough rifles in front eventually kill half the picket, which makes it fall back. Simple for the player: you cannot shoot men out from behind a bank from the front. |
| Cover reaches two cells behind a bank, and a bank next to the shooter covers nobody | A whole team can now shelter behind one bank. Two men at arm's length across the same bank have no cover from each other. |
| Rifle hit chance in the open 8% to 14% | "A unit under fire that is not in cover dies fast" was not true. |
| Suppression per shot 12 to 20, to a neighbour 4 to 8, through cover 60% to 40% | Men walking in the open now go to ground under fire instead of arriving intact. |
| Test range redrawn: open ground in front of the picket, jungle strips hiding a route round each flank | The old map let attackers reach the picket almost unseen, so a rush worked 9 times in 10. A picket would have a field of fire. |

### Where it stands now

Two hundred seeded battles per plan (`make gate1 RUNS=200`):

| Attack | Succeeded | Attackers still fit, of 10 |
|---|---|---|
| Frontal, stopping in front | 0 of 200 | 0.0 |
| Frontal rush to the picket's bank | 6 of 200 | 0.3 |
| Pin, then flank | 191 of 200 | 8.8 |
| Flank with team 1 holding fire | 177 of 200 | 7.3 |

Success means the picket has nobody left in the fight within two minutes and at least
six of the ten attackers are fit. The criterion asks for frontal to fail at least 8 in
10 and pin-then-flank to succeed at least 7 in 10. Both frontal versions are tested.

### What this does not show

- **Covering fire matters less than the flank.** Holding fire and flanking anyway
  still works 88% of the time. Pinning first raises that to 95% and saves about one
  and a half men. The game currently says "go round" louder than "pin first".
- **A frontal attack is annihilated, not merely beaten.** Pinned men in the open stay
  there until they are shot. That may read as unfair rather than instructive.
- These are scripted plans on one map. A person will find other plans.
- Criterion 1 is about the rules. Criteria 2 to 5 are about whether it is fun, and
  only Amit playing can answer them.

### Verified

- Rules by unit tests. The briefing and the new map by screenshot.
- CI on Linux, on the previous commit.

### Not verified

- Feel in motion, and whether the briefing reads well on Amit's screen.
- The Windows export job in CI, and the Windows build itself.

### Decisions and why

| Decision | Why |
|---|---|
| Rows 1 and 2 of the briefing reworded after Amit's check | Rows 6 and 7 use the source's late-June figures, so the date became late June and the airfield attack "early May". Recorded in the history file. No claim was added. |
| The briefing shows a source line and "this map is a test range" | The game makes a historical claim on its first screen. It should say what the claim rests on and what is not real. |
| Withdrawn men are counted apart from casualties | Driving the enemy off and killing him are different outcomes, and the debrief should say which happened. |
| The picket does not turn to face a flank | It would need cover on more than one side and a place to move to. Holding or leaving is enough to make the flank matter. Listed as a rough edge. |
| The Gate 1 test also covers the frontal rush | The rush is the strongest frontal attack. A criterion that only tested a weak one would be a strawman. |

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
