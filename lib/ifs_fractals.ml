(* Iterated function systems: the chaos game and a collection of fractals.
   This file is both the library module Ifs_fractals and the file loaded by
   the toplevel script at the repository root, so it must stay directive-free
   plain OCaml. *)

type point = { x: float; y: float}

(* pb is the *cumulative* probability threshold: the last transform of a
   list must have pb = 1.0. kf = [|a; b; c; d; e; f|] encodes
   x' = a*x + b*y + c and y' = d*x + e*y + f. *)
type transfo = { pb: float; kf: float array}

type ifs = { po: point; sz: point; lt: transfo list}

let image kf p =
    { x= kf.(0)*.p.x+.kf.(1)*.p.y+.kf.(2);
    y= kf.(3)*.p.x+.kf.(4)*.p.y+.kf.(5)}

let rec select_image p rd = function
    | t::_ when rd<=t.pb -> image t.kf p
    | _::lt -> select_image p rd lt
    | [] -> raise Not_found

let window_open = ref false

let init ?(geometry=" 400x640") () =
    Graphics.open_graph geometry;
    window_open := true

let pixel_of_point po sz p =
    (int_of_float((p.x-.po.x)/.sz.x*.float_of_int(Graphics.size_x())),
    int_of_float((p.y-.po.y)/.sz.y*.float_of_int(Graphics.size_y())))

(* The chaos game itself: iterate the IFS n times from an arbitrary
   starting point, handing every visited point to plot. *)
let iterate fs n plot =
  let rec urs pt = function
   | 0 -> ()
   | i -> let p' = (select_image pt (Random.float 1.0) fs.lt) in
           let _ = plot p'
            in urs p' (i-1)
  in urs {x= 1.0; y= 1.0} n

let draw fs n =
 if not !window_open then init ();
 let _ = Graphics.clear_graph () in
  iterate fs n (fun p ->
   let (xx,yy) = pixel_of_point fs.po fs.sz p in
    Graphics.plot xx yy)

(* Off-screen rendering: the same chaos game accumulated into a
   width*height array of per-pixel hit counts (row 0 at the top). *)
let render ?(width=400) ?(height=640) fs n =
    let hits = Array.make (width*height) 0 in
    iterate fs n (fun p ->
     let xx = int_of_float((p.x-.fs.po.x)/.fs.sz.x*.float_of_int width)
     and yy = int_of_float((p.y-.fs.po.y)/.fs.sz.y*.float_of_int height) in
      if xx >= 0 && xx < width && yy >= 0 && yy < height then
       let k = (height-1-yy)*width+xx in
        hits.(k) <- hits.(k) + 1);
    hits

(* A minimal PNG writer, so images can be produced without a display and
   without any dependency beyond the standard library. The pixel data is
   wrapped in stored (uncompressed) deflate blocks, which the PNG format
   accepts. Checksums are computed in plain ints, masked to 32 bits. *)

let crc_table = Array.init 256 (fun n ->
    let c = ref n in
    for _ = 0 to 7 do
     c := (if !c land 1 = 1 then 0xEDB88320 lxor (!c lsr 1) else !c lsr 1)
    done; !c)

let crc32 s =
    let c = ref 0xFFFFFFFF in
    String.iter (fun ch ->
     c := crc_table.((!c lxor Char.code ch) land 0xFF) lxor (!c lsr 8)) s;
    !c lxor 0xFFFFFFFF

let adler32 s =
    let a = ref 1 and b = ref 0 in
    String.iter (fun ch ->
     a := (!a + Char.code ch) mod 65521;
     b := (!b + !a) mod 65521) s;
    (!b lsl 16) lor !a

let add_be32 buf v =
    for k = 3 downto 0 do
     Buffer.add_char buf (Char.chr ((v lsr (8*k)) land 0xFF))
    done

let add_chunk buf tag data =
    add_be32 buf (String.length data);
    Buffer.add_string buf tag;
    Buffer.add_string buf data;
    add_be32 buf (crc32 (tag ^ data))

(* Write raw scanline data (each row prefixed with its filter byte) as an
   8-bit PNG of the given color type (0 = grayscale, 2 = RGB). *)
