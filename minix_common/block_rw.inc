#ifndef BLOCK_RW_INC_INCLUDED
#define BLOCK_RW_INC_INCLUDED

(* Block functions for r/w between block cache and internal structures *)

function get_upper_8(num  : integer) : integer;
var
   i : integer;

begin
   i := 1; 
   while i <= 8  do begin
      num := SRL(num);
      i := i + 1
   end;
   retval(num)
end;

function get_lower_8(num  : integer) : integer;

begin
   retval(num AND $00FF)
end;



procedure copy_8_to_block(src : ^integer, dst : ^integer);
begin
   dst^ := get_lower_8(src^) AND $00FF
end;  


procedure copy_8_from_block(src : ^integer, dst : ^integer);
begin
   dst^ := get_lower_8(src^) AND $00FF
end;  


procedure copy_16_to_block(src : ^integer, dst : ^integer);

var
   b0 : integer,
   b1 : integer;
   
begin
   b1 := get_upper_8(src^);
   b0 := get_lower_8(src^);
   
   dst^ := b0;
   dst := dst + 1;
   dst^ := b1
end;  


procedure copy_16_from_block(src : ^integer, dst : ^integer);
var
   high : integer,
   low : integer,
   i : integer;

begin
   low := get_lower_8(src^);
   src := src + 1;
   high := get_lower_8(src^);
   
   i := 0; while (i < 8) do begin high := sll(high); i := i + 1 end;
   dst^ := high OR low
end;

   
procedure copy_32_from_block(src : ^integer, dst : ^integer);
var
   b0 : integer,
   b1 : integer,
   b2 : integer,
   b3 : integer,
   i : integer;
   
begin
   b0 := get_lower_8(src^);
   src := src + 1;
   b1 := get_lower_8(src^);
   src := src + 1;
   b2 := get_lower_8(src^);
   src := src + 1;
   b3 := get_lower_8(src^);
   
   i := 0; while (i < 8) do begin b3 := sll(b3); i := i + 1 end;
   dst^ := b3  OR b2;
   
   dst := dst + 1;
   i := 0; while (i < 8) do begin b1 := sll(b1); i := i + 1 end;
   dst^ := b1  OR b0
end;  

procedure copy_32_to_block(src : ^integer, dst : ^integer);
var
   b0 : integer,
   b1 : integer,
   b2 : integer,
   b3 : integer;
   
begin
   b3 := get_upper_8(src^);
   b2 := get_lower_8(src^);
   src := src + 1;
   b1 := get_upper_8(src^);
   b0 := get_lower_8(src^);
   
   dst^ := b0;
   dst := dst + 1;
   dst^ := b1;
   dst := dst + 1;
   dst^ := b2;
   dst := dst + 1;
   dst^ := b3
end;  





#endif