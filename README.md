# EDEFB

EDEFB is the Elite Dangerous Electronic Flight Bag.  It is a Common Lisp
companion for the game.  It reads the live player journal and the snapshot
files written beside it, and keeps the picture of the ship you are flying.

The window is a live report.  It shows the ship name, the ship type,
and the landing pad class, then the current system, station, and body,
and the fuel, cargo, and credits from the cockpit status.  The report
uses Euro Caps when Elite Dangerous Market Connector has installed that
font.  It keeps reading those files while the window is open.

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
