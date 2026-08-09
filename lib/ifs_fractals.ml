(* Iterated function systems: the chaos game, and everything that draws
   its attractors — on screen or into a PNG file. The fractals themselves
   live in fractals.ml, whose types and values are re-exported here so
   that Ifs_fractals remains the single entry point of the library.

   This file is both the library module Ifs_fractals and the file loaded
   by the toplevel script at the repository root, so it must stay
   directive-free plain OCaml. *)

include Fractals

let image kf p =
    { x= kf.(0)*.p.x+.kf.(1)*.p.y+.kf.(2);
    y= kf.(3)*.p.x+.kf.(4)*.p.y+.kf.(5)}

let rec select_image p rd = function
    | t::_ when rd<=t.pb -> image t.kf p
    | _::lt -> select_image p rd lt
    | [] -> raise Not_found

(* Ask the graphics library rather than remember: the window may have been
   closed behind our back, by close_graph or by the window manager. *)
let window_open () =
    try ignore (Graphics.size_x ()); true
    with Graphics.Graphic_failure _ -> false

let init ?(geometry=" 400x640") () =
    Graphics.open_graph geometry

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
 if not (window_open ()) then init ();
 let _ = Graphics.clear_graph () in
  iterate fs n (fun p ->
   let (xx,yy) = pixel_of_point fs.po fs.sz p in
    Graphics.plot xx yy)

(* Draw, then wait for a keypress before closing the window. The graphics
   library only handles events while the program is inside an event call,
   so this is also what makes the window manager's close button work: at
   the toplevel prompt nothing reads events and the window ignores it. *)
let show fs n =
    draw fs n;
    (try ignore (Graphics.read_key ())
     with Graphics.Graphic_failure _ -> ());
    if window_open () then Graphics.close_graph ()

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
