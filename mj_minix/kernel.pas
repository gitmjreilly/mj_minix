#include <runtime.pas>
#include "h/const.inc"
#include "h/type.inc"
#include "h/com.inc"
#include "h/error.inc"
#include "h/callnr.inc"
#include "h/utility.inc"


(* included files not part of AST minix... *)
#include <strings.inc>
#include <term_colors.inc>
#include <k_userio.inc>
#include <sendrec.inc>

#include "disk_ctlr.inc"


const
   DISPATCH_JUMP = 62464;

const
   RX_INT_MASK           = $0001,
   CLOCK_INT_MASK        = $0002,
   TX_INT_MASK           = $0004,
   SW_INT_MASK           = $0008;



#define MINI_REC_COLOR  ANSI_RED
#define MINI_SEND_COLOR  ANSI_GREEN
#define PTY_COLOR  ANSI_YELLOW
#define HW_COLOR  ANSI_BLUE
#define SHELL_COLOR ANSI_MAGENTA
#define SHELL2_COLOR  ANSI_CYAN
#define CLOCK_COLOR  ANSI_CYAN
#define KERNEL_COLOR  ANSI_WHITE

const
   NUM_PROCESS_TABLE_ENTRIES = 100;

type
   (* Tanenbaum 757 - modified for jam cpu *)
   t_process_entry = record
      (* 9 registers necessary to restart a process *)
      ds : integer;
      cs : integer;
      es : integer;
      psp : integer;
      ptos : integer;
      pc : integer;
      flags : integer;
      rsp : integer;
      rtos : integer;

      (* 
        This is a linked list of processes wait to send to 
        this one.
      *)
      next_sender : ^t_process_entry;

      (* 
        Status of this process table entry (a bitmap):
          $0001 - waiting to receive
          $0002 - waiting to send
          $0004 - unallocated slot
      *)
      p_flags : integer;

      (* This is the slot number of the process we want to recv from. *)
      p_getfrom : integer;

      p_callerq  : ^t_process_entry;
      p_sendlink : ^t_process_entry;

      p_messbuf : t_message_ptr;

      (* ptr to next process in queue which is ready to run *)
      p_nextready  : ^t_process_entry;

      (* 
       * Tanenbaum does NOT have this.  He uses pointer arithmetic
       * to figure out what slot a pointer refers to.  This language 
       * cannot do that, so we are explicitly embedding the process_num.
       * This number can be NEGATIVE.
       * "TASKS" have negative numbers !!!
       *  
       *)
      process_num : integer
   end;


type
   t_message_ptr = ^integer;

type
   t_process_entry_ptr = ^t_process_entry;

   
var
   (* Global var to save lock state *)
   lockvar : integer,
   (* process_table : array[NUM_PROCESS_TABLE_ENTRIES] of t_process_entry, *)
   process_table : array[100] of t_process_entry,
   cur_proc : integer,
   prev_proc : integer,
   proc_ptr : ^t_process_entry,
   bill_ptr : ^t_process_entry,
   task_mess : array[10] of ^integer,
   busy_map : integer,
   tmp_proc_ptr : ^t_process_entry,
   (*
    * DEBUG TODO
    * Changed to 4 from 3
    * The idea is to have a low priority queue which will contain a single process
    * whose job is to read devices which would normally send interrupts and turn 
    * those interrupts into messages.  Normally this is what the "interrupt" procedure
    * does.
    * This change is only for testing so the whole system becomes deterministic.
    *)
   rdy_head : array [4] of t_process_entry_ptr,
   rdy_tail : array [4] of t_process_entry_ptr; (* Was in proc.h  should be NQ entries*)

var
   tmp_p : ^integer,
   UART_1_STATUS_ADDRESS : ^integer,
   UART_1_BIT_RATE_ADDRESS : ^integer,
   UART_1_DATA_ADDRESS : ^ integer,
   fake_pc : integer,
   oldPSP : integer,
   syscall_function : integer,
   m_ptr : integer,
   src_dest : integer,
   old_ds : integer,
   tmp_str : array[10] of integer;


var
   (* Memory mapped interrupt controller registers *)
   interrupt_status_ptr : ^integer,
   interrupt_mask_ptr : ^integer,
   interrupt_clear_ptr : ^integer;


var
   ir_status : integer;


guard;
var
   (* Changed to support 512 byte local var *)
   floppy_task_p_stack : array[800] of integer;
guard;

guard;
var
   floppy_task_r_stack : array[80] of integer;
guard;

var
   (* Changed to support 512 byte local var *)
   sys_task_p_stack : array[800] of integer;
guard;

guard;
var
   (* TODO determine if need a dummy word before a stack *)
   dummy_word : integer,
   sys_task_r_stack : array[80] of integer;
guard;

guard;
var
   pty_task_p_stack : array[500] of integer;
guard;

guard;
var
   pty_task_r_stack : array[100] of integer;
guard;

guard;
var
   clk_task_p_stack : array[300] of integer;
guard;

guard;
var
   clk_task_r_stack : array[100] of integer;
guard;

guard;
var
   shell_proc_p_stack : array[200] of integer;
guard;

guard;
var
   shell_proc_r_stack : array[100] of integer;
guard;

guard;
var
   shell2_proc_p_stack : array[200] of integer;
guard;

guard;
var
   shell2_proc_r_stack : array[100] of integer;
guard;

(* TODO remove *)
guard;
var
   hw_task_p_stack : array[512] of integer;
guard;

guard;
var
   hw_task_r_stack : array[100] of integer;
guard;

guard;
var
   k_stack : array[2048] of integer;
guard;

guard;
var
   k_rstack : array[1024] of integer;
guard;

var
   READY_MASK : integer,
   BUSY_MASK : integer,
   MISO_MASK: integer;




var
   big_buffer : array[512] of integer,
   DiskAddressMSW : integer,
   DiskAddressLSW : integer,
   BufPtr : ^integer,
   the_byte : integer,
   Addr0 : integer,
   Addr1 : integer,
   Addr2 : integer,
   FileName: array [13] of integer,
   DataSize: integer,
   LoadAddress: integer,
   StartAddress: integer,
   Line: array [80] of integer,
   SectorNum : integer,
   Ans: integer,
   StrLen: integer,
   FileIsPresent: integer,
   TmpNum : integer,
   slot_num : integer,
   Status: integer;


var
   debug_flag : integer;


const
   XMODEM_NAK = 21,
   XMODEM_ACK = 6,
   XMODEM_SOH = 1,
   XMODEM_EOT = 4;

var
   next_xmodem_byte_ptr : ^integer,
   xmodem_rx_started : integer,
   xmodem_packet_num : integer,
   xmodem_buffer : array[128] of integer;

(* Message to be sent by an interrupt - may need to be moved or reworked *)
var
   int_mess : message,
   hw_pty_mess : message,
   p_block_message : ^block_message;


var
   pty_int_was_seen : integer;

(* Constants to define p_flags bit mask  *)
var
   P_SLOT_FREE : integer,  (* $0001; *)
   NO_MAP      : integer,  (* $0002; *)
   SENDING     : integer,  (* $0004; *)
   RECEIVING   : integer;  (* $0008; *)


(* NIL pointer line 788 *)
var
   NIL_PROC : integer;  (* 0 *)



#####################################################################
procedure Delay(n : integer);
var i: integer;

begin

while n > 0 do begin
   n := n - 1;
   i := 1;
   while i > 0 do begin
      i := i - 1
   end
end

end;
#####################################################################

#####################################################################
procedure delay_ms(n : integer);
var i: integer;

begin

while n > 0 do begin
   n := n - 1;
   i := 20;
   while i > 0 do begin
      i := i - 1
   end
end

end;
#####################################################################


(* proc_addr - macro in Tanenbaum
 * returns a pointer a process slot given process num - which may be negative
 *)
function proc_addr(n : integer) : ^t_process_entry;
var
   p : ^t_process_entry;
begin
   p := adr(process_table[NR_TASKS + n]);
   retval(p)
end;



(*
 * lock, unlock and restore
 * In Tanenbaum, line 1567, 
 *
 * The fpga cpu does not have an instruction to save the 
 * interrupt state.  It may have to be added!
 *)
procedure lock();
begin
   (* disable ints AND save int status in "lockvar" *)
   asm 
      PUSHF
      DI
      LOCKVAR STORE
   end
end;

procedure unlock();
begin
   asm EI end
end;


procedure restore();
begin
   (* Restore int status FROM "lockvar" *)
   asm 
      LOCKVAR FETCH
      POPF
   end
end;

