#ifndef SUPER_INC
#define SUPER_INC
#include <block_rw.inc>

(*
 * Super block table.
 * Format is consistent w/16 bit machine
 * Not identical to AST1 structure because AST has some 8 bit fields
 * which will be a 16 bit word here.
 * 
 * The minix super_block is 18 BYTES on disk.
 *)

type
   (* See AST1,7971 *)
   t_super_block = record
      s_ninodes : integer;
      s_nzones  : integer;
      s_imap_blocks : integer;
      s_zmap_blocks : integer;
      s_firstdatazone : integer;
      s_log_zone_size : integer;
      s_max_size : array[2] of integer;
      s_magic : integer; (* This IS  a 16 bit val AST1, 7979 *)
      (* Fields for in-mem use only *)
      s_imap : array[I_MAP_SLOTS] of ^t_buf;
      s_zmap : array[ZMAP_SLOTS] of ^t_buf;
      s_dev : integer;
      s_isup : ^t_inode;
      s_imount : ^t_inode;
      s_rd_only : integer;
      s_dirt : integer
   end;

#define NIL_SUPER 0

var
   super_block : array[NR_SUPERS] of t_super_block;
   
procedure copy_super_from_block(src : ^integer, sp : ^t_super_block);

begin
   copy_16_from_block(src     , adr(sp^.s_ninodes));
   copy_16_from_block(src +  2, adr(sp^.s_nzones));
   copy_16_from_block(src +  4, adr(sp^.s_imap_blocks));
   copy_16_from_block(src +  6, adr(sp^.s_zmap_blocks));
   copy_16_from_block(src +  8, adr(sp^.s_firstdatazone));
   copy_16_from_block(src + 10, adr(sp^.s_log_zone_size));
   copy_32_from_block(src + 12, adr(sp^.s_max_size));
   copy_16_from_block(src + 16, adr(sp^.s_magic))
end;



#endif