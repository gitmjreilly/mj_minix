(*
 * Based on fs/cache.c AST1,8050
 *)

#include <sendrec.inc> 
 
var
   app_mess : message;


   
(*=================================================================*)
(* Diagnostics - not part of AST work
 * Want to confirm buffer cache is structurally correct.
 *)
procedure check_buffer_cache();
var
   i : integer,
   num_verified_bufs_seen : integer,
   num_verified_bufs_in_use : integer,
   ptr : ^ t_buf,
   bp : ^t_buf;
(*
   t_buf = record
      b__data : array [1024] of integer;
      b_next : ^t_buf;
      b_prev : ^t_buf;
      b_hash : ^t_buf;
      b_blocknr : integer;
      b_dev : integer; 
      b_dirt : integer;
      b_count : integer
   end;
*)
   
begin
   return;
   k_cpr(BLOCK_COLOR, "    Checking buffer cache..."); k_prln(1);
   
   num_verified_bufs_seen := 0;
   num_verified_bufs_in_use := 0;
   ptr := front;
   while (ptr <> NIL_BUF) do begin
      num_verified_bufs_seen := num_verified_bufs_seen + 1;
      if (ptr^.b_count > 0) then
         num_verified_bufs_in_use := num_verified_bufs_in_use + 1;
      k_cpr(BLOCK_COLOR, "       Cache Entry:"); k_prln(1);
      k_cpr(BLOCK_COLOR, "         addr:"); k_cpr_hex_num(BLOCK_COLOR, ptr);
      k_cpr(BLOCK_COLOR, " hash:"); k_cpr_hex_num(BLOCK_COLOR, ptr^.b_hash); 
      k_cpr(BLOCK_COLOR, " dev:"); k_cpr_hex_num(BLOCK_COLOR, ptr^.b_dev); 
      k_cpr(BLOCK_COLOR, " block_nr:"); k_cpr_hex_num(BLOCK_COLOR, ptr^.b_blocknr);
      k_cpr(BLOCK_COLOR, " dirt:"); k_cpr_hex_num(BLOCK_COLOR, ptr^.b_dirt); 
      k_cpr(BLOCK_COLOR, " count:"); k_cpr_hex_num(BLOCK_COLOR, ptr^.b_count); 
      k_prln(1);
      
      ptr := ptr^.b_next
   end;
   k_cpr(BLOCK_COLOR, "     From front"); k_prln(1);
   k_cpr(BLOCK_COLOR, "       num_bufs_seen : "); k_cpr_hex_num(BLOCK_COLOR, num_verified_bufs_seen); k_prln(1);
   k_cpr(BLOCK_COLOR, "       num_bufs_in_use : "); k_cpr_hex_num(BLOCK_COLOR, num_verified_bufs_in_use); k_prln(1);
   
   num_verified_bufs_seen := 0;
   num_verified_bufs_in_use := 0;
   ptr := rear;
   while (ptr <> NIL_BUF) do begin
      num_verified_bufs_seen := num_verified_bufs_seen + 1;
      if (ptr^.b_count > 0) then
         num_verified_bufs_in_use := num_verified_bufs_in_use + 1;
      
      ptr := ptr^.b_prev
   end;
   k_cpr(BLOCK_COLOR, "     From rear"); k_prln(1);
   k_cpr(BLOCK_COLOR, "       num_bufs_seen : "); k_cpr_hex_num(BLOCK_COLOR, num_verified_bufs_seen); k_prln(1);
   k_cpr(BLOCK_COLOR, "       num_bufs_in_use : "); k_cpr_hex_num(BLOCK_COLOR, num_verified_bufs_in_use); k_prln(1);
   
   k_cpr(BLOCK_COLOR, "     Buffer Hash Chains"); k_prln(1);
   i := 0;
   while (i < NR_BUF_HASH) do begin
      ptr := buf_hash[i];
      k_cpr(BLOCK_COLOR, "     hash : "); k_cpr_hex_num(BLOCK_COLOR, i); 
      while (ptr <> NIL_BUF) do begin
         k_cpr(BLOCK_COLOR, " "); k_cpr_hex_num(BLOCK_COLOR, ptr);
         ptr := ptr^.b_hash
      end;
      k_prln(1);
      
      i := i + 1
   end
      
end;
(*=================================================================*)
  
   
 
(*=================================================================*)
(* Based on AST1,8295
 * AST version does device independent i/o here.
 * This version just deals with raw sectors for now.
 *)
procedure  rw_block(
   bp : ^t_buf,
   rw_flag : integer);