(*===================================================================*)
(*
 * Tanenbaum line 1319.
 * This is where the code should go to wait for an interrupt
 * which will ultimately send a message restarting some process or task.
 *
 * This code is entered when no other process is ready to run.
 *
 * Called by restart if cur_proc is IDLE
 *)
procedure idle_loop();
var
   tmp : integer;
begin
   asm EI end;
   (* Spin in a language which does not allow null statements... *)
   while (1 = 1) do tmp := tmp
end;
(*===================================================================*)




(*===================================================================*)
procedure DebugOut(ANSIColor : integer, StrPtr : t_word_ptr, DoCR : integer);
begin
   if debug_flag then begin
      TextColor(ANSIColor);
      BIOS_PrintStrToUART(0, StrPtr, DoCr)
   end
end;
(*===================================================================*)


(*===================================================================*)
procedure ConsoleOut(ANSIColor : integer, StrPtr : t_word_ptr, DoCR : integer);
begin
   TextColor(ANSIColor);
   BIOS_PrintStrToUART(0, StrPtr, DoCr)
end;
(*===================================================================*)

#####################################################################
procedure BIOS_GetArgV(Ptr : t_word_ptr);
begin
   Ptr^ := adr(ArgV)
end;
#####################################################################


(*---------------------------------------------------------------------------*)
(*
 * Figure out which process to run next.
 * pick_proc will select a process from the head of the highest priority queue.
 *
 * The queues are not altered.
 *
 * pick_proc will assign to globals:   
 *     cur_proc and proc_ptr
 * 
 * which will then be used by restart to activate a process.
 * If no process is ready, pick_proc will just spin.
 *
 * Eventually an interrupt should cause a process to become ready
 * which means interrupts must be enabled before pick_proc is invoked.
 * If an interrupt is needed to cause pick_proc to exit then we must be certain
 * pick_proc s state can be saved somewhere.
 *
 * Called at end of interrupt(), line 1878
 * Called in unready, line 2168
 * Called in sched, line 2204
 *)
procedure pick_proc();

var
   x : integer,
   q : integer,
   tmp_str : array[10] of integer;

begin
   if debug_flag then begin
      k_cpr(KERNEL_COLOR, "Entered pick_proc; cur proc on entry is : "); 
      k_cpr_hex_num(KERNEL_COLOR, cur_proc); k_prln(1)      
   end;

   (* 
    * Search ALL of the process queues from highest prio to lowest.
    *)
   if rdy_head[TASK_Q] <> NIL_PROC then
      q := TASK_Q
   else if rdy_head[SERVER_Q] <> NIL_PROC then
      q := SERVER_Q
   else 
      q := USER_Q;
   
   x := q; (* simulator test point*)

   
   if debug_flag > 1 then  begin
      DebugOut(KERNEL_COLOR, "  q with ready task is  : ", 0);
      BIOS_NumToHexStr(q, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);

      DebugOut(KERNEL_COLOR, " Message below should show selected Q", 1);
      if rdy_head[TASK_Q] <> NIL_PROC then
         DebugOut(KERNEL_COLOR, "  selected TASK_Q", 1)
      else if rdy_head[SERVER_Q] <> NIL_PROC then
         DebugOut(KERNEL_COLOR, "  selected SERVER_Q", 1)
      else if rdy_head[USER_Q] <> NIL_PROC then
         DebugOut(KERNEL_COLOR, "  selected USER_Q", 1)
   end;
   
   prev_proc := cur_proc;
   if rdy_head[q] <> NIL_PROC then begin (* Some proc must be runnable *)
      (* Tanenbaum wants negative process numbers which he got with ptr arithmetic.
       * In this (Jamet) implementation process nums are stored in 
       * the process table.
       *)
      cur_proc := rdy_head[q]^.process_num;
      proc_ptr := rdy_head[q];
      if (cur_proc >= LOW_USER) then bill_ptr := proc_ptr;

      if debug_flag = 1 then begin
         DebugOut(KERNEL_COLOR, "   found runnable proc: ", 0);
         BIOS_NumToHexStr(cur_proc,  adr(tmp_str)); 
         DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
      end
   end
   else begin
      cur_proc := IDLE;
      proc_ptr := proc_addr(HARDWARE);
      bill_ptr := proc_ptr
   end;
   
   x := cur_proc; (* simulator test point*)

   if debug_flag then begin
      k_cpr(KERNEL_COLOR, "Leaving pick_proc; cur proc on entry is : "); 
      k_cpr_hex_num(KERNEL_COLOR, cur_proc); k_prln(1)      
   end
end;
(*---------------------------------------------------------------------------*)


(*---------------------------------------------------------------------------*)
(* ready - Tanenbaum 2122
 *
 * Add process described by rp to one of the appropriate queues.
 * The queue is determined by rps process number.
 *)
procedure ready(rp : t_process_entry_ptr);

var
   tmp_str : array[20] of integer,
   r : integer,
   q : integer;

