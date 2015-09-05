#ifndef MISC_C
#define MISC_C

(*
 * Based on fs/misc.c
 *)

 
 
(*******************************************************************)
(* do_sync based on AST1, 10318
 * DEV_STATUS : WIP
 *)
function do_sync() : integer;
var
   rip : ^t_inode,
   sp : ^t_super_block, 
   bp : ^t_buf,
   i : integer;
   
begin
   k_cpr(FS_COLOR, "Entered do_sync"); k_prln(1);

   sp := get_super(ROOT_DEV);
   (* TODO get time *)
   (* sp^.s_time := clock_time(); *)
   sp^.s_dirt := DIRTY;
   
   i := 0;
   while (i < NR_INODES) do begin
      rip := adr(inode[i]);
      if ((rip^.i_count > 0) AND (rip^.i_dirt = DIRTY)) then begin
         rw_inode(rip, WRITING)      
      end;
      i := i + 1
   end;
   
   
   i := 0;
   while (i < NR_SUPERS) do begin
      sp := adr(super_block[i]);
      if ((sp^.s_dev <> NO_DEV) AND (sp^.s_dirt = DIRTY)) then begin
         rw_super(sp, WRITING)      
      end;
      i := i + 1
   end;
   
   
   i := 0;
   while (i < NR_BUFS) do begin
      bp := adr(buf[i]);
      if ((bp^.b_dev <> NO_DEV) AND (bp^.b_dirt = DIRTY)) then begin
         rw_block(bp, WRITING)      
      end;
      i := i + 1
   end;
   

   k_cpr(FS_COLOR, "Leaving do_sync"); k_prln(1);
   retval(OK)
   
end;
(*******************************************************************)



#endif
