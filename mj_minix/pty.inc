(*
 * This file contains the pseudo tty (pty)  driver.
 * It is included with the kernel so it has direct access
 * to kernel structures like the process table (which it
 * needs in order to look up the data segment of the
 * caller process).
 *
 * This is meant to be a stand alone process sharing a common
 * address space with the kernel.
 *
 * This code makes use of the tcltr running on a Linux system.
 * 
 *)
 
#include "tctlr.inc"

#define PTY_IN_BYTES 200
#define PTY_OUT_BYTES 300
#define NR_PTYS 8

type
   (*
    * structure describing pty status
    * based on Tanenbaum 3380
    * There is support for NR_PTYS terminals from TCP connections from 
    * Linux TCTLR
    *)
   pty_struct_type = record
      pty_inqueue : array[PTY_IN_BYTES] of integer;
      (* Add to pty_inqueue at inhead; remove from intail *)
      pty_inhead : ^integer;
      pty_intail : ^integer;
      (* num chars in pty_inqueue *)
      pty_incount : integer;
      
      pty_lfct : integer;
      pty_outqueue : array[PTY_OUT_BYTES] of integer; 
      pty_outhead : ^integer;
      pty_outtail : ^integer;
      pty_outcount : integer;
      (* Information about incomplete input requests... *)
      pty_incaller : integer;    (* proc that made ACTUAL call, usually FS *)
      pty_inproc : integer;      (* proc on whose behalf work was done *)
      pty_in_vir : integer;      (* addr where data is to go in proc requesting data*)
      pty_inleft : integer;      (* num chars still reqd *)
      (* Information about incomplete output requests... *)
      pty_otcaller : integer;    (* proc that made ACTUAL call, usually FS *)
      pty_outproc : integer;     (* proc on whose behalf work was done *)
      pty_out_vir : integer;     (* addr where data comes from *)
      pty_outleft : integer;     (* num chars to be copied to out q *)
      pty_cum : integer;         (* chars copied to pty q so far *)
      pty_connection_status : integer;  (*  terminal state *)
      (* terminal num may be 0..(NR_PTYS - 1) *)
      pty_terminal_num : integer
   end;


var
   transmit_buffer_start : integer,
   pty_struct : array[NR_PTYS] of pty_struct_type;
   

(*=================================================================*
 * pty_init()
 * based on tty_init() line 4453
 * All we do here is initialize PTY structures
 * There is nothing specific to the h/w which implements the terminals.
 *=================================================================*)
procedure pty_init();
var
   tp : ^pty_struct_type,
   pty_num : integer;

begin
   pty_num := 0;
   while (pty_num < NR_PTYS) do begin
      tp := adr(pty_struct[pty_num]);

      tp^.pty_inhead := adr(tp^.pty_inqueue);
      tp^.pty_intail := adr(tp^.pty_inqueue);
      tp^.pty_incount := 0;
      (* Use pty_cum as num chars written to output q *)
      tp^.pty_cum := 0;
      (* TODO set proper connection status 
       * Not sure this is necessary *)
      tp^.pty_connection_status := 0;
      pty_num := pty_num + 1
   end
end;
(*=================================================================*)

(*=================================================================*
 * pty_reply AST1,4031
 * Send REPLY or REVIVE to proc who initiated call to this PTY task.
 * Called by 
 *    do_pty_read()
 *    do_tctlr_receive()
 *    finish()
 *=================================================================*)
procedure pty_reply(
   code : integer,     (* TASK_REPLY or REVIVE  *)
   replyee : integer,  (* proc to reply to      *)
   proc_nr : integer,  (* who work was done for *)
   status : integer,   (* ???                   *)
   extra : integer,
   other : integer);   (* for IOCTL replies     *)

var
    pty_mess : t_pty_reply_message;

begin
   pty_mess.m_type := code;
   pty_mess.REP_PROC_NR := proc_nr;
   pty_mess.REP_STATUS := status;
   pty_mess.PTY_FLAGS := extra;
   pty_mess.PTY_SPEK := other;
   send_p(replyee, adr(pty_mess))

end;
(*=================================================================*)


(*=================================================================*)
(*
 * pty_rd_chars()
 * based on rd_chars, AST1,3813
 * 
 * Copies from pty buf to user space
 * AST iterates over local buffers.
 * This routine just copies directly from tty_inqueue to user space.
 * 
 * Returns num chars written to user space. Right now this is always 1.
 * Basically we're operating in RAW mode.
 * 
 * Called by do_pty_read() which is the main procedure for 
 * handling a PTY_READ message.
 * 
 *)
(*=================================================================*)
function pty_rd_chars(tp : ^pty_struct_type) : integer;
(* tp is a ptr to the structure info for the proc to receive chars. *)
var
   rp : ^t_process_entry,
   ch : integer,
   tmp_str : array[20] of integer;

