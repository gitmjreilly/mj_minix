(*
 * This file contains the disk driver.
 * it is included with the kernel so it has direct access
 * to kernel structures like the process table (which it
 * needs in order to look up the data segment of the
 * caller process).
 *
 * It is loosely based on kernel/memory.c (line 2250)
 * It makes more sense to use memory.c than floppy.c (line 2400)
 * because this kernel is meant to be used with a much simpler
 * interface block device like an IDE drive or USB keyfob.
 *
 * This is meant to be a stand alone process sharing a common
 * address space with the kernel.
 * 
 *)
#include <term_colors.inc>
#include <disk_ctlr.inc>

#define FLOPPY_COLOR ANSI_YELLOW



#####################################################################
(* Write exactly 512 bytes *)
procedure floppy_write_sector(
             p : ^block_message,
             StatusPtr : t_word_ptr);

var
   rp : ^t_process_entry,
   counter : ^integer,
   start_time : integer,
   end_time : integer,
   run_time : integer,
   status : integer,
   BufPtr : ^integer,
   process_segment : integer,
   TmpCh: integer;

begin
   (* Get the process segment for the source data *)
   (* TODO  - Is m_source the right source? *)
   rp := proc_addr(p^.m_source);
   process_segment := rp^.DS;

   (* This is the 16 bit address of the data in the source
      process to be written to the storage medium.
   *)
   BufPtr := p^.ADDRESS;

   (* Copy the data from the  user process to our internal buffer *)
   (* Theres no need to copy the data from the user process to ours.
    * The user process is blocked so we can copy directly from it to the storage medium.
    *)
   (*
   num_bytes_copied := 0;
   while num_bytes_copied < 512 do begin
         LongFetch(BufPtr, adr(src_buffer[num_bytes_copied]));
         BufPtr := BufPtr + 1;
         num_bytes_copied := num_bytes_copied + 1
   end;
   *)

   (*
   p5_write512(adr(src_buffer), adr(p^.POSITION))
   *)
   disk_ctlr_write_512(
       process_segment, (* src seg *)
       BufPtr,
       adr(p^.POSITION),
       adr(status)
   )

