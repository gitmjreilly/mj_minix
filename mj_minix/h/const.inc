#ifndef H_CONST_INC
#define H_CONST_INC
(*
 * This file is the analog of h/const.h (line 0)
 * In Tanenbaums C version this file contains all of
 *)

const
   IDLE = -999; (* Tanenbaum, line 687 *)

const 
   BLOCK_SIZE = 1024;

(* "TASKS" aka drivers all have negative process numbers
 * but langauge only allows for positive array indices
 * so the process nums are offset by NR_TASKS.
 * see func proc_addr for an example.
 *)
const
    NR_TASKS  = 8;


#define T 0
#define D 1
#define S 2

#define NR_PROCS 16

(* Stuff related to queue managment *)
(*
 * Added low prio que for testing with disabled interrupts 
 *)
const
    NQ = 3,
    TASK_Q = 0,
    SERVER_Q = 1,
    USER_Q = 2;

#define MM_PROC_NR 0
#define FS_PROC_NR 1
#define INIT_PROC_NR 2
#define LOW_USER 2

#define BYTE $00FF
#define TO_USER 0
#define FROM_USER 2    
    
(* READING and WRITING are used in lots of places... *)
const
   READING = 0,
   WRITING = 1;

const
   (* 
    * device info consists of 8:8 - major, minor
    * ROOT is (1,0)
    *)
   ROOT_DEV = 256;

 #define MAX_PATH 128
   
#define NO_NUM $8000

#define I_TYPE $F000
#define I_REGULAR $8000
#define I_BLOCK_SPECIAL $6000
#define I_DIRECTORY $4000
#define ALL_MODES $DFF
#define RWX_MODES $1FF
#define R_BIT 4
#define W_BIT 2
#define X_BIT 1
#define I_NOT_ALLOC 0




#endif
