# 1.2.0 (unreleased)

- The predefined fractals moved out of `lib/ifs_fractals.ml` into their own
  `lib/fractals.ml`, together with the `point`, `transfo` and `ifs` types,
  so that adding or tuning a fractal no longer touches the code that draws
  it. `Ifs_fractals` re-exports them, so the library API is unchanged, and
  so is the toplevel workflow (the loader now uses `#mod_use` for the new
  file).
- `show fs n` draws a fractal, waits for a keypress and closes the window.
  Unlike `draw`, it leaves the program inside an event call, which is what
  lets the window manager's close button work.
- Fixed: after the graphics window was closed — by `Graphics.close_graph`
  or by the window manager — `draw` failed with `Graphic_failure "graphic
  screen not opened"` instead of opening a new window. `window_open` is now
  a function that asks the graphics library rather than a stale flag.
- Fractals can be read from Fractint `.ifs` files: `ifs-fractals -f
  FILE.ifs NAME` from the command line, `load_fractint` from the library.
  The format's plain weights are converted to cumulative thresholds (or
  derived from each map's determinant when the file gives none), and the
  viewport, which the format does not record, is fitted to the attractor
  by `fit`. `example/classics.ifs` collects a dozen classic systems to
  try it on.
- Three-dimensional systems — Fractint's `(3D)` entries, twelve or
  thirteen numbers per transform — are read and drawn as well, projected
  orthographically from a direction given by `-v YAW,PITCH` in degrees
  (`?yaw` and `?pitch` in the library). Reading a file now returns a
  `system`, either `Flat of ifs` or `Solid of ifs3`; `draw_system`,
  `show_system` and `save_png_system` take either.

# 1.1.0 (2026-08-05)

- Fractals can now be rendered to PNG files without a graphical display:
  `ifs-fractals -o fern.png barnsley` from the command line (with an
  optional `-s WIDTHxHEIGHT`), or `save_png` from the library. The PNG
  writer is self-contained — no new dependency.
- Density coloring: with `-c` (or `save_png ~color:true`), pixels are
  colored by how often the chaos game visits them, on a log scale from
  light green to dark blue.

# 1.0.0 (2026-07-27)

First release on opam, sixteen years after the first commit.

- Packaged with dune: the code now builds as a library (`ifs-fractals`,
  module `Ifs_fractals`) and an `ifs-fractals` command-line executable.
- The historical toplevel workflow (`#use "ifs_fractals.ml";;`) still works
  from a clone of the repository.
- Sixteen predefined fractals, including the five added in 2026: `maple`,
  `fiddlehead`, `vegvisir`, `sunflower` and `lace`.