end;
(*##################################################################*)


(*##################################################################*)
procedure floppy_read_sector( 
             p : ^block_message,
             StatusPtr : t_word_ptr);

var
   rp : ^t_process_entry,
   BufPtr : ^integer,
   process_segment : integer,
   counter : ^integer,
   start_time : integer,
   end_time : integer,
   run_time : integer,
   status : integer,
   i : integer,
   tmp : integer,
   TmpCh: integer;

begin
   (* TODO  - Is m_source the right source? *)
   rp := proc_addr(p^.m_source);
   process_segment := rp^.DS;
   BufPtr := p^.ADDRESS;

   k_cpr(FLOPPY_COLOR, "FLOPPY - reading sector"); k_prln(1);
	k_cpr(FLOPPY_COLOR, "  DS is "); k_cpr_hex_num(FLOPPY_COLOR, process_segment); k_prln(1);
	k_cpr(FLOPPY_COLOR, "  POS is :"); k_cpr_hex_num(FLOPPY_COLOR, p^.POSITION[0]); k_cpr(FLOPPY_COLOR, " "); k_cpr_hex_num(FLOPPY_COLOR, p^.POSITION[1]);
	k_prln(1);
   k_cpr(FLOPPY_COLOR, "  ADDRESS in user proc is : "); k_cpr_hex_num(FLOPPY_COLOR, p^.ADDRESS); k_prln(1);
   k_cpr(FLOPPY_COLOR, "  user proc segment is : "); k_cpr_hex_num(FLOPPY_COLOR, process_segment); k_prln(1);

   k_cpr(FLOPPY_COLOR, "  Waiting for empty rx fifo... "); k_prln(1);
   dc_wait_for_rx_n(0);
   k_cpr(FLOPPY_COLOR, "    Finished Waiting for empty rx fifo... "); k_prln(1);
   
   dc_start_read_512(
      adr(p^.POSITION), (* 2 word abs address on storage *)
      process_segment,
      BufPtr,
      adr(status)
   );
   k_cpr(FLOPPY_COLOR, "    Waiting for disk read to finish... "); k_prln(1);
   
   (* Now that we've started a dc read, we want to trigger and interrupt
    * when the disk controller uart has the 512 bytes. 
    * interrupt_mask_ptr is a global from the kernel. *)
   interrupt_mask_ptr^ := interrupt_mask_ptr^ OR DISK_UART_RX_HALF_MASK;

   (* Patiently wait for the sector to arrive.  The HARDWARE will tell us when.. *)
   receive_p(HARDWARE, p);
   k_cpr(FLOPPY_COLOR, "    FINISHED Waiting for disk read to finish... "); k_prln(1);
   
   dc_copy_rx_sector_to_user(process_segment, BufPtr)


end;
(*=================================================================*)


(*=================================================================*)
var
   disk_mess : message;
(*=================================================================*)


(*=================================================================*
procedure floppy_log();
begin
   ConsoleOut(KERNEL_COLOR, "Entered Floppy log", 1)
end;
(*=================================================================*

(*=================================================================*
 * do_mem(p) : integer;
 * handles r/w messages
 *
 *=================================================================*)
function do_mem (p : ^block_message) :integer;
var
   rp : ^t_process_entry,
   i : integer,
   process_segment : integer,
   buf_ptr : ^integer,
   val : integer,
   device : integer; (* not used right now *)

begin

   rp := proc_addr(p^.m_source);

   (* device should indicate which disk to r/w.
    * Here we assume it is the USB Wiz disk and ignore the actual value.
    *)
   device := p^.DEVICE;


   (* We need the segment associated with the 
    * process on whose behalf we are acting. 
    *)
   (*
   process_segment := rp^.DS;
   SetES(process_segment);
   *)

   (*
    * This is the actual communication with the device.
    *)
   if p^.m_type = DISK_READ then begin
      floppy_read_sector(p, adr(status))
   end

   (* Write from process memory to external device. *)
   else if p^.m_type = DISK_WRITE then begin
      floppy_write_sector(p, adr(status))
   end;
	
   retval(status)

end;



(*=================================================================*
 * disk_task()
 *=================================================================*)
procedure disk_task();
   
var
   (* process number on whose behalf this request is being made.
    * This is NOT necessarily the process making the request
    * which is captured in the m_source field of the recvd message.
    *)
   proc_nr : integer, 
   
   p : ^block_message,
   reply_ptr : ^reply_message,
   (* process number of the actual caller *)
   caller : integer,
   (* number of bytes to transfer; each byte occupies a word in ram *)
   count : integer,

   (* Return status of this task to the caller *)
   return_status : integer,

   start_sector_num : integer,

   tmp_str : array[20] of integer;

begin
   p := adr(disk_mess);
   reply_ptr := adr(disk_mess);

   ConsoleOut(PTY_COLOR, "Disk_task is starting now...", 1);
   (*
    * done in kernel now so debugging can be tested
   _pmod_128mInit();
   *)


   while (1) do begin
      
      (* Wait for a request *)
      (* format is func, src_dest, m_ptr SYSCALL *)
      (* SEND = 1; RECV = 2 *)
      receive_p(ANY, p);
      

      (*
       * caller is the number of the proc which sent message.
       * proc_nr is the number of the process on whose behalf this request is made.
       * probably FS.
       *)
      caller := p^.m_source;
      proc_nr := p^.PROC_NR; 
      count := p^.COUNT;

      if (p^.m_type = DISK_READ) then begin
         (*
         floppy_log()
         *)
         return_status := do_mem(p)
      end
      else if p^.m_type = DISK_WRITE then begin
         return_status := do_mem(p) (* 2nd param is sector num *)
      end
      else begin
         ConsoleOut(KERNEL_COLOR, "   DT: Unknown message type!", 1);
         return_status := EINVAL
      end;
         
      reply_ptr^.m_type := TASK_REPLY;
      reply_ptr^.REP_PROC_NR := proc_nr;
      reply_ptr^.REP_STATUS := return_status;
      send_p(caller, reply_ptr)
   end
end;   


