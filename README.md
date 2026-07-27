# Iterated Function Systems with OCaml

Fractals are images of infinite complexity, characterized by being "similar" to
themselves in some sense at all scales of magnification.

Iterated function systems (IFS) are a method of generating fractals using
self-similarity. An IFS image is defined as being the sum of geometric
transforms of itself: each transform is a small affine map (a combination of
scaling, rotation and translation) that maps the whole image onto one of its
parts. It turns out that simply specifying the transforms along
with a weight for each transform is enough to determine the image.


## How it works

The program draws the image with the so-called *chaos game*:

1. Start from an arbitrary point.
2. Pick one of the transforms at random, according to its weight.
3. Apply it to the current point and plot the result.
4. Repeat from step 2, a few hundred thousand times.

Whatever the starting point, the plotted points quickly converge onto the
*attractor* of the system — the fractal image. More iterations simply fill in
the picture with more detail.

In the code (`ifs_fractals.ml`), a fractal is described by an `ifs` record:

* `lt` — the list of affine transforms. Each transform has a coefficient array
  `kf = [|a; b; c; d; e; f|]` meaning `x' = a*x + b*y + c` and
  `y' = d*x + e*y + f`, and a probability `pb`. The probabilities are
  *cumulative*: the last transform of the list must have `pb = 1.0`.
* `po` and `sz` — the origin and size of the region of the plane to display,
  used to scale the points to the graphics window.

### Available fractals

Eleven classic fractals are predefined:

* `barnsley` — the Barnsley fern, the most famous IFS fractal (pictured below);
* `sierpinski` — the Sierpiński triangle;
* `dragon` — a dragon curve;
* `coral` — a coral-like branching shape;
* `tree` — a fractal tree;
* `star` — a star-shaped spiral;
* `zigzag` — a zigzag pattern;
* `crystal` — a crystal-like shape;
* `binary` — a binary branching pattern;
* `galaxy` — a spiral galaxy;
* `koch` — the Koch curve.


## How to use this code

### Installation

The program uses the OCaml [graphics](https://github.com/ocaml/graphics)
library, installed through [opam](https://opam.ocaml.org), the OCaml package
manager. On Debian/Ubuntu:

```bash
$ sudo apt install ocaml opam
$ opam init
$ opam install graphics ocamlfind
$ eval $(opam env)
```

`eval $(opam env)` makes the opam-installed libraries visible to the current
shell; run it again in any new terminal (or let `opam init` add it to your
shell profile).

### In your OCaml interpreter

The script is meant to be loaded in the interactive toplevel (it opens a
graphics window, so a graphical display is required):

```bash
$ ocaml
        OCaml version 5.3.0
```

```ocaml
# #use "ifs_fractals.ml";;
# draw barnsley 200000;;
```

The first line loads the script and opens a 400x640 graphics window. `draw`
takes a fractal and the number of points to plot — try smaller values like
`20000` to watch the image build up, or replace `barnsley` with any of the
predefined fractals above.

### Defining your own fractal

Add a new `ifs` record following the same pattern as the predefined ones:
choose your affine transforms, give them cumulative probabilities ending at
`1.0`, and pick `po`/`sz` so that the attractor fits in the displayed region.
Transform coefficients for many classic fractals can be found in the resources
below.

### Result

![Barnsley Fern](example/barnsley.png "Barnsley Fern")


## Resources

This work was carried out during a functional programming course.

Some information about Iterated Function Systems (with the Barnsley Fern):

* https://web.archive.org/web/20160913030719/http://nahee.com/spanky/www/fractint/ifs_type.html
* https://web.archive.org/web/20160509162647/http://paulbourke.net/fractals/ifs_fern_a/
* https://web.archive.org/web/20160401092248/http://mathcurve.com/fractals/fougere/fougere.shtml
* https://web.archive.org/web/20160401180724/http://charles.vassallo.pagesperso-orange.fr/fr/art/ifs.html


## Alternatives

* IFS in Common Lisp: https://github.com/jl2/ifs-qt
* J: https://news.ycombinator.com/item?id=12803076
* Barnsley Fern in G'MIC: https://rosettacode.org/wiki/Barnsley_fern#G.27MIC