begin
   if debug_flag then 
      DebugOut(PTY_COLOR, "  Entered pty_rd_chars... ", 1);

   (* Point at the process entry whose mem space we will fill 
    * We need rp so we can get the user process DS *)
   rp := proc_addr(tp^.pty_inproc);

   if debug_flag > 1 then  begin
      DebugOut(PTY_COLOR, "     on entry pty_inleft is : ", 0);
      BIOS_NumToHexStr(tp^.pty_inleft, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1)
   end;

   (* pty_inleft is the number of chars still required by the user proc *)
   if (tp^.pty_inleft = 0) then begin
      if debug_flag then  
         DebugOut(PTY_COLOR, "     pty_inleft is 0 so am returning...", 1);
      retval(0)
   end;

   if debug_flag > 1then  begin
      DebugOut(PTY_COLOR, "     on entry pty_incount is : ", 0);
      BIOS_NumToHexStr(tp^.pty_incount, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1)
   end;

   (* pty_incount is the number of already received chars in the pty buffer *)
   if (tp^.pty_incount = 0) then begin
      if debug_flag > 1 then  
         DebugOut(PTY_COLOR, "     pty_incount is 0 so am returning...", 1);
      retval(0)
   end;

   ch := tp^.pty_intail^;
   tp^.pty_intail := tp^.pty_intail + 1;

   if tp^.pty_intail = adr(tp^.pty_inqueue[PTY_IN_BYTES]) then begin
      tp^.pty_intail := adr(tp^.pty_inqueue)
   end;

   (* TODO This is single char copy because code operates
    * implicitly in RAW mode. *)
   phys_copy(0, adr(ch),               (* Copy from inqueue to *)
             rp^.DS, tp^.pty_in_vir,   (* to  user addr space  *)
             1);                       (* amount to copy.      *)

   tp^.pty_inleft  := tp^.pty_inleft - 1;
   tp^.pty_incount := tp^.pty_incount - 1;

   if debug_flag > 1 then  begin
      DebugOut(PTY_COLOR, "       on exit  pty_inleft is : ", 0);
      BIOS_NumToHexStr(tp^.pty_inleft, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1);
   
      DebugOut(PTY_COLOR, "       on exit pty_incount is : ", 0);
      BIOS_NumToHexStr(tp^.pty_incount, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1);
   
      DebugOut(PTY_COLOR, "       Leaving pty_rd_chars ", 0)
   end;
   retval(1)

end;
(*=================================================================*)


(*=================================================================*
 * do_pty_read(tp, pty_mess);
 * based on AST1, 3784
 * Handle the READ message which was recvd by PTY_TASK.
 * Called by pty_task()
 * The particular tp was determined by m_pty^.DEVICE prior to this call.
 *=================================================================*)
procedure do_pty_read (tp : ^pty_struct_type, m_ptr : ^t_pty_read_message) ;
var
   code : integer,
   caller : integer,
   tmp_str : array[20] of integer;

begin
   if debug_flag then  
      DebugOut(PTY_COLOR, "   Entered do_pty_read()", 1);

   (* TODO - Figure out why this code is here!!! *)
   if (tp^.pty_inleft > 0) then begin (* AST1,3792 *)
      if debug_flag then  
         DebugOut(PTY_COLOR, "      in_left > 0 so port already in use, returning...", 1);
      pty_reply(TASK_REPLY, m_ptr^.m_source, m_ptr^.PROC_NR, 0, 0, 0);
      return
   end;

   (* Process that made the actual call.  Probably FS *)
   tp^.pty_incaller := m_ptr^.m_source;

   (* TODO PROC_NR is used to select process address
    * Normally FS makes call ON BEHALF of a user process
    * Force it to m_source until FS is implemented.    *)
   tp^.pty_inproc := m_ptr^.m_source;
   (*
   tp^.pty_inproc := m_ptr^.PROC_NR;
   *)
   tp^.pty_in_vir := m_ptr^.ADDRESS;
   tp^.pty_inleft := m_ptr^.COUNT;
   (* This is where a process is bound to a specific terminal/terminal *)
   tp^.pty_terminal_num := m_ptr^.DEVICE;

   (* pty_rd_chars copies chars to user process defined by tp 
    * code is the number of characters copied to user. *)
   code := pty_rd_chars(tp);  (* AST1,3804 *)
   if (code = 0) then begin
      if debug_flag then  
         DebugOut(PTY_COLOR, "      no chars available so no reply will be sent to user", 1);
      return
   end;

   (* If we got this far, send a reply to m_source *)
   caller := tp^.pty_inproc;

   
   pty_reply(TASK_REPLY, m_ptr^.m_source, caller, code, 0, 0);
   if debug_flag then  
      DebugOut(PTY_COLOR, "   Leaving do_pty_read()", 1)

end; 
(*=================================================================*)


