#ifndef READ_INC
#define READ_INC

#include <k_userio.inc>

(*
 * Based on fs/read.c
 *)

(* rw_user based on AST1,10042
 * DEV_STATUS : WIP
 *)
function rw_user(
	s : integer,  (* Space *)
	u : integer,  (* process to r/w to (usually "who") *)
   vir : integer, (* address to move to or from *)
   bytes : integer, (* How much to moove *)
	buff : ^integer,  (* ptr to buff in FS space *)
	direction : integer) (* To or from user *)
      : integer;
var
   umess : mess_5;
   
begin
   k_pr("Entered rw_user..."); k_prln(1);

   if (direction = TO_USER) then begin
      umess.SRC_PROC_NR := FS_PROC_NR;
      umess.SRC_BUFFER[1] := buff;
      umess.DST_PROC_NR := u;
      umess.DST_BUFFER[1] := vir
   end
   else begin
      umess.SRC_PROC_NR := u;
      umess.SRC_BUFFER[1] := vir;
      umess.DST_PROC_NR := FS_PROC_NR;
      umess.DST_BUFFER[1] := buff
   end;
   
   
   umess.COPY_BYTES[1] := bytes;
   umess.m_type := SYS_COPY;
   send_p(SYSTASK, adr(umess));
   receive_p(SYSTASK, adr(umess));

   k_pr("Leaving rw_user..."); k_prln(1);
   retval(umess.m_type)
end;


(*******************************************************************)
(* read_map based on AST1,9984
 * DEV_STATUS : WIP
 *)
(* Given inode and position within file,
 * return the BLOCK number in which that position may be found.
 * TODO use full 32 bits of position
 * note position is 32 bits and block_pos is also 32 bits.
 *) 
function read_map(rip : ^t_inode, position : ^array[2] of integer) : integer;

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
   (* excess is the number of zones beyond what can be stored in the inode.
    * in AST1, 9995 this is a long..
    *)
   excess : integer;

