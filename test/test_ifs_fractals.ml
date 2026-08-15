(* Tests for the library: run them with `dune test`.

   Nothing here opens a graphics window — the drawing functions are the
   one part that needs a display, and they are thin wrappers over the
   pieces tested below. Everything else is checked: the affine maps and
   the projection, the chaos game, the framing of an attractor, the
   Fractint parser, and the hand-written PNG writer, whose output is read
   back and decoded rather than merely counted in bytes.

   The chaos game is random, so the seed is fixed: a failure here is
   meant to be reproducible. Where a property is statistical (how many
   pixels a fractal lights up) the bound is deliberately loose, so that
   only a real breakage trips it. *)

open Ifs_fractals

let () = Random.init 20260815

(* A tiny harness: no test framework, no new dependency. *)

let checks = ref 0
let failures = ref 0

let check name ok =
    incr checks;
    if not ok then begin
     incr failures;
     print_endline ("FAIL  " ^ name)
    end

(* Run a group of checks, reporting an unexpected exception as a failure
   rather than letting it abort the rest of the suite. *)
let case name f =
    try f () with e ->
     incr checks; incr failures;
     Printf.printf "FAIL  %s: raised %s\n" name (Printexc.to_string e)

let check_error name f =
    incr checks;
    match f () with
    | _ ->
       incr failures;
       Printf.printf "FAIL  %s: expected Ifs_error, nothing raised\n" name
    | exception Ifs_error _ -> ()
    | exception e ->
       incr failures;
       Printf.printf "FAIL  %s: expected Ifs_error, got %s\n" name
        (Printexc.to_string e)

let near ?(eps=1e-9) a b = abs_float (a -. b) <= eps

let same_floats a b =
    Array.length a = Array.length b
    && (let ok = ref true in
        Array.iteri (fun i v -> if not (near v b.(i)) then ok := false) a;
        !ok)

(* The affine maps *)

let () = case "image" (fun () ->
    (* kf = [|a; b; c; d; e; f|] is x' = a*x + b*y + c, y' = d*x + e*y + f *)
    let p = image [|1.0; 2.0; 3.0; 4.0; 5.0; 6.0|] {x = 1.0; y = 1.0} in
    check "image x" (near p.x 6.0);
    check "image y" (near p.y 15.0);
    let q = image [|0.0; 0.0; 7.0; 0.0; 0.0; 8.0|] {x = 5.0; y = -3.0} in
    check "image constant map" (near q.x 7.0 && near q.y 8.0))