(*=================================================================*)
(*
 * pty_in_char()
 * based on in_char, AST1,3581
 * called by do_tctlr_receive()
 * 
 * Purpose is to do raw/cooked processing and 
 * place a char in tty_inqueue.
 *
 * Right now behaviour is RAW so only a single char is ever added.
 * MULTI terminal Compatible
 * 
 * Called by do_tctlr_receive()
 * 
 *)
(*=================================================================*)
procedure pty_in_char(
   line : integer,     (* line (for us) is really terminal num 0..3 *)
   ch   : integer);    (* ch is char to be processed              *)

var
   tmp_str : array[20] of integer,
   tp : ^pty_struct_type;

begin
   if debug_flag then begin
      DebugOut(PTY_COLOR, "   Entered pty_in_char", 1);
      DebugOut(PTY_COLOR, "      line is (must be 0..3) : ", 0);
      BIOS_NumToHexStr(line, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1)
   end;

   (* Tanenbaum 3590, 3596  *)
   tp := adr(pty_struct[line]);
   if (tp^.pty_incount >= PTY_IN_BYTES) then begin
      ConsoleOut(PTY_COLOR, "      in_queue is full - Char will be discarded!", 1);
      if debug_flag then
         DebugOut(PTY_COLOR, "      in_queue is full - Char will be discarded!", 1);
      return
   end;

   tp^.pty_inhead^ := ch;
   tp^.pty_inhead := tp^.pty_inhead + 1;
   if tp^.pty_inhead = adr(tp^.pty_inqueue[PTY_IN_BYTES]) then begin
      tp^.pty_inhead := adr(tp^.pty_inqueue)
   end;
   tp^.pty_incount := tp^.pty_incount + 1;

   if debug_flag then begin
      DebugOut(PTY_COLOR, "      On exit pty_incount :  ", 0);
      BIOS_NumToHexStr(tp^.pty_incount, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1);
      DebugOut(PTY_COLOR, "   Leaving pty_in_char", 1); k_prln(2)
   end
end;
(*=================================================================*)


(*=================================================================*)
(* One or more bytes has been recvd by the tctlr.  Go get some or all
 * of them.
 *
 * In Tanenbaum, the bytes are saved first by keyboard().
 * Theres no need for a keyboard() equivalent in this code because
 * the Linux tctlr has already buffered the input.
 * Theres also no need to copy them to a temp buffer as Tanenbaum does
 * on lines AST V1,3548 and 3549.
 * All we have to do is copy the chars directly to the pty_struct.
 * This is basically what do_charint, line 3528 does
 * specifically in the loop on 3556.
 * Individual chars are actually RAW/Cook handled and stored in the 
 * pty struct by in_char(), AST1 lines 3683 - 3686.
 *
 * The idea is we know chars have arrived from outside on terminal_num.
 * We'll retrieve them from the tcltr, but we'll stop short of overflowing
 * the pty input buffer.  It's OK to keep chars in tctlr until the next 
 * interrupt from the tctlr.
 *
 * Called by do_pty_int as a result of discovering chars are available
 * for this terminal_num.
 *
 * PTY_IN_BYTES is the size of the pty buffer for received chars
 * pty_incount is the number of received chars buffered in pty struct
 * pty_inleft is the number of chars still required by the user proc.
 *
 * Adjusted for tctlr
 *)
(*=================================================================*)
procedure do_tctlr_receive(
   terminal_num : integer, 
   (* The number of bytes received by the tctlr on this terminal. *)
   num_bytes_received_from_tctlr: integer);

var
   ch : integer,
   tmp_str : array[20] of integer,
   tmp_array : array[8] of integer,
   i : integer,
   receive_buffer_start : integer,
   num_bytes_to_retrieve : integer,
   tp : ^pty_struct_type,
   replyee : integer,
   caller  : integer,
   m : integer,
   num_free_slots : integer;