var
   p : ^block_message,
   reply_mess : ^pty_message,
   len : integer,
   abs_disk_position : t_s32,
   block_size_32 : t_s32,
   i : integer,
   status : integer,
   upper10 : integer,
   lower6 : integer;

begin
   k_cpr(BLOCK_COLOR, "entered rw_block"); k_prln(1);
   k_cpr(BLOCK_COLOR, "Address of bp^.b__data is : "); k_cpr_hex_num(BLOCK_COLOR, adr(bp^.b__data)); k_prln(1);

   (*
   upper10 := bp^.b_blocknr AND $FFC0;
   lower6  := bp^.b_blocknr AND $003F;
   abs_disk_position[0] := upper10;
   i := 0;
   while (i < 10) do begin
      lower6 := sll(lower6);
      i := i + 1
   end;
   abs_disk_position[1] := lower6;
   *)
   abs_disk_position[0] := 0;
   abs_disk_position[1] := bp^.b_blocknr;
   block_size_32[0] := 0;
   block_size_32[1] := BLOCK_SIZE;
   s32_mul(adr(abs_disk_position), adr(block_size_32), adr(abs_disk_position));
   
   
   if (rw_flag = WRITING) then begin
	  p := adr(app_mess);
	  reply_mess := adr(app_mess);

	  p^.m_type := DISK_WRITE;
	  (* Device is ignored - assume SD card *)
	  (* Count is  ignored - assume 512 bytes *)
	  p^.DEVICE := 0;
	  p^.COUNT := 512;

	  p^.POSITION[0] := abs_disk_position[0];
	  p^.POSITION[1] := abs_disk_position[1];
	  (* FLOPPY uses message source *)
	  (* TODO verify source is correct *)
	  p^.ADDRESS := adr(bp^.b__data);
	  k_cpr(BLOCK_COLOR, "     rw_block...Sending a message to floppy to write..."); k_prln(1);
	  send_p(FLOPPY, p);
     
	  receive_p(FLOPPY, p);
	  k_cpr(BLOCK_COLOR, "     rw_block...Got a REPLY from floppy to write..."); k_prln(1);

      (* We are reading a 1k block so we have to issue the second 512 byte read *)
	  abs_disk_position[1] := abs_disk_position[1] + 512;
	  
	  if abs_disk_position[1] = 0 then 
	     abs_disk_position[0] := abs_disk_position[0] + 1;
	     
      p := adr(app_mess);
	  reply_mess := adr(app_mess);

	  p^.m_type := DISK_WRITE;

     (* Device is ignored - assume SD card *)
	  (* Count is  ignored - assume 512 bytes *)
	  p^.DEVICE := 0;
	  p^.COUNT := 512;

	  p^.POSITION[0] := abs_disk_position[0];
	  p^.POSITION[1] := abs_disk_position[1];
	  (* FLOPPY uses message source *)
	  (* TODO verify source is correct *)
	  p^.ADDRESS := adr(bp^.b__data) + 512;
	  k_cpr(BLOCK_COLOR, "     rw_block...Sending a second message to floppy to write..."); k_prln(1);
	  send_p(FLOPPY, p);
	  receive_p(FLOPPY, p);
	  k_cpr(BLOCK_COLOR, "     rw_block...Got a second REPLY from floppy to write..."); k_prln(1)

   end
   else begin (* READING *)
	  p := adr(app_mess);
	  reply_mess := adr(app_mess);

	  p^.m_type := DISK_READ;
	  (* Device is ignored - assume SD card *)
	  (* Count is  ignored - assume 512 bytes *)
	  p^.DEVICE := 0;
	  p^.COUNT := 512;

	  p^.POSITION[0] := abs_disk_position[0];
	  p^.POSITION[1] := abs_disk_position[1];
	  (* FLOPPY uses message source *)
	  (* TODO verify source is correct *)
	  p^.ADDRESS := adr(bp^.b__data);
	  k_cpr(BLOCK_COLOR, "     rw_block...Sending a message to floppy to read..."); k_prln(1);
	  send_p(FLOPPY, p);
     
	  receive_p(FLOPPY, p);
	  k_cpr(BLOCK_COLOR, "     rw_block...Got a REPLY from floppy to read..."); k_prln(1);

      (* We are reading a 1k block so we have to issue the second 512 byte read *)
	  abs_disk_position[1] := abs_disk_position[1] + 512;
	  
	  if abs_disk_position[1] = 0 then 
	     abs_disk_position[0] := abs_disk_position[0] + 1;
	     
      p := adr(app_mess);
	  reply_mess := adr(app_mess);

	  p^.m_type := DISK_READ;

     (* Device is ignored - assume SD card *)
	  (* Count is  ignored - assume 512 bytes *)
	  p^.DEVICE := 0;
	  p^.COUNT := 512;

	  p^.POSITION[0] := abs_disk_position[0];
	  p^.POSITION[1] := abs_disk_position[1];
	  (* FLOPPY uses message source *)
	  (* TODO verify source is correct *)
	  p^.ADDRESS := adr(bp^.b__data) + 512;
	  k_cpr(BLOCK_COLOR, "     rw_block...Sending a second message to floppy to read..."); k_prln(1);
	  send_p(FLOPPY, p);
	  receive_p(FLOPPY, p);
	  k_cpr(BLOCK_COLOR, "     rw_block...Got a second REPLY from floppy to read..."); k_prln(1)

   end;
   
   bp^.b_dirt := CLEAN;
   
   k_cpr(BLOCK_COLOR, "leaving rw_block"); k_prln(1)