let () = case "image3" (fun () ->
    (* kf3 keeps the file's order: the 3x3 matrix, then the translation *)
    let k = [|1.0; 2.0; 3.0; 4.0; 5.0; 6.0; 7.0; 8.0; 9.0;
              10.0; 11.0; 12.0|] in
    let p = image3 k {x3 = 1.0; y3 = 1.0; z3 = 1.0} in
    check "image3 x" (near p.x3 16.0);
    check "image3 y" (near p.y3 26.0);
    check "image3 z" (near p.z3 36.0))

let () = case "project" (fun () ->
    let p = {x3 = 1.0; y3 = 2.0; z3 = 3.0} in
    let flat = project p in
    check "project keeps x and y, drops z"
     (near flat.x 1.0 && near flat.y 2.0);
    (* a quarter turn around the vertical axis brings z into view *)
    let turned = project ~yaw:(Float.pi /. 2.0) p in
    check "project yaw" (near turned.x (-3.0) && near turned.y 2.0);
    (* tipping forward by a quarter turn looks down on the system *)
    let tipped = project ~pitch:(Float.pi /. 2.0) p in
    check "project pitch" (near tipped.x 1.0 && near tipped.y (-3.0)))

let () = case "determinants" (fun () ->
    check "area" (near (area [|2.0; 1.0; 0.0; 1.0; 3.0; 0.0|]) 5.0);
    check "area of a degenerate map"
     (near (area [|1.0; 2.0; 0.0; 2.0; 4.0; 0.0|]) 0.0);
    (* twice the identity in space scales volumes eightfold *)
    check "volume"
     (near (volume [|2.0; 0.0; 0.0; 0.0; 2.0; 0.0; 0.0; 0.0; 2.0;
                     9.0; 9.0; 9.0|]) 8.0);
    check "volume of a flattening map"
     (near (volume [|1.0; 0.0; 0.0; 0.0; 1.0; 0.0; 0.0; 0.0; 0.0;
                     0.0; 0.0; 0.0|]) 0.0))

(* The chaos game *)

let () = case "iterate plots every point" (fun () ->
    let n = ref 0 in
    iterate sierpinski 1000 (fun _ -> incr n);
    check "iterate count" (!n = 1000);
    let n3 = ref 0 in
    let shrink = {lt3 = [{pb3 = 1.0;
                        kf3 = [|0.5; 0.0; 0.0; 0.0; 0.5; 0.0; 0.0; 0.0; 0.5;
                                0.0; 0.0; 0.0|]}]} in
    iterate3 shrink 1000 (fun _ -> incr n3);
    check "iterate3 count" (!n3 = 1000))

let () = case "the chaos game is reproducible" (fun () ->
    let run () =
     let acc = ref [] in
     Random.init 1234;
     iterate barnsley 500 (fun p -> acc := (p.x, p.y) :: !acc);
     !acc in
    check "same seed, same points" (run () = run ()))

(* The Sierpinski triangle is the sharpest shape to test: its attractor
   is exactly the triangle spanned by the three fixed points, minus the
   middle one, so points must land inside the first and never in the
   second. The predefined system has vertices (0,0), (2,0) and
   (1, sqrt 3). *)
let () = case "the Sierpinski attractor is where it should be" (fun () ->
    let root3 = sqrt 3.0 in
    let inside x y =
     y >= -1e-9 && y <= root3 *. x +. 1e-9
     && y <= root3 *. (2.0 -. x) +. 1e-9 in
    let outside = ref 0 and in_hole = ref 0 in
    (* the centre of the central hole, and a radius well inside it *)
    let hx = 1.0 and hy = root3 /. 3.0 in
    iterate sierpinski 100_000 (fun p ->
     if not (inside p.x p.y) then incr outside;
     let dx = p.x -. hx and dy = p.y -. hy in
     if sqrt (dx *. dx +. dy *. dy) < 0.15 then incr in_hole);
    check "no point outside the triangle" (!outside = 0);
    check "no point in the central hole" (!in_hole = 0))

(* The Koch curve is as recognisable, and as easy to state: it joins (0,0)
   to (1,0) without ever leaving the equilateral triangle they span. *)
let () = case "the Koch curve joins its endpoints" (fun () ->
    let outside = ref 0 and seen = ref 0 in
    iterate koch 50_000 (fun p ->
     incr seen;
     (* the starting point is not on the curve; give the orbit time to
        settle onto it *)
     if !seen > 100
        && (p.x < -1e-6 || p.x > 1.000001
            || p.y < -1e-6 || p.y > sqrt 3.0 /. 6.0 +. 1e-3) then
      incr outside);
    check "the curve stays in its triangle" (!outside = 0))

(* The predefined fractals *)

let () = case "the predefined fractals are well formed" (fun () ->
    check "sixteen of them" (List.length all = 16);
    let names = List.map (fun (n, _, _) -> n) all in
    check "names are unique"
     (List.length (List.sort_uniq compare names) = List.length names);
    List.iter (fun (name, fs, n) ->
     check (name ^ ": has transforms") (fs.lt <> []);
     check (name ^ ": a positive iteration count") (n > 0);
     check (name ^ ": a non-empty viewport") (fs.sz.x > 0.0 && fs.sz.y > 0.0);
     List.iter (fun t ->
      check (name ^ ": six coefficients") (Array.length t.kf = 6)) fs.lt;
     (* cumulative thresholds: increasing, the last one exactly 1.0 *)
     let ok = ref true and prev = ref 0.0 in
     List.iter (fun t ->
      if t.pb <= !prev || t.pb > 1.0 then ok := false;
      prev := t.pb) fs.lt;
     check (name ^ ": increasing probabilities") !ok;
     check (name ^ ": last probability is 1.0")
      (near (List.nth fs.lt (List.length fs.lt - 1)).pb 1.0)) all)

(* A viewport that does not frame its fractal is invisible in the code and
   plain on screen: the window stays empty, or nearly so. That is how
   sierpinski and koch were drawn for years, their coefficients written in
   Fractint's order instead of kf's, so both are checked here — the points
   must land in the region the record says to display, and light up enough
   of it to be a picture. *)
let () = case "every predefined fractal lands in its viewport" (fun () ->
    List.iter (fun (name, fs, _) ->
     let n = ref 0 and inside = ref 0 in
     iterate fs 20_000 (fun p ->
      incr n;
      if p.x >= fs.po.x && p.x <= fs.po.x +. fs.sz.x
         && p.y >= fs.po.y && p.y <= fs.po.y +. fs.sz.y then incr inside);
     check (name ^ ": inside its viewport") (!inside * 100 >= !n * 99);
     let width = 100 and height = 160 in
     let hits = render ~width ~height fs 50_000 in
     let lit = Array.fold_left (fun n c -> if c > 0 then n + 1 else n) 0 hits in
     check (name ^ ": draws something") (lit > 200);
     check (name ^ ": does not fill the frame")
      (lit < width * height * 90 / 100)) all)

(* Reading Fractint files *)

let flat_of name text =
    match List.assoc name (parse_fractint text) with
    | Flat fs -> fs
    | Solid _ -> failwith (name ^ " should be flat")

let solid_of name text =
    match List.assoc name (parse_fractint text) with
    | Solid fs -> fs
    | Flat _ -> failwith (name ^ " should be solid")

let () = case "a file's coefficients are reordered" (fun () ->
    (* the file reads a b c d e f, meaning x' = a*x + b*y + e and
       y' = c*x + d*y + f, which our kf stores as a b e c d f *)
    let fs = flat_of "t" "t { .1 .2 .3 .4 .5 .6 1 }" in
    check "one transform" (List.length fs.lt = 1);
    check "coefficients"
     (same_floats (List.hd fs.lt).kf [|0.1; 0.2; 0.5; 0.3; 0.4; 0.6|]);
    (* the same row without the probability takes another path *)
    let fs = flat_of "t" "t { .1 .2 .3 .4 .5 .6 }" in
    check "coefficients, no probability given"
     (same_floats (List.hd fs.lt).kf [|0.1; 0.2; 0.5; 0.3; 0.4; 0.6|]);
    check "a single transform is certain" (near (List.hd fs.lt).pb 1.0))

let () = case "weights become cumulative thresholds" (fun () ->
    let fs = flat_of "t"
     "t {\n\
      \  .5 0 0 .5 0 0 .1\n\
      \  .5 0 0 .5 1 0 .3\n\
      \  .5 0 0 .5 0 1 .6\n\
      }" in
    let pbs = List.map (fun t -> t.pb) fs.lt in
    check "thresholds"
     (match pbs with
      | [a; b; c] -> near a 0.1 && near b 0.4 && near c 1.0
      | _ -> false))

let () = case "missing weights come from the determinants" (fun () ->
    (* areas .25 and .0625: the first map is weighted .25/.3125 = .8 *)
    let fs = flat_of "t" "t {\n  .5 0 0 .5 0 0\n  .25 0 0 .25 .5 0\n}" in
    check "weighted by area"
     (match List.map (fun t -> t.pb) fs.lt with
      | [a; b] -> near a 0.8 && near b 1.0
      | _ -> false);
    (* with no area to go by either, the maps are equally likely *)
    let fs = flat_of "t" "t {\n  0 0 0 0 0 0\n  0 0 0 0 1 0\n}" in
    check "equal weights as a last resort"
     (match List.map (fun t -> t.pb) fs.lt with
      | [a; b] -> near a 0.5 && near b 1.0
      | _ -> false))

let () = case "the file's syntax" (fun () ->
    let text =
     "; a comment line\n\
      first {                 ; a name, then its maps\n\
      \  .5,0,0,.5,0,0\t; commas and tabs separate too\n\
      \  .5 0 0 .5 1 0\n\
      }\n\
      \n\
      second { .5 0 0 .5 0 0\n\
      \  .5 0 0 .5 0 1 }\n" in
    let entries = parse_fractint text in
    check "two entries" (List.length entries = 2);
    check "in the file's order"
     (List.map fst entries = ["first"; "second"]);
    check "two transforms each"
     (List.for_all (fun (_, sys) ->
       match sys with Flat fs -> List.length fs.lt = 2 | Solid _ -> false)
      entries))

let () = case "3D entries" (fun () ->
    let text =
     "spike (3D) {\n\
      \  .5 0 0 0 .5 0 0 0 .5 0 0 0 .4\n\
      \  .5 0 0 0 .5 0 0 0 .5 1 2 3 .6\n\
      }" in
    let fs = solid_of "spike" text in
    check "the (3D) marker is dropped from the name"
     (List.map fst (parse_fractint text) = ["spike"]);
    check "two transforms" (List.length fs.lt3 = 2);
    check "twelve coefficients, in the file's order"
     (same_floats (List.nth fs.lt3 1).kf3
      [|0.5; 0.0; 0.0; 0.0; 0.5; 0.0; 0.0; 0.0; 0.5; 1.0; 2.0; 3.0|]);
    check "thresholds"
     (match List.map (fun t -> t.pb3) fs.lt3 with
      | [a; b] -> near a 0.4 && near b 1.0
      | _ -> false);
    (* twelve numbers and no probability: weighted by volume, here equal *)
    let fs = solid_of "s"
     "s (3d) {\n\
      \  .5 0 0 0 .5 0 0 0 .5 0 0 0\n\
      \  .5 0 0 0 .5 0 0 0 .5 1 0 0\n\
      }" in
    check "volume weights"
     (match List.map (fun t -> t.pb3) fs.lt3 with
      | [a; b] -> near a 0.5 && near b 1.0
      | _ -> false))

let () =
    let bad name text = check_error name (fun () -> parse_fractint text) in
    bad "a second '{'" "t { { .5 0 0 .5 0 0 }";
    bad "a '}' on its own" "}";
    bad "a name with no braces" "t";
    bad "an unclosed brace" "t {\n  .5 0 0 .5 0 0\n";
    bad "something that is not a number" "t { .5 0 zero .5 0 0 }";
    bad "too few numbers" "t {\n  1 2 3\n}";
    bad "too many numbers" "t {\n  1 2 3 4 5 6 7 8\n}";
    bad "an empty entry" "t { }";
    bad "flat and solid transforms mixed"
     "t {\n  .5 0 0 .5 0 0\n  .5 0 0 0 .5 0 0 0 .5 0 0 0\n}";
    (* the format cannot say which part of the plane to look at, so a
       system whose maps do not contract has nothing to frame *)
    bad "maps that escape to infinity" "t {\n  2 0 0 2 1 1\n}"

let () = case "the example file" (fun () ->
    let path =
     List.find Sys.file_exists
      ["../example/classics.ifs"; "example/classics.ifs"] in
    let entries = load_fractint path in
    check "a dozen systems" (List.length entries = 12);
    check "fern comes first" (fst (List.hd entries) = "fern");
    check "the 3D ones are solid"
     (List.for_all (fun (name, sys) ->
       let solid = match sys with Solid _ -> true | Flat _ -> false in
       solid = (String.length name > 2
                && String.lowercase_ascii (String.sub name 0 2) = "3d"))
      entries);
    check "the fern has four maps"
     (match List.assoc "fern" entries with
      | Flat fs -> List.length fs.lt = 4
      | Solid _ -> false);
    check "the solid fern has four maps"
     (match List.assoc "3dfern" entries with
      | Solid fs -> List.length fs.lt3 = 4
      | Flat _ -> false))

(* Framing *)

let () = case "fit frames the attractor undistorted" (fun () ->
    let fs = fit ~aspect:1.5 {barnsley with po = {x = 0.0; y = 0.0};
                              sz = {x = 1.0; y = 1.0}} in
    check "the viewport has the requested aspect ratio"
     (near ~eps:1e-6 (fs.sz.x /. fs.sz.y) 1.5);
    let n = ref 0 and inside = ref 0 in
    iterate fs 20_000 (fun p ->
     incr n;
     if p.x >= fs.po.x && p.x <= fs.po.x +. fs.sz.x
        && p.y >= fs.po.y && p.y <= fs.po.y +. fs.sz.y then incr inside);
    check "it holds the fern" (!inside * 100 >= !n * 99))

(* A solid system is framed per view, which is the whole point of not
   storing its viewport: a shape ten units long in z is thin seen from
   the front and wide seen from the side. *)
let () = case "fit3 follows the view" (fun () ->
    let arm z = {pb3 = 0.0;
                 kf3 = [|0.01; 0.0; 0.0; 0.0; 0.01; 0.0; 0.0; 0.0; 0.5;
                         0.0; 0.0; z|]} in
    let rod = {lt3 = [{(arm 0.0) with pb3 = 0.5}; {(arm 5.0) with pb3 = 1.0}]} in
    let (_, front) = fit3 ~aspect:1.0 rod in
    let (_, side) = fit3 ~aspect:1.0 ~yaw:(Float.pi /. 2.0) rod in
    check "seen end on, the rod is small" (front.x < 2.0);
    check "seen from the side, it is ten units long" (side.x > 10.0))

(* The PNG writer *)

let be32 s i =
    Char.code s.[i] lsl 24 lor (Char.code s.[i+1] lsl 16)
    lor (Char.code s.[i+2] lsl 8) lor Char.code s.[i+3]

(* Walk the chunks of a PNG file, checking the signature and every CRC.
   Returns the chunks in order, as (tag, data) pairs. *)
let png_chunks data =
    if String.length data < 8 || String.sub data 0 8 <> "\137PNG\r\n\026\n"
     then failwith "not a PNG signature";
    let chunks = ref [] and pos = ref 8 in
    while !pos < String.length data do
     let len = be32 data !pos in
     let tag = String.sub data (!pos + 4) 4 in
     let payload = String.sub data (!pos + 8) len in
     if be32 data (!pos + 8 + len) <> crc32 (tag ^ payload) then
      failwith ("bad CRC in chunk " ^ tag);
     chunks := (tag, payload) :: !chunks;
     pos := !pos + 12 + len
    done;
    List.rev !chunks

(* Undo what output_png does to the pixels: a zlib stream of stored
   deflate blocks. Anything else means the writer changed and this
   decoder — not the PNG format — needs to follow. *)
let inflate_stored s =
    let cmf = Char.code s.[0] and flg = Char.code s.[1] in
    if cmf land 0x0f <> 8 then failwith "not a deflate stream";
    if (cmf * 256 + flg) mod 31 <> 0 then failwith "bad zlib header";
    let out = Buffer.create (String.length s) in
    let pos = ref 2 and last = ref false in
    while not !last do
     let header = Char.code s.[!pos] in
     if header land 0x06 <> 0 then failwith "not a stored block";
     last := header land 1 = 1;
     let len = Char.code s.[!pos+1] lor (Char.code s.[!pos+2] lsl 8) in
     let nlen = Char.code s.[!pos+3] lor (Char.code s.[!pos+4] lsl 8) in
     if len lxor 0xFFFF <> nlen then failwith "inconsistent block length";
     Buffer.add_substring out s (!pos + 5) len;
     pos := !pos + 5 + len
    done;
    let raw = Buffer.contents out in
    if be32 s !pos <> adler32 raw then failwith "bad adler32";
    raw

let read_file path =
    let ic = open_in_bin path in
    Fun.protect ~finally:(fun () -> close_in_noerr ic)
     (fun () -> really_input_string ic (in_channel_length ic))

(* Read a PNG back as (width, height, colour type, scanlines without
   their filter byte), checking everything the format constrains. *)
let decode_png path =
    let chunks = png_chunks (read_file path) in
    check "the file ends with IEND"
     (List.nth_opt (List.rev chunks) 0 = Some ("IEND", ""));
    let ihdr = List.assoc "IHDR" chunks in
    let width = be32 ihdr 0 and height = be32 ihdr 4 in
    check "eight bits per sample" (Char.code ihdr.[8] = 8);
    check "no interlacing, no exotic filter"
     (String.sub ihdr 10 3 = "\000\000\000");
    let color_type = Char.code ihdr.[9] in
    let bpp = if color_type = 2 then 3 else 1 in
    let raw = inflate_stored (List.assoc "IDAT" chunks) in
    check "the image has as many bytes as pixels"
     (String.length raw = height * (width * bpp + 1));
    let rows = ref [] in
    for row = height - 1 downto 0 do
     let start = row * (width * bpp + 1) in
     check "every scanline is unfiltered" (raw.[start] = '\000');
     rows := String.sub raw (start + 1) (width * bpp) :: !rows
    done;
    (width, height, color_type, String.concat "" !rows)

let with_temp_png f =
    let path = Filename.temp_file "ifs-test" ".png" in
    Fun.protect ~finally:(fun () -> try Sys.remove path with Sys_error _ -> ())
     (fun () -> f path)

let () = case "checksums" (fun () ->
    (* the CRC of an empty IEND chunk is the same in every PNG ever made *)
    check "crc32" (crc32 "IEND" = 0xAE426082);
    check "adler32 of the empty string" (adler32 "" = 1);
    check "adler32" (adler32 "abc" = 0x024D0127))

let () = case "a black and white PNG" (fun () ->
    with_temp_png (fun path ->
     save_png ~width:60 ~height:90 sierpinski 20_000 path;
     let (w, h, color_type, pixels) = decode_png path in
     check "the requested size" (w = 60 && h = 90);
     check "greyscale" (color_type = 0);
     let black = ref 0 and white = ref 0 and other = ref 0 in
     String.iter (function
      | '\000' -> incr black
      | '\255' -> incr white
      | _ -> incr other) pixels;
     check "only black and white" (!other = 0);
     check "some of the triangle is drawn" (!black > 200);
     check "and some of the background is not" (!white > 200)))

let () = case "a density coloured PNG" (fun () ->
    with_temp_png (fun path ->
     save_png ~width:60 ~height:90 ~color:true barnsley 50_000 path;
     let (w, h, color_type, pixels) = decode_png path in
     check "the requested size" (w = 60 && h = 90);
     check "true colour" (color_type = 2);
     let white = ref 0 and colored = ref 0 and darkest = ref false in
     String.iteri (fun i _ ->
      if i mod 3 = 0 then begin
       let p = String.sub pixels i 3 in
       if p = "\255\255\255" then incr white
       else begin
        incr colored;
        (* the most visited pixel is the far end of the ramp *)
        if p = "\008\029\088" then darkest := true
       end
      end) pixels;
     check "a white background" (!white > 200);
     check "coloured points" (!colored > 200);
     check "the densest pixel gets the end of the ramp" !darkest))

let () = case "rendering a solid system" (fun () ->
    let path =
     List.find Sys.file_exists
      ["../example/classics.ifs"; "example/classics.ifs"] in
    let fern = List.assoc "3dfern" (load_fractint path) in
    with_temp_png (fun out ->
     save_png_system ~width:50 ~height:50 ~yaw:1.0 ~pitch:0.2 fern 20_000 out;
     let (w, h, _, pixels) = decode_png out in
     check "the requested size" (w = 50 && h = 50);
     let black = ref 0 in
     String.iter (fun c -> if c = '\000' then incr black) pixels;
     check "the fern is drawn" (!black > 100)))

(* The verdict *)

let () =
    if !failures = 0 then
     Printf.printf "%d checks passed.\n" !checks
    else begin
     Printf.printf "%d of %d checks failed.\n" !failures !checks;
     exit 1
    end
