(*Generated by Lem from julia.lem.*)

(* Specification of Solidity intermediate language *)

open Lem_pervasives
open Lem_list
open Lem_word
open Word256
open Word160
open Word8

type id = int

type builtin_type =
 | Boolean
 | S256
 | S128
 | S64
 | S32
 | S8
 | U256
 | U128
 | U64
 | U32
 | U8



