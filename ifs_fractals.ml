#use "topfind";;
#require "graphics";;

type point = { x: float; y: float}

type transfo = { pb: float; kf: float array}

type ifs = { po: point; sz: point; lt: transfo list}

let image kf p =
    { x= kf.(0)*.p.x+.kf.(1)*.p.y+.kf.(2);
    y= kf.(3)*.p.x+.kf.(4)*.p.y+.kf.(5)};;

let rec select_image p rd = function
    | t::_ when rd<=t.pb -> image t.kf p
    | _::lt -> select_image p rd lt
    | [] -> raise Not_found;;

open Graphics;;
open_graph " 400x640";;

let pixel_of_point po sz p =
    (int_of_float((p.x-.po.x)/.sz.x*.float_of_int(size_x())),
    int_of_float((p.y-.po.y)/.sz.y*.float_of_int(size_y())));;

let trace fs n =
 let _ = clear_graph () in
  let rec urs pt = function
   | 0 -> ()
   | i -> let p' = (select_image pt (Random.float 1.0) fs.lt) in
           let (xx,yy) = pixel_of_point fs.po fs.sz p' in
            let _ = plot xx yy
             in urs p' (i-1)
  in urs {x= 1.0; y= 1.0} n;;

let barnsley =
{ po = {x= -2.25 ; y= -0.50};
sz = {x= 5.00 ; y= 11.00};
lt = [{pb= 0.84; kf= [| 0.85; 0.04; 0.00; -0.04; 0.85; 1.60|]};
{pb= 0.91; kf= [|-0.15; 0.28; 0.00; 0.26; 0.24; 0.44|]};
{pb= 0.98; kf= [| 0.20;-0.26; 0.00; 0.23; 0.22; 1.60|]};
{pb= 1.00; kf= [| 0.00; 0.00; 0.00; 0.00; 0.16; 0.00|]}]};;

let sierpinski =
{ po = {x= -5.0 ; y= -8.0};
sz = {x= 5.0 ; y= 3.0};
lt = [{pb= 0.333; kf= [|0.5; 0.0; 0.0; 0.5; 0.0; 0.0|]};
{pb= 0.666; kf= [|0.5; 0.0; 0.0; 0.5; 1.0; 0.0|]};
{pb= 1.00; kf= [|0.5; 0.0; 0.0; 0.5; 0.5; 0.8660254|]}]};;

let dragon =
{ po = {x= -40.0 ; y= -10.0};
sz = {x= 110.0 ; y= 110.0};
lt = [{pb= 0.787473; kf= [| 0.824074; 0.281482; -10.88229; -0.212346;
0.864198; -0.110607|]};
{pb= 1.0; kf= [| 0.288272; 0.720988; 0.78536; -0.463889; -0.377778;
80.095795|]}]};;

let corail =
{ po = {x= -45.0 ; y= -5.0};
sz = {x= 95.0 ; y= 100.0};
lt = [{pb= 0.40; kf= [| 0.307692; -0.531469; 50.401953; -0.461538;
-0.293706; 80.655175|]};
{pb= 0.55; kf= [| 0.307692; -0.076923; -10.295248; 0.153846;
-0.447552; 40.152990|]};
{pb= 1.00; kf= [| 0.000000; 0.545455; -40.893637; 0.692308;
-0.195804; 70.269794|]}]};;

let arbre =
{ po = {x= -0.3 ; y= 0.0};
sz = {x= 0.6 ; y= 0.5};
lt = [{pb= 0.05; kf= [| 0.0; 0.0; 0.0; 0.0; 0.5; 0.0|]};
{pb= 0.45; kf= [| 0.42; -0.42; 0.0; 0.42; 0.42; 0.2|]};
{pb= 0.85; kf= [| 0.42; 0.42; 0.0; -0.42; 0.42; 0.2|]};
{pb= 1.00; kf= [| 0.1; 0.0; 0.0; 0.0; 0.1; 0.2|]}]};;

let etoile =
{ po = {x= -50.0 ; y= -20.0};
sz = {x= 100.0 ; y= 100.0};
lt = [{pb= 0.912675; kf= [| 0.745455; -0.459091; 10.460279; 0.406061;
0.887121; 0.691072|]};
{pb= 1.0; kf= [| -0.424242; -0.065152; 30.809567; -0.175758;
-0.218182; 60.741476|]}]};;

let zigzag =
{ po = {x= -70.0 ; y= -20.0};
sz = {x= 150.0 ; y= 130.0};
lt = [{pb= 0.888128; kf= [| -0.632407; -0.614815; 30.840822;
-0.54537;
0.659259; 10.282321|]};
{pb= 1.0; kf= [| -0.036111; 0.444444; 20.071081; 0.210185; 0.037037;
80.330552|]}]};;

let cristal =
{ po = {x= -0.0 ; y= -70.0};
sz = {x= 100.0 ; y= 140.0};
lt = [{pb= 0.747826; kf= [| 0.69697; -0.481061; 20.147003; -0.393939;
-0.662879; 10.310288|]};
{pb= 1.0; kf= [| 0.090909; -0.443182; 40.286558; 0.515152; -0.094697;
20.925762|]}]};;

let binary =
{ po = {x= -50.0 ; y= -1.0};
sz = {x= 100.0 ; y= 95.0};
lt = [{pb= 0.333333; kf= [| 0.5; 0.0; -20.563477; 0.0; 0.5;
-0.000003|]};
{pb= 0.666666; kf= [| 0.5; 0.0; 20.436544; 0.0; 0.5; -0.000003|]};
{pb= 1.0; kf= [| 0.0; -0.5; 40.873085; 0.5; 0.0; 70.563492|]}]};;

let galaxie =
{ po = {x= -8.0 ; y= -1.0};
sz = {x= 16.0 ; y= 12.0};
lt = [{pb= 0.787879; kf= [| 0.787879; -0.424242; 1.758647; 0.242424;
0.859848; 1.408065|]};
{pb= 0.909091; kf= [| -0.121212; 0.257576; -6.721654; 0.151515;
0.053030; 1.377236|]};
{pb= 1.0; kf= [| 0.181818; -0.136364; 6.086107; 0.090909; 0.181818;
1.568035|]}]};;

let koch =
{ po = {x= -2.25 ; y= -4.0};
sz = {x= 11.00 ; y= 8.00};
lt = [{pb= 0.25; kf= [|0.333; 0.0; 0.0; 0.333; 0.0; 0.0|]};
{pb= 0.50; kf= [|0.167; -0.287; 0.287; 0.167; 0.333; 0.0|]};
{pb= 0.75; kf= [|0.167; 0.287; -0.287; 0.167; 0.5; 0.287|]};
{pb= 1.0; kf= [|0.333; 0.0; 0.0; 0.333; 0.667; 0.0|]}]};;
