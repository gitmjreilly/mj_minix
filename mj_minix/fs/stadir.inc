#ifndef STADIR
#define STADIR



(*******************************************************************)
(* stat_inode()  based on AST1, 11592
 * DEV_STATUS : WIP
 *)
function stat_inode(rip : ^t_inode,   filp_ptr : ^t_filp, user_addr : ^integer) : integer;

var
   stp : ^t_stat,
   statbuf : t_stat,
   r : integer,
   v : integer (* ?? *);

begin
   stp := adr(statbuf);
   stp^.st_dev := rip^.i_dev;
   stp^.st_ino := rip^.i_num;
   stp^.st_mode := rip^.i_mode;
   stp^.st_nlink := rip^.i_nlinks AND $00FF;
   stp^.st_uid := rip^.i_uid;
   stp^.st_gid := rip^.i_gid;
   stp^.st_rdev := rip^.i_zone[0];
   s32_copy(adr(rip^.i_size), adr(stp^.st_size));
   
   (* TODO do pipe and time stuff *)
   
   (*
    * From read.inc
   r := rw_user(seg, usr, buff, chunk, (adr(bp^.b__data) + off),   dir);
   *) 
   
   v := user_addr;
   
   r := rw_user(
      D,                 (* space - ignored *)
      who,               (* process to write to, in this case proc who sent message *)
      v,                 (* address in user space to write to*)
      15,                (* how much are we writing sizeof(statbuf) *)
      stp,               (* local address of data *)
      TO_USER);          (* write to user *)
   
   retval(r)   

end;
(*******************************************************************)

(*******************************************************************)
(* do_stat()  based on AST1, 11553
 * DEV_STATUS : WIP
 * uses an M1 message
 *)
function do_stat() : integer;

var
   rip : ^t_inode,
   r : integer;

begin
   k_cpr(FS_COLOR, "Entered do_stat"); k_prln(1);
   if (fetch_name(name1, name1_length, M1) <> OK) then begin
      k_cpr(FS_COLOR, "  prob w fetch_name Leaving do_stat UNsuccessfully"); k_prln(1);
      retval(err_code)
   end;
   
   rip := eat_path(adr(user_path));
   if (rip = NIL_INODE) then begin
      k_cpr(FS_COLOR, "  prob w eat_path Leaving do_stat UNsuccessfully"); k_prln(1);
      retval(err_code)
   end;
   
   (* Please note name2 is a #def alias in an M1 message; its the pointer to user space buffer *)
   r := stat_inode(rip, NIL_FILP, name2);
   put_inode(rip);

   k_cpr(FS_COLOR, "Leaving do_stat successfully"); k_prln(1);
   retval(r)

end;
(*******************************************************************)


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