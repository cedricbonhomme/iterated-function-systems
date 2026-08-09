let usage_msg =
  "Draw an IFS fractal in a graphics window, or render it to a PNG file.\n\
   Usage: ifs-fractals [-n N] [-f FILE.ifs] [-o FILE [-s WxH] [-c]] FRACTAL\n"

let () =
  let iterations = ref 0 in
  let list_only = ref false in
  let chosen = ref None in
  let output = ref None in
  let size = ref (400, 640) in
  let color = ref false in
  let from_file = ref None in
  let set_size s =
    let dims =
      match String.index_opt s 'x' with
      | Some i ->
          ( int_of_string_opt (String.sub s 0 i),
            int_of_string_opt
              (String.sub s (i + 1) (String.length s - i - 1)) )
      | None -> (None, None)
    in
    match dims with
    | Some w, Some h when w > 0 && h > 0 -> size := (w, h)
    | _ -> raise (Arg.Bad ("bad size " ^ s ^ ", expected WIDTHxHEIGHT"))
  in
  let spec =
    [ ("-n", Arg.Set_int iterations,
       "N Number of points to plot (default: a per-fractal recommendation)");
      ("-f", Arg.String (fun f -> from_file := Some f),
       "FILE Read the fractals from a Fractint .ifs file");
      ("-o", Arg.String (fun f -> output := Some f),
       "FILE Write a PNG image to FILE instead of opening a window");
      ("-s", Arg.String set_size,
       "WxH Size of the image written with -o (default: 400x640)");
      ("-c", Arg.Set color,
       " Color the image written with -o by point density");
      ("--list", Arg.Set list_only, " List the available fractals and exit") ]
  in
  Arg.parse spec (fun s -> chosen := Some s) usage_msg;
  (* The fractals to choose from: the predefined ones, or those of a
     Fractint file. A file gives no iteration count, so recommend one. *)
  let catalogue () =
    match !from_file with
    | None -> Ifs_fractals.all
    | Some file ->
        let width, height = !size in
        let aspect = float_of_int width /. float_of_int height in
        List.map
          (fun (name, fs) -> (name, fs, 300_000))
          (Ifs_fractals.load_fractint ~aspect file)
  in
  let unknown name =
    Printf.eprintf
      "Unknown fractal %S. Run 'ifs-fractals %s--list' to see the available \
       ones.\n"
      name
      (match !from_file with
      | None -> ""
      | Some f -> Printf.sprintf "-f %s " (Filename.quote f));
    exit 1
  in
  let show (_, fs, default_n) =
    let n = if !iterations > 0 then !iterations else default_n in
    match !output with
    | Some file ->
        let width, height = !size in
        Ifs_fractals.save_png ~width ~height ~color:!color fs n file;
        Printf.printf "Wrote %s (%dx%d, %d points).\n" file width height n
    | None -> (
        if !color then
          prerr_endline "Warning: -c only applies to images written with -o.";
        try
          Ifs_fractals.draw fs n;
          print_endline "Press any key in the window (or close it) to quit.";
          try ignore (Graphics.read_key ())
          with Graphics.Graphic_failure _ -> ()
        with Graphics.Graphic_failure msg ->
          Printf.eprintf
            "Cannot open the graphics window (%s): a graphical display is \
             required.\n"
            msg;
          exit 1)
  in
  let run () =
    let catalogue = catalogue () in
    match (!list_only, !chosen, catalogue) with
    | true, _, _ ->
        List.iter
          (fun (name, _, n) ->
            Printf.printf "%-12s (default: %d points)\n" name n)
          catalogue
    (* A file holding a single fractal needs no name. *)
    | false, None, [ only ] when !from_file <> None -> show only
    | false, None, _ ->
        Arg.usage spec usage_msg;
        exit 1
    | false, Some name, _ -> (
        let eq n =
          String.lowercase_ascii n = String.lowercase_ascii name
        in
        match List.find_opt (fun (n, _, _) -> eq n) catalogue with
        | Some entry -> show entry
        | None -> unknown name)
  in
  try run () with
  | Ifs_fractals.Ifs_error msg ->
      Printf.eprintf "%s: %s\n"
        (match !from_file with Some f -> f | None -> "error")
        msg;
      exit 1
  | Sys_error msg ->
      Printf.eprintf "%s\n" msg;
      exit 1
