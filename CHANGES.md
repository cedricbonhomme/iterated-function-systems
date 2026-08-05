# 1.1.0 (unreleased)

- Fractals can now be rendered to PNG files without a graphical display:
  `ifs-fractals -o fern.png barnsley` from the command line (with an
  optional `-s WIDTHxHEIGHT`), or `save_png` from the library. The PNG
  writer is self-contained — no new dependency.

# 1.0.0 (2026-07-27)

First release on opam, sixteen years after the first commit.

- Packaged with dune: the code now builds as a library (`ifs-fractals`,
  module `Ifs_fractals`) and an `ifs-fractals` command-line executable.
- The historical toplevel workflow (`#use "ifs_fractals.ml";;`) still works
  from a clone of the repository.
- Sixteen predefined fractals, including the five added in 2026: `maple`,
  `fiddlehead`, `vegvisir`, `sunflower` and `lace`.
