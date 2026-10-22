# EDEFB

EDEFB is the Elite Dangerous Electronic Flight Bag.  It is a Common Lisp
companion for the game.  It reads the live player journal and the snapshot
files written beside it, and keeps the picture of the ship you are flying.

The window is a live report.  Along the top are the game date and
time, then the current position.  A fleet carrier is shown as its
callsign and the name the journal wrote.  The left cluster is the
commander: the name, the ranks, the legal state, and the credits.  The next cluster has a Ship light and an On Foot light, the orange and
blue squares of the cockpit indicators.  The bright square is the
picture being shown.  Either square shows that picture, so the ship
remains available while the commander is on foot.  The ship picture includes the hull, whether the shields
are up, the power distribution, the fuel, and the cargo used, free,
and total.  The on-foot picture is the suit.
The report is orange text on black, in the style of a ship cockpit
display.
It keeps reading those files while the window is open.

Those files live under
`Saved Games\Frontier Developments\Elite Dangerous`: the NDJSON journal,
plus `Status.json`, `Cargo.json`, `ModulesInfo.json`, `NavRoute.json`, and
the docked market, shipyard, and outfitting dumps.

## Libraries

The interface is [FitzCLIM](https://github.com/cgore/FitzCLIM).  Shared
utilities come from [Sigma](https://github.com/cgore/sigma).  Other Common
Lisp libraries are used when their licenses fit the 3-clause BSD license
in [LICENSE.md](LICENSE.md).

## License

3-clause BSD.  See [LICENSE.md](LICENSE.md).  Copyright (c) 2026, Christopher
Mark Gore, Soli Deo Gloria.
