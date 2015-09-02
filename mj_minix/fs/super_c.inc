(* 
 * Based on fs/super.c
 *)

#ifndef SUPER_C_INC
#define SUPER_C_INC



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
(*
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
*)


(*==


(*=================================================================*)
(*
 * free_bit based on AST1, 8747
 * We made no attempt to match the AST code.
 *)
 (*
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
*)   
(*=================================================================*)



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

   (* TODO add support for panic! *)
   (*
   if ( ( sp^.s_imap_blocks > I_MAP_SLOTS) OR
        ( sp^.s_zmap_blocks > ZMAP_SLOTS)    ) then 
      panic("too many map blocks", NO_NUM);
   *)
   
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
(*=================================================================*)


(*=================================================================*)
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


(*==================================================================*)
(*
 * rw_super() based on AST1,8824 
 * Read a super block from disk.
 * Reminder super_block is at a known location - block 1
 *    block 0 is always the boot block (used or not)
 * The device is not explicitly specified.  
 * sp points to a t_super_block and sp^.s_dev must already be set.
 *
 * DEV_STATUS:rw_super - done 20130913
 *)

procedure rw_super(
   sp : ^t_super_block, 
   (* rw_flag is either READING or WRITING *)
   rw_flag : integer);

var
   i : integer,
   bp : ^t_buf,
   dev : integer;

begin
   k_cpr(FS_COLOR, "Entered rw_super"); k_prln(1);
   check_buffer_cache();
   if (rw_flag = READING) then begin
      (* Save device because it will be overwritten upon copy. *)
      dev := sp^.s_dev;
      k_cpr(FS_COLOR, "  device is : "); k_prnum(dev); k_prln(1);

	  (* Pls note AST used SUPER_BLOCK but 
	   * with this case INsensitve language SUPER_BLOCK
	   * conflicts with super_block (which is an array of super block entries.
	   * So we use SUPER_BLK
	   *)
      bp := get_block(sp^.s_dev, SUPER_BLK, NORMAL);
      k_cpr(FS_COLOR, "Finished getting super block in rw_super"); k_prln(1);
      check_buffer_cache();
      
      (* Custom copy routine because jam cpu has 16 bit words 
       * Cant use copy() as AST did.
       *)
      copy_super_from_block(adr(bp^.b__data), sp);
      sp^.s_dev := dev;
      (* Weve got the super block now!  Is it correct? *)
    
      k_cpr(FS_COLOR, "  s_inodes is        : "); k_cpr_hex_num(FS_COLOR, sp^.s_ninodes); k_prln(1);
      k_cpr(FS_COLOR, "  s_nzones is        : "); k_cpr_hex_num(FS_COLOR, sp^.s_nzones); k_prln(1);
      k_cpr(FS_COLOR, "  s_imap_blocks is   : "); k_cpr_hex_num(FS_COLOR, sp^.s_imap_blocks); k_prln(1);
      k_cpr(FS_COLOR, "  s_zmap_blocks is   : "); k_cpr_hex_num(FS_COLOR, sp^.s_zmap_blocks); k_prln(1);
      k_cpr(FS_COLOR, "  s_firstdatazone is : "); k_cpr_hex_num(FS_COLOR, sp^.s_firstdatazone); k_prln(1);
      k_cpr(FS_COLOR, "  s_log_zone_size is : "); k_cpr_hex_num(FS_COLOR, sp^.s_log_zone_size); k_prln(1);
      k_cpr(FS_COLOR, "  s_max_size (up) is : "); k_cpr_hex_num(FS_COLOR, sp^.s_max_size[0]); k_prln(1);
      k_cpr(FS_COLOR, "  s_max_size (lo) is : "); k_cpr_hex_num(FS_COLOR, sp^.s_max_size[1]); k_prln(1);
      k_cpr(FS_COLOR, "  s_magic is         : "); k_cpr_hex_num(FS_COLOR, sp^.s_magic); k_prln(1)
   end
   else begin (* TODO fix this !! We are writing *)
      bp := get_block(sp^.s_dev, SUPER_BLK, NO_READ);
      copy_super_from_block(adr(bp^.b__data), sp);
      bp^.b_dirt := DIRTY
   end;

   sp^.s_dirt := CLEAN;
   put_block(bp, ZUPER_BLOCK);
   k_cpr(FS_COLOR, "Finished putting block in rw_super"); k_prln(1);
   check_buffer_cache();

   k_cpr(FS_COLOR, "Leaving rw_super"); k_prln(1)

end;
(*==================================================================*)


(*==================================================================*)
(*
 * load_super() based on AST1 9231
 * DEV_STATUS: load_super - WIP
 *)

procedure load_super();
var
   super_num : integer,
   sp : ^t_super_block,
   rip : ^t_inode;

begin
   k_cpr(FS_COLOR, "Entered load_super"); k_prln(1);
   super_num := 0;
   while (super_num < NR_SUPERS) do begin
      super_block[super_num].s_dev := NO_DEV;
      super_num := super_num + 1
   end;

   (* Read super_block for root file system. *)
   sp := adr(super_block[0]);
   sp^.s_dev := ROOT_DEV;

   rw_super(sp, READING);
   rip := get_inode(ROOT_DEV, ROOT_INODE);
   k_cpr(FS_COLOR, " rip is : "); k_cpr_hex_num(FS_COLOR, rip); k_prln(1);
   (* Check Super Block For Consistency *)
   if (  (rip^.i_mode AND I_TYPE) <> I_DIRECTORY OR
         (sp^.s_magic <> SUPER_MAGIC)               ) then
      panic("Root file system is corrupted.", NO_NUM);

   k_cpr(FS_COLOR, "  DEBUG load_super():Root inode looks good!"); k_prln(1);

      
   sp^.s_imount := rip;
   dup_inode(rip);
   sp^.s_isup := rip;
   sp^.s_rd_only := 0;
  
   if (load_bit_maps(ROOT_DEV) <> OK) then
      panic("init: can't load root bit maps", NO_NUM);
 
   dump_bit_maps();
  
   k_cpr(FS_COLOR, "Leaving  load_super"); k_prln(1)

end;
(*==================================================================*)



#endif