begin
   if debug_flag then begin
      DebugOut(PTY_COLOR, "   Entered do_tctlr_receive - terminal: ", 0);
      BIOS_NumToHexStr(terminal_num, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1);
      k_cpr(PTY_COLOR, "num_bytes is : "); k_cpr_hex_num(PTY_COLOR, num_bytes_received_from_tctlr); k_prln(1)
   end;

   tp := adr(pty_struct[terminal_num]);

   (* Find out exactly how much space is left in the pty receiver buffer
    * We need to do this at the outset so we can retrieve the 
    * maximum number of chars from the tctlr at the start *)

   (* We know how many bytes the tctlr has recvd
    * and we know how many chars are in the pty buffer
    * We'll retrieve as many as will fit ALL AT ONCE from tctlr *)
   num_free_slots := PTY_IN_BYTES - tp^.pty_incount;
   if (num_bytes_received_from_tctlr > num_free_slots) then begin
      num_bytes_to_retrieve := num_free_slots
   end
   else begin
      num_bytes_to_retrieve := num_bytes_received_from_tctlr
   end;

   if debug_flag > 1 then begin
      k_cpr(PTY_COLOR, "num bytes to retr : "); k_cpr_hex_num(PTY_COLOR, num_bytes_to_retrieve); k_prln(1)
   end;
   
   (* Send cmd to tctlr to retrieve the correct number of bytes
    * This will result in all of the bytes sitting in the large
    * fifo connected to the tctlr.  They can be read at any time. *)
   tctlr_receive_from_terminal(terminal_num, num_bytes_to_retrieve);
   
   i := 0; 
   while (i < num_bytes_to_retrieve) do begin
   
      ch := tctlr_get_raw();

      tmp_array[0] := ch;
      tmp_array[1] := 0;
      tmp_array[1] := 0;
      if debug_flag > 1 then begin
         DebugOut(PTY_COLOR, "   DEBUG - Saw char : ", 0); 
         DebugOut(PTY_COLOR, adr(tmp_array), 1)
      end;

      
      (* Do raw/cooked and store a single char in in_queue *)
      pty_in_char(terminal_num, ch); (* AST 3559 *)

      (* If the user proc still wants a char, send it to the user with pty_rd_chars() *)
      if (tp^.pty_inleft > 0) then begin
         if debug_flag > 1 then
            DebugOut(PTY_COLOR, "   DEBUG - in_left > 0, sending char to uspace", 1);
         m := pty_rd_chars(tp);  (* AST1,3566 *)
         replyee := tp^.pty_incaller;
         caller  := tp^.pty_inproc;
         pty_reply(REVIVE, replyee, caller, m, 0, 0)
      end
      else begin
         if debug_flag > 1 then
            DebugOut(PTY_COLOR, "   DEBUG - in_left <=  0, doing nothing ", 1)
      end;

      i := i + 1
   end;

   if debug_flag then begin
      DebugOut(PTY_COLOR, "  tp^.pty_incount is : ", 0);
      BIOS_NumToHexStr(tp^.pty_incount, adr(tmp_str));
      DebugOut(PTY_COLOR, adr(tmp_str), 1)
   end

end;
(*=================================================================*)


(*=================================================================*)
(* TODO
 * Right now output is purely synchronous
 * has to be changed to wait for interrupt
 * 
 * Adjusted for tctlr
 *)
procedure finish(tp : ^pty_struct_type, code : integer);
var
   replyee : integer,
   caller : integer;

begin
   DebugOut(PTY_COLOR, "Entering finish ()", 1);

   replyee := tp^.pty_otcaller;
   caller := tp^.pty_outproc;

   pty_reply(TASK_REPLY, replyee, caller, code, 0, 0);

   DebugOut(PTY_COLOR, "Leaving finish ", 1)
end;
(*=================================================================*)


(*=================================================================*)
(* Notify a blocked sender its transmission is complete
 * Called by do_pty_int to indicate a transmission is complete
 * Adjusted for tctlr *)
procedure do_tctlr_ack_send(terminal_num : integer);

var
   tmp_str : array[20] of integer,
   i : integer,
   num_bytes_received : integer,
   receive_buffer_start : integer,
   tp : ^pty_struct_type,
   m : integer,
   replyee : integer,
   caller  : integer;

begin
   DebugOut(PTY_COLOR, "   Entered do_tctlr_ack_send - terminal: ", 0);
   BIOS_NumToHexStr(terminal_num, adr(tmp_str));
   DebugOut(PTY_COLOR, adr(tmp_str), 1);

   (*
   tctlr_clear_transmission_flag(terminal_num);
   *)
   
   (* TODO
    * Restore finish() here???
    * AST has it here.
    * MJ has it as part of do_pty_write hierarchy.
    * The effect is to make all writes synchronous. *)
   (*
   tp := adr(pty_struct[terminal_num]);
   finish(tp, 0);
   *)
   
   DebugOut(PTY_COLOR, "   Leaving do_tctlr_ack_send  ", 1)

end;
(*=================================================================*)



(*=================================================================*)
(*
 * this is the global message used by pty for sending and receiving.
 *)
var
   pty_mess : message;
(*=================================================================*)


(*=================================================================
 * do_pty_int()
 * 
 *=================================================================*)
procedure do_pty_int();
var
   terminal_num : integer,
   tmp_str : array[30] of integer,
   tmp_array : array[8] of integer,
   i : integer,
   num_bytes_received : integer,
   receive_buffer_start : integer,
   tp : ^pty_struct_type,
   tctlr_status : tctlr_status_type,
   host_transmission_status : integer,
   packet_type : integer,
   packet_size : integer,
   rp : ^t_process_entry,
   replyee : integer,
   caller : integer,
   tmp_p : ^ptc_packet_type,
   num_to_copy_to_in_q : integer,
   src_p : ^ptc_packet_type,
   dst_p : ^integer,
   end_dst_p : ^integer,
   start_dst_p : ^integer,
   buffer_num : integer,
   num_bytes_received_from_terminal : integer;

begin
   DebugOut(PTY_COLOR, "Entered do_pty_int() examining all terminals", 1);
   (*
   k_cpr(PTY_COLOR, "  num_buffers filled : "); k_cpr_hex_num(PTY_COLOR, num_tctlr_buffers_filled); k_prln(1);
   *)
   
   buffer_num := 0;
   while (buffer_num < num_tctlr_buffers_filled) do begin

      (* k_cpr(PTY_COLOR, "Examining buffer num : "); k_cpr_hex_num(PTY_COLOR, buffer_num); k_prln(1); *)
   
      (* Get and (for now) throw away packet from PTC *)
      
      (*
      Packet is a string of form
      type, terminal_num, size (3 bytes total)
      body (body can be empty for an ACK packet)
      padding (for a total of 256 bytes)      
      *)
      
      (* tctlr_buffer was filled by low level interrupt routine *)
      tmp_p := adr(tctlr_buffer[buffer_num]);    
      
      packet_type := tmp_p^.packet_type;
      terminal_num := tmp_p^.terminal_num;
      packet_size := tmp_p^.packet_size;
      tp := adr(pty_struct[terminal_num]);
      
      if (packet_type = TERMINAL_INPUT) then begin
         k_cpr(PTY_COLOR, "  Dealing with terminal input  ");  k_prln(1);
      
   
         num_to_copy_to_in_q := packet_size;
         k_cpr(PTY_COLOR, "    num chars recvd is (hex) : "); k_cpr_hex_num(PTY_COLOR, packet_size); k_prln(1);
         tmp_p := adr(tctlr_buffer[buffer_num]);
         src_p := adr(tmp_p^.rest);
         dst_p := tp^.pty_inhead;
         start_dst_p := adr(tp^.pty_inqueue);
         end_dst_p := adr(tp^.pty_inqueue) + PTY_IN_BYTES - 1;
         
         while (1) do begin
            if (num_to_copy_to_in_q = 0) then break;
         
            dst_p^ := src_p^;
            
            (* inc both src and destination ptrs
             * we assume src doesnt wrap
             * dst (in pty struct) can wrap *)
            src_p := src_p + 1;
            
            if (dst_p = end_dst_p) then 
               dst_p := start_dst_p
            else
               dst_p := dst_p + 1;
               
            tp^.pty_incount := tp^.pty_incount + 1;
            num_to_copy_to_in_q := num_to_copy_to_in_q - 1         
         end;
         tp^.pty_inhead := dst_p
         
         (*
         i := 0;
         while (i < packet_size) do  begin
            tmp_str[i] := tmp_p^.rest[i];
            i := i + 1
         end;
         tmp_str[i] := 0;
         
         k_cpr(PTY_COLOR, "term num : "); k_cpr_hex_num(PTY_COLOR, tmp_p^.terminal_num); k_prln(1);
         k_cpr(PTY_COLOR, "Str is : "); k_cpr(PTY_COLOR, adr(tmp_str)); k_prln(1);
         k_cpr(PTY_COLOR, "pty incount is : "); k_cpr_hex_num(PTY_COLOR, tp^.pty_incount); k_prln(1)
         *)
         
      end (* Code handling TERMINAL INPUT *)
      else begin (* Handling a write ack *)
         (* k_cpr(PTY_COLOR, "  Sending WRITE reply message "); k_prln(1); *)
         finish(tp, 0)
         (* k_cpr(PTY_COLOR, "  Finished Sending WRITE reply message "); k_prln(1) *)
         
      end;
      buffer_num := buffer_num + 1
    
    
   end; 
   
   
   
   
   
   
   
   (* Global var set by actual interrupt; cleared here *)
   ASM
      DI
   END;
   num_tctlr_buffers_filled := 0;
   ASM
      EI
   END;
      
   
   (* Now check all waiting procs to see if any are waiting for input
      which may have been satisfied as a result of chars arriving during
      interrupt *)
   (*
   k_cpr(PTY_COLOR, "Checking all ptys to see if proc is waiting..."); k_prln(1);
   *)
   terminal_num := 0;
   while (terminal_num < NR_PTYS) do begin
      tp := adr(pty_struct[terminal_num]);
      (*
      k_cpr(PTY_COLOR, "Checking terminal : "); k_cpr_hex_num(PTY_COLOR, terminal_num); k_prln(1);
      *)
      
      terminal_num := terminal_num + 1;
   
      (* Check to see if the in_q has any chars in it *)
      if (tp^.pty_incount = 0) then continue;
   
      (* Check to see if user proc is waiting for chars *)
      if (tp^.pty_inleft = 0) then continue;

      (* k_cpr(PTY_COLOR, "  inleft and incount both > 0 ... "); k_prln(1); *)

      (* Point at the process entry whose mem space we will fill 
       * We need rp so we can get the user process DS *)
      rp := proc_addr(tp^.pty_inproc);

      (* Copy from in_q to user *)
      while (1) do begin
         (* Check to see if the in_q has any chars in it *)
         if (tp^.pty_incount = 0) then break;
      
         (* Check to see if user proc is waiting for chars *)
         if (tp^.pty_inleft = 0) then break;

         ch := tp^.pty_intail^;
         tp^.pty_intail := tp^.pty_intail + 1;

         if tp^.pty_intail = adr(tp^.pty_inqueue[PTY_IN_BYTES]) then begin
            tp^.pty_intail := adr(tp^.pty_inqueue)
         end;

         phys_copy(0, adr(ch),               (* Copy from inqueue to *)
                   rp^.DS, tp^.pty_in_vir,   (* to  user addr space  *)
                   1);                       (* amount to copy.      *)

         tp^.pty_inleft  := tp^.pty_inleft - 1;
         tp^.pty_incount := tp^.pty_incount - 1;
         replyee := tp^.pty_incaller;
         caller  := tp^.pty_inproc;
         (*
         k_cpr(PTY_COLOR, "  sending reply..."); k_prln(1);
         k_cpr(PTY_COLOR, "   copied char : "); k_cpr_hex_num(PTY_COLOR, ch); k_prln(1);
         k_cpr(PTY_COLOR, "   Checking replyee : "); k_cpr_hex_num(PTY_COLOR, replyee); k_prln(1);
         k_cpr(PTY_COLOR, "   Checking caller : "); k_cpr_hex_num(PTY_COLOR, caller); k_prln(1); 
         *)
         pty_reply(TASK_REPLY, replyee, caller, 1, 0, 0)         
      end
      
   end;
   
   DebugOut(PTY_COLOR, "Leaving do_pty_int()", 1)
end;
(*=================================================================*)


(*=================================================================*)
(* This procedure is supposed to flush all pending host to terminal
 * transmissions.  In the tctlr, there are no visible pending transmissions
 * so, for now, this does nothing.
 *
 * Flush doesn't do anything with tctlr implementation.
 * Adjusted for tctlr
 *)
procedure flush(tp : ^pty_struct_type);
var
   terminal_num : integer;

begin
   
   terminal_num := tp^.pty_terminal_num;
   

   tctlr_write_to_str_to_term(terminal_num, adr(tp^.pty_outqueue), tp^.pty_cum);

   
   tp^.pty_cum := 0
end;
(*=================================================================*)

(*=================================================================*)
(* Send a single char to tctlr for output, 
 * Called by console
 *
 * Adjusted for tctlr
 *
 *)
procedure out_char(tp : ^pty_struct_type, c : integer); 
var
   terminal_num : integer;


begin
   DebugOut(PTY_COLOR, "  Entering out_char ()", 1);
   terminal_num := tp^.pty_terminal_num;

   (*
    * Dont send chars directly to term ctlr
    * Buffer them in tp struct
   *)
   (*
   tctlr_write_raw(terminal_num, c);
   *)
   if (tp^.pty_cum = PTY_OUT_BYTES) then begin
      flush(tp)
   end;
   tp^.pty_outqueue[tp^.pty_cum] := c;
   tp^.pty_cum := tp^.pty_cum  + 1;

   DebugOut(PTY_COLOR, "  Leaving out_char ()", 1)
end;
(*=================================================================*)


(*=================================================================*
 * console(tp)
 * TODO
 * based on AST1, 4178
 * Basic idea is to retrieve all chars from user space and feed
 * them to single char output routine.
 * We've take some liberty with AST code.
 * Here all chars are pointed to by pty_out_vir
 * segment info comes from .pty_outproc and process table.
 *
 * Adjusted for tctlr
 *=================================================================*)
procedure console (tp : ^pty_struct_type);
var
   src_ds : integer,
   offset : integer,
   rp : ^t_process_entry,
   tmp_array : array[6] of integer,
   terminal_num : integer,
   orig_num_chars : integer,
   c : integer;

begin
   DebugOut(PTY_COLOR, "Entering console() ", 1);

   (* Given pty_outproc, we can look up the procs DS
    * and then fetch chars from user space. *)
   rp := proc_addr(tp^.pty_outproc);
   SetES(rp^.DS);

   orig_num_chars := tp^.pty_outleft;

   terminal_num := tp^.pty_terminal_num;


   DebugOut(PTY_COLOR, "  Fetching all chars from user space for output", 1);
   offset := tp^.pty_out_vir;
   while (tp^.pty_outleft > 0) do begin
      LongFetch(offset, adr(c));
      (* out_char in AST1 is about writing to screen
       * here it is about populating tctlr one char at a time with out_char *)
      tmp_array[0] := c;
      DebugOut(PTY_COLOR, "   DEBUG - Saw char(from user) : ", 0); tmp_array[1] := 0;
      DebugOut(PTY_COLOR, adr(tmp_array), 1);

      out_char(tp, c); 
      offset := offset + 1;
      tp^.pty_outleft := tp^.pty_outleft - 1

   end;

   flush(tp);
   (* Notice we do NOT reply to caller, reply is sent by INT handler *)

   DebugOut(PTY_COLOR, "Leaving console() ", 1)
end;
(*=================================================================*)



(*=================================================================*
 * do_pty_write(tp, pty_mess);
 * TODO
 * based on AST1, 3905
 * 
 * tp was selected from message.DEVICE
 * tp array entry is DEVICE
 *
 * Adjusted for tctlr 
 *
 *=================================================================*)
procedure do_pty_write (tp : ^pty_struct_type, m_ptr : ^t_pty_write_message) ;
var
   code : integer,
   rp : ^t_process_entry,
   caller : integer,
   orig_num_chars : integer,
   terminal_num : integer,
   offset : integer,
   c : integer,
   tmp_array : array[5] of integer,
   tmp_str : array[20] of integer;

begin
   (*
   k_cpr(PTY_COLOR, "   Entered do_pty_write()"); k_prln(1);
   *)

   (* Copy useful stuff from message to pty struct 
    * otcaller is the process that actually sent the message *)
   tp^.pty_otcaller := m_ptr^.m_source;
   (* TODO change outproc to process needing work not FS (which is m_source)  *)
   (* tp^.pty_outproc := m_ptr^.PROC_NR; *)
   tp^.pty_outproc := m_ptr^.m_source;
   tp^.pty_out_vir := m_ptr^.ADDRESS;
   tp^.pty_outleft := m_ptr^.COUNT;
   tp^.pty_terminal_num := m_ptr^.DEVICE;
   (* DEBUG  What is this ? *)
   (* tp^.pty_waiting := WAITING; *)


   (* AST uses a ptr to func which ultimately calls console() 
    * We use the same func name here but call it directly *)
    (*
   console(tp);
   *)

   (* Given pty_outproc, we can look up the procs DS
    * and then fetch chars from user space. *)
   rp := proc_addr(tp^.pty_outproc);
   SetES(rp^.DS);

   orig_num_chars := tp^.pty_outleft;
   k_cpr(PTY_COLOR, "in PTY_WRITE orig_num_chars is : "); k_cpr_hex_num(PTY_COLOR, orig_num_chars); k_prln(1);

   terminal_num := tp^.pty_terminal_num;


   DebugOut(PTY_COLOR, "  Fetching all chars from user space for output", 1);
   offset := tp^.pty_out_vir;
   (* Fill the out_q *)
   while (tp^.pty_outleft > 0) do begin
      LongFetch(offset, adr(c));
      (* out_char in AST1 is about writing to screen
       * here it is about populating tctlr one char at a time with out_char *)
      tmp_array[0] := c;
      (*
      DebugOut(PTY_COLOR, "   DEBUG - Saw char(from user) : ", 0); tmp_array[1] := 0;
      DebugOut(PTY_COLOR, adr(tmp_array), 1);
      *)
      
      (*
      if (tp^.pty_cum = PTY_OUT_BYTES) then begin
         tctlr_write_to_str_to_term(terminal_num, adr(tp^.pty_outqueue), tp^.pty_cum);
         tp^.pty_cum := 0
      end;
      *)
       
      tp^.pty_outleft := tp^.pty_outleft - 1;
      offset := offset + 1;
      tp^.pty_outqueue[tp^.pty_cum] := c;
      tp^.pty_cum := tp^.pty_cum + 1

   end; (* while loop iterating over pty_outleft chars from user proc *)
   tctlr_write_to_str_to_term(terminal_num, adr(tp^.pty_outqueue), tp^.pty_cum);
   tp^.pty_cum := 0

   (* -------------------- *)
   
   (* TODO 
    * This is NOT what AST does.
    * We are immediately notifying caller that write is complete.
    * AST did it in interrupt.
    * Removed call to finish() in do_pty_int() hierarchy. *)
    (*
   finish(tp, 0);   
   *)
   (*
   k_cpr(PTY_COLOR, "   Leaving do_pty_write()"); k_prln(1)
   *)

end; 
(*=================================================================*)



   

(*=================================================================*
 * pty_task()
 *=================================================================*)
procedure pty_task();
var
   
   (* process number on whose behalf this request is being made.
    * This is NOT necessarily the process making the request
    * which is captured in the m_source field of the recvd message.
    *)
   proc_nr : integer, 
   
   p : ^block_message,
   read_message : ^t_pty_read_message,
   int_message : ^t_pty_int_message,
   write_message : ^t_pty_write_message,
   reply_ptr : ^reply_message,
   (* process number of the actual caller *)
   caller : integer,
   (* number of bytes to transfer; each byte occupies a word in ram *)
   count : integer,

   m_type : integer,

   (* Return status of this task to the caller *)
   return_status : integer,

   start_sector_num : integer,

   TmpBuf : array[6] of integer,
   upper8 : integer,
   lower8 : integer,
   terminal_num : integer,
   clear_reg : integer,
   tp : ^pty_struct_type,

   tmp_str : array[20] of integer;

begin
   ConsoleOut(PTY_COLOR, "PTY Task is starting now...", 1);

   pty_init();

   p := adr(pty_mess);
   reply_ptr := adr(pty_mess);


   while (1) do begin
      if debug_flag  > 1 then begin
         k_cpr(PTY_COLOR, "   PTY: waiting to recv..."); k_prln(1)
      end;
      
      (* Wait for a request *)
      (* format is func, src_dest, m_ptr SYSCALL *)
      (* SEND = 1; RECV = 2 *)
      receive_p(ANY, p);

      (* caller is the actual sender of the message *)
      caller := p^.m_source;

      if debug_flag  > 1 then begin
         BIOS_NumToHexStr(caller, adr(tmp_str));
         DebugOut(PTY_COLOR, "   PTY: Caller aka src is : ", 0); DebugOut(PTY_COLOR, adr(tmp_str), 1);
         
         BIOS_NumToHexStr(p^.m_type, adr(tmp_str));
         DebugOut(PTY_COLOR, "   PTY: m_type is : ", 0); DebugOut(PTY_COLOR, adr(tmp_str), 1);
         read_message := p;
         BIOS_NumToHexStr(read_message^.PROC_NR, adr(tmp_str));
         DebugOut(PTY_COLOR, "   PTY:   PROC_NR (only applies to R/W msgs : ", 0); 
         DebugOut(PTY_COLOR, adr(tmp_str), 1)
      end;
      
      (* Set up message specific pointers.
       * Initialized to 0 to cause mem errors if accidentally refd
       *)
      read_message := 0;
      write_message := 0;
      int_message := 0;

      if (p^.m_type = PTY_READ) then begin
         read_message := p;
         (* TODO disconnect caller and DEVICE
          *
          * Use caller >=2 to define device 
          * This is the MAGIC
          * This is where a given user proc (caller) is tied to a 
          * specific terminal. *)
         read_message^.DEVICE := caller - 2;

         if (debug_flag > 1) then begin
         k_cpr(PTY_COLOR, "   PTY: recvd PTY_READ msg");  k_prln(1)
         end;
         
         (* AST used LINE, we use DEVICE to minimize message confusion *)
         (* tp := adr(tty_struct[p^.PTY_LINE]); *)
         tp := adr(pty_struct[read_message^.DEVICE]);

         BIOS_NumToHexStr(read_message^.DEVICE, adr(tmp_str));
         if debug_flag > 1 then begin
            DebugOut(PTY_COLOR, "   PTY:   DEVICE (to read from) : ", 0); 
            DebugOut(PTY_COLOR, adr(tmp_str), 1)
         end;

         do_pty_read(tp, read_message) 
      end
      else if (p^.m_type = PTY_WRITE) then begin
         write_message := p;
         (* Weve gotten an upstream WRITE request *)
         if (debug_flag > 1) then begin
            k_cpr(PTY_COLOR, "   PTY: recvd PTY_WRITE msg");  k_prln(1)
         end;
         
         (* TODO disconnect caller and DEVICE
          *
          * Use caller >=2 to define device 
          * This is the MAGIC
          * This is where a given user proc (caller) is tied to a 
          * specific terminal. *)
         write_message^.DEVICE := caller - 2;

         if (debug_flag > 1) then begin
            BIOS_NumToHexStr(write_message^.DEVICE, adr(tmp_str));
            DebugOut(PTY_COLOR, "   PTY:   DEVICE (to write to) : ", 0); 
            DebugOut(PTY_COLOR, adr(tmp_str), 1)
         end;

         (* AST used LINE, we use DEVICE to minimize message confusion *)
         (* tp := adr(tty_struct[p^.PTY_LINE]); *)
         tp := adr(pty_struct[write_message^.DEVICE]);

         do_pty_write(tp, write_message) 
      end
      else if p^.m_type = PTY_INT then begin
         (* Something happened with the tctlr *)
         (* lock(); *)
         int_message := p;
         if (debug_flag >= 1) then begin
            k_cpr(PTY_COLOR, "   PTY: Recvd PTY_INT msg...");  k_prln(1)
         end;
         (* TODO invoke do_pty_int *)
         do_pty_int()
         (* restore() *)
      end
      else begin
         k_cpr(PTY_COLOR, "   PTY: UNKNOWN message type!"); k_prln(1);
         return_status := EINVAL
      end

   end
end;   