end;
(*=================================================================*)

(*=================================================================*)
(* Based on AST1, 8079 *)
function get_block(
   dev : integer,
   block : integer,
   (* only_search is an optimization
    * if NO_READ, dont bother reading, otherwise act normal
    *)
   only_search : integer) : ^t_buf;

var
   bp : ^t_buf,
   prev_ptr : ^t_buf;


begin
   k_cpr(BLOCK_COLOR, "DEBUG Entered get_block()"); k_prln(1);
   k_cpr(BLOCK_COLOR, "  dev is : "); k_prnum(dev); k_prln(1);
   k_cpr(BLOCK_COLOR, "  block is : "); k_pr_hex_num(block); k_prln(1);

   k_cpr(BLOCK_COLOR, "     cache before adjustments..."); k_prln(1);
   check_buffer_cache();
   (* Point at the head of the hash chain for this block *)
   bp := buf_hash[block AND (NR_BUF_HASH - 1)] ;

   (* AST1,8100 checks for NO_ DEV.  Not sure why this would ever happen... *)
   if (dev <> NO_DEV) then begin
      k_cpr(BLOCK_COLOR, "  Searching hash chain..."); k_prln(1);
      while (bp <> NIL_BUF) do begin
         if ( (bp^.b_blocknr = block) AND (bp^.b_dev = dev)) then begin
            k_cpr(BLOCK_COLOR, "    Found theblock..."); k_prln(1);
            (* We found the right block from the right device *)
            if (bp^.b_count = 0) then begin
               k_cpr(BLOCK_COLOR, "      b_count was 0"); k_prln(1);
               bufs_in_use := bufs_in_use + 1;
               k_cpr(BLOCK_COLOR, "      global bufs_in_use is : "); k_prnum(bufs_in_use); k_prln(1)
            end;
            bp^.b_count := bp^.b_count + 1;
            retval(bp)
         end
         else begin
            (* Havent found block yet.  Point at next one...*)
            bp := bp^.b_hash
         end
      end
   end;
   (* If we got this far we didnt find the block...*)
   k_cpr(BLOCK_COLOR, "  We did NOT find the block so we'll have to read it in"); k_prln(1);

   (* Are there any buffers left for us? *)
   if (bufs_in_use = NR_BUFS) then begin
     k_cpr(BLOCK_COLOR, "  Fatal error - All fs buffers are in use"); k_prln(1); while (1) do bp:=bp
   end;

   bufs_in_use := bufs_in_use + 1;

   (* Scan the entire buffer array looking for a free one. *)
   bp := front;
   while (bp^.b_count > 0) AND (bp^.b_next <> NIL_BUF) do bp := bp^.b_next;

   if ( (bp = NIL_BUF) OR (bp^.b_count > 0) ) then begin
     k_cpr(BLOCK_COLOR, "  Fatal error - no free buffers"); k_prln(1); while (1) do bp:=bp
   end;

   k_cpr(BLOCK_COLOR, "     Found a block to use..."); k_prln(1);
   k_cpr(BLOCK_COLOR, "        Its addr is : "); k_cpr_hex_num(BLOCK_COLOR, bp); k_prln(1);
   (* If we got this far, we found an empty block *)
   (* Now we have to remove the block from its old hash chain... *)
   prev_ptr := buf_hash[bp^.b_blocknr AND (NR_BUF_HASH - 1)];
   k_cpr(BLOCK_COLOR, " bp^.b_blocknr is : "); k_cpr_hex_num(BLOCK_COLOR, bp^.b_blocknr); k_prln(1);
   k_cpr(BLOCK_COLOR, " About to remove the found block from the hash chain."); k_prln(1);
   k_cpr(BLOCK_COLOR, " Hash Chain Ptr is : "); k_cpr_hex_num(BLOCK_COLOR, prev_ptr); k_prln(1);
   if (prev_ptr = bp) then begin
      buf_hash[bp^.b_blocknr AND (NR_BUF_HASH - 1)] := bp^.b_hash
   end
   else begin
      while (prev_ptr^.b_hash <> NIL_BUF) do begin
         if (prev_ptr^.b_hash = bp) then begin
            prev_ptr^.b_hash := bp^.b_hash;
            break
         end
         else begin
            prev_ptr := prev_ptr^.b_hash
         end
      end
   end;
   k_cpr(BLOCK_COLOR, "     Finished removing block from old hash chain..."); k_prln(1);

   if (bp^.b_dirt = DIRTY) AND (bp^.b_dev <> NO_DEV) then begin
      k_cpr(BLOCK_COLOR, "     saving dirty block..."); k_prln(1);
      rw_block(bp, WRITING)
   end;
   (* OK. Now, finally, we can use the block bp points to... *)
   bp^.b_dev := dev;
   bp^.b_blocknr := block;
   bp^.b_count := bp^.b_count + 1;
   bp^.b_hash := buf_hash[bp^.b_blocknr AND (NR_BUF_HASH - 1)];
   buf_hash[bp^.b_blocknr AND (NR_BUF_HASH - 1)] := bp;

   k_cpr(BLOCK_COLOR, "     cache after adjustments..."); k_prln(1);
   check_buffer_cache();
   
   if ((dev <> NO_DEV) AND (only_search = NORMAL)) then begin
      k_cpr(BLOCK_COLOR, "     reading block"); k_prln(1);
      rw_block(bp, READING)
   end;


   k_cpr(BLOCK_COLOR, "DEBUG Leaving get_block()"); k_prln(1);
   retval(bp)
