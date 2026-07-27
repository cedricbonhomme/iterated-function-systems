(* Toplevel entry point, kept for the historical workflow:
       $ ocaml
       # #use "ifs_fractals.ml";;
       # draw barnsley 200000;;
   The actual code lives in lib/ifs_fractals.ml (also built as the
   ifs-fractals opam package); run this from the repository root. *)

#use "topfind";;
#require "graphics";;
#use "lib/ifs_fractals.ml";;

init ();;
