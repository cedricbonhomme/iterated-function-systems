# Building New IFS Attractors: a Working Vocabulary of Affine Maps

A paper on the *inverse* problem of iterated function systems: given a shape
in mind, how does one write the affine coefficients that produce it?

The attractor of an affine IFS is determined by a handful of real numbers,
and the classical attractors are well documented, but the craft of designing
new ones is mostly folklore. The paper names five families of affine maps
that compose into new attractors, states each as a formula, and gives the
exact coefficients of a working attractor as witness:

* **stem maps** — rank-deficient "terminators" that squash the whole
  attractor onto a thin segment;
* **spiral generators** — one dominant rotation-contraction plus satellite
  motifs;
* **radial replication** — copies along the rim of a dome, for umbels;
* **golden-angle maps** — phyllotaxis in two transforms;
* **symmetry maps** — a *non-contracting* rotation at scale 1.0, which draws
  nothing itself and distributes the work of the other maps around a circle.

Symmetry maps leave the classical Hutchinson framework, so the paper records
the average contractivity condition of Barnsley, Demko and Elton that makes
them legitimate, and bounds them with a rigidity result: an isometry inside
the system forces the attractor to be invariant under it. That is why an IFS
can only offer a symmetric idealization of a designed symbol such as the
Icelandic vegvísir, and it leads to a closing discussion of why grown forms
admit compact IFS descriptions while designed ones resist them.

The six attractors used as witnesses (`maple`, `fiddlehead`, `vegvisir`,
`sunflower`, `lace`, alongside the classical `barnsley`) are all shipped in
the [`ifs-fractals`](https://opam.ocaml.org/packages/ifs-fractals/) opam
package built from this repository:

```bash
opam install ifs-fractals
ifs-fractals lace
```

## Reading it

The built PDF is `main.pdf` in this directory.

A narrative account of how the new attractors were designed is on the
author's blog:
[Challenging Claude's creativity with IFS fractals and OCaml](https://www.cedricbonhomme.org/2026/07/27/challenging-claude-with-ifs-fractals/).

## Building it

Needs a TeX distribution with `pdflatex` and `bibtex` (on Debian/Ubuntu,
`texlive-latex-recommended` and `texlive-fonts-recommended` are enough):

```bash
make          # pdflatex, bibtex, pdflatex, pdflatex
make clean    # remove the intermediate files
```

Files:

| File | Contents |
| --- | --- |
| `main.tex` | the paper |
| `refs.bib` | bibliography |
| `figures/` | attractor renderings, drawn by the library in this repository |
| `Makefile` | build |

## Citing it

```bibtex
@misc{bonhomme2026ifs,
  author = {C{\'e}dric Bonhomme},
  title  = {Building New {IFS} Attractors: a Working Vocabulary of Affine Maps},
  year   = {2026},
  url    = {https://github.com/cedricbonhomme/iterated-function-systems/tree/master/paper}
}
```
