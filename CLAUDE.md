# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

An OCaml project that draws fractals using Iterated Function Systems (IFS), rendered with the OCaml `graphics` library. It is packaged with dune as the `ifs-fractals` opam package: a library (`lib/`, module `Ifs_fractals`) plus a command-line executable (`bin/`). There are no tests and no lint setup.

## Building and running

Dependencies (one-time setup): `opam install dune graphics ocamlfind`, then `eval $(opam env)`.

- `dune build` — builds the library, the executable, and regenerates `ifs-fractals.opam` from `dune-project`.
- `dune exec -- ifs-fractals lace` — draws a fractal (requires a graphical display). Also `--list`, `-n N` to override the iteration count, and `-o FILE` (plus optional `-s WxH`) to render a PNG headlessly instead — use that to test rendering without a display.
- Historical toplevel workflow, from the repo root: `ocaml`, then `#use "ifs_fractals.ml";;` and `draw barnsley 200000;;`. The root `ifs_fractals.ml` is only a loader: it `#mod_use`s `lib/fractals.ml` (so the module `Fractals` exists) then `#use`s `lib/ifs_fractals.ml`, and opens the Graphics window. Loading `lib/ifs_fractals.ml` on its own fails — it starts with `include Fractals`.

## Code structure

The library is two files, both kept directive-free so they work compiled and in a toplevel alike:

`lib/fractals.ml` (module `Fractals`) holds only data — the core types and the predefined fractals. `lib/ifs_fractals.ml` (module `Ifs_fractals`, the library's entry point) starts with `include Fractals`, re-exporting all of it, and adds every algorithm. Because dune wraps the library, `Fractals` is reachable from outside only through that `include`; keep it.

- `point`, `transfo`, `ifs` — core types, defined in `fractals.ml`. A `transfo` is one affine map: `pb` is the *cumulative* probability threshold (the last transform in a list must have `pb = 1.0`) and `kf` is a 6-element array `[|a; b; c; d; e; f|]` encoding `x' = a*x + b*y + c`, `y' = d*x + e*y + f`. An `ifs` bundles the viewport origin `po`, viewport size `sz`, and the transform list `lt`.
- `iterate fs n plot` — the chaos game: iterates from `{x=1.0; y=1.0}`, picking a transform per step via `Random.float` against the cumulative `pb` thresholds, and hands every point to `plot`.
- `draw fs n` — runs the chaos game into the 400x640 Graphics window (opened lazily on first draw, or explicitly with `init ()`), and returns with the window still open. `show fs n` draws, waits for a keypress, then closes: the graphics library only handles events (including the window manager's close button) while inside an event call, so a bare `draw` leaves an unclosable window. `window_open ()` probes the library instead of caching a flag, so `draw` reopens a window that was closed behind its back.
- `render ?width ?height fs n` — runs it into an off-screen array of per-pixel hit counts; `save_png ?width ?height ?color fs n file` writes it as an 8-bit PNG (self-contained writer using stored deflate blocks — needs no display and no image library). Default is black-on-white; `~color:true` maps hit counts through `density_ramp` on a log scale.
- Predefined `ifs` values (all in `fractals.ml`): `barnsley`, `sierpinski`, `dragon`, `coral`, `tree`, `star`, `zigzag`, `crystal`, `binary`, `galaxy`, `koch`, `maple`, `fiddlehead`, `sunflower`, `lace`, `vegvisir` — all listed in `all` (name, ifs, recommended iterations). To add a fractal, define a new `ifs` record in `fractals.ml` following the same pattern (cumulative probabilities ending at 1.0, viewport chosen to frame the attractor), add it to `all`, and mention it in the README's "Available fractals" list.

`ifs-fractals.opam` is generated — edit `dune-project`, not the opam file.
