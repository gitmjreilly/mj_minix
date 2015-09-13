#ifndef GLO_INC
#define GLO_INC

(*
 * Based on fs/glo.h AST1,78000
 *)

var
   super_user : integer,


   who : integer,
   fs_call : integer,
   user_path : array [MAX_PATH] of integer,
   err_code : integer,
   fp : ^t_fproc;

var
   (* Ptrs to cast message and use with param.inc *)
   m1_in : ^mess_1,
   m2_in : ^mess_2,
   m3_in : ^mess_3,

   m1_out : ^mess_1,
   m2_out : ^mess_2,
   
   in_msg : mess_3,
   out_msg : mess_1;
(*   
   p : ^block_message,
   reply_ptr : ^reply_message;
*)   
   
#endif
