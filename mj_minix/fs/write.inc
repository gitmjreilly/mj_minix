#ifndef WRITE_INC
#define WRITE_INC

#include <k_userio.inc>
#include "param.inc"
#include "super_c.inc"
#include "filedes.inc"

(*
 * Based on fs/write.c
 *)

 
 
(*******************************************************************)
(* zero_block based on AST1, 10318
 * DEV_STATUS : WIP
 *)
procedure zero_block(bp : ^t_buf);
var
   i : integer;
   
begin
   i := 0;
   while (i < 1024) do begin
      bp^.b__data[i] := 0;
      i := i + 1
   end;
   bp^.b_dirt := DIRTY
end;
(*******************************************************************)



(*******************************************************************)
(* write_map based on AST1, 10135
 * DEV_STATUS : WIP
 *)
(* Given a file described by rip, and logical position
 * connect new_zone to it by updating direct, indirect or doubly indirect
 * zone pointer AND ensure inode is written by marking it DIRTY.
 * Please note a new block may have to be allocated, if the position
 * "spills over" into an indirect or doubly indirect block.
 *) 
function write_map(rip : ^t_inode, position : ^array[2] of integer, new_zone : integer) : integer;

var
   bp : ^t_buf,
   scale : integer,
   block_pos : t_s32,
   zone : integer,
   boff : integer,
   b : integer,
   z : integer,
   i : integer,
   x : integer,
   new_ind : integer,
   new_dbl : integer,
   zp : ^integer,
   (* excess is the number of zones beyond what can be stored in the inode.
    * in AST1, 9995 this is a long..
    *)
   excess : integer;

begin
   k_cpr(FS_COLOR, "Entered write_map pos is : "); 
   k_cpr_hex_num(FS_COLOR, position^[0]);   k_cpr_hex_num(FS_COLOR, position^[1]);
   k_prln(1);
   
   rip^.i_dirt := DIRTY;
   bp := NIL_BUF;
   
   (* scale := scale_factor(rip); *)
   scale := 0;
   
   (* block_pos := position / BLOCK_SIZE; - AST1,10156 !!! had to
    * translated as shown below.
    *)
   block_pos[0] := position^[0];
   block_pos[1] := position^[1];
   i := 0;
   while i < 10 do begin
      s32_srl(adr(block_pos));
      i := i + 1
   end;
   
   (* zone := block_pos >> scale
    * scale is always 0
    * since zone is only 16 bits, we only need the lower
    * portion of block_pos
    *)
   zone := block_pos[1];
   k_cpr(FS_COLOR, "  Given position above zone is  : "); 
   k_cpr_hex_num(FS_COLOR, zone);
   k_prln(1);

    
   (* Is zone described in inode? *)
   if (zone < NR_DZONE_NUM) then begin
      k_cpr(FS_COLOR, "  zone < NR_DZONE_NUM..."); k_prln(1);
      rip^.i_zone[zone] := new_zone;
      k_cpr(FS_COLOR, "Leaving write_map - zone is in inode"); 
      k_prln(1);
      retval(OK)
   end;
  
   (* If we got this far zone is either single or double indirect *)
   excess := zone - NR_DZONE_NUM;
   k_cpr(FS_COLOR, "  Accessing an indirect zone - zone is : "); k_pr_hex_num(zone); 
   k_cpr(FS_COLOR, "    excess is : "); k_pr_hex_num(excess); k_prln(1);

   new_ind := 0;
   new_dbl := 0;
   
   
   if (excess < NR_INDIRECTS) then begin
      k_cpr(FS_COLOR, "  zone < NR_INDRECTS..."); k_prln(1);
      (* No need to any zone, block conversions.
       * z now represents the block with the indirect zone numbers
       * eg if z is 50 then block 50 contains 512 16 bit zone numbers.
       *)
      zp := adr(rip^.i_zone[NR_DZONE_NUM])
   end;
   (* TODO add support for double indirects *)
   
   if (zp^ = NO_ZONE) then begin
      k_cpr(FS_COLOR, "  There is no indirect zone allocated; will create one"); k_prln(1);
      zp^ := alloc_zone(rip^.i_dev, 0);
      new_ind := 1;
      if (bp <> NIL_BUF) then bp^.b_dirt := DIRTY;
      if (zp^ = NO_ZONE) then begin
         k_cpr(FS_COLOR, "  ERROR unable to alloc indirect zone"); k_prln(1);
         k_cpr(FS_COLOR, "Leaving write_map after error above");  k_prln(1);
         retval(err_code)      
      end
   end;   

   put_block(bp, INDIRECT_BLOCK);
   
   
   b := zp^ (* << scale *); 
   if (new_ind) then begin
      bp := get_block(rip^.i_dev, b, NO_READ);
      zero_block(bp)
   end
   else begin
      bp := get_block(rip^.i_dev, b, NORMAL)   
   end;
   
   k_cpr(FS_COLOR, "  Stuffing new_zone into indirect block at block offset");  
   k_cpr_hex_num(FS_COLOR,  (excess * 2)); k_prln(1);
   GetLower8(new_zone, adr(bp^.b__data[excess * 2]));
   GetUpper8(new_zone, adr(bp^.b__data[excess * 2 + 1]));
   bp^.b_dirt := DIRTY;
   put_block(bp, INDIRECT_BLOCK);
 
   k_cpr(FS_COLOR, "SUCCESSFULLL Leaving write_map ");  k_prln(1);
   retval(OK)

   
