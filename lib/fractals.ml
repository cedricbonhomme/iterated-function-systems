(* The collection of predefined fractals, and the types they are built
   from. Kept apart from the algorithms in ifs_fractals.ml, so that adding
   or tuning a fractal never touches the code that draws it.

   This file is loaded as the module Fractals, by dune and by the toplevel
   script at the repository root alike, so it must stay directive-free
   plain OCaml. *)

type point = { x: float; y: float}

(* pb is the *cumulative* probability threshold: the last transform of a
   list must have pb = 1.0. kf = [|a; b; c; d; e; f|] encodes
   x' = a*x + b*y + c and y' = d*x + e*y + f. *)
type transfo = { pb: float; kf: float array}

type ifs = { po: point; sz: point; lt: transfo list}

(* Three-dimensional systems, as found in the (3D) entries of Fractint
   files. kf3 is a 12-element array [|a; b; c; d; e; f; g; h; i; j; k; l|]
   encoding x' = a*x + b*y + c*z + j, y' = d*x + e*y + f*z + k and
   z' = g*x + h*y + i*z + l — the file's own order, unlike the flat kf.
   The field names carry a 3 so as not to shadow the flat ones. *)
type point3 = { x3: float; y3: float; z3: float}

type transfo3 = { pb3: float; kf3: float array}

(* A solid system carries no viewport: which part of space to show depends
   on the direction it is looked at from, so the region is worked out once
   the points have been projected. *)
type ifs3 = { lt3: transfo3 list}

(* Either kind of system — what reading a file gives back. *)
type system = Flat of ifs | Solid of ifs3

let barnsley =
{ po = {x= -2.25 ; y= -0.50};
sz = {x= 5.00 ; y= 11.00};
lt = [{pb= 0.84; kf= [| 0.85; 0.04; 0.00; -0.04; 0.85; 1.60|]};
{pb= 0.91; kf= [|-0.15; 0.28; 0.00; 0.26; 0.24; 0.44|]};
{pb= 0.98; kf= [| 0.20;-0.26; 0.00; 0.23; 0.22; 1.60|]};
{pb= 1.00; kf= [| 0.00; 0.00; 0.00; 0.00; 0.16; 0.00|]}]}

(* The three corners of the triangle: (0,0), (2,0) and (1, sqrt 3). *)
let sierpinski =
{ po = {x= -0.10 ; y= -0.89};
sz = {x= 2.20 ; y= 3.52};
lt = [{pb= 0.333; kf= [|0.5; 0.0; 0.0; 0.0; 0.5; 0.0|]};
{pb= 0.666; kf= [|0.5; 0.0; 1.0; 0.0; 0.5; 0.0|]};
{pb= 1.00; kf= [|0.5; 0.0; 0.5; 0.0; 0.5; 0.8660254|]}]}

let dragon =
{ po = {x= -40.0 ; y= -10.0};
sz = {x= 110.0 ; y= 110.0};
lt = [{pb= 0.787473; kf= [| 0.824074; 0.281482; -10.88229; -0.212346;
0.864198; -0.110607|]};
{pb= 1.0; kf= [| 0.288272; 0.720988; 0.78536; -0.463889; -0.377778;
80.095795|]}]}

let coral =
{ po = {x= -45.0 ; y= -5.0};
sz = {x= 95.0 ; y= 100.0};
lt = [{pb= 0.40; kf= [| 0.307692; -0.531469; 50.401953; -0.461538;
-0.293706; 80.655175|]};
{pb= 0.55; kf= [| 0.307692; -0.076923; -10.295248; 0.153846;
-0.447552; 40.152990|]};
{pb= 1.00; kf= [| 0.000000; 0.545455; -40.893637; 0.692308;
-0.195804; 70.269794|]}]}

let tree =
{ po = {x= -0.3 ; y= 0.0};
sz = {x= 0.6 ; y= 0.5};
lt = [{pb= 0.05; kf= [| 0.0; 0.0; 0.0; 0.0; 0.5; 0.0|]};
{pb= 0.45; kf= [| 0.42; -0.42; 0.0; 0.42; 0.42; 0.2|]};
{pb= 0.85; kf= [| 0.42; 0.42; 0.0; -0.42; 0.42; 0.2|]};
{pb= 1.00; kf= [| 0.1; 0.0; 0.0; 0.0; 0.1; 0.2|]}]}

let star =
{ po = {x= -50.0 ; y= -20.0};
sz = {x= 100.0 ; y= 100.0};
lt = [{pb= 0.912675; kf= [| 0.745455; -0.459091; 10.460279; 0.406061;
0.887121; 0.691072|]};
{pb= 1.0; kf= [| -0.424242; -0.065152; 30.809567; -0.175758;
-0.218182; 60.741476|]}]}

let zigzag =
{ po = {x= -70.0 ; y= -20.0};
sz = {x= 150.0 ; y= 130.0};
lt = [{pb= 0.888128; kf= [| -0.632407; -0.614815; 30.840822;
-0.54537;
0.659259; 10.282321|]};
{pb= 1.0; kf= [| -0.036111; 0.444444; 20.071081; 0.210185; 0.037037;
80.330552|]}]}

let crystal =
{ po = {x= -0.0 ; y= -70.0};
sz = {x= 100.0 ; y= 140.0};
lt = [{pb= 0.747826; kf= [| 0.69697; -0.481061; 20.147003; -0.393939;
-0.662879; 10.310288|]};
{pb= 1.0; kf= [| 0.090909; -0.443182; 40.286558; 0.515152; -0.094697;
20.925762|]}]}

