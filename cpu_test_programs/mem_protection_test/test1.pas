(* The purpose of this program is to test the memory protection
 * features of the cpu simulator.
 * In order to test the features, the "simulator" format file must be used
 * because it has the "type" information embedded in it.
 * 
 * When assembling this program, set the load address to be $1000
 *)
         
#include <runtime.pas>
#include <k_userio.inc>

var
   ch : integer,
   p : ^integer,
   x : integer;
   

procedure write_to_code();
begin
   (* Assuming there is code at p... try writing to it 
    * Should cause a simulator error *)
   p := $1001;
   p^ := 17
end   ;


procedure read_from_code();
begin
   (* Assuming there is code at p... try reading from it 
    * Should cause a simulator error *)
   p := $1001;
   x := p^
end   ;

procedure exec_none();
begin
   asm
      0x4000 TO_R
      RET
   end
end;
   

   
(* If assembled at x1000, then 1000 will contain data type *)   
procedure exec_data();
begin
   asm
      0x1000 TO_R
      RET
   end
end;
   

procedure read_none();
begin
   (* Assuming there is NONE at p... try reading from it 
    * Should cause a simulator error *)
   p := $4001;
   x := p^
end   ;
   
procedure write_none();
begin
   (* Assuming there is NONE at p... try writing to it 
    * Should cause a simulator error *)
   p := $4001;
   p^ := 93
end   ;
   

   
(*=================================================================*)
begin
	k_pr("Hello World! This is a two way terminal"); k_prln(2);
   k_pr("Attempting a weird memory access...");

   exec_data();
   
   
	k_pr("Goodbye Cruel World!"); k_prln(2);
   asm
      HALT
   end
end.
(*=================================================================*)
	