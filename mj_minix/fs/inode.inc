#ifndef INODE_INC
#define INODE_INC

(*


 * This file is the based on fs/inode.h, AST1, 7850
 *)



type
   (* Part of an inode is on disk
    * Part is only in mem.
    * The on disk part occupies 32 bytes.
    *)
   t_inode = record
      i_mode : integer;
      i_uid : integer;
      i_size : array[2] of integer;
      i_modtime : array[2] of integer;
      i_gid : integer;
      i_nlinks : integer;
      i_zone : array[NR_ZONE_NUMS] of integer;
      (* In mem portion only... *)
      i_dev : integer;
      i_num : integer;
      i_count : integer;
      i_dirt : integer;
      i_pipe : integer;
      i_mount : integer;
      i_seek : integer
   end;
   
var
   inode : array[NR_INODES] of t_inode;

#define NIL_INODE 0

#define NO_PIPE 0
#define I_PIPE  1
#define NO_MOUNT 0
#define I_MOUNT 1
#define NO_SEEK 0
#define I_SEEK 1

  
#endif