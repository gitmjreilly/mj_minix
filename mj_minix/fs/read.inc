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
   block_spec : integer,
   n : integer,
   bp : ^t_buf;
   
begin
   k_cpr(RW_COLOR, "Entered rw_chunk()"); k_prln(1);
   k_cpr(RW_COLOR, "  pos is "); k_pr_hex_num(position^[0]); k_pr_hex_num(position^[1]); k_prln(1);

   (* AST1, 9939 *)
   block_spec := ( (rip^.i_mode AND I_TYPE) = I_BLOCK_SPECIAL);
   (* TODO handle block special devices 
      For now, just complain *)
   if (block_spec) then begin
      k_cpr(RW_COLOR, "    ERROR saw  block spec dev; cannot handle them yet");  k_prln(1);
      retval(1)
   end
   else begin
      k_cpr(RW_COLOR, "    INFO about to read block for non block spec dev");  k_prln(1);
      b := read_map(rip, position);
      dev := rip^.i_dev;
      k_cpr(RW_COLOR, "      (rw_chunk) dev is "); k_pr_hex_num(dev); k_prln(1);
      k_cpr(RW_COLOR, "      (rw_chunk) blk is "); k_pr_hex_num(b); k_prln(1)  
   end;
   
   (* AST1, 9948 *)
   (* Are we looking at unallocated space in file ? *)
   if ( (block_spec = 0) AND (b = NO_BLOCK) ) then begin
      k_cpr(RW_COLOR, "    INFO working w/ file with hole");  k_prln(1);
      if (rw_flag = READING) then begin
         k_cpr(RW_COLOR, "    INFO reading from non existent blk");  k_prln(1);
         bp := get_block(NO_DEV, NO_BLOCK, NORMAL);
         zero_block( bp)
      end 
      else begin
         k_cpr(RW_COLOR, "    (rw_chunk) INFO reading/writing to non existtent blk");  k_prln(1);
         k_cpr(RW_COLOR, "    (rw_chunk) INFO calling new_block");  k_prln(1);
         bp := new_block(rip, position);
         if (bp = NIL_BUF) then begin
            k_cpr(RW_COLOR, "    (rw_chunk) ERROR could not alloc new block in rw_chunk");  k_prln(1);
            retval(err_code)
         end;      
         k_cpr(RW_COLOR, "      (rw_chunk) INFO allocd new block in rw_chunk");  k_prln(1);
         k_cpr(RW_COLOR, "      (rw_chunk) It is at "); k_pr_hex_num(bp); k_prln(1)  
      end
   end
   (* AST1, 9957 *)
   else begin
      k_cpr(RW_COLOR, "    (rw_chunk) INFO reading/writing from/to EXISTING  blk");  k_prln(1);
      if ( (rw_flag = WRITING) AND (chunk = BLOCK_SIZE) ) then begin
         k_cpr(RW_COLOR, "    INFO write optimization will - not read block before getting it cause chunk = BLOCK");  k_prln(1);
         n := NO_READ
      end
      else begin
         k_cpr(RW_COLOR, "    INFO setting n to NORMAL before calling get_block"); k_prln(1);
         n := NORMAL
      end;

      
      bp := get_block(dev, b, n)
   (* AST1, 9965 *)
   end;
   
   (* TODO add partial block zero'ing - AST1, 9968 *)
   
   if rw_flag = READING then begin
      dir := TO_USER
   end
   else begin
      dir := FROM_USER
   end;
   
   k_cpr(RW_COLOR, "    addr of bdata is "); k_pr_hex_num(adr(bp^.b__data)); k_prln(1);
   k_cpr(RW_COLOR, "    off is "); k_pr_hex_num(off); k_prln(1);
   k_cpr(RW_COLOR, "   about to call rw_user"); k_prln(1);
   k_cpr(RW_COLOR, "      buff (src) is "); k_pr_hex_num(buff); k_prln(1);
   k_cpr(RW_COLOR, "      bdata (dst) is "); k_pr_hex_num(adr(bp^.b__data)); k_prln(1);
   r := rw_user(seg, usr, buff, chunk, (adr(bp^.b__data) + off),   dir);
   
   if (rw_flag = WRITING) then begin
      k_cpr(RW_COLOR, "  INFO marking newly written block dirty "); k_prln(1);
      bp^.b_dirt := DIRTY
   end;
   
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
 * AST1, 9794
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
    (* AST1, 9826 *)
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
   
   (* TODO add check for char special files AST1, 9836 *)
   
   
   (* Outer loop keeps going until there are no bytes 
    * left to be read or written.
    *)
   k_cpr(RW_COLOR,  "  Entering r/w loop..."); k_prln(1);
   (* AST1, 9861 *)
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
      
      (* AST1, 9866 *)
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
      
      k_cpr(RW_COLOR, "  Num bytes left (before reading or writing chunk : "); k_pr_hex_num(bytes_left[0]); k_pr_hex_num(bytes_left[1]); k_prln(1);
      (* AST1, 9874 *)
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
   k_prln(2);
   
   
   
   if (rw_flag = WRITING) then begin (* AST1, 9887 *)
      if s32_g(adr(position), adr(rip^.i_size)) then begin
         k_cpr(RW_COLOR,  "   INFO position is greater than size : "); k_pr_hex_num(position[0]); k_pr_hex_num(position[1]); k_prln(1);
         k_cpr(RW_COLOR,  "     INFO making size match positon : "); k_prln(1);
         s32_copy(adr(position), adr(rip^.i_size));
         rip^.i_dirt := DIRTY
      end   
   end;
   
   s32_copy(adr(position), adr(f^.filp_pos));
   
   (* TODO Skip read ahead code for now... *)
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