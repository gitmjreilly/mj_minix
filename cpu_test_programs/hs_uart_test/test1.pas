(*
   The purpose of this program is to test the high speed serial
   port located at 
      F020 - date in/out
      F021 - status bits
         7 - RES
         6 - RES
         5 - RES
         4 - RES
         3 - out buffer full
         2 - out buffer empty
         1 - in buffer full
         0 - in buffer empty
*)
         
#include <runtime.pas>
#include <k_userio.inc>

var
   ch : integer,
   x : integer,
   DATA_ADDR : ^ integer,
   STATUS_ADDR : ^ integer;

(*=================================================================*)
function hs_char_is_available(): integer;
var
   stat : integer;
   
begin
   stat := STATUS_ADDR^;   
   (* Is the empty flag false?  If so then a char is available *)
   if ((stat AND $0001) = 0) then begin
      retval(1)
   end;
   retval(0)
end;
(*=================================================================*)


(*=================================================================*)
procedure pr_hs_char(ch : integer);

var
   stat : integer;
   
begin
   (* Spin waiting for hs uart to have free space *)
   while (1) do begin
      stat := STATUS_ADDR^;   
      (* Is the full flag false?  If so then a char is available *)
      if ((stat AND $0008) = 0) then break
   end;
   DATA_ADDR^ := ch
end;
(*=================================================================*)


(*=================================================================*)
(* Get an hs char; it is assumed to already be in the hs uart *)
function get_hs_char(): integer;

var
   ch : integer;
   
begin
   ch := DATA_ADDR^;   
   retval(ch)
end;
(*=================================================================*)

   
(*=================================================================*)
procedure init();
begin
   DATA_ADDR := $F020;
   STATUS_ADDR := $F021
end;
(*=================================================================*)
   
   
(*=================================================================*)
begin
   init();
	k_pr("Hello World! This is a two way terminal"); k_prln(2);
   
   while (1) do begin
      (* Check hs port for char; if avail, send to console *)
      if (hs_char_is_available()) then begin
         ch := get_hs_char();
         BIOS_PrintChToUART(0, ch)
      end;
      
      if (console_char_is_available()) then begin
         BIOS_GetChFromUART(0, adr(ch));
         pr_hs_char(ch)
      end
      
      
   end;
   
	k_pr("Goodbye Cruel World!"); k_prln(2);
   asm
      HALT
   end
end.
(*=================================================================*)
	