begin
   lock();

   if debug_flag >= 1 then begin
      DebugOut(KERNEL_COLOR, "Entered ready", 1)
   end;

   (* Tanenbaum uses ptr arithmetic to get process number.
    * This language does not support C style pointer arithmetic
    * so we have resorted to storing the process number as part
    * of the process table entry.
    *)
   r := rp^.process_num;

   if debug_flag >= 1 then begin
      DebugOut(KERNEL_COLOR, "   proc_num of process being made ready : " , 0);
      BIOS_NumToHexStr(r,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;

   if r < 0 then  begin
      q := TASK_Q;
      DebugOut(KERNEL_COLOR, "   q is TASK", 1)
   end
   else if r < LOW_USER then begin
      q := SERVER_Q;
      DebugOut(KERNEL_COLOR, "   q is SERVER", 1)
   end
   else begin (* None of the other queues?  Default to LOW_Q. *)
      q := USER_Q;
      DebugOut(KERNEL_COLOR, "   q is USER ", 1)
   end;
   
   (* Put rp at the tail of its queue. *)
   if rdy_head[q] = NIL_PROC then
      rdy_head[q] := rp
   else 
      rdy_tail[q]^.p_nextready := rp;

   rdy_tail[q] := rp;

   rp^.p_nextready := NIL_PROC;

   restore();



   if debug_flag >= 1 then begin
      DebugOut(KERNEL_COLOR, "Leaving ready", 1)
   end

end;
(*===================================================================*)

(*===================================================================*)
(*
 * called by mini_send when a message cant be sent.
 * called by mini_rec when a message cant be received.
 *)
procedure unready(rp : t_process_entry_ptr);

var 
  r : integer,
  q : integer,
  xp : t_process_entry_ptr;

begin
   if debug_flag >= 1 then begin
      DebugOut(KERNEL_COLOR, "Entered unready", 1)
   end;

   lock();

   (* 
    * Figure out which queue rp is on.
    * Tanenbaum uses ptr arithmetic to get process number
    * We have resorted to storing the process number as part
    * of the process table entry.
    *)
   r := rp^.process_num;

   if debug_flag >= 1 then begin
      BIOS_NumToHexStr(r,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, "  Proc being marked unready is : ", 0);
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;

   if r < 0 then 
      q := TASK_Q
   else if r < LOW_USER then
      q := SERVER_Q
   else 
      q := USER_Q;

   if debug_flag > 1 then begin
      BIOS_NumToHexStr(q,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, "  Its q is :  ", 0);
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;

   xp := rdy_head[q];
   if xp = NIL_PROC then begin 
      DebugOut(KERNEL_COLOR, "  The head ptr for this q is empty.  Returning...", 1);
      return
   end;

   (* 
    * Check to see if the process described by rp is at the
    * head of its appropriate queue.  If so, remove it from 
    * queue and designate a new process as ready to run.
    *)
   if xp = rp then begin
      if debug_flag > 1 then
         DebugOut(KERNEL_COLOR, "  This proc is at head of its q.  Rm-ing it...", 1);
      rdy_head[q] := xp^.p_nextready;
          
      pick_proc()
   end
   (* If weve gotten this far, we are making a process "unready"
    * which is NOT the currently running process.  This could happen
    * if a signal is sent.
    *)
   else begin
      if debug_flag > 1 then
         DebugOut(KERNEL_COLOR, "  This proc is NOT at head of its q.  Rm-ing it...", 1);
      while xp^.p_nextready <> rp do begin
         xp := xp^.p_nextready;
         if xp = NIL_PROC then return
      end;

      xp^.p_nextready := xp^.p_nextready^.p_nextready;

      while xp^.p_nextready <> NIL_PROC do 
         xp := xp^.p_nextready;
      
      rdy_tail[q] := xp
   end;

   restore();

   if debug_flag >= 1 then begin
      DebugOut(KERNEL_COLOR, "Leaving unready", 1)
   end

end;
(*===================================================================*)


(*===================================================================*)
(* sched AST1, 2186
 * Called by do_clocktick() AST1,3243 which is part of the CLOCK task
 * sched() is called when a USER process has used its quantum.
 * 
 * sched() and pick_proc() are NOT the same.
 * sched() adjusts the USER Q moving the head proc to the tail.
 * pick_proc() selects the highest prio proc from the highest prio Q.
 *)
procedure sched();


begin
   lock();

   if rdy_head[USER_Q] = NIL_PROC then begin
      (* ConsoleOut(CLOCK_COLOR, "   USERQ is empty; returning...", 1); *)
      restore();
      return
   end;

   (* If we got this far, at least 1 user proc is queued. 
    * Put the currently active user proc at the end of the queue.
    *)
   rdy_tail[USER_Q]^.p_nextready := rdy_head[USER_Q];   
   rdy_tail[USER_Q] := rdy_head[USER_Q];   
   rdy_head[USER_Q] := rdy_head[USER_Q]^.p_nextready;
   rdy_tail[USER_Q]^.p_nextready := NIL_PROC;
   pick_proc();
   restore()

end;
(*==================================================================*)

(*==================================================================*)
(*
 * load_task
 * load a task into the process table
 * The task code is part of the kernel address space and thus
 * has access to kernel structures like the process table.
 *
 * We accept a LOGICAL process number. It is converted to a 
 * process table index by function proc_addr();
 * Processes with negative process numbers are considered tasks and 
 * will be placed on the TASK_Q by ready().
 *)
procedure load_task(
   start_address : t_word_ptr,
   p_stack_address : t_word_ptr,
   r_stack_address : t_word_ptr,
   proc_num : integer);
  
var
   proc_ptr : ^t_process_entry,
   tmp_str : array[20] of integer,
   seg_val : integer;

begin

   if debug_flag then begin
      DebugOut(KERNEL_COLOR, "Entering load_task", 1);

      DebugOut(KERNEL_COLOR, "  start_address is : ", 0);
      BIOS_NumToHexStr(start_address,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "  PSP              : ", 0);
      BIOS_NumToHexStr(p_stack_address,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "  RSP              : ", 0);
      BIOS_NumToHexStr(r_stack_address,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "  proc_num is      : ", 0);
      BIOS_NumToHexStr(proc_num,  adr(tmp_str)); 
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;
   
   proc_ptr :=  proc_addr(proc_num);

   if proc_ptr^.p_flags AND P_SLOT_FREE <> P_SLOT_FREE then begin
      DebugOut(KERNEL_COLOR, "This proc_num is already in use!  Try again.", 1);
      return
   end;

   proc_ptr^.ds := 0;
   proc_ptr^.cs := 0;
   proc_ptr^.es := 0;
   proc_ptr^.psp := p_stack_address;
   proc_ptr^.rsp := r_stack_address;
   proc_ptr^.ptos := 0;
   proc_ptr^.rtos := 0;
   proc_ptr^.pc := start_address;
   (* Notice flags are 1 to enable interrupts! *)
   proc_ptr^.flags := 1;
   proc_ptr^.p_nextready := NIL_PROC;

   DebugOut(KERNEL_COLOR, "  Marking task ready", 1);
   ready(proc_ptr);

   DebugOut(KERNEL_COLOR, "Setting p_flags to 0.", 1);
   proc_ptr^.p_flags := 0;

   DebugOut(KERNEL_COLOR, "Leaving load_task", 1)

end;
#####################################################################


(*-----------------------------------------------------------------*) 
(*
 * The format should be the special simulator format
 * The format is BINARY
 * Each word comes as 2 bytes MSB first
 *    word 1     :  Words 1 and 2 are a MAGIC identifier 0000 0002
 *    word 2  
 *    word 3     : size of program in words
 *    word 4     : loading address
 *    word 5     : starting address
 *    words 6-n  : 3 * size in bytes (as shown below)
 *       byte - type (guard, data, code)
 *       byte - MSB of data val
 *       byte - LSB of data val *)
procedure load_hex_sim_header(
   filename_ptr : ^integer,
   program_size_ptr : ^integer, 
   load_address_ptr : ^integer, 
   start_address_ptr : ^integer, 
   proc_num : integer,
   status_ptr : ^integer);
  
var
   word1 : integer,
   word2 : integer,
   VersionNum: integer,
   size : integer,
   Tmp: integer,
   proc_ptr : ^t_process_entry,
   TmpStr : array[50] of integer,
   WordCount: integer,
   seg_val : integer,
   magic : integer,
   stat : integer,
   BufPtr: t_word_ptr;

   
begin
   seg_val := proc_num  * $1000;
   SetES(seg_val);

   proc_ptr :=  proc_addr(proc_num);

   if proc_ptr^.p_flags AND P_SLOT_FREE <> P_SLOT_FREE then begin
      k_pr("This slot is already in use!  Try again."); k_prln(1);
      return
   end;
   proc_ptr^.p_flags := 0;

   ConsolePrintStr("Load Name is :", 0); ConsolePrintStr(filename_ptr, 1); k_prln(1);

   disk_ctlr_open_file(filename_ptr, adr(stat));
   if (stat <> 0) then  begin
      k_pr("Could not open file; returning..."); k_prln(1);
      status_ptr^ := 1;
      return
   end;

   word1 := dc_get_file_word();
   word2 := dc_get_file_word();
   if ((word1 <> 0) OR (word2 <> 2)) then begin
      k_pr("ERROR did not see magic 0000:0002 returning...");
      return
   end;
   k_pr("Magic num has been read..."); k_prln(1);
   program_size_ptr^ := dc_get_file_word();
   load_address_ptr^ := dc_get_file_word();
   start_address_ptr^ := dc_get_file_word();
   
   disk_ctlr_close_file(adr(stat));

   proc_ptr^.ds := seg_val;
   proc_ptr^.cs := seg_val;
   proc_ptr^.es := seg_val;
   proc_ptr^.psp := $FF00;
   proc_ptr^.rsp := $FE00;
   proc_ptr^.ptos := 0;
   proc_ptr^.rtos := 0;
   proc_ptr^.pc := start_address_ptr^;
   
   ready(proc_ptr)
   
end;   
(*-----------------------------------------------------------------*) 

#####################################################################
(*
  ASCII  file format 
  Has to be ASCII to work with USBWiz

  Return 3 on bad open
  Return 1 if invalid magic number
  Return 4 is...
 
  The Load File format, in words (MSB First), is:
     0000
     0002
     SSSS  (prog size in words, excluding header)
     LLLL  (load address - NB 16 bits only)
     AAAA  (Start address - NB 16 bits only)
     program... (SSSS hex words)
 
  We accept a LOGICAL process number. It is converted to a 
  process table index by function proc_addr();

  proc_num must be >= 2
  This is because procs < 0 are considered tasks (and end up on TASK_Q)
  Tasks 0, 1 are the memory manager and file system

  Because we have so much memory on the Nexys 3, each proc will be loaded
  into a dedicated 64K segment.
  e.g. proc_num 2 will be loaded into $20000
  
 
*)
(*
procedure load_file(
   FileNamePtr : t_word_ptr, 
   program_size_ptr : ^integer, 
   load_address_ptr : ^integer, 
   start_address_ptr : ^integer, 
   proc_num : integer,
   StatusPtr : t_word_ptr);
  
var
   VersionNum: integer,
   size : integer,
   Tmp: integer,
   proc_ptr : ^t_process_entry,
   TmpStr : array[50] of integer,
   WordCount: integer,
   seg_val : integer,
   magic : integer,
   BufPtr: t_word_ptr;

begin
   seg_val := proc_num  * $1000;
   SetES(seg_val);

   proc_ptr :=  proc_addr(proc_num);

   if proc_ptr^.p_flags AND P_SLOT_FREE <> P_SLOT_FREE then begin
      ConsolePrintStr("This slot is already in use!  Try again.", 1);
      return
   end;
   
   ConsolePrintStr("Load Name is :", 0);
   ConsolePrintStr(FileNamePtr, 1);

   BIOS_OpenFile(FileNamePtr, 0, StatusPtr);
   if StatusPtr^ <> 0 then begin
      StatusPtr^ := 3;
      return
   end;
   ConsolePrintStr("File has been opened.", 1);

   Read4(adr(magic));
   if magic <> 0 then begin
      ConsolePrintStr("Did not see a magic zero in the loaded file!", 1);
      StatusPtr^ := 1;
      BIOS_CloseFile(adr(Tmp));
      return
   end;
   ConsolePrintStr("magic zero has been read.", 1);

   Read4(adr(magic));
   if magic <> 2 then begin
      ConsolePrintStr("Did not see magic 2 in the loaded file!", 1);
      StatusPtr^ := 1;
      BIOS_CloseFile(adr(Tmp));
      return
   end;
   ConsolePrintStr("Magic 2 has been read.", 1);

   Read4(program_size_ptr);
   size := program_size_ptr^;
   ConsolePrintStr("Data Size has been read.", 1);

   Read4(load_address_ptr);
   ConsolePrintStr("Load address has been read.", 1);

   Read4(start_address_ptr);
   ConsolePrintStr("Start address has been read.", 1);


   proc_ptr^.ds := seg_val;
   proc_ptr^.cs := seg_val;
   proc_ptr^.es := seg_val;
   proc_ptr^.psp := $FF00;
   proc_ptr^.rsp := $FE00;
   proc_ptr^.ptos := 0;
   proc_ptr^.rtos := 0;
   proc_ptr^.pc := start_address_ptr^;

   proc_ptr^.flags := 1;
   
   BufPtr := LoadAddress;
   while size  <> 0 do begin
      size := size - 1;

      if size AND $00FF = 0 then begin
         ConsolePrintStr("*", 0)
      end;

      Read4(adr(Tmp));
      LongStore(BufPtr, Tmp);
      BufPtr := BufPtr + 1
   end;
   ConsolePrintStr("", 1);

   BIOS_CloseFile(adr(Tmp));
   if Tmp <> 0 then begin
      StatusPtr^ := 4
   end;

   ConsoleOut(KERNEL_COLOR, "  Marking PROCESS ready", 1);
   ready(proc_ptr);

   ConsolePrintStr("Setting p_flags to 0.", 1);
   proc_ptr^.p_flags := 0;
   StatusPtr^ := 0

end;
*)
#####################################################################

#####################################################################
(*
procedure load_file_2(
   DataSizePtr : t_word_ptr, 
   LoadAddressPtr : t_word_ptr, 
   StartAddressPtr : t_word_ptr, 
   slot_num : integer,
   StatusPtr : t_word_ptr);
  
var
   VersionNum: integer,
   Tmp: integer,
   proc_ptr : ^t_process_entry,
   TmpStr : array[50] of integer,
   WordCount: integer,
   LeadingZero: integer,
   seg_val : integer,
   BufPtr: t_word_ptr;

begin
   seg_val := (slot_num + 1) * $1000;
   SetES(seg_val);
   proc_ptr := adr(process_table[slot_num]);


   if proc_ptr^.p_flags AND P_SLOT_FREE <> P_SLOT_FREE then begin
      ConsolePrintStr("This slot is already in use!  Try again.", 1);
      return
   end;

   xmodem_rx_started := 0;
   
   read4_2(adr(LeadingZero));
   if LeadingZero <> 0 then begin
      ConsolePrintStr("Did not see a leading zero in the loaded file!", 1);
      StatusPtr^ := 1;
      return
   end;

   read4_2(adr(VersionNum));
   if VersionNum <> 1 then begin
      ConsolePrintStr("Version num was not 1 .", 1);
      BIOS_NumToHexStr(VersionNum , adr(TmpStr));
      ConsolePrintStr(adr(TmpStr), 1);
      StatusPtr^ := 2;
      return
   end;

   read4_2(DataSizePtr);

   read4_2(LoadAddressPtr);

   read4_2(StartAddressPtr);

   proc_ptr^.ds := seg_val;
   proc_ptr^.cs := seg_val;
   proc_ptr^.es := seg_val;
   proc_ptr^.psp := $A000;
   proc_ptr^.rsp := $B000;
   proc_ptr^.ptos := 0;
   proc_ptr^.rtos := 0;
   proc_ptr^.pc := StartAddressPtr^;
   proc_ptr^.flags := 0;
   
   WordCount := 1;
   BufPtr := LoadAddressPtr^;
   while WordCount <= DataSizePtr^ do begin
      if WordCount AND $00FF = 0 then begin
         BIOS_NumToHexStr(WordCount, adr(tmp_str))
         ConsolePrintStr("*", 0)
      end;

      read4_2(adr(Tmp));
      LongStore(BufPtr, Tmp);
      BufPtr := BufPtr + 1;
      WordCount := WordCount + 1
   end;

   finish_xmodem_read();

   ConsolePrintStr("Setting p_flags to 0.", 1);
   proc_ptr^.p_flags := 0;
   StatusPtr^ := 0

end;
*)
#####################################################################


(* 
 * Restart the process associated with slot cur_proc and whose    
 * process table slot is pointed at by proc_ptr.
 *
 * Tanenbaum, line 1288
 *)
procedure restart();
begin

   if cur_proc = IDLE then begin
      k_cpr(HW_COLOR, "in restart cur_proc is IDLE"); k_prln(1);
      asm BRA idle_loop end
   end;

   asm DI end;


   ASM
      proc_ptr FETCH 0 + FETCH TO_R # Store DS
      proc_ptr FETCH 1 + FETCH TO_R # Store CS
      proc_ptr FETCH 2 + FETCH TO_R # Store ES
      proc_ptr FETCH 3 + FETCH TO_R # Store PSP
      proc_ptr FETCH 4 + FETCH TO_R # Store PTOS
      proc_ptr FETCH 5 + FETCH TO_R # Store PC
      proc_ptr FETCH 6 + FETCH TO_R # Store FLAGS
      proc_ptr FETCH 7 + FETCH TO_R # Store RSP
      proc_ptr FETCH 8 + FETCH TO_R # Store RTOS
   END;

   ASM
      RETI 
   END

end;
####################################################################


#####################################################################
(* 
   Save the entire state of a process.  An assembly language
   procedure probably put all of these parameters on the 
   stack.
*)
(*
procedure Save(
   PTOS : integer,
   PSP  : integer,
   RTOS : integer,
   RSP  : integer,
   CS   : integer,
   PC   : integer,
   FLAGS: integer);

begin
   proc_ptr^.ptos := PTOS;
   proc_ptr^.psp := psp;
   proc_ptr^.rtos := rtos;
   proc_ptr^.rsp := rsp;
   proc_ptr^.cs := cs;
   proc_ptr^.pc := pc;
   proc_ptr^.flags := flags
end;
*)
#####################################################################




#####################################################################
procedure cp_mess(
   caller : integer, 
   src_ds : integer, 
   src_ptr :  t_word_ptr, 
   dest_ds : integer, 
   dest_ptr : t_word_ptr);

var
   tmp : integer,
   tmp_str : array[20] of integer,
   orig_dest_ptr : integer,
   i : integer;

begin
   lock();
   if debug_flag >= 1 then begin
      ConsolePrintStr("Entered cp_mess!", 1)
   end;

   orig_dest_ptr := dest_ptr;

   i := 1;
   while i <= MESS_SIZE do begin
      SetES(src_ds);
      LongFetch(src_ptr, adr(tmp));

      SetES(dest_ds);
      LongStore(dest_ptr , tmp);

      i := i + 1;
      src_ptr := src_ptr + 1;
      dest_ptr := dest_ptr + 1
   end;

   (* Explicitly add caller to the message.
    * This way, the receiver knows who sent the message
    * which is important if the receiver received from ANY.
    *)
   if debug_flag >= 1 then begin
      ConsolePrintStr("   still in cp_mess caller is  ", 0);
      BIOS_NumToHexStr(caller, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
      ConsolePrintStr("Leaving cp_mess", 1)
   end;
   SetES(dest_ds);
   LongStore(orig_dest_ptr , caller);
   restore()

end;
(*===================================================================*)


(*===================================================================*)
(*
 * mini_send  - Tanenbaum 1971
 *)
procedure mini_send(
   caller : integer, 
   dest : integer, 
   m_ptr : t_message_ptr,
   result_ptr : t_word_ptr);

var
   tmp_str : array[10] of integer,
   is_receiving : integer,
   caller_ptr : ^t_process_entry,
   next_ptr   : ^t_process_entry,
   dest_ptr   : ^t_process_entry;

begin
   
   caller_ptr := proc_addr(caller);
   dest_ptr := proc_addr(dest);

   if debug_flag > 1 then begin
      DebugOut(MINI_SEND_COLOR, "Entered mini_send", 1);
      BIOS_NumToHexStr(caller, adr(tmp_str));
      DebugOut(MINI_SEND_COLOR, "  caller is :", 0);
      ConsolePrintStr(adr(tmp_str), 1);
      BIOS_NumToHexStr(dest, adr(tmp_str));
      DebugOut(MINI_SEND_COLOR, "  dest is :", 0);
      ConsolePrintStr(adr(tmp_str), 1)
   end;

   if dest_ptr^.p_flags AND RECEIVING = RECEIVING then begin
      if debug_flag > 1 then 
         DebugOut(MINI_SEND_COLOR, "   destination p_flags has RECEIVING set", 1);

      if dest_ptr^.p_getfrom = ANY then begin
         is_receiving := 1;
         if debug_flag > 1 then 
            DebugOut(MINI_SEND_COLOR, "     is receiving from ANY", 1)
      end
      else if dest_ptr^.p_getfrom = caller then begin
         is_receiving := 1;
         if debug_flag > 1 then 
            DebugOut(MINI_SEND_COLOR, "     is receiving specifically from the caller", 1)
      end
      else
         is_receiving := 0
   end
   else
      is_receiving := 0;

   if is_receiving = 1 then begin
      if debug_flag > 1 then begin
         DebugOut(MINI_SEND_COLOR, "   destination is waiting to receive!", 1);
         DebugOut(MINI_SEND_COLOR, "      message will be copied", 1);
         DebugOut(MINI_SEND_COLOR, "      and marked ready ", 1)
      end;

      cp_mess(caller, caller_ptr^.ds, m_ptr, dest_ptr^.ds, dest_ptr^.p_messbuf);
      dest_ptr^.p_flags := dest_ptr^.p_flags - RECEIVING;
      k_cpr(MINI_SEND_COLOR, "Clearing receiving flag ; flags are :"); k_pr_hex_num(dest_ptr^.p_flags); k_prln(1);
      if dest_ptr^.p_flags = 0 then ready(dest_ptr)
   end

   else begin (* The destination process was not waiting... *)
      if debug_flag > 1 then begin
         DebugOut(MINI_SEND_COLOR, "      No receiver we will block unless sender is H/W", 1)
      end;

      if caller = HARDWARE then begin
         DebugOut(MINI_SEND_COLOR, "      Sender is H/W; will return E_OVERRUN", 1);
         result_ptr^ := E_OVERRUN;
         return
      end;
         
      (* The destination was not waiting. *)
      caller_ptr^.p_messbuf := m_ptr;
      (* caller_ptr^.p_flags := caller_ptr^.p_flags + SENDING; *)
      caller_ptr^.p_flags := SENDING;

      (* The process is now blocked.  Now we put in on dests queue. *)
      unready(caller_ptr);

      next_ptr := dest_ptr^.p_callerq;
      if next_ptr = NIL_PROC then begin
         dest_ptr^.p_callerq := caller_ptr
      end
      else begin
         while next_ptr^.p_sendlink <> NIL_PROC do 
            next_ptr := next_ptr^.p_sendlink;

         next_ptr^.p_sendlink := caller_ptr
      end;
      caller_ptr^.p_sendlink := NIL_PROC
   end;

   result_ptr^ := OK;    

   caller := caller
end;
(*===================================================================*)


(*===================================================================*)
(*
 * mini_rec Tanenbaum 2032
 * caller is the number of the process which wants to receive.
 * src is the number of the process which should have sent a message 
 * to the caller.
 *)
procedure mini_rec(
   caller : integer, 
   src : integer, 
   m_ptr : t_message_ptr,
   result_ptr : t_word_ptr);


var
   sender       : integer,
   caller_ptr   : ^t_process_entry,
   sender_ptr   : ^t_process_entry,
   prev_ptr     : ^t_process_entry,
   tmp_str      : array[20] of integer,
   is_found     : integer;

begin
   if debug_flag > 1 then begin
      DebugOut(MINI_REC_COLOR, "Entered mini_rec", 1);

      BIOS_NumToHexStr(caller, adr(tmp_str));
      DebugOut(MINI_REC_COLOR, "   Caller (aka recvr) is                 : ", 0); 
      DebugOut(MINI_REC_COLOR, adr(tmp_str), 1);

      BIOS_NumToHexStr(src, adr(tmp_str));
      DebugOut(MINI_REC_COLOR, "   Src (possible sender) is (0400 = ANY) : ", 0); 
      DebugOut(MINI_REC_COLOR, adr(tmp_str), 1)
   end;

   caller_ptr := proc_addr(caller);

   (* 
      The caller can only recv (immediately) if another process is blocked 
      trying to send to it (rendevous principle)  If not, the caller must be blocked.
      We have to check the callers linked list of processes waiting to send
      to it.
   *)
   sender_ptr := caller_ptr^.p_callerq;

   if debug_flag > 1 then begin
      DebugOut(MINI_REC_COLOR, "Walking the sender linked list...", 1);

      BIOS_NumToHexStr(sender_ptr, adr(tmp_str));
      DebugOut(MINI_REC_COLOR, "sender_ptr is ", 0); 
      DebugOut(MINI_REC_COLOR, adr(tmp_str), 1);
      if sender_ptr = NIL_PROC then begin
         DebugOut(MINI_REC_COLOR, "   Sender list is empty!", 1)
      end
   end;

   while sender_ptr <> NIL_PROC do begin
      (* We get the sender number from the process entry. *)
      (* Tanenbaum uses pointer arithmetic.               *)
      (* Remember this number can be NEGATIVE !!!         *)
      (* It WILL be negative for TASKS !!!                *)
      sender := sender_ptr^.process_num;

      if debug_flag = 1 then begin
         BIOS_NumToHexStr(sender, adr(tmp_str));
         DebugOut(MINI_REC_COLOR, "sender is ", 0); 
         DebugOut(MINI_REC_COLOR, adr(tmp_str), 1) 
      end;

      is_found := 0;
      if (src = ANY) OR (src = sender) then is_found := 1;
     
      if is_found = 1 then begin
         if debug_flag > 1 then begin
            DebugOut(MINI_REC_COLOR, "      Found a sender", 1);
            if (src = ANY) then
               DebugOut(MINI_REC_COLOR, "      sender (from linked list)  is ANY", 1)
            else
               DebugOut(MINI_REC_COLOR, "      sender (from linked list) is src", 1)
         end;

         (* A process has already q'd a message to be recv'd *)
         cp_mess(
            sender, 
            sender_ptr^.ds, 
            sender_ptr^.p_messbuf,
            caller_ptr^.ds, 
            m_ptr);

         (* sender_ptr^.p_flags := sender_ptr^.p_flags - SENDING; *)
         (* Note that the sender is no longer sending *)
         sender_ptr^.p_flags := 0;

         if sender_ptr^.p_flags = 0 then begin
            DebugOut(MINI_REC_COLOR, "      marking the sender ready.", 1);
            ready(sender_ptr)
        end;

         if sender_ptr = caller_ptr^.p_callerq then
            caller_ptr^.p_callerq := sender_ptr^.p_sendlink
         else
            prev_ptr^.p_sendlink := sender_ptr^.p_sendlink;
  
         result_ptr^ := OK;
         if debug_flag > 1 then begin
            DebugOut(MINI_REC_COLOR, "       ### Sender was found!", 1);
            DebugOut(MINI_REC_COLOR, "       ###  about to return from mini_recv!", 1)
         end;

         return (* Break out of the while linked list walk... *)

      end; (* end of the code executed when a sender was found waiting *)
      prev_ptr := sender_ptr;
      sender_ptr := sender_ptr^.p_sendlink
   end;  (* End of the while loop, looking for a pending sender... *)
 
   if debug_flag > 1 then begin
      DebugOut(MINI_REC_COLOR, "       No sender was found .  Blocking....", 1); 
      DebugOut(MINI_REC_COLOR, "       will mark caller/receiver unready", 1)
   end;

   (* 
      If we got this far, no sender was blocked trying to 
      send to the caller(receiver), so the caller(receiver) must be blocked.
   *)
   caller_ptr^.p_getfrom := src;
   caller_ptr^.p_messbuf := m_ptr;
   caller_ptr^.p_flags := caller_ptr^.p_flags + RECEIVING;
   unready(caller_ptr);

   (* TODO  Memory manager code still has to be added. *)


   caller := caller
end;
(*===================================================================*)


(*===================================================================*)
(* 
 * We only support a few system calls, SEND, RECEIVE, BOTH.
 * Tanenbaum 1929
 *)
procedure sys_call(
   func     : integer,       (* SEND or RECEIVE or BOTH *)
   caller   : integer,       (* process slot number of the caller *)
   src_dest : integer,       (* src to recv from or dest to send to *)
   m_ptr    : t_message_ptr  (* ptr to the callers message buffer *)
);

var
   n : integer,
   rp : ^t_process_entry,
   tmp_str : array[10] of integer;

begin
   rp := proc_addr(caller);


   (* We rarely want to see these message *)
   if debug_flag > 2 then begin
      DebugOut(KERNEL_COLOR, "Entered sys_call...", 1);
   
      BIOS_NumToHexStr(func, adr(tmp_str));
      DebugOut(KERNEL_COLOR, "   Func is (SEND=1, RECV=2, BOTH=3) : ", 0);
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      BIOS_NumToHexStr(caller, adr(tmp_str));
      DebugOut(KERNEL_COLOR, "   Caller is                        : ", 0);
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      BIOS_NumToHexStr(src_dest, adr(tmp_str));
      DebugOut(KERNEL_COLOR, "   SRC_DEST is  (0400 = ANY)        : ", 0);
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   
   end;

   if func AND SEND = SEND then begin
      mini_send(caller, src_dest, m_ptr, adr(n))
   end;

   if func AND RECEIVE = RECEIVE then begin
      mini_rec(caller, src_dest, m_ptr, adr(n))
   end;


   if debug_flag > 1 then 
      DebugOut(KERNEL_COLOR, "Leaving sys_call...", 1)
end;
(*===================================================================*)


(*===================================================================*)
(*
This is where system calls go.  If this code is running, it was 
because a process invoked the syscall instruction and the syscall
vector was (previously) patched with a jump here.

Please note, the syscall instruction disables interrupts!

The caller should have placed the following on its PSTACK:
   dst(if message is send) OR src (if message is receive)
   func (send, receive or both)
   message_ptr

   parameter order:
         dst_src func message_ptr syscall
*)
(* 
   t_process_entry = record
      ds : integer;
      cs : integer;
      es : integer;
      psp : integer;
      ptos : integer;
      pc : integer;
      flags : integer;
      rsp : integer;
      rtos : integer
   end;
*)
procedure s_call();

begin
   (* 
      First we need to save the state of the process for later
      restoration.                                    

      Upon entry, the compiler generated code like:
         0 SP_FETCH TO_R SP_FETCH 0 + SP_STORE
      This needs to be undone.

      This includes getting rid of the extra push that was done
   *)
   ASM
      FROM_R
      SP_STORE   
      DROP   
   END;



   (* 
      Put all of the process state on the parameter stack so
      it can be saved in the process table.
      Remember the SYSCALL instruction which got us here already
      pushed every register onto the outgoing process RSTACK.
   *)

   (* 
      REMINDER: At this point, we are still on the callers parameter 
      and return stacks.
   *) 

   (* Copy all registers from rstack to pstack *)
   ASM
      FROM_R	# Get RTOS 
      FROM_R	# Get old rsp 
      FROM_R	# Get flags
      FROM_R	# Get pc 
      FROM_R	# Get ptos
      FROM_R	# Get psp
      FROM_R	# Get es
      FROM_R	# Get cs 
      R_FETCH	# Get ds
   END;

   (*
      All of the parameters which we have to save are now on the 
      outgoing tasks pstack.  Since we save the old PSP and PTOS
      (as part of the syscall)
      this should not present a problem when we later restore the 
      (currently outgoing) task.
      The code below saves everything to the current process
      process table entry.
      Remember the 3 syscall parameters on still on pstack!
   *)
   (* 
   t_process_entry = record
      ds : integer;
      cs : integer;
      es : integer;
      psp : integer;
      ptos : integer;
      pc : integer;
      flags : integer;
      rsp : integer;
      rtos : integer
   end;
   *)

   (* SetES($0000); - Was pstack affected?  Cant get params *)

   ASM
      0 TO_ES
      proc_ptr LONG_FETCH 0 + LONG_STORE # Store DS
      proc_ptr LONG_FETCH 1 + LONG_STORE # Store CS
      proc_ptr LONG_FETCH 2 + LONG_STORE # Store ES
      proc_ptr LONG_FETCH 3 + LONG_STORE # Store PSP
      proc_ptr LONG_FETCH 4 + LONG_STORE # Store PTOS
      proc_ptr LONG_FETCH 5 + LONG_STORE # Store PC
      proc_ptr LONG_FETCH 6 + LONG_STORE # Store FLAGS
      proc_ptr LONG_FETCH 7 + LONG_STORE # Store RSP
      proc_ptr LONG_FETCH 8 + LONG_STORE # Store RTOS

      m_ptr LONG_STORE
      src_dest LONG_STORE
      syscall_function LONG_STORE
   END;


   (*
      Initialize the kernel stack.  We do not RESTORE the kernel
      stack, because nothing is preserved on the kernel stack
      between system calls.
      K_SP_STORE sets PSP to PTOS and DS to 0
   *)

   ASM
      k_stack K_SP_STORE
      k_rstack RP_STORE
   END;


   
   if debug_flag > 1 then begin
      DebugOut(KERNEL_COLOR, "Entered s_call and all state has been saved", 1);
   
      DebugOut(KERNEL_COLOR, "   PC : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.pc, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   PTOS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.ptos, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   FLAGS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.flags, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   RSP : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.rsp, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   PSP : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.psp, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   proc_ptr : ", 0); 
      BIOS_NumToHexStr(adr(proc_ptr), adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   proc_ptr^ : ", 0); 
      BIOS_NumToHexStr(proc_ptr, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   RTOS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.rtos, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   DS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.ds, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   CS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.cs, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "   es : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.es, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;

   if debug_flag > 1 then begin
      DebugOut(KERNEL_COLOR, "   These were the syscall parameters: ", 1); 
   
      DebugOut(KERNEL_COLOR, "      syscall_func        : ", 0); 
      BIOS_NumToHexStr(syscall_function, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "      src_dest (0400=ANY) : ", 0); 
      BIOS_NumToHexStr(src_dest, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1);
   
      DebugOut(KERNEL_COLOR, "      m_ptr               : ", 0); 
      BIOS_NumToHexStr(m_ptr, adr(tmp_str));
      DebugOut(KERNEL_COLOR, adr(tmp_str), 1)
   end;

   sys_call(syscall_function, cur_proc, src_dest, m_ptr);

   (* Restart(); *)
   ASM BRA restart END;

   (* Dummy line to make ';' compilation prob go away *) Old_DS := Old_DS
end;
(*===================================================================*)


#####################################################################
(*
 * Send m_ptr to task.  The message was created by the interrupt
 * handler.
 *
 * Tanenbaum, line 1878
 * 
 * This code is called by base_interrupt()
 *)
procedure interrupt(task : integer, m_ptr : ^message);

var
   x : integer,
   tmp_str : array[40] of integer,
   result : integer;


begin
   DebugOut(HW_COLOR, "Entered interrupt() Task is : ", 0);
   if task = $FFFD then DebugOut(HW_COLOR, "CLOCK", 1)
   else if task = $FFF8 then DebugOut(HW_COLOR, "PTY", 1)
   else if task = $FC19 then DebugOut(HW_COLOR, "IDLE", 1);
   
   BIOS_NumToHexStr(cur_proc,  adr(tmp_str)); 
   DebugOut(HW_COLOR, "cur_proc is : ", 0); DebugOut(HW_COLOR, adr(tmp_str), 1);

   x := task; (* simulator test point*)
   mini_send(HARDWARE, task, m_ptr, adr(result));
   if result <> OK then begin
      (* We could not send a message so we will remember we have to send one later *)
      (* Should only happen with PTY messages... *)
      DebugOut(HW_COLOR, "INTERRUPT could not send mess to task ", 0);
      if task = $FFFD then DebugOut(HW_COLOR, "CLOCK", 1)
      else if task = $FFF8 then DebugOut(HW_COLOR, "PTY", 1)
      else if task = $FC19 then DebugOut(HW_COLOR, "IDLE", 1);
      if task = PTY then begin
         DebugOut(HW_COLOR, "    INTERRUPT : Remembering PTY", 1);
         pty_int_was_seen := 1
      end
   end
   else begin
      DebugOut(HW_COLOR, "INTERRUPT Successfully sent mess to task ", 0);
      if task = $FFFD then DebugOut(HW_COLOR, "CLOCK", 1)
      else if task = $FFF8 then DebugOut(HW_COLOR, "PTY", 1)
      else if task = $FC19 then DebugOut(HW_COLOR, "IDLE", 1);
      if task = PTY then begin
         DebugOut(HW_COLOR, "    INTERRUPT : Clearing PTY flag", 1);
         pty_int_was_seen := 0
      end
   end;


   (* Only call pick_proc, if a task has just been readied AND
    * a user process had been running. 
    * We also call pick_proc if cur_proc is IDLE.
    *)

   if ((rdy_head[TASK_Q]) <> NIL_PROC AND (cur_proc >= 0) OR (cur_proc = IDLE)) then begin
      DebugOut(HW_COLOR, "    calling pick_proc at end of interrupt()", 1);
      pick_proc()
   end;
   if debug_flag then begin
      BIOS_NumToHexStr(cur_proc,  adr(tmp_str)); 
      DebugOut(HW_COLOR, "    new interrupt: cur_proc is : ", 0); 
      DebugOut(HW_COLOR, adr(tmp_str), 1);
      DebugOut(HW_COLOR, "    leaving interrupt.", 1)
   end
end;
#####################################################################

#include "pty.inc"
#include "clock.inc"
#include "floppy.inc" 
#include "system.inc"
#include "shell.inc"
#include "shell2.inc"


(*
This is where interrupts go.  If this code is running, it was 
because an interrupt occurred and the interrupt
vector was (previously) patched with a jump here.

  In Tanenbaum, there are multiple as interrupt routines 
  (e.g. tty_int, disk_int, clock_int...)
  Since this cpu has only one interrupt, ALL interrupts vector
  here and the interrupt controller must be polled to figure 
  out which interrupt occurred.

  Once we know which interrupt occurred, we call "interrupt" which
  will turn an interrupt into a message and send it to the correct
  task.
*)

(* 
   t_process_entry = record
      ds : integer;
      cs : integer;
      es : integer;
      psp : integer;
      ptos : integer;
      pc : integer;
      flags : integer;
      rsp : integer;
      rtos : integer
   end;
*)
procedure base_interrupt();

begin
   (* 
      First we need to save the state of the interrupted process 
      for later restoration.                                    

      In Tanenbaum, saving state is done with "save" which is used
      both by the system call function (s_call) and by the 
      assembly language interrupt routines.

      Upon entry, the compiler generated code like:
         0 SP_FETCH TO_R SP_FETCH 0 + SP_STORE
      This needs to be UNDONE by the following ASM code.

      Please note interrupts were disabled upon entry.

      This includes getting rid of the extra push that was done
   *)
   ASM
      FROM_R
      SP_STORE   
      DROP   
   END;



   (* 
      Put all of the CURRENT process state on the parameter stack so
      it can be saved in the process table.
      Remember the interrupt which got us here already
      pushed every register onto the outgoing process RSTACK.
   *)

   (* 
      REMINDER: At this point, we are still on the interrupted 
      processs parameter and return stacks.
   *) 

   (* Copy all registers from rstack to pstack *)
   ASM
      FROM_R	# Get RTOS 
      FROM_R	# Get old rsp 
      FROM_R	# Get flags
      FROM_R	# Get pc 
      FROM_R	# Get ptos
      FROM_R	# Get psp
      FROM_R	# Get es
      FROM_R	# Get cs 
      R_FETCH	# Get ds
   END;

   (*
      All of the parameters which we have to save are now on the 
      outgoing tasks pstack.  Since we save the old PSP and PTOS
      (as part of the interrupt action of the CPU)
      this should not present a problem when we later restore the 
      (currently outgoing) task.
      The code below saves everything to the current process
      process table entry.
   *)
   (* 
   t_process_entry = record
      ds : integer;
      cs : integer;
      es : integer;
      psp : integer;
      ptos : integer;
      pc : integer;
      flags : integer;
      rsp : integer;
      rtos : integer
   end;
   *)

   (* SetES($0000); - Was pstack affected?  Cant get params *)

   ASM
      0 TO_ES
      proc_ptr LONG_FETCH 0 + LONG_STORE # Store DS
      proc_ptr LONG_FETCH 1 + LONG_STORE # Store CS
      proc_ptr LONG_FETCH 2 + LONG_STORE # Store ES
      proc_ptr LONG_FETCH 3 + LONG_STORE # Store PSP
      proc_ptr LONG_FETCH 4 + LONG_STORE # Store PTOS
      proc_ptr LONG_FETCH 5 + LONG_STORE # Store PC
      proc_ptr LONG_FETCH 6 + LONG_STORE # Store FLAGS
      proc_ptr LONG_FETCH 7 + LONG_STORE # Store RSP
      proc_ptr LONG_FETCH 8 + LONG_STORE # Store RTOS
   END;


   (*
      Initialize the kernel stack.  We do not RESTORE the kernel
      stack, because nothing is preserved on the kernel stack
      between system calls.
      K_SP_STORE sets PSP to PTOS and DS to 0
   *)

   ASM
      k_stack K_SP_STORE
      k_rstack RP_STORE
   END;

   

   if debug_flag >= 1 then begin
      ConsolePrintStr("Entered base_interrupt and all state has been saved", 1);
   
      ConsolePrintStr("PC : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.pc, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("PTOS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.ptos, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("FLAGS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.flags, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("RSP : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.rsp, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("PSP : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.psp, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("proc_ptr : ", 0); 
      BIOS_NumToHexStr(adr(proc_ptr), adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("proc_ptr^ : ", 0); 
      BIOS_NumToHexStr(proc_ptr, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("RTOS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.rtos, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("DS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.ds, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("CS : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.cs, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1);
   
      ConsolePrintStr("es : ", 0); 
      BIOS_NumToHexStr(proc_ptr^.es, adr(tmp_str));
      ConsolePrintStr(adr(tmp_str), 1)
   end;



   if (interrupt_status_ptr^ AND CLOCK_INT_MASK) = CLOCK_INT_MASK then begin
      (* We got a clock interrupt, turn it into a message for the clock_task *)
      DebugOut(HW_COLOR, "===TICK===", 1); 
      interrupt_clear_ptr^ := CLOCK_INT_MASK;
      interrupt_clear_ptr^ := 0;
      (* NOTE TODO
       * the message is not initialized.
       * The clock task only accepts interrupt messages now and does
       * not look at the m_type.
       *)
      interrupt(CLOCK, adr(int_mess));
      hw_pty_mess.m_type := PTY_INT;
      interrupt(PTY, adr(hw_pty_mess))

      
   end;


   DebugOut(HW_COLOR, " About to restart at end of base_interrupt", 1);

   (* Restart(); *)
   (* As a result of calling interrupt above, cur_proc and proc_ptr MAY
    * have changed.
    *)
   ASM BRA restart END;

   (* Dummy line to make ';' compilation prob go away *) Old_DS := Old_DS
end;
#####################################################################



#####################################################################
(*
Patch the system call vector so it causes a jump to s_call.
Remember all registers have been saved on the rstack.
*)
procedure PatchVectors();
var
   Ptr : ^integer;

begin
   DebugOut(KERNEL_COLOR, "Patching interrupt vector...", 1);
   (* Mark vectors as DATA_RW for simulator so they may be patched.
    * The LONG_TYPE_STORE instruction is a nop on the actual h/w. *)
   asm
      1 0xFD00 LONG_TYPE_STORE
      1 0xFD01 LONG_TYPE_STORE
      1 0xFD02 LONG_TYPE_STORE
      1 0xFD03 LONG_TYPE_STORE
   end;
   Ptr := $FD00;
   Ptr^ := $0004; # BRANCH
   Ptr := $FD01;
   Ptr^ := adr(base_interrupt);
   DebugOut(KERNEL_COLOR,"Patching syscall vector...", 1);
   Ptr := $FD02;
   Ptr^ := $0004; # BRANCH
   Ptr := $FD03;
   Ptr^ := adr(s_call);

   (* Mark vectors as CODE_RO for simulator so their contents
    * may be executed. The LONG_TYPE_STORE instruction is a 
    * nop on the actual h/w. *)
   asm
      0 0xFD00 LONG_TYPE_STORE
      0 0xFD01 LONG_TYPE_STORE
      0 0xFD02 LONG_TYPE_STORE
      0 0xFD03 LONG_TYPE_STORE
   end
   
end;
#####################################################################


(*
*)
procedure init_process_table();
var
   i : integer;

begin
   DebugOut(KERNEL_COLOR,  "Initializing process table...", 1);
   i := 0;
   while i < NUM_PROCESS_TABLE_ENTRIES do begin
      process_table[i].next_sender := 0;
      process_table[i].p_flags :=  0;
      process_table[i].p_flags := 
         process_table[i].p_flags OR P_SLOT_FREE;
      (* Tanenbaum uses pointer arithmetic and negative task nums
       * Without pointer arithmetic, I embed, the process number 
       * in the process table to compensate.
       *)
      process_table[i].process_num :=  i - NR_TASKS;
      process_table[i].p_callerq :=  NIL_PROC;
      i := i + 1
   end
end;
(*==================================================================*)

var
   i : integer;

(*===================================================================*)
begin
   (* 
      This is the kernel entry point.
      We assume CS is 0 upon entry.
   *)
  


   interrupt_status_ptr := $F010;
   interrupt_mask_ptr := $F011;
   interrupt_clear_ptr := $F012;

   ConsolePrintStr("Starting kernel...", 1);


   ASM
      k_stack K_SP_STORE
      k_rstack RP_STORE
   END;

   (* Ints dont need to be enabled until "run" *)
   ASM
      DI
   end;

   PatchVectors();
   interrupt_mask_ptr^ := 0;

   interrupt_mask_ptr^ := interrupt_mask_ptr^ OR CLOCK_INT_MASK;
 
   NIL_PROC := 0;

   debug_flag := 1;


   (* Slot entries used by process code - bit mask for p_flags. *)
   P_SLOT_FREE := $0001;
   NO_MAP      := $0002;
   SENDING     := $0004;
   RECEIVING   := $0008;

   dc_init();

   (* This is a global ptr to a buffer used by the xmodem receiver.
    *)
   next_xmodem_byte_ptr := 0;
   xmodem_rx_started := 0;


   init_process_table();
   rdy_head[TASK_Q] := NIL_PROC;
   rdy_head[SERVER_Q] := NIL_PROC;
   rdy_head[USER_Q] := NIL_PROC;

(*
   load_task(adr(disk_task), 
             adr(disk_task_p_stack), 
             adr(disk_task_r_stack), 
             0);
*)

   pty_int_was_seen := 0;

   
   load_task(
      adr(disk_task),
      adr(floppy_task_p_stack),
      adr(floppy_task_r_stack),
      FLOPPY);
   
   
   load_task(
      adr(sys_task),
      adr(sys_task_p_stack),
      adr(sys_task_r_stack),
      SYSTASK);


   load_task(
      adr(pty_task),
      adr(pty_task_p_stack),
      adr(pty_task_r_stack),
      PTY);

   load_task(
      adr(clock_task),
      adr(clk_task_p_stack),
      adr(clk_task_r_stack),
      CLOCK);

   (*
    * Load a temporary shell to exercise pty task
    *)
    
   load_task(
      adr(shell_proc),
      adr(shell_proc_p_stack),
      adr(shell_proc_r_stack),
      2);
   
   
   (*
    * Load a temporary shell to exercise pty task
    *)
(*
   load_task(
      adr(shell2_proc),
      adr(shell2_proc_p_stack),
      adr(shell2_proc_r_stack),
      3);
*)
 
   DebugOut(KERNEL_COLOR, "5 second delay.", 1);
   (*
   delay_ms(5000);
   *)

   SetES($0000);


   bill_ptr := proc_addr(HARDWARE);



   while 1=1 do  begin
      k_pr("MJ Console Shell >");
      k_gets(adr(Line));
      
      (*
       *
       * Create the global ARGV array to be used by 
       * loaded applications and this shell to figure
       * out what the program name is.
       *
      *)
      ParseLine(adr(Line));

      BIOS_StrLen(ArgV, adr(StrLen));
      if StrLen = 0 then continue;

      ArgVPtr := adr(ArgV);
      while ArgVPtr^ <> 0 do begin
         ConsoleOut(KERNEL_COLOR, ArgVPtr^, 1);
         ArgVPtr := ArgVPtr + 1
      end;

      (*
      BIOS_StrCmp(ArgV, "cd", adr(Ans));
      if Ans = 1 then begin
         ConsoleOut(KERNEL_COLOR, "Enter dir to CD to >", 0);
         ConsoleGetStr(ArgV);
         BIOS_CD(ArgV, adr(Status));
         if Status = 0 then begin
            ConsoleOut(KERNEL_COLOR, "CD was successful!", 1)
         end
         else begin
            ConsoleOut(KERNEL_COLOR, "CD Failed!", 1)
         end;
         continue
      end;
      *)
      
      (*
      BIOS_StrCmp(ArgV, "ls", adr(Ans));
      if Ans = 1 then begin
         ConsoleOut(KERNEL_COLOR, "Saw ls... running ls proc", 1);
         Ls();
         continue
      end;
      *)

      compare_strings(ArgV, "load_header", adr(ans));
      if (ans = 1) then begin
         k_pr("Calling load_hex_sim_header"); k_prln(1);
         
         k_pr("Enter hex sim file name >"); k_gets(adr(filename));
         k_pr("Enter proc_num > "); k_get_num(adr(slot_num));
         
         load_hex_sim_header(
            adr(filename),
            adr(DataSize), 
            adr(LoadAddress),
            adr(StartAddress), 
            slot_num,
            adr(Status));
          
         if (Status <> 0) then begin
            k_pr("Could not load header..");
            continue
         end;
         
         k_pr("data size : "); k_pr_hex_num(datasize); k_prln(1);
         k_pr("loadaddress size : "); k_pr_hex_num(loadAddress); k_prln(1);
         k_pr("Start Address size : "); k_pr_hex_num(StartAddress); k_prln(1);
         continue
      end;
      
      (*
      BIOS_StrCmp(ArgV, "load_file", adr(Ans));
      if Ans = 1 then begin
         ConsoleOut(KERNEL_COLOR, "Enter name of file to load>", 0);
         ConsoleGetStr(adr(FileName));

         ConsoleOut(KERNEL_COLOR, "Enter proc_num >", 0);
         ConsoleGetStr(adr(Line));
         BIOS_HexStrToNum(adr(Line), adr(slot_num));

         load_file(
            adr(FileName), 
            adr(DataSize), 
            adr(LoadAddress),
            adr(StartAddress), 
            slot_num,
            adr(Status));

         ConsoleOut(KERNEL_COLOR, "Data Size : ", 0);
         BIOS_NumToHexStr(DataSize, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Load Address : ", 0);
         BIOS_NumToHexStr(LoadAddress, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Start Address : ", 0);
         BIOS_NumToHexStr(StartAddress, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Status : ", 0);
         BIOS_NumToHexStr(Status, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "CS : ", 0);
         tmp_proc_ptr := proc_addr(slot_num);
         BIOS_NumToHexStr(tmp_proc_ptr^.cs, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         continue
      end;
      *)
      
      (*
      BIOS_StrCmp(ArgV, "load2", adr(Ans));
      if Ans = 1 then begin

         ConsoleOut(KERNEL_COLOR, "Enter process table logical num>", 0);
         ConsoleGetStr(adr(Line));
         BIOS_HexStrToNum(adr(Line), adr(slot_num));

         load_file_2(
            adr(DataSize), 
            adr(LoadAddress),
            adr(StartAddress), 
            slot_num,
            adr(Status));

         ConsoleOut(KERNEL_COLOR, "Data Size : ", 0);
         BIOS_NumToHexStr(DataSize, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Load Address : ", 0);
         BIOS_NumToHexStr(LoadAddress, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Start Address : ", 0);
         BIOS_NumToHexStr(StartAddress, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "Status : ", 0);
         BIOS_NumToHexStr(Status, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         ConsoleOut(KERNEL_COLOR, "CS : ", 0);
         proc_ptr :=  proc_addr(slot_num);
         BIOS_NumToHexStr(proc_ptr^.cs, ArgV);
         ConsoleOut(KERNEL_COLOR, ArgV, 1);

         continue
      end;
      *)

      BIOS_StrCmp(ArgV, "run", adr(Ans));
      if Ans = 1 then begin
         ConsoleOut(KERNEL_COLOR, "In run.  Calling pick_proc for first time", 1);
         pick_proc();

         Restart()
      end;

      (* TODO - How does this string comparison work? 
       * Is ArgV a pointer?  Can't find it.
       * Looks like an array in strings.inc *)
      BIOS_StrCmp(ArgV, "debug_setting", adr(Ans));
      if Ans = 1 then begin
         k_cpr(KERNEL_COLOR, "Enter debug setting (0 = none, 1 = some, > 1 A LOT ) >");
         k_get_num(adr(debug_flag)) ;
         continue
      end;

 
      ConsoleOut(KERNEL_COLOR, "No such command or program!", 1)


   end;


   (* Dummy line to keep us from forgetting to omit ';' in last
      valid source line. 
   *)
   proc_ptr := proc_ptr
end.

