#ifndef COM_INC_INCLUDED
#define COM_INC_INCLUDED
(*
 * This file is the analog of h/com.h (line 150)
 *)

#define SEND 1
#define RECEIVE 2
#define BOTH 3
#define ANY 1024

#define SYSTASK -2
#  define SYS_COPY 6


(*
 * Task numbers...
 * Dont know where Tanenbaum keeps this info...
 *)
const
   HARDWARE = -1,
   CLOCK = -3,
   MEM = -4,
   FLOPPY = -5,
   WINCHESTER = -6,
   TTY = -7,
   PTY = -8,
   HW_TASK_NUM = 90;

const
   (* 
    * m_types for block_messages; Tanenbaum line 185 
    * m_type is a field in messages
    * Numbers have to be consistent with those used by
    * the tty/pty(jamet) driver
    *)
   DISK_INT = 1,
   DISK_READ = 3,
   DISK_WRITE = 4,
   DISK_IOCTL = 5;

const
   (* 
    * m_types for tty messages 
    * m_type is a field in messages
    * Numbers have to be consistent with those used by
    * the tty/pty(jamet) driver
    *)
   TTY_CHAR_INT = 1,
   TTY_O_DONE = 2,
   TTY_READ = 3,
   TTY_WRITE = 4,
   TTY_IOCTL = 5;

const
   (* 
    * m_types for tty (and Jamet PTY) messages 
    * m_type is a field in messages
    * Numbers have to be consistent with those used by
    * the tty/pty(jamet) driver (at least for r/w).
    * PTY_INT is here because the Wiznet can 
    * generate an INT for many reasons and PTY will have to
    * do the work to figure out wy.
    *)
   PTY_CHAR_INT = 1,
   PTY_O_DONE = 2,
   PTY_READ = 3,
   PTY_WRITE = 4,
   PTY_IOCTL = 5,
   PTY_INT = 6;

   
#define SRC_SPACE m5c1
#define SRC_PROC_NR m5i1
#define SRC_BUFFER m5l1
#define DST_SPACE m5c2
#define DST_PROC_NR m5i2
#define DST_BUFFER m5l2
#define COPY_BYTES m5l3   

(* Tanenbaum named message fields using #define 
 * I will create new message types and use pointers to them.
 *)

(*
 * Jamets basic block.  Messages will be of this type.
 * From Tanenbaum (loosely) line 554.
 *)
const
   MESS_SIZE=20;

type
   message = record 
      m_source : integer;
      m_type : integer;
      block : array[18] of integer
   end;

(* This is the msg pty task will recv when m_type = PTY_READ *)
type
   t_pty_read_message = record 
      m_source : integer;
      m_type : integer;
      DEVICE : integer;
      PROC_NR : integer;
      COUNT : integer;
      POSITION : array[2] of integer; 
      ADDRESS : ^integer
   end;

(* This is the msg pty task will recv when m_type = PTY_WRITE *)
type
   t_pty_write_message = record 
      m_source : integer;
      m_type : integer;
      DEVICE : integer;
      PROC_NR : integer;
      COUNT : integer;
      POSITION : array[2] of integer; 
      ADDRESS : ^integer
   end;


(* This is the msg pty task will recv when m_type = PTY_INT *)
type
   t_pty_int_message = record 
      m_source : integer;
      m_type : integer
   end;

(* This is the msg pty task will reply with *)
type
   t_pty_reply_message = record 
      m_source : integer;
      m_type : integer;
      REP_PROC_NR : integer;
      REP_STATUS : integer;
      PTY_FLAGS : integer;
      PTY_SPEK : integer
   end;

type
   block_message = record (* See Tanenbaum line 206 *)
      m_source : integer;
      m_type : integer;
      DEVICE : integer;
      PROC_NR : integer;
      COUNT : integer;
      POSITION : array[2] of integer; 
      ADDRESS : ^integer
   end;

type
   (* TODO 
    * These message types are getting confusing!
    * Reconcile messages
    *)
   pty_message = record (* See Tanenbaum line 213 *)
      m_source : integer;
      m_type : integer;
      REP_PROC_NR : integer;
      REP_STATUS : integer;
      PTY_LINE : integer;
      PTY_REQUEST : integer;
      PTY_SPEK : integer;
      PTY_FLAGS : integer
   end;

type
   reply_message = record (* See Tanenbaum line 219 *)
      m_source : integer;
      m_type : integer;
      REP_PROC_NR : integer;
      REP_STATUS : integer 
   end;

#endif