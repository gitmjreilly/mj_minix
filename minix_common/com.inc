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

#define FLOPPY -5
#  define DISK_READ 3
#  define DISK_WRITE 4


#define TTY -7
#define PTY -8
#  define TTY_CHAR_INT 1
#  define   PTY_CHAR_INT  1
#  define   PTY_O_DONE  2
#  define   PTY_READ 3
#  define   PTY_WRITE  4
#  define   PTY_IOCTL  5
#  define   PTY_INT  6

   
#define SRC_SPACE m5c1
#define SRC_PROC_NR m5i1
#define SRC_BUFFER m5l1
#define DST_SPACE m5c2
#define DST_PROC_NR m5i2
#define DST_BUFFER m5l2
#define COPY_BYTES m5l3   


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