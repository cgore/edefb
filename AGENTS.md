# AGENTS.md

This repository is EDEFB, the Elite Dangerous Electronic Flight Bag.  It is Common Lisp.  The product description is in `README.md`.  Do not restate it in source comments.

The game's interface is the files it writes under `Saved Games\Frontier Developments\Elite Dangerous`: the NDJSON player journal, and the snapshot files beside it (`Status.json`, `Cargo.json`, `ModulesInfo.json`, `NavRoute.json`, and the docked market, shipyard, and outfitting dumps).  Read those files.  Do not invent a live network API to the game client.

## Interface

The interface is FitzCLIM, at `D:\Programming\Lisp\FitzCLIM` (`https://github.com/cgore/FitzCLIM.git`).  It is being built to the design in that repository's `AGENTS.md`: CLIM II on SBCL, a Windows frame manager that realizes gadgets as native controls, application panes drawn by FitzCLIM that hold presentations, and a native OpenGL pane whose picks are presentations.  The 2D graphics protocol stays two-dimensional.  Use FitzCLIM for the flight bag.  The 3D views are the galaxy map and the system map, alongside the ordinary panels.

## Libraries

Use Sigma whenever it already provides the utility you need.  Load `:sigma` and use the specific package (`sigma/behave`, `sigma/sequence`, `sigma/string`, `sigma/control`, `sigma/numeric`, `sigma/hash`, and the others).  Call `sigma:use-all-sigma` only in a scratch listener.  Application code names the package it uses.  Sigma is the ASDF system `:sigma` at <https://github.com/cgore/sigma>.  On this machine the checkout is `D:\Programming\Lisp\sigma`.

Use another Common Lisp library when its license is compatible with the 3-clause BSD license in `LICENSE.md`.  A compatible license lets EDEFB depend on the library, or vendor it, while EDEFB's own code stays 3-clause BSD.  Permissive licenses meet that test, including BSD, MIT, ISC, the Apache License 2.0, and public-domain dedications.  A copyleft license does not.  Keep that library's copyright and license notice with any code you vendor.

## Testing

Make all code well tested.  Cover the behavior you add or change, including the edges that change can break.  Run the tests before you commit.

Write those tests with Sigma's `sigma/behave` package whenever it can express them.  Group examples with `behavior` and `spec`.  Assert with `should`, `should-not`, `should-be-a`, `should-be-null`, `should-be-true`, `should-be-false`, and the generated comparators such as `should=` and `should-equal`.

## Copyright and license

The license is the 3-clause BSD notice in `LICENSE.md`.  Leave that text as it is written.

A new source file carries that notice at the top, each line prefixed with `;;;; `.  The copyright year is the year of the file.  When you edit a file in a later year, make the year a range from the first year on the notice through the year of the edit.

The notice names Christopher Mark Gore.  `Soli Deo Gloria` stays on the following line.

## Git

Commit finished work and push it.  The remote is `https://github.com/cgore/edefb.git` and the branch is `master`.  Do not rename the branch to `main`.  Do not force-push.

In other repositories Christopher reviews the tree and lands the commits himself.  In this repository, do not leave a finished change uncommitted for him to land.