end;
(*=================================================================*)


(*=================================================================*)
procedure put_block(bp : ^t_buf, block_type : integer);

var
   next_ptr : ^t_buf,
   prev_ptr : ^t_buf;

begin
   if (bp = NIL_BUF) then return;
   k_cpr(BLOCK_COLOR, "DEBUG Entered put_block() and bp is not NIL"); k_prln(1);
   k_cpr(BLOCK_COLOR, "     cache before adjustments..."); k_prln(1);
   check_buffer_cache();
   
   
   (* Check to see if the block is still in use
    * If so, just note the count has decreased.
    * If it is no longer in use remove it from the LRU list.
    *)
   bp^.b_count := bp^.b_count - 1;
   if (bp^.b_count > 0) then return;
   
   (* Note that the GLOBAL total number of bufs IN USE has decreased. *)
   bufs_in_use := bufs_in_use - 1;
   next_ptr := bp^.b_next;
   prev_ptr := bp^.b_prev;
   if (prev_ptr <> NIL_BUF) then
      prev_ptr^.b_next := next_ptr
   else
      front := next_ptr;
      
   if (next_ptr <> NIL_BUF) then
      next_ptr^.b_prev := prev_ptr
   else begin
      rear := prev_ptr
   end;
      
   (* Put the block back on the LRU chain. *)
   if (block_type AND ONE_SHOT) then begin
      (* Put the block at the front of the LRU chain for quick reuse. *)
      bp^.b_prev := NIL_BUF;
      bp^.b_next := front;
      if (front = NIL_BUF) then
         rear := bp
      else
         front^.b_prev := bp;

      front := bp
   end
   else begin
      (* Block will probably be needed again.  Put it at the REAR or the
       * LRU list so it wont be reused right away.
       *)
      bp^.b_prev := rear;
      bp^.b_next := NIL_BUF;
      if (rear = NIL_BUF) then
         front := bp
      else
         rear^.b_next := bp;
         
      rear := bp
   end;

   (* OK weve put the block back on the LRU list.
    * Some blocks though are so critical we should write
    * them back to disk NOW in case of a crash.
    *)
   if ( (block_type AND WRITE_IMMED <> 0) AND
        (bp^.b_dirt = DIRTY)  AND
        (bp^.b_dev <> NO_DEV)) then begin
      rw_block(bp, WRITING)
   end;
   
   (* Handle the special case of blocks which must NOT be cached
    * because mount might use a cached block.
    * TODO Understand whats happening here...
    *)
   if (block_type = ZUPER_BLOCK) then
      bp^.b_dev := NO_DEV;

   k_cpr(BLOCK_COLOR, "     cache after adjustments..."); k_prln(1);
   check_buffer_cache();
      
   k_cpr(BLOCK_COLOR, "     leaving put_block()..."); k_prln(1)
      
end; 
   
(*=================================================================*)
