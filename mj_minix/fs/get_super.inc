(* Super extra to remove circular conflicts involving get_super *)



(*=================================================================*)
(* Based on AST1,8771
 * Super block for dev is assumed to be present.
 * DEV_STATUS:get_super - looks done 12 Sep 2013
 *)
function get_super(dev : integer) : ^t_super_block;
var
   i : integer,
   sp : ^t_super_block;
   
begin
   i := 0;
while (i < NR_SUPERS) do begin   
   sp := adr(super_block[i]);
   if (sp^.s_dev = dev) then retval(sp);
   i := i + 1
end;

k_cpr(ANSI_WHITE, "Panic can't find superblock for device");
k_cpr_hex_num(ANSI_WHITE, dev)


end;
(*=================================================================*)




(*===============================================================*)
(*
 * alloc_bit based on AST1, 8689
 * We made no attempt to match the AST code.
 * AST tried to allocate a bit near an input bit.
 * This doesn't really matter in 2015 on Jamet's system.
 *)
function alloc_bit(
   map_ptr : ^array[100] of ^t_buf,  
   map_bits : integer,                 (* actual number of bits in map *)
   bit_blocks : integer,               (* actual number of blocks *)
   origin : integer) : integer;        (* origin - bit number to be "near" ignored in this implementation *)
   
var
   block_num : integer,
   byte_num : integer,
   allocated_bit_num : integer,
   tmp : integer,
   bp : ^t_buf;
   
   
begin
   allocated_bit_num := 0;
   k_cpr(MAP_COLOR, "Entered alloc_bit"); k_prln(1);
   k_cpr(MAP_COLOR, "  map_bits "); k_cpr_hex_num(MAP_COLOR, map_bits); k_prln(1);
   k_cpr(MAP_COLOR, "  bit blocks "); k_cpr_hex_num(MAP_COLOR, bit_blocks); k_prln(1);
   
   (* Iterate over all blocks in the map *)
   block_num := 0;
   while (block_num < bit_blocks) do begin
      k_cpr(MAP_COLOR, "  Checking block : "); k_cpr_hex_num(MAP_COLOR, block_num); k_prln(1);
   
      bp := map_ptr^[block_num];
      (* Check every byte in the block *)
      byte_num := 0;
      while (byte_num < 1024) do begin
         if (bp^.b__data[byte_num] <> $00FF) then break;
         
         byte_num := byte_num + 1;
         allocated_bit_num := allocated_bit_num + 8;
         if (__ug(allocated_bit_num, map_bits) ) then begin
            k_cpr(MAP_COLOR, "Leaving alloc_bit; did not find free bit"); k_prln(1);
            retval(NO_BIT)
         end
      end;
      
      (* If we got this far EITHER
       *   we found a byte with a free bit (in which case we are Done OR
       *   we searched the entire block and found nothing.
       * Which was it? *)
      if (byte_num < 1024) then begin
         tmp := bp^.b__data[byte_num];

         if    ((tmp AND $0001) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 0;
            tmp := tmp OR $0001
         end
         elsif ((tmp AND $0002) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 1;
            tmp := tmp OR $0002
         end
         elsif ((tmp AND $0004) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 2;
            tmp := tmp OR $0004
         end
         elsif ((tmp AND $0008) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 3;
            tmp := tmp OR $0008
         end
         elsif ((tmp AND $0010) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 4;
            tmp := tmp OR $0010
         end
         elsif ((tmp AND $0020) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 5;
            tmp := tmp OR $0020
         end
         elsif ((tmp AND $0040) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 6;
            tmp := tmp OR $0040
         end
         elsif ((tmp AND $0080) = 0) then begin 
            allocated_bit_num := allocated_bit_num + 7;
            tmp := tmp OR $0080
         end;

         bp^.b__data[byte_num] := tmp;
         bp^.b_dirt := DIRTY;
         k_cpr(MAP_COLOR, "Leaving alloc_bit; success bit num: ");
         k_cpr_hex_num(MAP_COLOR, allocated_bit_num); k_prln(1);
         retval(allocated_bit_num)
      end;
      
      block_num := block_num + 1
      
   end;
   
   k_cpr(MAP_COLOR, "Leaving alloc_bit; did not find free bit - ran out of blocks"); k_prln(1);
   retval(NO_BIT)
end;   
(*=================================================================*)




(*=================================================================*)
(*
 * free_bit based on AST1, 8747
 * We made no attempt to match the AST code.
 *)
procedure free_bit(
   map_ptr : ^array[100] of ^t_buf,  
   bit_returned : integer);
   
var
   block_num : integer,
   byte_offset_in_block : integer,
   bit_offset_in_byte : integer,
   bit_offset_in_block : integer,
   bp : ^t_buf;
   
   
begin
   block_num := bit_returned / 8192;
   bp := map_ptr^[block_num];
   
   bit_offset_in_block := bit_returned MOD 8192;
   byte_offset_in_block := bit_offset_in_block / 8;
   bit_offset_in_byte := bit_offset_in_block MOD 8;
   
   (* TODO Notice the implicit assumption that bit is set *)
   if    (bit_offset_in_byte = 0) then bp^.b__data[byte_offset_in_block] := $FE AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 1) then bp^.b__data[byte_offset_in_block] := $FD AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 2) then bp^.b__data[byte_offset_in_block] := $FB AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 3) then bp^.b__data[byte_offset_in_block] := $F7 AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 4) then bp^.b__data[byte_offset_in_block] := $EF AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 5) then bp^.b__data[byte_offset_in_block] := $DF AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 6) then bp^.b__data[byte_offset_in_block] := $BF AND bp^.b__data[byte_offset_in_block]
   elsif (bit_offset_in_byte = 7) then bp^.b__data[byte_offset_in_block] := $7F AND bp^.b__data[byte_offset_in_block];
   
   bp^.b_dirt := DIRTY
   
end;   
(*=================================================================*)
