let usage_msg =
  "Draw an IFS fractal in a graphics window, or render it to a PNG file.\n\
   Usage: ifs-fractals [-n N] [-o FILE [-s WxH] [-c]] FRACTAL\n"

let () =
  let iterations = ref 0 in
  let list_only = ref false in
  let chosen = ref None in
  let output = ref None in
  let size = ref (400, 640) in
  let color = ref false in
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
      ("-o", Arg.String (fun f -> output := Some f),
       "FILE Write a PNG image to FILE instead of opening a window");
      ("-s", Arg.String set_size,
       "WxH Size of the image written with -o (default: 400x640)");
      ("-c", Arg.Set color,
       " Color the image written with -o by point density");
      ("--list", Arg.Set list_only, " List the available fractals and exit") ]
  in
  Arg.parse spec (fun s -> chosen := Some s) usage_msg;
  if !list_only then
    List.iter
      (fun (name, _, n) -> Printf.printf "%-12s (default: %d points)\n" name n)
      Ifs_fractals.all
  else
    match !chosen with
    | None ->
        Arg.usage spec usage_msg;
        exit 1
    | Some name -> (
        match
          List.find_opt (fun (n, _, _) -> n = name) Ifs_fractals.all
        with
        | None ->
            Printf.eprintf
              "Unknown fractal %S. Run 'ifs-fractals --list' to see them.\n"
              name;
            exit 1
        | Some (_, fs, default_n) -> (
            let n = if !iterations > 0 then !iterations else default_n in
            match !output with
            | Some file ->
                let width, height = !size in
                Ifs_fractals.save_png ~width ~height ~color:!color fs n file;
                Printf.printf "Wrote %s (%dx%d, %d points).\n" file width
                  height n
            | None -> (
                if !color then
                  prerr_endline
                    "Warning: -c only applies to images written with -o.";
            try
              Ifs_fractals.draw fs n;
              print_endline
                "Press any key in the window (or close it) to quit.";
              try ignore (Graphics.read_key ())
              with Graphics.Graphic_failure _ -> ()
            with Graphics.Graphic_failure msg ->
              Printf.eprintf
                "Cannot open the graphics window (%s): a graphical display \
                 is required.\n"
                msg;
              exit 1)))
