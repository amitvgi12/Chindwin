# Gate 1 playtest

One sitting of about forty minutes. You play; Claude cannot. The question is the one
in the brief: does pinning and flanking feel good with no art?

Criterion 1 (the rules do what pillar 1 says) is already checked by an automated test.
This sheet covers criteria 2 to 5 in `docs/SCOPE.md`.

## Before you start

1. `git pull`, then `make check`. It should end with `TESTS OK`.
2. Have a timer and somewhere to make tally marks.
3. `make run`. Read the briefing and the "how to play" page once. Start the timer when
   the map appears.

Keep the debug overlay (`O`) **off** for the thirty minutes. Criterion 3 depends on it.

## The thirty minutes

Play however you like. There is no set plan. Things worth trying if you run dry:

- Walk both teams straight at the picket.
- Pin with one team from the middle bank, then send the other round the north.
- The same round the south.
- Flank with no covering fire: put team 1 behind the bank and press `F`.
- Start an attack, then press `B` to pull a team out.
- Try to win spending as few rounds as you can.

While you play, keep three tallies:

| Tally | Mark it when |
|---|---|
| Restarts | you press `R` because **you** wanted another go, not because the fight had ended and there was nothing else to do |
| Losses explained | an attempt fails and you can say why in one sentence, from what the screen showed |
| Losses not explained | an attempt fails and you cannot |

Also note the time on the timer when you first gave an order to **each** team.

## When the timer reaches thirty minutes

Stop, even mid-fight, and answer before doing anything else.

| # | Criterion | Your answer | Pass if |
|---|---|---|---|
| 2 | You replay it unprompted | Restarts: ___ | 3 or more |
| 3 | You can explain each loss | Explained: ___ Not explained: ___ | "Not explained" is 0 |
| 4 | Orders are quick | First order to team 1 at ___, to team 2 at ___ | both within 2 minutes |
| 5 | You want another go | Keep playing or stop? ___ | "keep playing" |

Gate 1 passes only if all four pass. Be strict. A gate that cannot fail is not a gate.

## Then, five minutes with the overlay on

Press `O` and play one more attack. Tell Claude:

- Did anything the overlay showed surprise you?
- Was there a loss you could not explain that the overlay did explain? That points at
  something the normal screen should be showing.

## What to paste back to Claude

```
Restarts: 
Losses explained / not explained: 
First order to team 1 / team 2: 
Keep playing or stop: 
The best moment: 
The worst moment: 
One thing that felt unfair: 
One thing that felt too easy: 
Walking speed (too slow / right / too fast): 
How fast men get hit (too slow / right / too fast): 
Did covering fire feel worth the rounds: 
Overlay surprises: 
```

## If Gate 1 fails

That is a normal result. `docs/SCOPE.md` allows two rounds of changes, two weeks each,
before the review on 7 February 2027. Say which criterion failed and what the worst
moment was; that is where the next change goes.
