# 1.2.0 (unreleased)

- The predefined fractals moved out of `lib/ifs_fractals.ml` into their own
  `lib/fractals.ml`, together with the `point`, `transfo` and `ifs` types,
  so that adding or tuning a fractal no longer touches the code that draws
  it. `Ifs_fractals` re-exports them, so the library API is unchanged, and
  so is the toplevel workflow (the loader now uses `#mod_use` for the new
  file).

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
