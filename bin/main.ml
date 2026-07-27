let usage_msg =
  "Draw an IFS fractal in a graphics window.\n\
   Usage: ifs-fractals [-n N] FRACTAL\n"

let () =
  let iterations = ref 0 in
  let list_only = ref false in
  let chosen = ref None in
  let spec =
    [ ("-n", Arg.Set_int iterations,
       "N Number of points to plot (default: a per-fractal recommendation)");
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
              exit 1))