end;   
(*******************************************************************)




(*******************************************************************)
(* new_block based on AST1,10265
 * DEV_STATUS : WIP
 *)
(* Given inode and position within file,
 * return pointer to block associated with (rip, position)
 * The block may not exist; if it doesn't it's newly allocated.
 * Implicit assumption is zone <=> block  *)
function new_block(rip : ^t_inode, position : ^array[2] of integer) : integer;

var
   bp : ^t_buf,
   scale : integer,
   block_pos : t_s32,
   zone : integer,
   boff : integer,
   b : integer,
   z : integer,
   i : integer,
   x : integer,
   r : integer,
   (* excess is the number of zones beyond what can be stored in the inode.
    * in AST1, 9995 this is a long..
    *)
   excess : integer;

begin
   k_cpr(FS_COLOR, "Entered new_block pos is : "); 
   k_cpr_hex_num(FS_COLOR, position^[0]);
   k_cpr_hex_num(FS_COLOR, position^[1]);
   k_prln(1);
   (* scale := scale_factor(rip); *)
   scale := 0;
   
   (* Get the blocknum (not zone num) associated with position *)
   k_cpr(FS_COLOR, "  Trying to get block associated w/pos above."); 
   b := read_map(rip, position);
   if (b = NO_BLOCK) then begin
      k_cpr(FS_COLOR, "    No block; we will allocate one."); 
      (* There's no block associated with this position
       * allocate a zone <=> block for it.
       * Notice all we do is allocate a zone on dev.  The Zone is not associated with a particular file yet.
       * AST1 tries to alloc a zone near an existing one
       * for us, this doesn't matter, hence zero parameter *)
      z := alloc_zone(rip^.i_dev, 0);
      if (z = NO_ZONE) then begin 
         k_cpr(FS_COLOR, "  Unable to alloc zone for the position above. Returning."); 
         k_cpr(FS_COLOR, "  Unable to alloc zone for the position above. Returning."); 
         retval(NIL_BUF)
      end;
      k_cpr(FS_COLOR, "  Newly allocd zone is : ");    k_cpr_hex_num(FS_COLOR, z); k_prln(1)

   end;
   
   (* Map the zone z to (rip, position).
    * Basically this results in an update to rip or rips indirect blocks *)
   k_cpr(FS_COLOR, "  attempting to map zone to position"); 
   r := write_map(rip, position, z);
   if (r <> OK) then begin
      k_cpr(FS_COLOR, "  FAILED attempting to map zone to position");
      free_zone(rip^.i_dev, z);
      err_code := r;
      retval(NIL_BUF)
   end;
   
   bp := get_block(rip^.i_dev, b, NO_READ);
   zero_block(bp);
   retval(bp)
  
end;   
(*******************************************************************)





#endif
