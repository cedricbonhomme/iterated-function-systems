# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

An OCaml project that draws fractals using Iterated Function Systems (IFS), rendered with the OCaml `graphics` library. It is packaged with dune as the `ifs-fractals` opam package: a library (`lib/`, module `Ifs_fractals`) plus a command-line executable (`bin/`). There are no tests and no lint setup.

## Building and running

Dependencies (one-time setup): `opam install dune graphics ocamlfind`, then `eval $(opam env)`.

- `dune build` — builds the library, the executable, and regenerates `ifs-fractals.opam` from `dune-project`.
- `dune exec -- ifs-fractals lace` — draws a fractal (requires a graphical display). Also `--list`, and `-n N` to override the iteration count.
- Historical toplevel workflow, from the repo root: `ocaml`, then `#use "ifs_fractals.ml";;` and `draw barnsley 200000;;`. The root `ifs_fractals.ml` is only a loader: it `#use`s `lib/ifs_fractals.ml` and opens the Graphics window.

## Code structure

All the real code lives in `lib/ifs_fractals.ml` (kept directive-free so it works both compiled and `#use`d in a toplevel):

- `point`, `transfo`, `ifs` — core types. A `transfo` is one affine map: `pb` is the *cumulative* probability threshold (the last transform in a list must have `pb = 1.0`) and `kf` is a 6-element array `[|a; b; c; d; e; f|]` encoding `x' = a*x + b*y + c`, `y' = d*x + e*y + f`. An `ifs` bundles the viewport origin `po`, viewport size `sz`, and the transform list `lt`.
- `draw fs n` — the chaos game: iterates from `{x=1.0; y=1.0}`, picking a transform per step via `Random.float` against the cumulative `pb` thresholds, and plots each point scaled to the 400x640 Graphics window. The window is opened lazily on first draw (or explicitly with `init ()`).
- Predefined `ifs` values: `barnsley`, `sierpinski`, `dragon`, `coral`, `tree`, `star`, `zigzag`, `crystal`, `binary`, `galaxy`, `koch`, `maple`, `fiddlehead`, `sunflower`, `lace`, `vegvisir` — all listed in `all` (name, ifs, recommended iterations). To add a fractal, define a new `ifs` record following the same pattern (cumulative probabilities ending at 1.0, viewport chosen to frame the attractor), add it to `all`, and mention it in the README's "Available fractals" list.

`ifs-fractals.opam` is generated — edit `dune-project`, not the opam file.
