# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A single-file OCaml script (`ifs_fractals.ml`) that draws fractals using Iterated Function Systems (IFS), rendered with the OCaml `graphics` library. There is no build system, no tests, and no lint setup — the script is meant to be loaded into the OCaml toplevel.

## Running

Dependencies (one-time setup): `opam install graphics ocamlfind`, then `eval $(opam env)`.

Run interactively in the OCaml toplevel (requires a graphical display, since it opens a Graphics window):

```ocaml
$ ocaml
# #use "ifs_fractals.ml";;
# draw barnsley 200000;;
```

The second argument to `draw` is the number of iterations (plotted points).

## Code structure

Everything lives in `ifs_fractals.ml`:

- `point`, `transfo`, `ifs` — core types. A `transfo` is one affine map: `pb` is the *cumulative* probability threshold (the last transform in a list must have `pb = 1.0`) and `kf` is a 6-element array `[|a; b; c; d; e; f|]` encoding `x' = a*x + b*y + c`, `y' = d*x + e*y + f`. An `ifs` bundles the viewport origin `po`, viewport size `sz`, and the transform list `lt`.
- `draw fs n` — the chaos game: iterates from `{x=1.0; y=1.0}`, picking a transform per step via `Random.float` against the cumulative `pb` thresholds, and plots each point scaled to the 400x640 Graphics window.
- The rest of the file is predefined `ifs` values: `barnsley`, `sierpinski`, `dragon`, `coral`, `tree`, `star`, `zigzag`, `crystal`, `binary`, `galaxy`, `koch`, `maple`, `fiddlehead`. To add a fractal, define a new `ifs` record following the same pattern (cumulative probabilities ending at 1.0, viewport chosen to frame the attractor).

Note: `#use "ifs_fractals.ml"` opens the Graphics window immediately (the `open_graph` call sits mid-file), so the file only works in a toplevel session, not compiled.
