(* The purpose of this program is to test the tctlr software
 * by creating an interactive terminal program. *)
         
#include <runtime.pas>
#include <k_userio.inc>
#include <tctlr.inc>
   
var
   terminal_num : integer,
   tctlr_status : tctlr_status_type,
   s: array[80] of integer,
   byte_num : integer,
   num_bytes_to_retrieve : integer,
   ch : integer;
   

   
(*=================================================================*)
(* Main Program *)

begin
	k_pr("Hello World! This is a two way terminal designed to exercise tctlr");
   k_prln(2);

   while (1) do begin
      
    
      if (console_char_is_available()) then begin
         BIOS_GetChFromUART(0, adr(ch));
      
         (* If we got a char, send it to all of the terminals *)
         terminal_num := 0;
         while (terminal_num < NUM_TERMINALS) do begin
            tctlr_write_raw(terminal_num, ch);
            terminal_num := terminal_num + 1
         end
      end;

      (* Get the full status from the tctlr
       * It is an array with an entry per terminal
       * Each entry has the number of bytes received by the host from the terminal
       *    and a transmission status (is 1 if transmission is completed; 0 otherwise *)
      tctlr_get_status(adr(tctlr_status));
      
      (* Clear the transmission flags  *)
      terminal_num := 0;
      while (terminal_num < NUM_TERMINALS) do begin
         tctlr_clear_transmission_flag(terminal_num);
         terminal_num := terminal_num + 1
      end;


      (* Retrieve chars from terminals *)
      terminal_num := 0;
      while (terminal_num < NUM_TERMINALS) do begin
         num_bytes_to_retrieve := tctlr_status[terminal_num].num_bytes_received_from_terminal;

         if (num_bytes_to_retrieve <> 0) then begin

            (* Send cmd to tctlr to retrieve the correct number of bytes
             * This will result in all of the bytes sitting in the large
             * fifo connected to the tctlr.  They can be read at any time. *)
            tctlr_receive_from_terminal(terminal_num, num_bytes_to_retrieve);
            byte_num := 0; 
            while (byte_num < num_bytes_to_retrieve) do begin         
               s[byte_num] := tctlr_get_raw();
               byte_num := byte_num + 1
            end;
            s[byte_num] := 0;
            k_pr(" *** Data from term "); k_prnum(terminal_num); k_pr("   ");k_pr(adr(s)); k_prln(1)
         end;
         terminal_num := terminal_num + 1
      end
   end
end.
(*=================================================================*)
	