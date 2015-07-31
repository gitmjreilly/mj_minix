#ifndef FS_CONST_INC
#define FS_CONST_INC
(*
 * Based on AST1, 7500
 * DEV_STATUS:const.inc - in progress
 *)

 
 
 #define NR_ZONE_NUMS 9
 
#define NR_BUFS 10
#define NR_BUF_HASH 8
#define NR_FDS 20
#define NR_FILPS 64
#define I_MAP_SLOTS 4
#define ZMAP_SLOTS 6
#define NR_INODES 32
#define NAME_SIZE 14

#define SUPER_MAGIC $137F

#define NR_SUPERS 3

const NORMAL = 0;
const NO_READ = 1;
const NO_BIT = 0;

const LOOK_UP = 0;
const ENTER = 1;
const DELETE = 2;

const CLEAN = 0;
const DIRTY = 1;

(* Changed name from BLOCK to BLK to avoid
 * conflict with super_block array.
 *)
const BOOT_BLK = 0;
const SUPER_BLK = 1;
#define ROOT_INODE 1

(* Derived sizes - Just listed here... *)
#define INODES_PER_BLOCK 32
#define DIR_ENTRY_SIZE 16
(* #define NR_DIR_ENTRIES (1024/DIR_ENTRY_SIZE) *)
#define NR_DIR_ENTRIES 64
#define NR_DZONE_NUM (NR_ZONE_NUMS - 2)
#define NR_INDIRECTS 512
#define INODE_SIZE 32
   
#endif