begin
   k_cpr(FS_COLOR, "Entered read_map pos is : "); 
   k_cpr_hex_num(FS_COLOR, position^[1]);
   k_prln(1);
   (* scale := scale_factor(rip); *)
   scale := 0;
   
   (* block_pos := position / BLOCK_SIZE; - AST1,10000 !!! had to
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
   (* Looking for block offset within a zone
    * in our case, the offset is always zero.
    *)
   boff := block_pos - zone;
    
   (* Is zone within described in inode? *)
   if (zone < NR_DZONE_NUM) then begin
      k_cpr(FS_COLOR, "  zone < NR_DZONE_NUM..."); k_prln(1);
      z := rip^.i_zone[zone];
      if z = NO_ZONE then begin
         k_cpr(FS_COLOR, "Leaving read_map - returning NO_ZONE"); k_prln(1);
         retval(NO_BLOCK)
      end;
      (* b := z << scale + boff *)
      b := z;
      k_cpr(FS_COLOR, "Leaving read_map - found block :"); 
      k_cpr_hex_num(FS_COLOR, b);
      k_prln(1);
      retval(z)   
   end;
  
   (* If we got this far zone is either single or double indirect *)
   excess := zone - NR_DZONE_NUM;
   k_cpr(FS_COLOR, "  Accessing an indirect zone - zone is : "); k_pr_hex_num(zone); 
   k_cpr(FS_COLOR, "    excess is : "); k_pr_hex_num(excess); k_prln(1);

   if (excess < NR_INDIRECTS) then begin
      k_cpr(FS_COLOR, "  zone < NR_INDRECTS..."); k_prln(1);
      (* No need to any zone, block conversions.
       * z now represents the block with the indirect zone numbers
       * eg if z is 50 then block 50 contains 512 16 bit zone numbers.
       *)
      z := rip^.i_zone[NR_DZONE_NUM];
      k_cpr(FS_COLOR, "    z (blk with indirects) is : "); k_pr_hex_num(z); k_prln(1)
   end;
   (* TODO add support for double indirects *)
   
   if z = NO_ZONE then begin
      k_cpr(FS_COLOR, "Leaving read_map - returning NO_ZONE"); k_prln(1);
      retval(NO_BLOCK)
   end;
   


   b := z;
   bp := get_block(rip^.i_dev, b, NORMAL);
   k_cpr(FS_COLOR, "    fetched block : "); k_pr_hex_num(b); k_prln(1);
   (* Now that we have the block with the indirect block numbers
    * we need to look inside of it to get the actual block number.
    * Remember the first NR_DZONE_NUM blocks were described in the inode.
    * The 16 bit numbers are stored as 2 16 bit vals because of the way they 
    * are read in.  Little endian.
    *)
   z := bp^.b__data[excess * 2] + (bp^.b__data[excess * 2 + 1])  * 256;
   put_block(bp, INDIRECT_BLOCK);
    
   if z = NO_ZONE then begin
      k_cpr(FS_COLOR, "Leaving read_map - returning NO_ZONE"); k_prln(1);
      retval(NO_BLOCK)
   end;
   
   b := z;
   k_cpr(FS_COLOR, "    returning block num : "); k_pr_hex_num(b); k_prln(1);
   k_cpr(FS_COLOR, "Leaving read_map - OK"); k_prln(1);

   retval(b)

end;   
(*******************************************************************)


(*******************************************************************)
(* rw_chunk based on AST1,9919
 * DEV_STATUS WIP
 *)
function rw_chunk (
   rip : ^t_inode,
   position : ^t_s32,
   off : integer,       (* AST has this has unsigned.  Should it be t_s32 here? *)
   chunk : integer,
   rw_flag : integer,
   buff : integer,      (* AST has this as pointer, but it is in user space *)
   seg : integer,
   usr : integer) : integer;
   
var
   b : integer,
   r : integer,
   dev : integer,
   dir : integer,
   n : integer,
   bp : ^t_buf;
   
begin
   k_cpr(RW_COLOR, "Entered rw_chunk()"); k_prln(1);
   k_cpr(RW_COLOR, "  pos is "); k_pr_hex_num(position^[0]); k_pr_hex_num(position^[1]); k_prln(1);
   b := read_map(rip, position);
   dev := rip^.i_dev;
   k_cpr(RW_COLOR, "    dev is "); k_pr_hex_num(dev); k_prln(1);
   k_cpr(RW_COLOR, "    blk is "); k_pr_hex_num(b); k_prln(1);
   
   n := NORMAL;
   bp := get_block(dev, b, n);
   
   if rw_flag = READING then begin
      dir := TO_USER
   end
   else begin
      dir := FROM_USER
   end;
   
   k_cpr(RW_COLOR, "    addr of bdata is "); k_pr_hex_num(adr(bp^.b__data)); k_prln(1);
   k_cpr(RW_COLOR, "    off is "); k_pr_hex_num(off); k_prln(1);
   r := rw_user(seg, usr, buff, chunk, (adr(bp^.b__data) + off),   dir);
   
   if (off + chunk) = BLOCK_SIZE then begin
      n := FULL_DATA_BLOCK
   end
   else begin
      n := PARTIAL_DATA_BLOCK
   end;
   put_block(bp, n);
   
   k_cpr(RW_COLOR, "Leaving rw_chunk"); k_prln(1);
   retval(r)
end;
(*******************************************************************)


(*******************************************************************)
(* This is tricky.  There is a lot of mixed 16/32 signed, unsigned 
 * arithmetic.  In this implementation, I am going with as much 
 * 32 bit signed arithmetic as possible.
 * Please note the following fields come from the input message:
 *    nbytes : integer
 *    buffer : pointer to mem location
 *    fd : integer
 *
 *)
function read_write(rw_flag : integer) : integer;
var
   zero_32 : t_s32,
   block_size_32 : t_s32,
   rip : ^t_inode,
   f : ^t_filp,
   bytes_left : t_s32,
   f_size : t_s32,
   off : integer,
   nbytes_32 : t_s32,
   ans_32 : t_s32,
   off_32 : t_s32,
   buffer_32 : t_s32,
   position : t_s32,
   cum_io :t_s32,
   r : integer,
   chunk : integer,
   chunk_32 : t_s32,
   mode_word : integer,
   virg : integer,
   usr : integer,
   seg : integer;
   
   
begin
   k_cpr(RW_COLOR, "Entered read_write()"); k_prln(1);
   s32_set_zero(adr(zero_32));
   
   block_size_32[1] := BLOCK_SIZE;
   block_size_32[0] := 0;
   
   k_cpr(RW_COLOR,  "  nbytes (to read/write) is : "); k_prnum(nbytes); k_prln(1);
   nbytes_32[0] := 0;
   nbytes_32[1] := nbytes;
      
   buffer_32[0] := 0;
   buffer_32[1] := buffer;
   
   (* TODO add special handling for MM *)
   rw_flag := rw_flag;
   usr := who;
   k_cpr(RW_COLOR,  "  usr is : "); k_prnum(usr); k_prln(1);
   seg := D;
   if nbytes = 0 then begin
      k_cpr(RW_COLOR, "Leaving read_write()"); k_prln(1);
      retval(0)
   end;
   
   (* Check on the size of the requested r/w.
    * Only the MM is allowed to set nbytes > 32K - dont know why..
    *)
   if (who <> MM_PROC_NR) AND (__ug(nbytes, $7FFF)) then begin
      retval(EINVAL)
   end;
     
   (* check for a valid fd 
    * err_code is globally set by get_filp
    *)
   f := get_filp(fd);
   if (f = NIL_FILP) then begin
      retval(err_code)
   end;
   
   (* Now that we have the filp entry, we can get the r/w current position
    * which is a 32 bit signed value.
    * REMEMBER position is NOT the size.
    *
    * There is also a check for position < 0
    * In 32 bits this means a file > 2GB!
    * Not sure how it would ever get that large given other checks.
    * Maybe AST was just being safe.
    *)
   s32_copy(adr(f^.filp_pos), adr(position));
   if s32_l(adr(position), adr(zero_32)) then begin
      retval(EINVAL)
   end;

   (* Get the inode for the given filp entry (which came from the fd *)
   rip := f^.filp_ino;
   
   (* Get the current size of the file *)
   s32_copy(adr(rip^.i_size), adr(f_size));
   k_cpr(RW_COLOR,  "  file size is : ");    k_pr_hex_num(f_size[0]); k_pr_hex_num(f_size[1]); k_prln(1);
   
   r := OK;
   s32_set_zero(adr(cum_io));
   virg := 1; (* True *)
   
   mode_word := rip^.i_mode AND I_TYPE;
   
   (* Outer loop keeps going until there are no bytes 
    * left to be read or written.
    *)
   k_cpr(RW_COLOR,  "  Entering r/w loop..."); k_prln(1);
   while s32_ne(adr(nbytes_32), adr(zero_32))  do begin
      k_cpr(RW_COLOR,  "  ====== LOOP TOP ====="); k_prln(1);
      k_cpr(RW_COLOR,  "   nbytes is : "); k_pr_hex_num(nbytes_32[0]); k_pr_hex_num(nbytes_32[1]); k_prln(1);
      k_cpr(RW_COLOR,  "   position is : ");       k_pr_hex_num(position[0]); k_pr_hex_num(position[1]); k_prln(1);
      
      (* Figure out exactly how many bytes to read or write
       * given the position, figure out the offset within a block
       * e.g. if the offset is 600, the amount is 424
       * We will read min(424, nbytes_32)
       *)
      __s32_pos_div_and_mod(adr(position), adr(block_size_32), adr(ans_32), adr(off_32)) ; 
      k_cpr(RW_COLOR,  "   pos DIV bs is : "); k_pr_hex_num(ans_32[1]); k_prln(1);
      k_cpr(RW_COLOR,  "   pos MOD bs is : "); k_pr_hex_num(off_32[1]); k_prln(1);
            
      s32_sub(adr(block_size_32), adr(off_32), adr(chunk_32));
      k_cpr(RW_COLOR,  "   chunk to r/w is : "); k_pr_hex_num(chunk_32[0]); k_pr_hex_num(chunk_32[1]); k_prln(1);
      
      
      s32_min(adr(nbytes_32), adr(chunk_32), adr(chunk_32));
      k_cpr(RW_COLOR,  "   min (nbytes, chunk) is : "); k_pr_hex_num(chunk_32[1]); k_prln(1);
      
      if rw_flag = READING then begin
         k_cpr(RW_COLOR,  "  file size is : ");    k_pr_hex_num(f_size[0]); k_pr_hex_num(f_size[1]); k_prln(1);
         k_cpr(RW_COLOR,  "   position is : ");       k_pr_hex_num(position[0]); k_pr_hex_num(position[1]); k_prln(1);
         k_cpr(RW_COLOR, "   bytes_left (before f_size-pos) is : "); k_pr_hex_num(bytes_left[0]); k_pr_hex_num(bytes_left[1]); k_prln(1);
         k_cpr(RW_COLOR, "   positon rt before sub :"); k_pr_hex_num(position[0]); k_pr_hex_num(position[1]); k_prln(1);
         
         s32_sub(adr(f_size), adr(position), adr(bytes_left));
         k_cpr(RW_COLOR, "   bytes_left left  after subtraction is : "); k_pr_hex_num(bytes_left[0]); k_pr_hex_num(bytes_left[1]); k_prln(1);
         (* if s32_le(adr(bytes_left), adr(zero_32)) then begin *)
         if s32_eq(adr(bytes_left), adr(zero_32)) then begin 
            k_cpr(RW_COLOR " bytes_left = 0 - breaking out of loop "); k_prln(1);
            break
         end
         else begin
            k_cpr(RW_COLOR "  bytes_left > zero "); k_prln(1);
            if s32_g(adr(chunk_32), adr(bytes_left)) then begin
               k_cpr(RW_COLOR, "  chunk is > bytes_left!!"); k_prln(1);
               s32_copy(adr(bytes_left), adr(chunk_32));
               chunk := chunk_32[1];
               k_cpr(RW_COLOR, "   new chunk size  is : "); k_pr_hex_num(chunk_32[1]); k_prln(1)
            end
         end
      end;
      
      (* TODO Do chunk code ... *)
      k_cpr(RW_COLOR, "  Num bytes left (before reading chunk : "); k_pr_hex_num(bytes_left[0]); k_pr_hex_num(bytes_left[1]); k_prln(1);
      r := rw_chunk(rip, adr(position), off_32[1], chunk_32[1], rw_flag, buffer, seg, usr);
      if r <> OK then begin
         break
      end;
      k_cpr(RW_COLOR,   "At BOTTOM, about to adjust nbytes_32 and chunk_32"); k_prln(1);
      k_cpr(RW_COLOR,  "   nbytes is : "); k_pr_hex_num(nbytes_32[0]); k_pr_hex_num(nbytes_32[1]); k_prln(1);
      k_cpr(RW_COLOR,  "   chunk : "); k_pr_hex_num(chunk_32[0]); k_pr_hex_num(chunk_32[1]); k_prln(1);
      s32_add(adr(buffer_32), adr(chunk_32), adr(buffer_32));
      s32_sub(adr(nbytes_32), adr(chunk_32), adr(nbytes_32));
      s32_add(adr(cum_io), adr(chunk_32), adr(cum_io));
      
      s32_add(adr(position), adr(chunk_32), adr(position));
      k_cpr(RW_COLOR,  "   new position after reading chunk is : ");       k_pr_hex_num(position[0]); k_pr_hex_num(position[1]); k_prln(1);
      virg := 0
   end;
   k_cpr(RW_COLOR, "  Finished big loop"); k_prln(1);
   
   s32_copy(adr(position), adr(f^.filp_pos));
   
   (* Skip read ahead code for now... *)
   if r = OK then begin
      retval(cum_io[1])
   end
   else begin
      retval(r)
   end;
   
   k_cpr(RW_COLOR, "Leaving read_write()"); k_prln(1)
end;
(*******************************************************************)


(*******************************************************************)
function do_read() : integer;
begin
   retval(read_write(READING))
end;
(*******************************************************************)


#endif