(* 
 * Based on fs/super.c
 *)

#ifndef SUPER_C_INC
#define SUPER_C_INC

#include "super.inc"
#include "utility.inc"



(*=================================================================*)
(* Based on AST1,8810
 * DEV_STATUS:scale_factor - 
 * Just a stub. - We assume block to zone is 1:1
 *)
function old_scale_factor(ip : ^t_inode) : integer;
begin
   (* sp^.s_log_zone_size  (sp for this ip) *)
   retval(0)
end;
(*=================================================================*)


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
(*
 * load_bit_maps based on AST1, 8631
 *)
function load_bit_maps(dev : integer) : integer;
var
   sp : ^t_super_block,
   i : integer,
   zbase : integer;
   
begin
   k_cpr(FS_COLOR, "DEBUG entered load_bit_maps()"); k_prln(1);
   sp := get_super(dev);
   if (bufs_in_use + sp^.s_imap_blocks + sp^.s_zmap_blocks + 3) >= NR_BUFS then
      retval(ERROR);
   if ( ( sp^.s_imap_blocks > I_MAP_SLOTS) OR
        ( sp^.s_zmap_blocks > ZMAP_SLOTS)    ) then 
      panic("too many map blocks", NO_NUM);
      
   k_cpr(FS_COLOR, "   about to read   imap_blocks :"); 
   k_cpr_hex_num(FS_COLOR, sp^.s_imap_blocks); k_prln(1);
   i := 0;
   while (i < sp^.s_imap_blocks) do begin
      sp^.s_imap[i] := get_block(dev, SUPER_BLK + 1 + i, NORMAL);
      i := i + 1
   end;
   
   k_cpr(FS_COLOR, "   about to read   zmap_blocks :"); 
   k_cpr_hex_num(FS_COLOR, sp^.s_zmap_blocks); k_prln(1);
   zbase := SUPER_BLK + 1 + sp^.s_imap_blocks;
   i :=0;
   while (i < sp^.s_zmap_blocks) do begin
      sp^.s_zmap[i] := get_block(dev, zbase + i, NORMAL);
      i := i + 1
   end;
   sp^.s_imap[0]^.b__data[0] := sp^.s_imap[0]^.b__data[0] OR 3;
   sp^.s_zmap[0]^.b__data[0] := sp^.s_zmap[0]^.b__data[0] OR 1;
 
   bufs_in_use := bufs_in_use + sp^.s_imap_blocks + sp^.s_zmap_blocks;
   k_cpr(FS_COLOR, "DEBUG leaving load_bit_maps()"); k_prln(1);
   retval(OK)
end;


procedure dump_bit_maps();
var
   bp : ^t_buf,
   sp : ^t_super_block,
   word_num : integer;
   
begin
   k_cpr(FS_COLOR, "Dumping Bit maps..."); k_prln(1);
   sp := get_super(ROOT_DEV);

   k_cpr(FS_COLOR, "  Dumping INODE Bit maps..."); k_prln(1);
   bp := sp^.s_imap[0];
   k_cpr(FS_COLOR, "  bp for inode bit map is : "); k_cpr_hex_num(FS_COLOR, bp); k_prln(1);
   word_num := 0;
   while (word_num < 100) do begin
      k_cpr_hex_num(FS_COLOR, bp^.b__data[word_num]); k_prln(1);
      word_num := word_num + 1
   end;

   bp := sp^.s_zmap[0];
   k_cpr(FS_COLOR, "  Dumping ZONE Bit maps..."); k_prln(1);
   k_cpr(FS_COLOR, "  bp for zone bit map is : "); k_cpr_hex_num(FS_COLOR, bp); k_prln(1);
   word_num := 0;
   while (word_num < 100) do begin
      k_cpr_hex_num(FS_COLOR, bp^.b__data[word_num]); k_prln(1);
      word_num := word_num + 1
   end;

   k_cpr(FS_COLOR, "Finished Dumping Bit maps..."); k_prln(1)

end;

#endif

