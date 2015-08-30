#include <k_userio.inc>


(*
 * Main program for file system.  Based on AST1,8950.
 *)

#include "../h/const.inc"
#include "../h/type.inc"
#include "../h/error.inc"


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
 * new_node based on AST1,9557
 *
 * DEV_STATUS: new_node - WIP
 *)
function new_node(path : ^integer, bits : integer, z0 : integer) : ^t_inode;

var
   rlast_dir_ptr : ^t_inode,
   rip : ^t_inode,
   r : integer,
   string : array[NAME_SIZE] of integer;

   
begin
   k_cpr(FS_COLOR, "Entered new_node"); k_prln(1);
   rlast_dir_ptr := last_dir(path, adr(string));
   if (rlast_dir_ptr = NIL_INODE) then begin
      k_cpr(FS_COLOR, "  Tried and failed to use last_dir on path : ");
      k_cpr(FS_COLOR, path); k_prln(1);
      k_cpr(FS_COLOR, "Leaving new_node"); k_prln(1);
      retval(NIL_INODE)
   end;
   k_cpr(FS_COLOR, "  Successfully called last_dir on path : ");
   k_cpr(FS_COLOR, path); k_prln(1);

   
   k_cpr(FS_COLOR, "  Trying to advance() to : "); k_cpr(FS_COLOR, adr(string)); k_prln(1);
   rip := advance(rlast_dir_ptr, adr(string));
   
   
   if ( (rip = NIL_INODE) AND (err_code = (ENOENT)) ) then begin



      k_cpr(FS_COLOR, "  advance failed string not in dir will try create new dir "); k_prln(1);
      
      (* We tried to advance but the string was not in the last dir 
       * so we will create a new directory entry. *)
      k_cpr(FS_COLOR, "  attempting to alloc an inode in last dir above "); k_prln(1);
      rip := alloc_inode(rlast_dir_ptr^.i_dev, bits);
      if (rip = NIL_INODE) then begin
         k_cpr(FS_COLOR, "  ERROR could not alloc an inode (in new_node) "); k_prln(1);
         put_inode(rlast_dir_ptr);
         k_cpr(FS_COLOR, "Leaving new_node after ERROR above"); k_prln(1);
         retval(NIL_INODE)
      end;
      k_cpr(FS_COLOR, "  SUCCESS allocating an inode (in new_node) "); k_prln(1);

      
      rip^.i_nlinks := rip^.i_nlinks + 1;
      (* TODO figure out what z0 is!!! *)
      rip^.i_zone[0] := z0;
      k_cpr(FS_COLOR, "  INFO forcing inode to disk (in new_node) "); k_prln(1);
      rw_inode(rip, WRITING);

      k_cpr(FS_COLOR, "  INFO trying to create new dir entry (in new_node) "); k_prln(1);
      r := search_dir(rlast_dir_ptr, adr(string), adr(rip^.i_num), ENTER);
      if (r <> OK) then begin
         k_cpr(FS_COLOR, "  ERROR unable to add string to directory"); k_prln(1);
         put_inode(rlast_dir_ptr);
         rip^.i_nlinks := rip^.i_nlinks - 1;
         rip^.i_dirt := DIRTY;
         put_inode(rip);
         err_code := r;
         k_cpr(FS_COLOR, "Leaving new_node"); k_prln(1);
         retval(NIL_INODE)      
      end
   end
   else begin
      (* Last component "string" exists *)
      k_cpr(FS_COLOR, "  INFO string probably already exists"); k_prln(1);
      if (rip <> NIL_INODE) then 
         r := EEXIST
      else
         r := err_code
      
   end;
   
   put_inode(rlast_dir_ptr);
   err_code := r;
   
   
   k_cpr(FS_COLOR, "Leaving new_node SUCCESSFULLY "); k_prln(1);
   retval(rip)
   
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