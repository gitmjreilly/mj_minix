#ifndef BUF_INC
#define BUF_INC
(*
 * This file is the analog of fs/buf.h, AST1, 7550
 * Lots of changes required here.
 * AST uses unions which this language does not have.
 * Also, there is the problem of wanting to maintaining disk format
 * compatibility (so all of the existing Linux tools can be used to create
 * mount, and check filesystems.
 * Some things which are bytes on disk will end up being 16b words in mem.
 *)

(*
 * These 5 types are all of the forms the data can take inside a block
 *)
(*
type
   t_b__data = array [1024] of integer;


type
   t_b__ind = array [512] of integer;

type
   t_b__inode = array [32] of integer;

type
   t_b__int = array [512] of integer;
*)


type
   t_b__dir = array [64] of dir_struct;


type
   (*
    * This is an element of the block cache.
      AST1 has a union for the data portion.
      Right now, all I have is the raw data as 1024 words.
      Only the LSB of those words will be read from or written to disk.
    *)
   t_buf = record
      b__data : array [1024] of integer;
      b_next : ^t_buf;
      b_prev : ^t_buf;
      b_hash : ^t_buf;
      b_blocknr : integer;
      b_dev : integer; (* major | minor *)
      b_dirt : integer;
      b_count : integer
   end;

const
   NIL_BUF = 0;

var
   buf : array [NR_BUFS] of t_buf;

var
   buf_hash : array[NR_BUF_HASH] of ^t_buf,
   front : ^t_buf,
   rear : ^t_buf;


var
   (*
    * Global count of number of disk block buffers currently in use.
    *)
   bufs_in_use : integer;


const WRITE_IMMED = $0100;
const ONE_SHOT    = $0200;

const INODE_BLOCK      = (* 0 + WRITE_IMMED *) $0100;
const DIRECTORY_BLOCK = (* 1 + WRITE_IMMED *) $0101;
const INDIRECT_BLOCK  = (* 2 + WRITE_IMMED *) $0102;

const I_MAP_BLOCK      = (* 3 + WRITE_IMMED + ONE_SHOT *) $0303;
const ZMAP_BLOCK       = (* 4 + WRITE_IMMED + ONE_SHOT *) $0304;
const ZUPER_BLOCK      = (* 5 + WRITE_IMMED + ONE_SHOT *) $0305;

const FULL_DATA_BLOCK  = 6;
const PARTIAL_DATA_BLOCK  = 7;

#endif
