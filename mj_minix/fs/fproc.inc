#ifndef FPROC_INC
#define FPROC_INC

(*
 * based on fproc.h AST1,7750
 *)

type
   t_fproc = record
      fp_workdir : ^t_inode;
      fp_rootdir : ^t_inode;
      fp_filp : array[NR_FDS] of ^t_filp;
      fs_tty : integer;
      fp_task : integer
   end;


var
   fproc : array[NR_PROCS] of t_fproc;



#endif