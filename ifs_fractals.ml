(* Toplevel entry point, kept for the historical workflow:
       $ ocaml
       # #use "ifs_fractals.ml";;
       # draw barnsley 200000;;
   The actual code lives in lib/: the fractals in fractals.ml, loaded as
   the module Fractals, and the drawing in ifs_fractals.ml (both also
   built as the ifs-fractals opam package); run this from the repository
   root. *)

#use "topfind";;
#require "graphics";;
#mod_use "lib/fractals.ml";;
#use "lib/ifs_fractals.ml";;

init ();;
