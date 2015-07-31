#include <k_userio.inc>


(*
 * Main program for file system.  Based on AST1,8950.
 *)

#include "../h/const.inc"
#include "../h/type.inc"
#include "../h/error.inc"



#include "const.inc"
#include "type.inc"
#include "buf.inc"
#include "file.inc"
#include "fproc.inc"
#include "glo.inc"
#include "inode.inc"
#include "super.inc"
#include "param.inc"

var
   (* AST1,9474 mode map was an array of chars
    * it was initialized  as follows:
    * {R_BIT, W_BIT, R_BIT|W_BIT, 0}
    *)
   mode_map : array[4] of integer;


(*==================================================================*)
(*
 * do_open() based on AST1,9622
 * Uses message type m3
 *
 * DEV_STATUS:do_open - WIP
 *)

function do_open() : integer;

var
   rip : ^t_inode,
   r : integer,
   bits : integer,
   fil_ptr : ^t_filp,
   file_d : integer;
   

begin
   k_cpr(FS_COLOR, "Entered do_open"); k_prln(1);
   
   (* Check the open mode; mode is a #defined field in message m3 *)
   (* 0 = read
    *)
   if (mode < 0) OR (mode > 2) then retval(EINVAL);
   
   k_cpr(FS_COLOR, "  name_length is : "); k_cprnum(FS_COLOR, name_length); k_prln(1);
   (* fetch name stores the results in the global user_path *)
   if (fetch_name(name, name_length, M3) <> OK) then retval(err_code);
   k_cpr(FS_COLOR, "  retrieved name : "); k_cpr(FS_COLOR, adr(user_path)); k_prln(1);
   
   bits := mode_map[mode];
   r := get_fd(bits, adr(file_d), adr(fil_ptr));
   if r <> OK then begin
      k_cpr(FS_COLOR, "Leaving do_open could not get fd"); k_prln(1);
      retval(r)
   end;
   
   rip := eat_path(adr(user_path));
   if rip = NIL_INODE then begin
      k_cpr(FS_COLOR, "Leaving do_open rip b/c file was nil"); k_prln(1);
      retval(err_code)
   end;
   
   r := forbidden(rip, bits, 0);
   if r <> OK then begin
      k_cpr(FS_COLOR, "Leaving do_open rip b/c access was forbidden"); k_prln(1);
      put_inode(rip);
      retval(r)
   end;
  
   (* TODO Put in code for directories and special files.
    * This code only handles regular files at this time.
    *)
   if rip^.i_mode AND I_TYPE = I_DIRECTORY then begin
      k_cpr(FS_COLOR, "  inode is for a dir"); k_prln(1);
      if (bits AND W_BIT) then begin
         k_cpr(FS_COLOR, "  W mode is set NG!!"); k_prln(1);
         put_inode(rip);
         retval(EISDIR)         
      end
   end;
   
   fp^.fp_filp[file_d] := fil_ptr;
   fil_ptr^.filp_count := 1;
   fil_ptr^.filp_ino := rip;
   
   k_cpr(FS_COLOR, "Leaving do_open SUCCESSFULLY; fd is : "); k_prnum(file_d); k_prln(1);
   retval(file_d)
end;
(*==================================================================*)

(*==================================================================*)
(*
 * do_close based on AST1,9680
 * Uses message type m3
 *
 * DEV_STATUS:do_close - WIP
 *)

function do_close() : integer;

var
   rfilp : ^t_filp,
   rip : ^t_inode,
   rw :integer,
   r : integer,
   mode_word : integer,
   fil_ptr : ^t_filp;

begin
   k_cpr(FS_COLOR, "Entered do_close"); k_prln(1);
   (* The close() func makes use of fields in an m1 type message 
    * See param.inc for fd field.
    *)
   k_cpr(FS_COLOR, "  FD is : "); k_cprnum(FS_COLOR, fd); k_prln(1);
   rfilp := get_filp(fd);
   if rfilp = NIL_FILP then begin
      k_cpr(FS_COLOR, "  Could not file filp"); k_prln(1);      
      k_cpr(FS_COLOR, "Leaving do_close"); k_prln(1);
      retval(err_code)   
   end;
   
   rip := rfilp^.filp_ino;
   mode_word := rip^.i_mode AND I_TYPE;
   
   (* TODO Add code for pipes and special devs *)
   rfilp^.filp_count := rfilp^.filp_count - 1;
   if (rfilp^.filp_count = 0) then begin
      k_cpr(FS_COLOR, "  filp_count has gone to 0; returning inode..."); k_prln(1);      
      put_inode(rfilp^.filp_ino)
   end;
   
   fp^.fp_filp[fd] := NIL_FILP;
   
   k_cpr(FS_COLOR, "Leaving do_close Successfully"); k_prln(1);
   retval(OK)
end;
(*==================================================================*)

(*==================================================================*)
(*
 * init_open exists because this compiler cannot pre-initialize variables.
 * It is called in the main program.
 *)
procedure init_open();
begin
   mode_map[0] := R_BIT;
   mode_map[1] := W_BIT;
   mode_map[2] := R_BIT OR W_BIT;
   mode_map[3] := 0
end;