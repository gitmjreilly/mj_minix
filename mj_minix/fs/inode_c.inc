#include "inode.inc"

   (*
   t_inode = record
      i_mode : integer;
      i_uid : integer;
      i_size : array[2] of integer;
      i_modtime : array[2] of integer;
      i_gid : integer;
      i_nlinks : integer;
   *)
   
(*=================================================================*)

procedure dump_inode(rip : ^t_inode);

begin
   k_cpr(INODE_COLOR, "Inode dump:");

   k_prln(1); k_cpr(INODE_COLOR, "  i_mode is       : "); k_cpr_hex_num(INODE_COLOR, rip^.i_mode); k_prln(1);
   k_cpr(INODE_COLOR, "  i_uid is        : "); k_cpr_hex_num(INODE_COLOR, rip^.i_uid); k_prln(1);
      k_cpr(INODE_COLOR, "  i_size hi is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_size[0]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_size lo is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_size[1]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_modtime hi is : "); k_cpr_hex_num(INODE_COLOR, rip^.i_modtime[0]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_modtime lo is : "); k_cpr_hex_num(INODE_COLOR, rip^.i_modtime[1]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_gid is        : "); k_cpr_hex_num(INODE_COLOR, rip^.i_gid); k_prln(1);
      k_cpr(INODE_COLOR, "  i_nlinks  is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_nlinks); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[0] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[0]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[1] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[1]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[2] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[2]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[3] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[3]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[4] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[4]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[5] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[5]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[6] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[6]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[7] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[7]); k_prln(1);
      k_cpr(INODE_COLOR, "  i_zone[8] is    : "); k_cpr_hex_num(INODE_COLOR, rip^.i_zone[8]); k_prln(1);
      
   k_cpr(INODE_COLOR, "Inode dump finished:"); k_prln(1)

end;


(*=================================================================*)


(*=================================================================*)
procedure copy_inode_from_block(src : ^integer, sp : ^t_inode);

begin
   copy_16_from_block(src     , adr(sp^.i_mode));   
   copy_16_from_block(src +  2, adr(sp^.i_uid));
   copy_32_from_block(src +  4, adr(sp^.i_size));
   copy_32_from_block(src +  8, adr(sp^.i_modtime));
   copy_8_from_block (src + 12, adr(sp^.i_gid));
   copy_8_from_block (src + 13, adr(sp^.i_nlinks));
   (* Copy 9 zones ( 7 direct; 1 indirect; 1 indirect) *)
   copy_16_from_block(src + 14, adr(sp^.i_zone[0]));
   copy_16_from_block(src + 16, adr(sp^.i_zone[1]));
   copy_16_from_block(src + 18, adr(sp^.i_zone[2]));
   copy_16_from_block(src + 20, adr(sp^.i_zone[3]));
   copy_16_from_block(src + 22, adr(sp^.i_zone[4]));
   copy_16_from_block(src + 24, adr(sp^.i_zone[5]));
   copy_16_from_block(src + 26, adr(sp^.i_zone[6]));
   copy_16_from_block(src + 28, adr(sp^.i_zone[7]));
   copy_16_from_block(src + 30, adr(sp^.i_zone[8]))
end;
(*=================================================================*)


(*=================================================================*)
procedure copy_inode_to_block(src : ^t_inode, dst : ^integer);

begin
   copy_16_to_block(adr(src^.i_mode), dst);   
   copy_16_to_block(adr(src^.i_uid),  dst + 2);
   copy_32_to_block(adr(src^.i_size), dst + 4);
   copy_32_to_block(adr(src^.i_modtime), dst + 8);
   copy_8_to_block (adr(src^.i_gid),     dst + 12);
   copy_8_to_block (adr(src^.i_nlinks),  dst + 13);
   (* Copy 9 zones ( 7 direct; 1 indirect; 1 indirect) *)
   copy_16_to_block(adr(src^.i_zone[0]), dst + 14);
   copy_16_to_block(adr(src^.i_zone[1]), dst + 16);
   copy_16_to_block(adr(src^.i_zone[2]), dst + 18);
   copy_16_to_block(adr(src^.i_zone[3]), dst + 20);
   copy_16_to_block(adr(src^.i_zone[4]), dst + 22);
   copy_16_to_block(adr(src^.i_zone[5]), dst + 24);
   copy_16_to_block(adr(src^.i_zone[6]), dst + 26);
   copy_16_to_block(adr(src^.i_zone[7]), dst + 28);
   copy_16_to_block(adr(src^.i_zone[8]), dst + 30)
end;
(*=================================================================*)


(*=================================================================*)
(* Based on AST1,8503 *)
procedure wipe_inode(rip : ^t_inode);
var
   i : integer;
   
begin
   k_cpr(INODE_COLOR, "Entered wipe_inode");  k_prln(1);
   rip^.i_size := 0;
   rip^.i_dirt := DIRTY;
   i := 0;
   while (i < NR_ZONE_NUMS) do begin
      rip^.i_zone[i] := NO_ZONE;
      i := i + 1
   end;
   
   k_cpr(INODE_COLOR, "Leaving wipe_inode");  k_prln(1)
end;
(*=================================================================*)


(*=================================================================*)
(* Based on AST1,8543 *)
procedure rw_inode(rip : ^t_inode, rw_flag : integer);
var
   offset : integer,
   bp : ^t_buf,
   dip : ^t_inode,
   sp : ^t_super_block,
   b : integer;
   
begin
   k_cpr(INODE_COLOR, "  Entered rw_inode");  k_prln(1);
   sp := get_super(rip^.i_dev);
   
   b := (rip^.i_num / INODES_PER_BLOCK) +
         sp^.s_imap_blocks +
         sp^.s_zmap_blocks +
         2; (* Skip over the boot and super blocks *)
         
   bp := get_block(rip^.i_dev, b, NORMAL);
   
   offset := (rip^.i_num - 1) MOD INODES_PER_BLOCK;
   
   k_cpr(INODE_COLOR, "in rw_inode inode numb is : "); k_cpr_hex_num(INODE_COLOR, rip^.i_num); k_prln(1);

   k_cpr(INODE_COLOR, "            imap blocks  is : "); k_cpr_hex_num(INODE_COLOR, sp^.s_imap_blocks); k_prln(1);
   k_cpr(INODE_COLOR, "            zmap blocks is : "); k_cpr_hex_num(INODE_COLOR, sp^.s_zmap_blocks); k_prln(1);

   k_cpr(INODE_COLOR, "            block num  is : "); k_cpr_hex_num(INODE_COLOR, b); k_prln(1);
   k_cpr(INODE_COLOR, "            offset     is : "); k_cpr_hex_num(INODE_COLOR, offset); k_prln(1);
   
   dip := adr(bp^.b__data) + offset * 32;  (* Multiply by inode size *)
   
   if (rw_flag = READING) then begin
      k_cpr(INODE_COLOR, "Reading inode..."); k_prln(1);
      copy_inode_from_block(dip, rip);
      dump_inode(rip)
   end
   else begin
      copy_inode_to_block(rip, dip);
      bp^.b_dirt := DIRTY
   end;
   
   put_block(bp, INODE_BLOCK);
   rip^.i_dirt := CLEAN;
   
   k_cpr(INODE_COLOR, "leaving rw_inode()"); k_prln(1)
         
end;
(*=================================================================*)


(*=================================================================*)
(* get_inode based on AST1, 8379
 * DEV_STATUS:get_inode - looks done 12 Sep 2013
 *)
function get_inode(dev : integer, numb : integer) : ^t_inode;
 
var
   rip : ^t_inode,
   i : integer,
   xp : ^t_inode;

begin
   xp := NIL_INODE;
   i := 0;
   
   while (i < NR_INODES) do begin
      rip := adr(inode[i]);
      if (rip^.i_count > 0) then begin
         if ((rip^.i_dev = dev) AND (rip^.i_num = numb)) then begin
            rip^.i_count := rip^.i_count + 1;
            retval(rip)
         end
      end
      else begin
         xp := rip
      end;
      
      i := i + 1      
      
   end;

   (*
    * If we got this far, we did not find the inode we 
    * were looking for.  With luck we found a free
    * slot pointed to by xp.
    *)
   if (xp = NIL_INODE) then begin
      (* err_code := ENFILE *)
      retval(NIL_INODE)
   end;
   
   (* If we got this far, we found a free slot. *)
   xp^.i_dev := dev;
   xp^.i_num := numb;
   xp^.i_count := 1;

   if (dev <> NO_DEV) then
      rw_inode(xp, READING);

   retval(xp)
   
end;
(*=================================================================*)


(*=================================================================*)
(* put_inode based on AST1,8421
 * DEV_STATUS:put_inode - WIP
 *)
procedure put_inode(rip : ^t_inode);
 
var
      i : integer,
   xp : ^t_inode;

begin
   k_cpr(INODE_COLOR, "Entered put_inode"); k_prln(1);
   if (rip = NIL_INODE) then return;
   
   rip^.i_count := rip^.i_count - 1;
   if (rip^.i_count = 0) then begin
      (* TODO bunch of stuff to return file blocks... *)
      if (rip^.i_dirt = DIRTY) then begin
         k_cpr(INODE_COLOR, "  rip is dirty - will write it."); k_prln(1);
         rw_inode(rip, WRITING)      
      end
   end;


   k_cpr(INODE_COLOR, "Leaving put_inode"); k_prln(1);
   xp := xp
end;
(*=================================================================*)

(*=================================================================*)
(* dup_inode based on AST1, 8579
 * DEV_STATUS:dup_inode - done
 *)
procedure dup_inode(ip : ^t_inode);
begin
   ip^.i_count := ip^.i_count + 1
end;
(*=================================================================*)


(*=================================================================*)
(* alloc_inode based on AST1, 8446
 * DEV_STATUS:alloc_inode - WIP
 *)
function alloc_inode(dev : integer, bits : integer) : ^t_inode;
var
   rip : ^t_inode,
   sp : ^t_super_block,
   numb : integer,
   b : integer;

begin
   k_cpr(INODE_COLOR, "Entered alloc_inode"); k_prln(1);
   sp := get_super(dev);
   k_cpr(INODE_COLOR, "  Looking for an inode bit..."); k_prln(1);
   b := alloc_bit(adr(sp^.s_imap), sp^.s_ninodes + 1, sp^.s_imap_blocks, 0);
   if (b = NO_BIT) then begin
      k_cpr(INODE_COLOR, "    ERROR Unable to find free inode bit..."); k_prln(1);
      k_cpr(INODE_COLOR, "    Leaving alloc_inode after failing to find free inode bit"); 
      k_prln(1);
      retval(NIL_INODE)   
   end;

   k_cpr(INODE_COLOR, "  Success allocating an inode bit: "); 
   k_cpr_hex_num(INODE_COLOR, b);
   k_prln(1);
   
   
   
   numb := b;
   
   
   

   k_cpr(INODE_COLOR, "  Trying to alloc in-mem inode slot..."); k_prln(1);
   rip := get_inode(NO_DEV, numb);
   if (rip = NIL_INODE) then begin
      k_cpr(INODE_COLOR, "  ERROR unable to alloc in-mem inode slot."); 
      free_bit(adr(sp^.s_imap), b)
   end
   else begin
      k_cpr(INODE_COLOR, "  Success allocating in-mem inode slot."); 
      rip^.i_mode := bits;
      rip^.i_nlinks := 0;
      rip^.i_uid := fp^.fp_effuid;
      rip^.i_gid := fp^.fp_effgid;
      rip^.i_dev := dev;
      wipe_inode(rip)      
   end;
   
   
   k_cpr(INODE_COLOR, "Leaving alloc_inode"); k_prln(1);
   retval(rip)
end; 
(*=================================================================*)

 