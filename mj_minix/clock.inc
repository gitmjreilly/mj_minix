(*
 * This file contains the clock task (driver).
 * It is included with the kernel so it has direct access
 * to kernel functions and associate dadta structures.
 *
 * This is meant to be a stand alone process sharing a common
 * address space with the kernel.
 *
 *)

const
   (* When this was 1, fib would sometimes block
    * and then restart when i/o was done on another socket?!!
    *)
   SCHED_RATE = 2;

(*
 * Variables global to clock process
 * should be local to this file (but wont be...) 
 *)
var
   clock_mess : message,
   clk_sched_ticks : integer,
   clock_prev_ptr : ^t_process_entry;


(*=================================================================*)
procedure do_clocktick();
begin
   
   (*
   DebugOut(CLOCK_COLOR, "CLOCK entering do_clock_tick()", 1);
   *)
   clk_sched_ticks := clk_sched_ticks - 1;
   if clk_sched_ticks = 0 then begin
      DebugOut(CLOCK_COLOR, "CLOCK    sched_ticks = 0", 1);
      (*
       * AST does not seem to init prev_ptr...
       *)
      (*
      if (bill_ptr = clock_prev_ptr) then begin 
         DebugOut(CLOCK_COLOR, "CLOCK    bill_ptr = prev_ptr; calling sched", 1);
         sched()
      end;
      *)
      (* TODO restore logic above - for now Force reschedule no matter what ... *)
      sched();
      clk_sched_ticks := SCHED_RATE;
      clock_prev_ptr := bill_ptr
   end
   (*
   DebugOut(CLOCK_COLOR, "CLOCK leaving do_clock_tick()", 1)
   *)
end;
(*=================================================================*)
   

(*=================================================================*
 * clock_task()
 *=================================================================*)
procedure clock_task();

begin
   DebugOut(CLOCK_COLOR, "CLOCK Task is starting now...", 1);

   clk_sched_ticks := SCHED_RATE;
   (*
    * prev_ptr is compared to (global) bill_ptr
    * AST does not seem to initialize it, so we do here...
    * It is used by do_clock_tick to initiate a quantum process switch
    * bill_ptr is set by pick_proc and only ever points to user procs.
    *)
   clock_prev_ptr := proc_addr(HARDWARE);

   while (1) do begin
      DebugOut(CLOCK_COLOR, "==============", 1);
      DebugOut(CLOCK_COLOR, "CLOCK Task about to recv...", 1);
      receive_p(ANY, adr(clock_mess));
      DebugOut(CLOCK_COLOR, "CLOCK Task just recv'd...", 1);
      do_clocktick()
   end
end;   

