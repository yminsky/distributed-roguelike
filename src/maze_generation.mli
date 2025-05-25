(** Procedural maze generation. *)

open! Core

(** Configuration for maze generation *)
module Config : sig
  type t

  (** Default configuration *)
  val default : t
end

(** Generate a maze with the given configuration.

    @param config Generation parameters
    @param seed Random seed for reproducible generation
    @return Set of wall positions *)
val generate : config:Config.t -> seed:int -> Protocol.Position.Set.t
