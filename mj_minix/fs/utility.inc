#ifndef UTILITY_INC
#define UTILITY_INC

(*
 * Based on fs/utility.c
 *)

function cmp_string(rsp1 : ^integer, rsp2 : ^integer, n : integer) : integer;
begin
   while (n > 0) do begin
      if (rsp1^ <> rsp2^) then retval(0);
      rsp1 := rsp1 + 1;
      rsp2 := rsp2 + 1;
      n := n - 1
   end;
   retval(1)
end; 
 
 
(* fetch_name based on AST1,12512 
 * DEV_STATUS :fetch_name - looks done 18 Oct 2013 
 *)
function fetch_name(path : ^integer, len : integer, flag : integer) : integer;
var
   err_code : integer,
   rpu : ^integer,
   vpath : integer,
   rpm : ^integer;
   
begin
   k_cpr(FS_COLOR, "entered fetch_name"); k_prln(1);
   k_cpr(FS_COLOR, "  length is : "); k_cprnum(FS_COLOR, len); k_prln(1);
   if (flag = M3) AND (len <= M3_STRING) then begin
      k_cpr(FS_COLOR, "  name is part of message"); k_prln(1);
      rpu := adr(user_path);
      rpm := adr(pathname); (* path_name is part of m3 message *)
      while (len > 0) do begin
         rpu^ := rpm^;
         rpu := rpu + 1;
         rpm := rpm + 1;
         len := len - 1  
      end;
      (* AST did not add NULL but it is obvious he wanted to fit a 
       * 14 char name in the message field so we add the null here.
       *)
      rpu^ := 0;
     
      k_cpr(FS_COLOR, "leaving fetch_name after copying from message"); k_prln(1);
      retval(OK)
   end;
   
   if (len > MAX_PATH) then begin
      err_code := E_LONG_STRING;
      k_cpr(FS_COLOR, "leaving fetch_name after seeing long string"); k_prln(1);
      retval(ERROR)
   end;

   vpath := path;
   err_code := rw_user(D, who, vpath, len, adr(user_path), FROM_USER);
   (* As with in-message name, we need a null here too. *)
   user_path[len] := 0;
   k_cpr(FS_COLOR, "leaving fetch_name after calling rw_user"); k_prln(1);
   retval(err_code)
end;

 
procedure panic(format : ^integer, num : integer);
begin
   k_cpr(FS_COLOR, "File system panic!");
   if (num <> NO_NUM) then
      k_cpr_hex_num(FS_COLOR, num);
   k_prln(1)
end;



#endif