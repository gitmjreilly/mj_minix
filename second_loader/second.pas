(*
   port located at 
      F000 - date in/out
      F001
      F002 - tx empty
      F003 - tx 1/2 empty
      F004 - tx 1/4 empty
      F005 - tx full
      F006 - rx empty
      F007 - rx 1/2 full
      F008 - rx 1/4 full
      F009 - rx full
      ---
      F00E - rx num bytes
      F00F - tx num bytes
*)
         
#include <runtime.pas>


var
   data_ptr : ^integer,
   rx_empty_ptr : ^integer,

   type_byte : integer,
   data_word : integer,
   
   length : integer,
   orig_length : integer,
   magic : integer,
   load_addr : ^integer,
   orig_load_addr : ^integer,
   start_addr : ^integer,


   k_stack : array[100] of integer,
   k_rstack : array[100] of integer,
   tmp_str : array[10] of integer;
   
   

(*=================================================================*)
procedure num_to_hex_str(Num : integer, StrPtr : ^integer);
var
   i : integer,
   Tmp : integer;

begin
   (*
    * Trying to figure out how much time this is all taking...
    *)
   StrPtr^ := 0 ;

   Tmp := Num AND $F000;
   (* Pick off most significant hex digit *)
   i := 1; 
   while i <= 12 do begin
      Tmp := SRL(Tmp);
      i := i + 1
   end;
   if Tmp < 10 then
      Tmp := Tmp + 48
   else
      Tmp := Tmp + 55;
   StrPtr^ := Tmp;

   StrPtr := StrPtr + 1;
   Tmp := Num AND $0F00;
   (* Pick off 2nd most significant hex digit *)
   i := 1; 
   while i <= 8 do begin
      Tmp := SRL(Tmp);
      i := i + 1
   end;
   if Tmp < 10 then
      Tmp := Tmp + 48
   else
      Tmp := Tmp + 55;
   StrPtr^ := Tmp;
   
   StrPtr := StrPtr + 1;
   Tmp := Num AND $00F0;
   (* Pick off 3rd most significant hex digit *)
   i := 1; 
   while i <= 4 do begin
      Tmp := SRL(Tmp);
      i := i + 1
   end;
   if Tmp < 10 then
      Tmp := Tmp + 48
   else
      Tmp := Tmp + 55;
   StrPtr^ := Tmp;

   StrPtr := StrPtr + 1;
   Tmp := Num AND $000F;
   if Tmp < 10 then
      Tmp := Tmp + 48
   else
      Tmp := Tmp + 55;
   StrPtr^ := Tmp;

   StrPtr := StrPtr + 1;
   StrPtr^ := 0

end;
(*=================================================================*)
   

(*=================================================================*)
procedure pr(s : ^integer) ;
   
begin
   while (s^ <> 0) do begin
      data_ptr^ := s^;
      s := s + 1
   end;
   data_ptr^ := 10;
   data_ptr^ := 13
end;
(*=================================================================*)

   

(*=================================================================*)
function get_byte() : integer;
   
begin
   while (1) do begin
      if (rx_empty_ptr^ = 0) then break
   end;
   retval(data_ptr^)
end;
(*=================================================================*)


(*=================================================================*)
function get_word() : integer;
begin
   retval(get_byte() * 256 + get_byte())
end;
(*=================================================================*)



(*=================================================================*)
procedure halt();
begin
   asm
      halt
   end
end;
(*=================================================================*)

 
(*=================================================================*)
begin
  ASM
      k_stack K_SP_STORE
      k_rstack RP_STORE
   END;


   pr("Starting second stage loader now!  We expect a sim file."); 

   data_ptr := $F000;
   rx_empty_ptr := $F006;
   
   magic := get_word();
   if (magic <> 0) then begin
      pr("Did not see magic 0");
      halt()
   end;
    
   magic := get_word();
   if (magic <> 2) then begin
      pr("Did not see magic 2");
      halt()
   end;
   
   pr("Saw good magic");
   
   length := get_word();
   orig_length := length;
   
   load_addr := get_word();
   orig_load_addr := load_addr;
   
   start_addr := get_word();
   
   while (length <> 0) do begin
      length := length - 1;
      
      type_byte := get_byte();
      data_word := get_word();
      load_addr^ := data_word;
      load_addr := load_addr + 1
   
   end;


   pr("Successful Load"); 

   
   pr("Start Addr");
   num_to_hex_str(start_addr, adr(tmp_str));
   pr(adr(tmp_str));
      
   pr("Load Addr");
   num_to_hex_str(orig_load_addr, adr(tmp_str));
   pr(adr(tmp_str));
      
   pr("Length");
   num_to_hex_str(orig_length, adr(tmp_str));
   pr(adr(tmp_str));
    
   pr("Press any key to jump to loaded program.");
   type_byte := get_byte();
    
   asm
      start_addr FETCH TO_R RET
   end
   
   
end.
(*=================================================================*)
	