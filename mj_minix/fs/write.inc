#ifndef WRITE_INC
#define WRITE_INC

#include <k_userio.inc>
#include "param.inc"

(*
 * Based on fs/write.c
 *)

 
 


(*******************************************************************)
(* AST1, 10125 *)
function do_write() : integer;
begin
   retval(read_write(WRITING))
end;
(*******************************************************************)



#endif
