(* camlp5r *)
(* $Id: pprintf.ml,v 1.5 2010/09/03 13:21:29 deraugla Exp $ *)
(* Copyright (c) INRIA 2007-2010 *)

#load "pa_macro.cmo";

type pr_context = { ind : int; bef : string; aft : string; dang : string };
type pr_fun 'a = pr_context -> 'a -> string;

value tab ind = String.make ind ' ';
value empty_pc = {ind = 0; bef = ""; aft = ""; dang = ""};

IFDEF OCAML_1_07 OR COMPATIBLE_WITH_OLD_OCAML THEN
  value with_ind_bef pc ind bef =
    {ind = ind; bef = bef; aft = pc.aft; dang = pc.dang}
  ;
  value with_ind_bef_aft pc ind bef aft =
    {ind = ind; bef = bef; aft = aft; dang = pc.dang}
  ;
  value with_bef pc bef =
    {ind = pc.ind; bef = bef; aft = pc.aft; dang = pc.dang}
  ;
  value with_bef_aft pc bef aft =
    {ind = pc.ind; bef = bef; aft = aft; dang = pc.dang}
  ;
  value with_aft pc aft =
    {ind = pc.ind; bef = pc.bef; aft = aft; dang = pc.dang}
  ;
END;

value sprint_break nspaces offset pc f g =
  Pretty.horiz_vertic
    (fun () ->
       let sp = String.make nspaces ' ' in
       Pretty.sprintf "%s%s%s" (f {(pc) with aft = ""}) sp
         (g {(pc) with bef = ""}))
    (fun () ->
       let s1 = f {(pc) with aft = ""} in
       let s2 =
         g {(pc) with ind = pc.ind + offset; bef = tab (pc.ind + offset)}
       in
       Pretty.sprintf "%s\n%s" s1 s2)
;

value sprint_break_all force_newlines pc f fl =
  Pretty.horiz_vertic
    (fun () ->
       if force_newlines then Pretty.sprintf "\n"
       else
         loop (f (if fl = [] then pc else {(pc) with aft = ""})) fl
         where rec loop s =
           fun
           [ [(sp, off, f) :: fl] ->
               let s =
                 Pretty.sprintf "%s%s%s" s (String.make sp ' ')
                   (f {(pc) with bef = "";
                       aft = if fl = [] then pc.aft else ""})
               in
               loop s fl
           | [] -> s ])
    (fun () ->
       loop (f (if fl = [] then pc else {(pc) with aft = ""})) fl
       where rec loop s =
         fun
         [ [(sp, off, f) :: fl] ->
             let s =
               Pretty.sprintf "%s\n%s" s
                 (f {(pc) with ind = pc.ind + off; bef = tab (pc.ind + off);
                     aft = if fl = [] then pc.aft else ""})
             in
             loop s fl
         | [] -> s ])
;
