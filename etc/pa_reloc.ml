(* camlp5r *)
(* $Id: pa_reloc.ml,v 1.2 2010/09/07 14:04:19 deraugla Exp $ *)

(*
   meta/camlp5r etc/pa_reloc.cmo etc/pr_r.cmo -impl main/mLast.mli
*)

#load "pa_extend.cmo";
#load "q_MLast.cmo";

value patt_of_type gtn loc n t =
  let x = "x" ^ string_of_int n in
  let p = <:patt< $lid:x$ >> in
  match t with
  [ <:ctyp< loc >> -> (<:patt< loc >>, n)
  | _ -> (p, n + 1) ]
;

value rec expr_of_type gtn use_self loc t =
  match t with
  [ <:ctyp< $lid:tn$ >> ->
      if tn = gtn then Some (<:expr< self >>, True)
      else if List.mem tn ["bool"; "string"; "type_var"] then None
      else Some (<:expr< $lid:tn$ floc sh >>, use_self)
  | <:ctyp< ($list:tl$) >> ->
      let (rev_pl, _) =
        List.fold_left
          (fun (rev_pl, n) t ->
             let (p, n) = patt_of_type gtn loc n t in
             ([p :: rev_pl], n))
          ([], 1) tl
      in
      let (rev_el, _, use_self) =
        List.fold_left
          (fun (rev_el, n, use_self) t ->
             let (e, n, use_self) =
               match t with
               [ <:ctyp< loc >> -> (<:expr< floc loc >>, n, use_self)
               | _ ->
                   let x = "x" ^ string_of_int n in
                   let e = <:expr< $lid:x$ >> in
                   let (e, use_self) =
                     match expr_of_type gtn use_self loc t with
                     [ Some (f, use_self) -> (<:expr< $f$ $e$ >>, use_self)
                     | None -> (e, use_self) ]
                   in
                   (e, n + 1, use_self) ]
             in
             ([e :: rev_el], n, use_self))
          ([], 1, use_self) tl
      in
      let p = <:patt< ($list:List.rev rev_pl$) >> in
      let e = <:expr< ($list:List.rev rev_el$) >> in
      Some (<:expr< fun $p$ -> $e$ >>, use_self)
  | <:ctyp< $t1$ $t2$ >> ->
      match expr_of_type gtn use_self loc t2 with
      [ Some (e, use_self) ->
          let f =
            match t1 with
            [ <:ctyp< list >> -> <:expr< List.map >>
            | <:ctyp< option >> -> <:expr< option_map >>
            | <:ctyp< Ploc.vala >> -> <:expr< vala_map >>
            | <:ctyp< $lid:n$ >> -> <:expr< $lid:n^"_map"$ floc >>
            | _ -> <:expr< fucking_map >> ]
          in
          Some (<:expr< $f$ $e$ >>, use_self)
      | None -> None ]
  | _ ->
      Some (<:expr< fucking 9 >>, use_self) ]
;

value conv_cons_decl gtn use_self (loc, c, tl) =
  let tl = Pcaml.unvala tl in
  let (p, _) =
    let p = <:patt< $_uid:c$ >> in
    List.fold_left
      (fun (p1, n) t ->
         let (p2, n) =
           match t with
           [ <:ctyp< loc >> -> (<:patt< loc >>, n)
           | _ ->
               let x = "x" ^ string_of_int n in
               (<:patt< $lid:x$ >>, n + 1) ]
         in
         (<:patt< $p1$ $p2$ >>, n))
      (p, 1) tl
  in
  let e = <:expr< $_uid:c$ >> in
  let (e, _, use_self) =
    List.fold_left
      (fun (e1, n, use_self) t ->
         let x = "x" ^ string_of_int n in
         let e = <:expr< $lid:x$ >> in
         let (e2, n, use_self) =
           match t with
           [ <:ctyp< loc >> -> (<:expr< floc loc >>, n, use_self)
           | _ ->
               let (e, use_self) =
                 match expr_of_type gtn use_self loc t with
                 [ Some (f, use_self) -> (<:expr< $f$ $e$ >>, use_self)
                 | None -> (e, use_self) ]
               in
               (e, n + 1, use_self) ]
         in
         (<:expr< $e1$ $e2$ >>, n, use_self))
      (e, 1, use_self) tl
  in
  ((p, <:vala< None >>, e), use_self)
;

value gen_reloc loc tdl =
  match tdl with
  [ [{MLast.tdNam = (_, <:vala< "ctyp" >>)} :: _] ->
      let pel =
        List.map
          (fun td ->
             let tn = Pcaml.unvala (snd td.MLast.tdNam) in
             let (e, use_self) =
               match td.MLast.tdDef with
               [ <:ctyp< [ $list:cdl$ ] >> ->
                   let (pwel, use_self) =
                     List.fold_right
                       (fun cd (pwel, use_self) ->
                          let (pwe, use_self) =
                            conv_cons_decl tn use_self cd
                          in
                          ([pwe :: pwel], use_self))
                       cdl ([], False)
                   in
                   (<:expr< fun [ $list:pwel$ ] >>, use_self)
               | _ -> (<:expr< 0 >>, False) ]
             in
             let e =
               if use_self then <:expr< self where rec self = $e$ >>
               else e
             in
             let e = <:expr< fun floc sh -> $e$ >> in
             (<:patt< $lid:tn$ >>, e))
          tdl
      in
      <:str_item< value rec $list:pel$ >>
  | _ -> <:str_item< type $list:tdl$ >> ]
;

EXTEND
  Pcaml.str_item:
    [ [ "type"; tdl = LIST1 Pcaml.type_declaration SEP "and" ->
          gen_reloc loc tdl ] ]
  ;
END;