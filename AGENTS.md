# AGENTS.md

This repository is EDEFB, the Elite Dangerous Electronic Flight Bag.  It is Common Lisp.  The product description is in `README.md`.  Do not restate it in source comments.

The game's interface is the files it writes under `Saved Games\Frontier Developments\Elite Dangerous`: the NDJSON player journal, and the snapshot files beside it (`Status.json`, `Cargo.json`, `ModulesInfo.json`, `NavRoute.json`, and the docked market, shipyard, and outfitting dumps).  Read those files.  Do not invent a live network API to the game client.

## Copyright and license

The license is the 3-clause BSD notice in `LICENSE.md`.  Leave that text as it is written.

A new source file carries that notice at the top, each line prefixed with `;;;; `.  The copyright year is the year of the file.  When you edit a file in a later year, make the year a range from the first year on the notice through the year of the edit.

The notice names Christopher Mark Gore.  `Soli Deo Gloria` stays on the following line.

## Git

Commit finished work and push it.  The remote is `https://github.com/cgore/edefb.git` and the branch is `master`.  Do not rename the branch to `main`.  Do not force-push.

In other repositories Christopher reviews the tree and lands the commits himself.  In this repository, do not leave a finished change uncommitted for him to land.
