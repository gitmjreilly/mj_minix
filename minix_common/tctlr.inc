#ifndef TCTLR_INC_INCLUDED
#define TCTLR_INC_INCLUDED

#include <strings.inc>

(* This constant must be matched in the PTY driver *)
#define NUM_TERMINALS 8

#define TCTLR_DATA_ADDR $F020
#define TCTLR_STATUS_ADDR $F021

(*
   * Memory map $F020, $F021 for high speed UART
        * 0 - data in AND out
        * 1 - status bits (15 .. 0)
        *     
        * IN_EMPTY_MASK  = 0x0001 (bit 0)
        * IN_FULL_MASK   = 0x0002 (bit 1)
        * OUT_EMPTY_MASK = 0x0004 (bit 2)
        * OUT_FULL_MASK  = 0x0008 (bit 3)
        *
*)


(*=================================================================*)
type
   (* This type is meant for use by the pty driver *)
   tctlr_status_type = array[NUM_TERMINALS] of record
      num_bytes_received_from_terminal : integer;
      host_transmission_status : integer
   end;
(*=================================================================*)


(*=================================================================*)
(* Get a single char.
 * We spin forever, assuming a char will eventually arrive. *)
function tctlr_get_raw() : integer;
var
   x : integer,
   p : ^integer;
begin
   p := $F036;
   while (1) do begin
      (* If the input buffer is NOT empty, get the char *)
      if (p^  = 0) then break
   end;
   p := $F030;
   x := p^;
   retval(x)
end;      
(*=================================================================*)


(*=================================================================*)
(* Write a single byte to the tctlr
 *   meant for internal use only. *)
procedure _tctlr_write_one(ch : integer);
var
   p : ^integer;
begin
   p := $F035;
   while (1) do begin
      (* If the output fifo is NOT full, break and send char *)
      if (p^  = 0) then break
   end;
   p := $F030;
   p^ := ch
end;
(*=================================================================*)


(*=================================================================*)
(* Single char write to a terminal - requires protocol string
 * format of string is 
 *       String is of form tPPYY followed by ASCII_LF
         PP is the port num in ascii hex
         YY is the amount of data to transmit in ascii hex
         Raw data comes after command line (possibly binary)
  *
  *)
procedure tctlr_write_raw(terminal_num : integer, ch : integer);
var
   t : integer;
begin
   _tctlr_write_one($0074); (* t *)
   _tctlr_write_one(ASCII_ZERO); 
   t := terminal_num + ASCII_ZERO;
   _tctlr_write_one(t); (* term num as ASCII *)
   
   _tctlr_write_one(ASCII_ZERO); 
   _tctlr_write_one(ASCII_ZERO + 1); 
   
   _tctlr_write_one(ASCII_LF); 
   _tctlr_write_one(ch)
end;
(*=================================================================*)



(*=================================================================*)
(* String output - requires protocol string
 * format of command string to is 
 *       String is of form tPPYY followed by ASCII_LF
         PP is the port num in ascii HEX
         YY is the amount of data to transmit in ascii HEX
         Raw data comes after command line (possibly binary)
  *
  *)
procedure tctlr_write_to_str_to_term(terminal_num : integer,  s : ^integer, len : integer);
var
   t : integer,
   ch : integer,
   num_str : array[6] of integer;
   
begin
   (* Send "t" *)
   _tctlr_write_one($0074); (* t *)

   (* Send 2 digit hex terminal num *)
   _tctlr_write_one(ASCII_ZERO); 
   t := terminal_num + ASCII_ZERO;
   _tctlr_write_one(t); (* term num as ASCII *)
   

   (* Send 2 digit hex string lengt *)
   (* Convert the length to a string
    * func returns 4 hex digit string, but we only want the last 2  *)
   num_to_hex_str(len, adr(num_str));
   _tctlr_write_one(num_str[2]); 
   _tctlr_write_one(num_str[3]); 
   
   _tctlr_write_one(ASCII_LF); 
   
   (* Send the string from the queue *)
   while (len > 0) do begin
      ch := s^;
      len := len - 1;
      s := s + 1;
      _tctlr_write_one(ch)      
   end