let binary =
{ po = {x= -50.0 ; y= -1.0};
sz = {x= 100.0 ; y= 95.0};
lt = [{pb= 0.333333; kf= [| 0.5; 0.0; -20.563477; 0.0; 0.5;
-0.000003|]};
{pb= 0.666666; kf= [| 0.5; 0.0; 20.436544; 0.0; 0.5; -0.000003|]};
{pb= 1.0; kf= [| 0.0; -0.5; 40.873085; 0.5; 0.0; 70.563492|]}]}

let galaxy =
{ po = {x= -8.0 ; y= -1.0};
sz = {x= 16.0 ; y= 12.0};
lt = [{pb= 0.787879; kf= [| 0.787879; -0.424242; 1.758647; 0.242424;
0.859848; 1.408065|]};
{pb= 0.909091; kf= [| -0.121212; 0.257576; -6.721654; 0.151515;
0.053030; 1.377236|]};
{pb= 1.0; kf= [| 0.181818; -0.136364; 6.086107; 0.090909; 0.181818;
1.568035|]}]}

(* One side of the snowflake: a curve from (0,0) to (1,0), a third of the
   window high, so the 60 degree angles keep their shape. *)
let koch =
{ po = {x= -0.05 ; y= -0.74};
sz = {x= 1.10 ; y= 1.76};
lt = [{pb= 0.25; kf= [|0.333; 0.0; 0.0; 0.0; 0.333; 0.0|]};
{pb= 0.50; kf= [|0.167; -0.287; 0.333; 0.287; 0.167; 0.0|]};
{pb= 0.75; kf= [|0.167; 0.287; 0.5; -0.287; 0.167; 0.287|]};
{pb= 1.0; kf= [|0.333; 0.0; 0.667; 0.0; 0.333; 0.0|]}]}

let maple =
{ po = {x= -3.80 ; y= -3.65};
sz = {x= 7.60 ; y= 7.30};
lt = [{pb= 0.10; kf= [| 0.14; 0.01; -0.08; 0.00; 0.51; -1.31|]};
{pb= 0.45; kf= [| 0.43; 0.52; 1.49; -0.45; 0.50; -0.75|]};
{pb= 0.80; kf= [| 0.45; -0.49; -1.62; 0.47; 0.47; -0.74|]};
{pb= 1.00; kf= [| 0.49; 0.00; 0.02; 0.00; 0.51; 1.62|]}]}

let fiddlehead =
{ po = {x= -2.35 ; y= -0.45};
sz = {x= 3.70 ; y= 2.65};
lt = [{pb= 0.85; kf= [| 0.8645; -0.3146; 0.00; 0.3146; 0.8645; 0.40|]};
{pb= 0.95; kf= [| 0.15; 0.2598; 0.60; -0.2598; 0.15; 0.40|]};
{pb= 1.00; kf= [| 0.15; 0.00; 0.00; 0.00; 0.15; 0.00|]}]}

let sunflower =
{ po = {x= -1.08 ; y= -1.92};
sz = {x= 2.30 ; y= 3.68};
lt = [{pb= 0.88; kf= [| -0.7153; -0.6552; 0.00; 0.6552; -0.7153; 0.00|]};
{pb= 1.00; kf= [| 0.13; 0.00; 1.00; 0.00; 0.13; 0.00|]}]}

let lace =
{ po = {x= -0.90 ; y= -0.55};
sz = {x= 1.80 ; y= 2.00};
lt = [{pb= 0.18; kf= [| 0.2649; 0.1408; -0.7048; -0.1408; 0.2649; 0.38|]};
{pb= 0.36; kf= [| 0.3493; 0.0871; -0.4302; -0.0871; 0.3493; 0.5013|]};
{pb= 0.54; kf= [| 0.38; 0.00; 0.00; 0.00; 0.38; 0.55|]};
{pb= 0.72; kf= [| 0.3493; -0.0871; 0.4302; 0.0871; 0.3493; 0.5013|]};
{pb= 0.90; kf= [| 0.2649; -0.1408; 0.7048; 0.1408; 0.2649; 0.38|]};
{pb= 1.00; kf= [| 0.02; 0.00; 0.00; 0.00; 0.55; 0.00|]}]}

let vegvisir =
{ po = {x= -1.25 ; y= -2.00};
sz = {x= 2.50 ; y= 4.00};
lt = [{pb= 0.58; kf= [| 0.7071; -0.7071; 0.00; 0.7071; 0.7071; 0.00|]};
{pb= 0.76; kf= [| 0.40; 0.00; 0.45; 0.00; 0.04; 0.00|]};
{pb= 0.84; kf= [| 0.00; -0.11; 0.55; 0.11; 0.00; 0.00|]};
{pb= 0.92; kf= [| 0.00; -0.15; 0.82; 0.15; 0.00; 0.00|]};
{pb= 0.97; kf= [| 0.10; 0.00; 1.00; 0.00; 0.10; 0.00|]};
{pb= 1.00; kf= [| 0.18; 0.00; 0.00; 0.00; 0.18; 0.00|]}]}

(* Every predefined fractal, with a recommended number of iterations. *)
let all =
    [("barnsley", barnsley, 200_000);
    ("sierpinski", sierpinski, 200_000);
    ("dragon", dragon, 200_000);
    ("coral", coral, 200_000);
    ("tree", tree, 200_000);
    ("star", star, 200_000);
    ("zigzag", zigzag, 200_000);
    ("crystal", crystal, 200_000);
    ("binary", binary, 200_000);
    ("galaxy", galaxy, 200_000);
    ("koch", koch, 200_000);
    ("maple", maple, 200_000);
    ("fiddlehead", fiddlehead, 200_000);
    ("sunflower", sunflower, 500_000);
    ("lace", lace, 300_000);
    ("vegvisir", vegvisir, 500_000)]
