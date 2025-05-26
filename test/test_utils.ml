open! Core
open Lan_rogue

let print_map ~width ~height ~walls ~title =
  printf "%s:\n" title;
  for y = 0 to height - 1 do
    for x = 0 to width - 1 do
      let pos = Position.{ x; y } in
      if Set.mem walls pos then printf "#" else printf "."
    done;
    printf "\n"
  done
;;
