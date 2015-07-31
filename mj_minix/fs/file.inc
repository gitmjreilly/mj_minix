#ifndef FILE_INC
#define FILE_INC
(* 
 * file.inc based on file.h AST1, 7700
 *
 *)
 
 type
    t_filp = record
	   filp_mode : integer;
	   filp_count : integer;
	   filp_ino : ^t_inode;
	   filp_pos : t_s32
	end;

var
   filp : array[NR_FILPS] of t_filp;
   
#define NIL_FILP 0

#endif
