#ifndef FILEDES_INCLUDED
#define FILEDES_INCLUDED
#include <k_userio.inc>


(*
 * Main program for file system.  Based on AST1,8950.
 *)

#include "../h/const.inc"
#include "../h/type.inc"
#include "../h/error.inc"



#include "file.inc"


(*==================================================================*)
(*
 * get_fd based on AST1, 8871
 * DEV_STATUS:get_fd - WIP
 *)

function get_fd(bits : integer, k : ^integer, fpt : ^^t_filp) : integer;

var
   i : integer,
   f : ^t_filp;

begin
   k_cpr(FS_COLOR, "Entered get_fd"); k_prln(1);
   k^ := -1;
   
   k_cpr(FS_COLOR, "  Looking for a free file descriptor"); k_prln(1);
   i := 0;
   while i < NR_FDS do begin
      k_cpr(FS_COLOR, "  Checking FD : "); k_prnum(i); k_prln(1);
      
      (* fp was globally assigned in the main program.
       * It points to an fproc entry.
       * Each fproc entry contains a field called fp_filp 
       * which is and array of pointers to t_filp
       * There is a global array called filp.  Each entry is of type
       * t_filp.
       *)
      if fp^.fp_filp[i] = NIL_FILP then begin
         k_cpr(FS_COLOR, "  Found a free file descriptor"); k_prnum(i); k_prln(1);
         k^ := i; 
         break
      end;
      i := i + 1
   end;
   
   if k^ < 0 then retval(EMFILE);
   
   (* Weve got a file descriptor
    * now we need a free filp slot.
    * filp is an array of t_filp (AST1,7704)
    *)
   k_cpr(FS_COLOR, "  Searching filp table..."); k_prln(1);
   i := 0;
   while i < NR_FILPS do begin
      f := adr(filp[i]);
      k_cpr(FS_COLOR, "    Filp addr is "); k_pr_hex_num(f); k_prln(1);

      if f^.filp_count = 0 then begin
         f^.filp_mode := bits;
         s32_set_zero(adr(f^.filp_pos));
         fpt^ := f;
         k_cpr(FS_COLOR, "Leaving get_fd - FOUND empty filp slot : "); 
         k_cprnum(FS_COLOR,     i);
         k_prln(1);
         retval(OK)
      end;
      i := i + 1
   end;
   
   k_cpr(FS_COLOR, "Leaving get_fd - could not find empty filp slot"); k_prln(1);

   retval(ENFILE)

end;
(*==================================================================*)

(*==================================================================*)
(*
 * get_filp based on AST1, 8916
 * DEV_STATUS:get_filp - WIP
 *)
 function get_filp(fild : integer) : ^t_filp;
 begin
   err_code := EBADF;
   if (fild < 0) OR (fild >= NR_FDS) then retval(NIL_FILP);
   retval(fp^.fp_filp[fild]) (* May be NIL too *) 
 end;
(*==================================================================*)


(*==================================================================*)
(*
 * get_fd based on AST1, 8871
 * DEV_STATUS:get_fd - WIP
 *)
procedure init_filp();
var 
   i : integer;

begin
   i := 0;
   while i < NR_FILPS do begin
      filp[i] := NIL_FILP;
      i := i + 1
   end

end;
(*==================================================================*)

#endif