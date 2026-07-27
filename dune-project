(lang dune 3.8)
(name ifs-fractals)

(generate_opam_files true)

(source (github cedricbonhomme/iterated-function-systems))
(authors "Cédric Bonhomme <cedric@cedricbonhomme.org>")
(maintainers "Cédric Bonhomme <cedric@cedricbonhomme.org>")
(license "GPL-3.0-or-later")
(documentation "https://github.com/cedricbonhomme/iterated-function-systems")

(package
 (name ifs-fractals)
 (synopsis "IFS fractals (the Barnsley fern and friends) drawn with the chaos game")
 (description
  "Draws fractals defined by iterated function systems (IFS) in an OCaml \
   Graphics window, using the chaos game. Sixteen fractals are predefined \
   (the Barnsley fern, the Sierpinski triangle, a dragon curve, a maple \
   leaf, a sunflower, Queen Anne's lace, ...), available both from the \
   ifs-fractals command-line tool and as a library for the toplevel. \
   Defining a new fractal is a small record: a handful of affine \
   transforms with their weights and a viewport.")
 (tags (fractals graphics chaos-game ifs))
 (depends
  (ocaml (>= 4.09))
  (graphics (>= 5.1))))
