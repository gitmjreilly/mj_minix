#ifndef PROTECT_INC
#define PROTECT_INC
#include <k_userio.inc>


(*
 * Main program for file system.  Based on AST1,8950.
 *)

#include "../h/const.inc"
#include "../h/type.inc"
#include "../h/error.inc"




(*==================================================================*)
(*
 * do_chmod() based on AST1,11677 
 * Uses message type m3
 *
 * DEV_STATUS:do_chmod - WIP
 *)

procedure do_chmod();

var
   r : integer,
   rip : ^t_inode;
   

begin
   k_cpr(FS_COLOR, "Entered do_chmod"); k_prln(1);
   (* k_cpr(FS_COLOR, "name is : "); k_cpr(FS_COLOR, name); k_prln(1); *)
   k_cpr(FS_COLOR, "  name_length is : "); k_cprnum(FS_COLOR, name_length); k_prln(1);
   if (fetch_name(name, name_length, M3) <> OK) then retval(err_code);
   k_cpr(FS_COLOR, "  retrieved name : "); k_cpr(FS_COLOR, adr(user_path)); k_prln(1);
   
   rip := eat_path(adr(user_path));
   if (rip = NIL_INODE) then begin
      k_cpr(FS_COLOR, "  rip is NIL; returning from do_chmod"); k_prln(1);
      (* err_code declared in fs/utility.inc *)
      retval(err_code)
   end;
   
   (* Make the change to i_mode without checking any permissions *)
   rip^.i_mode := mode AND ALL_MODES;
   rip^.i_dirt := DIRTY;
   put_inode(rip);
  
   k_cpr(FS_COLOR, "Leaving do_chmod"); k_prln(1)

end;
(*==================================================================*)


(*==================================================================*)
(*
 * forbidden() based on AST1,11782
 * Uses message type m3
 *
 * DEV_STATUS:forbidden - WIP - purely a stub for now
 *)
function forbidden(rip : ^t_inode, access_desired : integer, real_uid : integer) : integer;
begin
   retval(OK)
end;
(*==================================================================*)

#endif