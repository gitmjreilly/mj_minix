#ifndef STADIR
#define STADIR




(*******************************************************************)
(* change()  base on AST1, 10515
 * DEV_STATUS : WIP
 *)
function change(iip : ^^t_inode, name_ptr : ^integer, len : integer) : integer;

var
   rip : ^t_inode,
   r : integer;

begin
   k_cpr(INODE_COLOR, "Entered change"); k_prln(1);

   k_cpr(INODE_COLOR, "  CAlling fetch_name"); k_prln(1);
   if (fetch_name(name_ptr, len, M3) <> OK) then begin
      k_cpr(INODE_COLOR, "Unsuccessfully Leaving change"); k_prln(1);
      retval(err_code)
   end;
   k_cpr(INODE_COLOR, "  fetch_name must have been OK"); k_prln(1);

   rip := eat_path(adr(user_path));
   if (rip = NIL_INODE) then begin
      k_cpr(INODE_COLOR, "Leaving change - UNSUCCESSFUL"); k_prln(1);
      retval(err_code)
   end;
   

   if ((rip^.i_mode AND I_TYPE) <> I_DIRECTORY) then begin
      k_cpr(INODE_COLOR, "  Unsuccessful - not a dir "); k_prln(1);
      r := ENOTDIR   
   end
   else begin
      r := forbidden(rip, X_BIT, 0)
   end;
      
   if (r <> OK) then begin
      k_cpr(INODE_COLOR, "  Unsuccessful - leaving change "); k_prln(1);
      put_inode(rip);
      retval(r)
   end;
   
   (* return the old inode now that we know we can change *)
   put_inode(iip^);
   iip^ := rip;
   
   
   k_cpr(INODE_COLOR, "Leaving change - SUCCESS"); k_prln(1);
   retval(OK)
end;
(*******************************************************************)


(*******************************************************************)
(* do_chdir() system call 12 based on AST1, 11475
 * DEV_STATUS : WIP
 * Uses 2 m3 fields name, name_length
 *)
function do_chdir() : integer;

var
   rfp : ^t_proc;
   
begin
   k_cpr(INODE_COLOR, "Entered do_chdir"); k_prln(1);


   k_cpr(INODE_COLOR, "Leaving do_chdir"); k_prln(1);
   (* TODO add MM support for do_exec *)
   
   k_cpr(INODE_COLOR, "name is : "); k_cpr(INODE_COLOR, name); k_prln(1);
   
   retval( change(adr(fp^.fp_workdir), name, name_length) )

end;
(*******************************************************************)

 
 

#endif