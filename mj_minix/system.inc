(*
 * This file contains the system task.
 * It is included with the kernel so it has direct access
 * to kernel structures like the process table (which it
 * needs in order to look up the data segment of the
 * caller process).
 *
 * It is loosely based on kernel/system.c (line 4550)
 *
 * This is meant to be a stand alone process sharing a common
 * address space with the kernel.
 * 
 *)
#include <term_colors.inc>

#define SYSTASK_COLOR ANSI_BLUE

var
   systask_mess : message;



(*=================================================================*
 * do_copy(p) : integer;
 * handles r/w messages
 * Loosely based on AST1,4922
 *
 *=================================================================*)
function do_copy (m_ptr : ^mess_5) :integer;
var
   rp : ^t_process_entry,
   b : integer,
   bytes : integer,
   buf_ptr : ^integer,
   val : integer,
   src_proc : integer,
   dst_proc : integer,
   src_ds : integer,
   dst_ds : integer,
   src_addr : integer,
   dst_addr : integer;
   
begin
   k_cpr(SYSTASK_COLOR, "   System task entered do_copy()..."); k_prln(1);
   src_proc := m_ptr^.SRC_PROC_NR;
   dst_proc := m_ptr^.DST_PROC_NR;
   bytes := m_ptr^.COPY_BYTES[1];
   rp := proc_addr(src_proc);
   src_ds := rp^.DS;
   rp := proc_addr(dst_proc);
   dst_ds := rp^.DS;
   src_addr := m_ptr^.SRC_BUFFER[1];
   dst_addr := m_ptr^.DST_BUFFER[1];
   (*
   k_cpr(SYSTASK_COLOR, "src proc is : "); k_cpr_hex_num(SYSTASK_COLOR, src_proc); k_prln(1);
   k_cpr(SYSTASK_COLOR, "dst proc is : "); k_cpr_hex_num(SYSTASK_COLOR, dst_proc); k_prln(1);
   k_cpr(SYSTASK_COLOR, "numbytes is : "); k_cpr_hex_num(SYSTASK_COLOR, bytes); k_prln(1);
   k_cpr(SYSTASK_COLOR, "src addr is : "); k_cpr_hex_num(SYSTASK_COLOR, src_addr); k_prln(1);
   k_cpr(SYSTASK_COLOR, "dst addr is : "); k_cpr_hex_num(SYSTASK_COLOR, dst_addr); k_prln(1);
   k_cpr(SYSTASK_COLOR, "src DS is   : "); k_cpr_hex_num(SYSTASK_COLOR, src_ds); k_prln(1);
   k_cpr(SYSTASK_COLOR, "dst DS is   : "); k_cpr_hex_num(SYSTASK_COLOR, dst_ds); k_prln(1);
   *)
   while (bytes <> 0) do begin
      SetES(src_ds);
      LongFetch(src_addr, adr(b));
      SetES(dst_ds);
      LongStore(dst_addr, b);
      bytes := bytes - 1;
      src_addr := src_addr + 1;
      dst_addr := dst_addr + 1
   end;
   
   retval(OK)

end;
(*=================================================================*)



(*=================================================================*
 * sys_task()
 *=================================================================*)
procedure sys_task();
   
var
   (* process number on whose behalf this request is being made.
    * This is NOT necessarily the process making the request
    * which is captured in the m_source field of the recvd message.
    *)
   proc_nr : integer, 
   
   p : ^mess_5,
   reply_ptr : ^reply_message,
   (* process number of the actual caller *)
   caller : integer,
   (* number of bytes to transfer; each byte occupies a word in ram *)
   count : integer,

   (* Return status of this task to the caller *)
   r : integer;


begin
   p := adr(systask_mess);
   reply_ptr := adr(systask_mess);

   k_cpr(SYSTASK_COLOR, "System task is starting now..."); k_prln(1);


   while (1) do begin
      
      (* Wait for a request *)
      (* format is func, src_dest, m_ptr SYSCALL *)
      (* SEND = 1; RECV = 2 *)
      receive_p(ANY, p);
      k_cpr(SYSTASK_COLOR, "   System task got a message..."); k_prln(1);

      if (p^.m_type = SYS_COPY) then begin
         r := do_copy(p)
      end
      else begin
         k_cpr(SYSTASK_COLOR, "   SYSTASK: Unknown message type!"); k_prln(1);
         r := E_BAD_FCN
      end;
         
      reply_ptr^.m_type := r;
      (* TODO fillin reply_ptr *)
      send_p(p^.m_source, reply_ptr)
   end
end;   