end;
(*=================================================================*)


(*=================================================================*)
(* Read an ASCII_LF terminated line from the tctlr *)
procedure tctlr_get_line(s : ^integer);
var 
   orig_s : ^integer,
   ch : integer;
   
begin
   orig_s := s;
   while (1) do begin
      ch := tctlr_get_raw();
      if (ch = ASCII_LF) then begin
         s^ := 0;
         break
      end;
      s^ := ch;
      s := s + 1
   end
end;
(*=================================================================*)


(*=================================================================*)
(* Send the receive from terminal command to the tctlr.
 * The tctlr is connected to the high speed serial port
 * String is of form rPPYY - string must end in ASCII_LF
 *   pp is the port num in hex
 *   YY is the amount of data to return
 * YY must be <= filled buffer size (which should have been already determined)
 * 
 * This is the command only.  The data is meant to be retrieved separately.
 * We assume the uart has a large fifo and so the data can be retrieved
 * later without fear of data over run *)
procedure tctlr_receive_from_terminal(
   terminal_num : integer,
   num_bytes_to_retrieve : integer);
   
var
   tmp_str : array[5] of integer,
   p : ^integer;
   
begin
   p := $F030;
   p^ := $72;  (* Send the 'r' *)
   p^ := $30;  (* Send the '0' *)
   p^ := $30 + terminal_num; (* Send ASCII for terminal num *)
   
   num_to_hex_str(num_bytes_to_retrieve, adr(tmp_str));   
   (* We only need last two chars of the 4 digit hex string *)
   p^ := tmp_str[2];
   p^ := tmp_str[3];
   p^ := ASCII_LF
end;
(*=================================================================*)
     
   
(*=================================================================*)
(* Get the tctlr status and store in a ready made structure
 *   The structure contains send and receive data for all terminals
 * String sent to tctlr is of form "s" - string must end in ASCII_LF
 *
 * A sequence of NUM_TERMINALS strings will be returned.  
 * Format of output from tctlr is :
 *   sst followed by ASCII_LF
 * ss is two char hex showing number of bytes in receive buffer for terminal
 * t is one char hex showing when a transmission (from host to terminal) is complete *)
procedure tctlr_get_status(p : ^tctlr_status_type);
   
var
   num_bytes_received_from_terminal : integer,
   host_transmission_status : integer,
   terminal_num : integer,
   tmp_str : array[5] of integer,
   p1 : ^integer,
   s : array[5] of integer;
   
begin
   (* Send the "status" command *)
   p1 := $F030;
   p1^ := $73;  (* Send the 's' *)
   p1^ := ASCII_LF;
  
   (* Now that we've sent the status cmd; get the results *)
   terminal_num := 0;
   while (terminal_num < NUM_TERMINALS) do begin
      tctlr_get_line(adr(tmp_str));

      s[0] := tmp_str[0]; s[1] := tmp_str[1]; s[2] := 0;
      str_to_hex_num(adr(s), adr(num_bytes_received_from_terminal));
      
      host_transmission_status := tmp_str[2] - ASCII_ZERO;
      
      p^[terminal_num].num_bytes_received_from_terminal := num_bytes_received_from_terminal;
      p^[terminal_num].host_transmission_status := host_transmission_status;
      terminal_num := terminal_num + 1
   end
   
end;
(*=================================================================*)

  
(*=================================================================*)
(* Clear the transmission complete flag for a terminal
 * format is cPP followed by ASCII_LF *)  
procedure tctlr_clear_transmission_flag(terminal_num : integer);
var
   p : ^integer,
   tmp_str : array[5] of integer;
begin
   p := $F030;
   p^ := $63;  (* Send the 'c' *)
   p^ := $30;  (* Send the '0' *)
   p^ := $30 + terminal_num; (* Send ASCII for terminal num *) 
   p^ := ASCII_LF

end;
(*=================================================================*)


#endif