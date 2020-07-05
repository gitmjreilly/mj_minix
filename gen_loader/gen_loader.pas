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
   magic : integer,
   file_format : integer,
   
   (* Made start_addr global for easier reference by asm *)
   start_addr : ^integer,

   k_stack : array[200] of integer,
   k_rstack : array[100] of integer;
   

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
(* halt doesn't really "halt."  It spins in place so it doesn't
 * cause the simulator to stop running.
 *)
procedure halt();
var
   x : integer;
begin
   asm
      HALT
   end;
   while (1) do
      x := x
  
end;
(*=================================================================*)

 
 
(*===================================================================*)
procedure LongTypeStore(LongPtr : integer, Val : integer);
begin
   return;
   
   ASM
      L_VAR -1 FETCH
      L_VAR -2 FETCH
      LONG_TYPE_STORE
   END
end;
(*===================================================================*)

(*===================================================================*)
(*
   We assume first 2 magic words have already been read.  We start
   at word 3.
   
	 V4 output format
	 Each word comes as 2 bytes MSB first
	    word 1     :  Words 1 and 2 are a MAGIC identifier 0000 0003
	    word 2  
	    word 3     : size of CODE in words
	    word 4     : CODE loading address
	    word 5     : CODE starting address
	
	    word 6     : size of DATA in words
	    word 7     : DATA loading address
	
	 words 2 * size in words for code
	
	 words 2 * size in words for data
*)	

procedure load_V4_file();
var
   data_word : integer,
   
   code_length : integer,
   orig_code_length : integer,
   code_load_addr : ^integer,
   orig_code_load_addr : ^integer,
   
   data_length : integer,
   orig_data_length : integer,
   data_load_addr : ^integer,
   orig_data_load_addr : ^integer,
   tmp_str : array[10] of integer;


begin
   pr("Loading a V4 file...");

   (* Word 3 is code length *)
   code_length := get_word();
   orig_code_length := code_length;
   
   (* Word 4 is code Load address *)
   code_load_addr := get_word();
   orig_code_load_addr := code_load_addr;
   
   (* Word 5 is starting address - only applies to code *)
   start_addr := get_word();

   (* Word 6 is data length *)
   data_length := get_word();
   orig_data_length := data_length;

   (* Word 7 is code Load address *)
   data_load_addr := get_word();
   orig_data_load_addr := data_load_addr;
   

   
   while (code_length <> 0) do begin
      code_length := code_length - 1;
      
      data_word := get_word();
            
      code_load_addr^ := data_word;
      
      code_load_addr := code_load_addr + 1   
   end;
   pr("Finished loading code...");


   while (data_length <> 0) do begin
      data_length := data_length - 1;
      
      data_word := get_word();
            
      data_load_addr^ := data_word;
      
      data_load_addr := data_load_addr + 1   
   end;
   pr("Finished loading data...");


   pr("Successful Load!"); 

   
   pr("Start Addr");
   num_to_hex_str(start_addr, adr(tmp_str));
   pr(adr(tmp_str));
      
   pr("Code Load Addr");
   num_to_hex_str(orig_code_load_addr, adr(tmp_str));
   pr(adr(tmp_str));
      
   pr("code_length");
   num_to_hex_str(orig_code_length, adr(tmp_str));
   pr(adr(tmp_str));
   
   
   pr("data Load Addr");
   num_to_hex_str(orig_data_load_addr, adr(tmp_str));
   pr(adr(tmp_str));
      
   pr("data_length");
   num_to_hex_str(orig_data_length, adr(tmp_str));
   pr(adr(tmp_str));
   
   
   
    
   pr("Press any key to jump to loaded program.");
   type_byte := get_byte();
    
   asm
      start_addr FETCH TO_R RET
   end
   
      
end;
(*===================================================================*)

 
 
 
 
(*=================================================================*)
begin
  ASM
      k_stack K_SP_STORE
      k_rstack RP_STORE
   END;

   data_ptr := $F000;
   rx_empty_ptr := $F006;
   
   pr("Starting second stage loader now!  We expect V4 file."); 
   
   file_format := 0;

   magic := get_word();
   if (magic <> 0) then begin
      pr("Did not see magic 0");
      halt()
   end;
    
   magic := get_word();
   if (magic = 4) then begin
      file_format := 4
   end;

   if (file_format = 0) then begin
      pr("Did not see valid magic number!");
      asm
         HALT
      end
   end;

   if (file_format = 4) then begin
      load_V4_file()
   end;
   
   pr("Saw good magic")
   
  
end.
(*=================================================================*)

