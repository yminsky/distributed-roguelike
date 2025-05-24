open! Core

val render_to_string : Notty.image -> string

val render_state_to_string
  :  ?width:int
  -> ?height:int
  -> Lan_rogue.Game_state.Local_state.t
  -> string
