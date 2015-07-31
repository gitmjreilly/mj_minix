#ifndef TYPE_INC
#define TYPE_INC

type 
(*
 * Directory entries (AST1, 8002) are EXACTLY 16 bytes in mem and on disk.
 * 14 bytes for the name and 2 bytes (treated as one unsigned int) for the inode.
 * 
 * The mem representation here will occupy 16 (16 bit) words in mem, but 16 bytes on disk.
 *    2 word for the inode number
 *   14 words for the name
 *
 * This means the 16 bit inode number will be split across two 16bit words.
 * The actual inode number is :
 *    inode_num = (d_inum_hi AND $00FF) * 256  + (d_inum_low AND $00FF)
 *
 *)
   dir_struct = record
      d_inum_lo : integer;
      d_inum_hi : integer;
      d_name : array[NAME_SIZE] of integer
   end;

(*
 * Based on AST1, 8008
 * AST1, p304 says an INODE is exactly 32 bytes on disk
 * Here it will be 32 bytes on disk but more (17 words)  in RAM
 * because some of the 8 bit fields are extended to 16 bits 
 * because there are no 8 bit values in this language.
 *)
 (*
  * TODO figure out if this is still used.
  * as of oct 19, 2013 it does not appear to be in use
  * the code in inode_c.inc takes care of copying inode to/from disk.
  *)

type 
   OLD_d_inode = record
      i_mode : integer;
      uid : integer; 
      (* 
       * i_size was a 32 bit word in AST1.  Since this language only
       * has integers, the 32 bit val has to be created with 2 integers.
       *)
      i_size : array[2] of integer;
      (* 
       * i_mod_time was a 32 bit word in AST1.  Since this language only
       * has integers, the 32 bit val has to be created with 2 integers.
       *)
      i_mod_time : array[2] of integer;
      (*
       * Is only 8 bits in AST1, but will occupy 1 16 bit word in RAM
       *)
      i_gid : integer; 
      (*
       * Is only 8 bits in AST1, but will occupy 1 16 bit word in RAM
       *)
      i_nlinks : integer; (* only 8 bits on disk *)
      i_zone : array[9] of integer
   end;

   
#endif