(* Iterated function systems: the chaos game, and everything that draws
   its attractors — on screen, into a PNG file, or read from a Fractint
   file. The fractals themselves live in fractals.ml, whose types and
   values are re-exported here so that Ifs_fractals remains the single
   entry point of the library.

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

exception Ifs_error of string

let ifs_error fmt = Printf.ksprintf (fun s -> raise (Ifs_error s)) fmt

(* The same two operations in space. *)
let image3 k p =
    { x3= k.(0)*.p.x3+.k.(1)*.p.y3+.k.(2)*.p.z3+.k.(9);
    y3= k.(3)*.p.x3+.k.(4)*.p.y3+.k.(5)*.p.z3+.k.(10);
    z3= k.(6)*.p.x3+.k.(7)*.p.y3+.k.(8)*.p.z3+.k.(11)}

let rec select_image3 p rd = function
    | t::_ when rd<=t.pb3 -> image3 t.kf3 p
    | _::lt -> select_image3 p rd lt
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

(* The chaos game in space. Its attractor cannot be drawn directly — the
   maps mix all three coordinates, so dropping z from them would describe
   a different system altogether. The game is played in space and only the
   points it visits are flattened, by project below. *)
let iterate3 fs n plot =
  let rec urs pt = function
   | 0 -> ()
   | i -> let p' = (select_image3 pt (Random.float 1.0) fs.lt3) in
           let _ = plot p'
            in urs p' (i-1)
  in urs {x3= 1.0; y3= 1.0; z3= 1.0} n

(* Orthographic projection: turn the attractor by yaw around the vertical
   axis, tip it by pitch, and drop the depth. Both angles are in radians;
   at zero, x and y are kept as they are and z is what disappears. *)
let project ?(yaw=0.0) ?(pitch=0.0) p =
    let cy = cos yaw and sy = sin yaw
    and cp = cos pitch and sp = sin pitch in
    let x = cy*.p.x3 -. sy*.p.z3 in
    let depth = sy*.p.x3 +. cy*.p.z3 in
    {x = x; y = cp*.p.y3 -. sp*.depth}

(* A source of plane points: something that plays the chaos game n times
   and hands every point to a callback. Both kinds of system give one, so
   everything downstream — framing, plotting, rendering — is shared. *)
let source fs = iterate fs

let source3 ?yaw ?pitch fs n plot =
    iterate3 fs n (fun p -> plot (project ?yaw ?pitch p))

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
let wait_then_close () =
    (try ignore (Graphics.read_key ())
     with Graphics.Graphic_failure _ -> ());
    if window_open () then Graphics.close_graph ()

let show fs n = draw fs n; wait_then_close ()

(* Off-screen rendering: the points of a source accumulated into a
   width*height array of per-pixel hit counts (row 0 at the top). *)
let accumulate ?(width=400) ?(height=640) po sz src n =
    let hits = Array.make (width*height) 0 in
    src n (fun p ->
     let xx = int_of_float((p.x-.po.x)/.sz.x*.float_of_int width)
     and yy = int_of_float((p.y-.po.y)/.sz.y*.float_of_int height) in
      if xx >= 0 && xx < width && yy >= 0 && yy < height then
       let k = (height-1-yy)*width+xx in
        hits.(k) <- hits.(k) + 1);
    hits

let render ?width ?height fs n =
    accumulate ?width ?height fs.po fs.sz (source fs) n

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
let encode ?(color=false) width height hits =
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
    Buffer.contents raw

let save_png ?(width=400) ?(height=640) ?(color=false) fs n file =
    output_png file width height (if color then 2 else 0)
     (encode ~color width height (render ~width ~height fs n))

(* Neither a Fractint file nor a solid system says which part of the plane
   to show, so run the chaos game once to find where the attractor lands
   and frame it. The first points are dropped: they are the transient
   before the orbit settles onto the attractor. aspect is the width/height
   ratio of the target image, matched so the picture is not distorted. *)
let viewport ?(samples=20_000) ?(margin=0.04) ?(aspect=400.0/.640.0) src =
    let minx = ref infinity and maxx = ref neg_infinity
    and miny = ref infinity and maxy = ref neg_infinity and seen = ref 0 in
    src samples (fun p ->
     incr seen;
     if !seen > 100 then begin
      if p.x < !minx then minx := p.x;
      if p.x > !maxx then maxx := p.x;
      if p.y < !miny then miny := p.y;
      if p.y > !maxy then maxy := p.y
     end);
    if not (Float.is_finite !minx && Float.is_finite !maxx
            && Float.is_finite !miny && Float.is_finite !maxy) then
     ifs_error
      "the transforms do not settle on an attractor: the points escape to \
       infinity";
    let span a b = let d = b -. a in
     (if d > 0.0 then d else 1.0) *. (1.0 +. 2.0 *. margin) in
    let w = span !minx !maxx and h = span !miny !maxy in
    let (w, h) = if w /. h > aspect then (w, w /. aspect) else (h *. aspect, h) in
    let cx = (!minx +. !maxx) /. 2.0 and cy = (!miny +. !maxy) /. 2.0 in
    ({x = cx -. w /. 2.0; y = cy -. h /. 2.0}, {x = w; y = h})

let fit ?samples ?margin ?aspect fs =
    let (po, sz) = viewport ?samples ?margin ?aspect (source fs) in
    {fs with po = po; sz = sz}

(* The viewport of a solid system depends on where it is looked at from,
   so it is derived per view rather than stored. *)
let fit3 ?samples ?margin ?aspect ?yaw ?pitch fs =
    viewport ?samples ?margin ?aspect (source3 ?yaw ?pitch fs)

(* Drawing and rendering either kind of system. A flat one goes through
   the plain path; a solid one is framed for the requested view first. *)
let draw_system ?yaw ?pitch sys n =
    match sys with
    | Flat fs -> draw fs n
    | Solid fs ->
       if not (window_open ()) then init ();
       let aspect = float_of_int (Graphics.size_x ())
                    /. float_of_int (Graphics.size_y ()) in
       let (po, sz) = fit3 ~aspect ?yaw ?pitch fs in
       let _ = Graphics.clear_graph () in
        source3 ?yaw ?pitch fs n (fun p ->
         let (xx,yy) = pixel_of_point po sz p in
          Graphics.plot xx yy)

let show_system ?yaw ?pitch sys n =
    draw_system ?yaw ?pitch sys n; wait_then_close ()

let save_png_system ?(width=400) ?(height=640) ?(color=false) ?yaw ?pitch
                    sys n file =
    match sys with
    | Flat fs -> save_png ~width ~height ~color fs n file
    | Solid fs ->
       let aspect = float_of_int width /. float_of_int height in
       let (po, sz) = fit3 ~aspect ?yaw ?pitch fs in
       let hits =
        accumulate ~width ~height po sz (source3 ?yaw ?pitch fs) n in
        output_png file width height (if color then 2 else 0)
         (encode ~color width height hits)

(* Fractint .ifs files: one or more named systems, one transform per line
   between braces, as six or seven numbers separated by spaces, tabs or
   commas, and ';' starting a comment.

       fern {                          ; Barnsley's Black Spleenwort
         0    0    0    .16 0 0    .01
         .85  .04 -.04  .85 0 1.6  .85
       }

   A line reads a b c d e f, meaning x' = a*x + b*y + e and
   y' = c*x + d*y + f — a different order than our kf — plus an optional
   probability. The probabilities are plain weights rather than our
   cumulative thresholds, and the format has no viewport at all, so both
   are derived below. *)

(* The words of one line, comment dropped and braces isolated. *)
let words line =
    let line =
     match String.index_opt line ';' with
     | Some i -> String.sub line 0 i
     | None -> line in
    let b = Buffer.create (String.length line) in
    String.iter (function
     | '{' | '}' as c -> Buffer.add_char b ' '; Buffer.add_char b c;
                         Buffer.add_char b ' '
     | ',' | '\t' | '\r' -> Buffer.add_char b ' '
     | c -> Buffer.add_char b c) line;
    List.filter (fun w -> w <> "") (String.split_on_char ' ' (Buffer.contents b))

(* Split the text into entries: a name and the rows of numbers between its
   braces, one transform per line, each row tagged with its line. *)
let group_entries text =
    let entries = ref [] and name = ref [] and rows = ref [] in
    let inside = ref false in
    List.iteri (fun i line ->
     let l = i + 1 in
     let row = ref [] in
     let end_row () =
      if !row <> [] then rows := (l, List.rev !row) :: !rows;
      row := [] in
     List.iter (fun w ->
      match w with
      | "{" when !inside -> ifs_error "line %d: unexpected '{'" l
      | "{" -> inside := true
      | "}" when not !inside ->
         ifs_error "line %d: '}' without a matching '{'" l
      | "}" ->
         end_row ();
         entries :=
          (String.concat " " (List.rev !name), List.rev !rows) :: !entries;
         name := []; rows := []; inside := false
      | w when not !inside -> name := w :: !name
      | w ->
         (match float_of_string_opt w with
          | Some v -> row := v :: !row
          | None -> ifs_error "line %d: %S is not a number" l w))
      (words line);
     end_row ())
     (String.split_on_char '\n' text);
    if !inside then ifs_error "unexpected end of file: '}' expected";
    if !name <> [] then ifs_error "unexpected end of file: '{' expected";
    List.rev !entries

(* One row of numbers: the coefficients, and the probability the file gave
   if any. A flat transform is six numbers, which our kf reorders; a solid
   one is twelve, which kf3 keeps as they come. Either may carry a
   probability as one extra number. *)
let transfo_of_row (l, vs) =
    match vs with
    | [a; b; c; d; e; f] -> ([|a; b; e; c; d; f|], None)
    | [a; b; c; d; e; f; p] -> ([|a; b; e; c; d; f|], Some p)
    | _ -> ifs_error "line %d: expected 6 or 7 numbers per transform, got %d"
            l (List.length vs)

let transfo3_of_row (l, vs) =
    match vs with
    | [_;_;_;_;_;_;_;_;_;_;_;_] -> (Array.of_list vs, None)
    | [a;b;c;d;e;f;g;h;i;j;k;m;p] ->
       ([|a;b;c;d;e;f;g;h;i;j;k;m|], Some p)
    | _ -> ifs_error
            "line %d: expected 12 or 13 numbers per 3D transform, got %d"
            l (List.length vs)

(* Turn the file's weights into our cumulative thresholds. A file may give
   no probabilities at all; each transform is then weighted by the area —
   the volume, in space — that it covers, the absolute value of its
   determinant, which is what makes the chaos game fill the attractor
   evenly. *)
let thresholds rows extent =
    let sum = List.fold_left (+.) 0.0 in
    let stated = List.map (function (_, Some p) -> p | (_, None) -> 0.0) rows
    and extents = List.map (fun (kf, _) -> extent kf) rows in
    let ws =
     if List.for_all (fun (_, p) -> p <> None) rows && sum stated > 0.0
      then stated
     else if sum extents > 0.0 then extents
     else List.map (fun _ -> 1.0) rows in
    let total = sum ws and acc = ref 0.0 and last = List.length rows - 1 in
    List.mapi (fun i w ->
     acc := !acc +. w;
     if i = last then 1.0 else !acc /. total) ws

(* kf holds the plane matrix at 0,1 and 3,4; kf3 holds the space one in
   its first nine slots. *)
let area kf = abs_float (kf.(0)*.kf.(4) -. kf.(1)*.kf.(3))

let volume k =
    abs_float (k.(0)*.(k.(4)*.k.(8) -. k.(5)*.k.(7))
            -. k.(1)*.(k.(3)*.k.(8) -. k.(5)*.k.(6))
            +. k.(2)*.(k.(3)*.k.(7) -. k.(4)*.k.(6)))

let cumulate rows =
    List.map2 (fun (kf, _) pb -> {pb; kf}) rows (thresholds rows area)

let cumulate3 rows =
    List.map2 (fun (kf3, _) pb3 -> {pb3; kf3}) rows (thresholds rows volume)

(* Fractint marks a solid system by writing (3D) after its name; the rows
   give it away too, being twice as long. The marker is dropped from the
   name, which is what one has to type to draw it. *)
let clean_name name =
    let kept =
     List.filter (fun w -> String.lowercase_ascii w <> "(3d)")
      (String.split_on_char ' ' name) in
    match String.concat " " kept with "" -> "unnamed" | n -> n

(* Parse the contents of a Fractint .ifs file: every named system it
   holds. A flat one is framed here, since its viewport never changes; a
   solid one is framed when drawn, once the view is known. *)
let parse_fractint ?samples ?margin ?aspect text =
    let entry (name, rows) =
     if rows = [] then ifs_error "%S: no transform" name;
     let solid (_, vs) = List.length vs >= 12 in
     let name = clean_name name in
      if List.for_all solid rows then
       (name, Solid {lt3 = cumulate3 (List.map transfo3_of_row rows)})
      else if List.exists solid rows then
       ifs_error "%S: mixes flat and 3D transforms" name
      else
       let fs = {po = {x= 0.0; y= 0.0}; sz = {x= 1.0; y= 1.0};
                 lt = cumulate (List.map transfo_of_row rows)} in
        (name, Flat (fit ?samples ?margin ?aspect fs))
    in List.map entry (group_entries text)

let load_fractint ?samples ?margin ?aspect file =
    let ic = open_in_bin file in
    let text =
     Fun.protect ~finally:(fun () -> close_in_noerr ic)
      (fun () -> really_input_string ic (in_channel_length ic)) in
    parse_fractint ?samples ?margin ?aspect text
