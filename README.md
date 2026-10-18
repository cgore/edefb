# EDEFB

EDEFB is the Elite Dangerous Electronic Flight Bag.  It is a Common Lisp
companion for the game.  It reads the live player journal and the snapshot
files written beside it, and keeps the picture of the ship you are flying.

Those files live under
`Saved Games\Frontier Developments\Elite Dangerous`: the NDJSON journal,
plus `Status.json`, `Cargo.json`, `ModulesInfo.json`, `NavRoute.json`, and
the docked market, shipyard, and outfitting dumps.

## License

3-clause BSD.  See [LICENSE.md](LICENSE.md).  Copyright (c) 2026, Christopher
Mark Gore, Soli Deo Gloria.