let output_png file width height color_type raw =
    (* zlib stream: header, stored deflate blocks of at most 64KB, adler32 *)
    let idat = Buffer.create (String.length raw + 64) in
    Buffer.add_string idat "\x78\x01";
    let len = String.length raw in
    let pos = ref 0 in
    while !pos < len do
     let blk = min 65535 (len - !pos) in
     Buffer.add_char idat (if !pos + blk = len then '\001' else '\000');
     Buffer.add_char idat (Char.chr (blk land 0xFF));
     Buffer.add_char idat (Char.chr (blk lsr 8));
     Buffer.add_char idat (Char.chr ((lnot blk) land 0xFF));
     Buffer.add_char idat (Char.chr (((lnot blk) lsr 8) land 0xFF));
     Buffer.add_substring idat raw !pos blk;
     pos := !pos + blk
    done;
    add_be32 idat (adler32 raw);
    let ihdr = Buffer.create 13 in
    add_be32 ihdr width;
    add_be32 ihdr height;
    Buffer.add_char ihdr '\x08'; (* 8 bits per sample *)
    Buffer.add_char ihdr (Char.chr color_type);
    Buffer.add_string ihdr "\x00\x00\x00";
    let png = Buffer.create (Buffer.length idat + 64) in
    Buffer.add_string png "\x89PNG\r\n\x1a\n";
    add_chunk png "IHDR" (Buffer.contents ihdr);
    add_chunk png "IDAT" (Buffer.contents idat);
    add_chunk png "IEND" "";
    let oc = open_out_bin file in
    Buffer.output_buffer oc png;
    close_out oc

(* Color ramp for density rendering, light to dark on the white
   background (from the YlGnBu sequential palette). *)
let density_ramp =
    [| (199,233,180); (127,205,187); (65,182,196); (29,145,192);
       (34,94,168); (8,29,88) |]

let ramp_color t =
    let m = Array.length density_ramp - 1 in
    let s = t *. float_of_int m in
    let i = min (m-1) (int_of_float s) in
    let f = s -. float_of_int i in
    let mix a b = int_of_float (float_of_int a +. f *. float_of_int (b-a)) in
    let (r1,g1,b1) = density_ramp.(i) and (r2,g2,b2) = density_ramp.(i+1) in
    (mix r1 r2, mix g1 g2, mix b1 b2)

(* Render fs with n points and write it to file as a PNG. By default the
   image is black points on white, like a screenshot of the graphics
   window; with ~color:true each pixel is instead colored by how often
   the chaos game visited it, on a log scale from light (rarely) to dark
   (constantly) — revealing the density structure of the attractor. *)
let save_png ?(width=400) ?(height=640) ?(color=false) fs n file =
    let hits = render ~width ~height fs n in
    let maxhits = Array.fold_left max 1 hits in
    let logmax = log (1.0 +. float_of_int maxhits) in
    (* scanlines, each prefixed with the "no filter" byte *)
    let raw = Buffer.create ((width*3+1)*height) in
    for row = 0 to height-1 do
     Buffer.add_char raw '\000';
     for col = 0 to width-1 do
      let c = hits.(row*width+col) in
       if not color then
        Buffer.add_char raw (if c > 0 then '\000' else '\255')
       else if c = 0 then
        Buffer.add_string raw "\255\255\255"
       else
        let (r,g,b) = ramp_color (log (1.0 +. float_of_int c) /. logmax) in
         Buffer.add_char raw (Char.chr r);
         Buffer.add_char raw (Char.chr g);
         Buffer.add_char raw (Char.chr b)
     done
    done;
    output_png file width height (if color then 2 else 0)
     (Buffer.contents raw)

let barnsley =
{ po = {x= -2.25 ; y= -0.50};
sz = {x= 5.00 ; y= 11.00};
lt = [{pb= 0.84; kf= [| 0.85; 0.04; 0.00; -0.04; 0.85; 1.60|]};
{pb= 0.91; kf= [|-0.15; 0.28; 0.00; 0.26; 0.24; 0.44|]};
{pb= 0.98; kf= [| 0.20;-0.26; 0.00; 0.23; 0.22; 1.60|]};
{pb= 1.00; kf= [| 0.00; 0.00; 0.00; 0.00; 0.16; 0.00|]}]}

let sierpinski =
{ po = {x= -5.0 ; y= -8.0};
sz = {x= 5.0 ; y= 3.0};
lt = [{pb= 0.333; kf= [|0.5; 0.0; 0.0; 0.5; 0.0; 0.0|]};
{pb= 0.666; kf= [|0.5; 0.0; 0.0; 0.5; 1.0; 0.0|]};
{pb= 1.00; kf= [|0.5; 0.0; 0.0; 0.5; 0.5; 0.8660254|]}]}

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

let koch =
{ po = {x= -2.25 ; y= -4.0};
sz = {x= 11.00 ; y= 8.00};
lt = [{pb= 0.25; kf= [|0.333; 0.0; 0.0; 0.333; 0.0; 0.0|]};
{pb= 0.50; kf= [|0.167; -0.287; 0.287; 0.167; 0.333; 0.0|]};
{pb= 0.75; kf= [|0.167; 0.287; -0.287; 0.167; 0.5; 0.287|]};
{pb= 1.0; kf= [|0.333; 0.0; 0.0; 0.333; 0.667; 0.0|]}]}

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
