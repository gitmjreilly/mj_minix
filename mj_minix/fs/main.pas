#include <runtime.pas>
#include <k_userio.inc>
#include <block_rw.inc>


(*
 * Main program for file system.  Based on AST1,8950.
 *)

#include "../h/const.inc"
#include "../h/callnr.inc"
#include "../h/type.inc"
(* #include "../h/callnr.inc" *)
#include "../h/com.inc"
#include "../h/error.inc" 
#include "../h/sta.inc"

#include <term_colors.inc>
#include <math_32.inc>
#include <sendrec.inc>

#define FS_COLOR ANSI_CYAN
#define INODE_COLOR ANSI_YELLOW
#define MAP_COLOR ANSI_GREEN
#define BLOCK_COLOR ANSI_BLUE
#define RW_COLOR ANSI_RED

#include "const.inc"
#include "type.inc"
#include "param.inc"
#include "buf.inc"
#include "fproc.inc"
#include "glo.inc"
#include "super.inc"
#include "inode.inc"

(* New special include to remove circular dependency on get_super *)
#include "get_super.inc"


(* Does utility have to come after read.inc b/c of call t rw_user() ?? *)
(*
 * utility needs read
 * read needs cache
 * cache needs get_super *)
#include "cache.inc"
#include "filedes.inc"

#include "rip_map_local.inc"
#include "read.inc"
#include "write.inc"
#include "utility.inc"


#include "link.inc"
#include "inode_c.inc"
#include "super_c.inc"

#include "misc.inc"

(* #include "write.inc" *)


#include "path.inc"
#include "protect.inc"
#include "stadir.inc"
#include "open.inc"


var
  x : integer;



(*====================================*)
(* Initialize the fs buffer pool.  AST1, 9107
   ASTs code does a lot of work ensuring blocks do not 
   cross a 64K boundary so DMA will work.
   Theres no such issue here.
   More important, all of the processes on my cpu are maxed (code and data)
   at 64k.  THIS MAY BE A PROBLEM DOWN THE LINE (wrote on 21 April 2013 -
   Lets see how fast I regret this...)

   Globals can be found in buf.inc.
*)
procedure buf_pool();
var
   i : integer,
   buf_num : integer,
   buf_hash_num : integer;

begin
   bufs_in_use := 0;
   front := ADR(buf[0]);
   rear :=  ADR(buf[NR_BUFS - 1]);

   buf_num := 0;
   while (buf_num < NR_BUFS) do begin
      buf[buf_num].b_blocknr := NO_BLOCK;
      buf[buf_num].b_dev := NO_DEV;
      buf[buf_num].b_next := adr(buf[buf_num + 1]);
      buf[buf_num].b_prev := adr(buf[buf_num - 1]);
      buf_num := buf_num + 1
   end;
   buf[0].b_prev := NIL_BUF;
   buf[NR_BUFS - 1].b_next := NIL_BUF;

   (* AST1, p616 had a lot of code dealing with buffers crossing 64k boundaries
      No need here.
   *)
   (* Theres a subtle thing going on here.
    * All of the buffers are put onto a single hash list.
    * The reason is there is other code (like get_block() which
    * expects EVERY buffer to be on a hash list.
    * get_block() when it finds an empty block first removes it from the hash list...
    *)
   buf_num := 0;
   while (buf_num < NR_BUFS) do begin
      buf[buf_num].b_hash := buf[buf_num].b_next;
      buf_num := buf_num + 1
   end;

   buf_hash[NO_BLOCK AND (NR_BUF_HASH -1)] := front;
   
   (*
    * This is new code; not part of AST1
    * get_block() searches the hash list, but the entries other
    * than the first were not initialized!
    *)
    i := 1;
    while i < (NR_BUF_HASH) do begin
      buf_hash[i] := NIL_BUF;
      i := i + 1
   end
   
end;
(*====================================*)





(*====================================*)
(* 
 * fs_init() based on AST1 9069
 *)
procedure fs_init();
var
   rip : ^t_inode,
   j : integer,
   i : integer;

begin
   k_cpr(FS_COLOR, "Entered fs_init"); k_prln(1);
   
   (* Do fancy Jamet casting.  See notebook 16 Sep 2013
    * We use pointers to cast message to correct type.
    * #defines in param.inc give nice names to ASTs fields.
    *)
   
   m3_in := adr(in_msg);
   m1_in := adr(in_msg);
   m2_in := adr(in_msg);
   
   (* The reply message is of type mess_1 
    * See AST1,7942
    *)
   m1_out := adr(out_msg);
   m2_out := adr(out_msg);
   
   buf_pool();
   (* load_ram loads a ram disk with root fs
    * This will not be done in this implementation.
    *
    * load_ram()
    *)
   k_cpr(FS_COLOR, "Checking buffer cache after buf_pool()"); k_prln(1);
   check_buffer_cache();
   load_super();

   (* Init fproc for procs 0 and 2 
    * mm = 0
    * fs = 1
    * init = 2
    *)
    (* fp is global - see fs/glo.inc *)
   i := 0;
   (*
    * NR_PROCS is used here to preload table until dynamic procs are in place.
    * TODO: only init dirs for mm and fs, not whole table
    *)
   while (i < NR_PROCS) do begin
      fp := adr(fproc[i]);
      rip := get_inode(ROOT_DEV, ROOT_INODE);
      fp^.fp_rootdir := rip;
      dup_inode(rip);
      fp^.fp_workdir := rip;
      (* TODO Add remainder of fproc fields *)
      j := 0;
      while j < NR_FDS do begin
         fp^.fp_filp[j] := NIL_FILP;
         j := j + 1
      end;

      i := i + 1

   end;
   (* open.inc has a global which needs to be initialized
    * See ast1,9474 for details...
    *)
   init_open();
   init_filp();
   k_cpr(FS_COLOR, "Leaving fs_init"); k_prln(1)

end;
(*====================================*)

(*====================================*)
(* 
 * fs_init() based on AST1 9069
 * Sets reply_type which is defined in param.inc as m1_out^.m_type
 * and m1 points to out_msg
 *)
procedure reply(whom : integer, result : integer);


begin
   k_cpr(FS_COLOR, "Entered reply"); k_prln(1);
   k_cpr(FS_COLOR, "  result is : "); k_prnum(result); k_prln(1);
   reply_type := result;
   send_p(whom, adr(out_msg));
   k_cpr(FS_COLOR, "leaving reply"); k_prln(1)
end;   
(*=================================================================*)





(*=================================================================*)
(* get_work based on AST1,9016
 * dev_status:WIP
 * Gets basic system calls; does not handle pipes or read aheads.
 *)
procedure get_work();
begin
   (* Wait for a request *)
   (* format is func, src_dest, m_ptr SYSCALL *)
   (* SEND = 1; RECV = 2 *)
   k_cpr(FS_COLOR, "  FS: Waiting to receive a message in get_work..."); k_prln(1);
   receive_p(ANY, adr(in_msg));
	k_cpr(FS_COLOR, "  FS: got a message"); k_prln(1);
   who := in_msg.m_source;
   fs_call := in_msg.m_type;
   k_cpr(FS_COLOR, "The type is : "); k_cpr_hex_num(FS_COLOR, in_msg.m_type); k_prln(1)
end;
(*=================================================================*)


(*====================================*)
var
   (* process number on whose behalf this request is being made.
    * This is NOT necessarily the process making the request
    * which is captured in the m_source field of the recvd message.
    *)
   proc_nr : integer, 
 
   (* process number of the actual caller *)
   caller : integer,
   (* number of bytes to transfer; each byte occupies a word in ram *)
   count : integer,

   (* Return status of this task to the caller *)
   return_status : integer,


   tmp_str : array[20] of integer,
   (* error is the system call function return value. *)
   error : integer,
   counter : ^integer;
   
guard;   
var  
   p_stack : array[800] of integer;
guard;

guard;   
var
   r_stack : array[50] of integer;
guard;
   
   
   
(* MAIN Program *)
begin
   asm
      p_stack SP_STORE
      r_stack RP_STORE
   end;
   
   k_cpr(FS_COLOR, "FS is starting now..."); k_prln(1);

   fs_init();
   (* TODO remove the pointers below *)
   (* p := adr(disk_mess); *)
   (* reply_ptr := adr(disk_mess); *)

   k_cpr(FS_COLOR, "FS is starting main loop..."); k_prln(1);

   while (1) do begin
      get_work();
      fp := adr(fproc[who]);
      if (fs_call = 3) then begin
         error := do_read();
         k_cpr(FS_COLOR, "error return from do_read is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 4) then begin
         error := do_write();
         k_cpr(FS_COLOR, "error return from do_write is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 5) then begin
         error := do_open();
         k_cpr(FS_COLOR, "error return from do_open is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 6) then begin
         error := do_close();
         k_cpr(FS_COLOR, "error return from do_close is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 8) then begin
         error := do_creat();
         k_cpr(FS_COLOR, "error return from do_close is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 12) then begin
         error := do_chdir();
         k_cpr(FS_COLOR, "error return from do_chdir is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 36) then begin
         error := do_sync();
         k_cpr(FS_COLOR, "error return from do_sync is : "); k_prnum(error); k_prln(1)
      end
      else if (fs_call = 15) then 
         do_chmod()
      else if (fs_call = 18) then 
         error := do_stat()
      else if (fs_call = 19) then 
         error := do_lseek()
      else begin
         k_cpr(FS_COLOR, " Unknown system call! : "); k_prnum(fs_call); k_prln(1)
      end;

      reply(who, error)
   end


end.
