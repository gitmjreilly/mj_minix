#ifndef DISK_CTLR_INC_INCLUDED
#define DISK_CTLR_INC_INCLUDED

#include <strings.inc>


(*
 * Memory Map
 *   F030 data port
 *   F040 serial interrput port
 *)


#define DC_DATA_PORT $F030
#define DC_STATUS_PORT $F031
#define DC_ACK_DATA_PORT $F040
#define DC_ACK_STATUS_PORT $F041
 
#define FILE_BUFFER_SIZE 256 
 
var
   dc_num_chars_read : integer,
   dc_file_buffer : array [FILE_BUFFER_SIZE] of integer;
   

(*===================================================================*)
procedure dc_init();
begin
   dc_num_chars_read := 256
end;
(*===================================================================*)
   
 
(*===================================================================*)
procedure _abs_32_to_512(
    abs_32 : ^array[2] of integer,
    sector_num : ^array[2] of integer);

var
   NumStr : array[5] of integer,
   i : integer,
   addr3 : integer,
   addr2 : integer,
   addr1 : integer,
   addr0 : integer;
   
   

begin
   sector_num^[0] := 0;
   sector_num^[1] := 0;

   GetUpper8(abs_32^[1], adr(addr0));
   GetLower8(abs_32^[0], adr(addr1));
   GetUpper8(abs_32^[0], adr(addr2));

   (* At this point weve shifted right by 8; one more bit to go...*)
   addr0 := srl(addr0) ;
   if (addr1 AND $0001) = 1 then
      addr0 := addr0 OR $0080;

   addr1 := srl(addr1) ;
   if (addr2 AND $0001) = 1 then
      addr1 := addr1 OR $0080;

   addr2 := srl(addr2) ;

   addr3 := 0;

   (* Now we have the 3 bytes; we need to put them into 2 words *)
   sector_num^[1] := addr0;
   i := 0;
   while i < 8 do begin
      addr1 := sll(addr1);
      i := i + 1
   end;
   sector_num^[1] := sector_num^[1] OR addr1;

   sector_num^[0] := addr2

end;
(*===================================================================*)


(*=================================================================*)
(* 
    IN_EMPTY_MASK  = 0x0001
    IN_FULL_MASK   = 0x0002
    OUT_EMPTY_MASK = 0x0004
    OUT_FULL_MASK  = 0x0008
*)
procedure disk_ctlr_wait_for_ack();
   
var
   tmp : integer,
   s : integer,
   ack_data_port : ^integer,
   ack_status_port : ^integer,
   tmp_str : array[5] of integer;
   
begin
   ack_data_port   := DC_ACK_DATA_PORT;
   ack_status_port := DC_ACK_STATUS_PORT;  
   
   (* Wait until the disk controller sends an ack that last action was completed *)
   while (1) do begin
      s := ack_status_port^;
      if ( (s AND $0001) = 0) then break
   end;

   k_cpr(ANSI_YELLOW, "DEBUG got ack data from disk ctlr"); k_prln(1);
   (* Read the data to empty the ack port *)
   tmp := ack_data_port^
end;
(*=================================================================*)


(*=================================================================*)
(* We are given an absolute 32 bit value on disk to read from
 * and a seg:offset pair in mem to write to .
 *
 * Send the read  command to the disk_ctlr.
 * The disk_ctlr is connected to the high speed serial port
 * String is of form rXXXX - string must end in ASCII_LF
 *   XXXX is the sector num in hex
 
 * This is the command only.  The data is meant to be retrieved separately.
 * We assume the uart has a large fifo and so the data can be retrieved
 * later without fear of data over run by the 
 * external serially connecte disk controller *)
procedure disk_ctlr_read_512(
   disk_abs_addr : ^array[2] of integer,
   dst_seg : integer,
   dst_ptr : ^integer, 
   status_ptr : ^integer
);

var
   i : integer,
   ch : integer,
    tmp_str : array[5] of integer,
    p : ^ integer,
    (* 32 bit sector num for use with disk ctlr *)
    sector_num : array[2] of integer;

begin
   k_pr("Entered disk_ctlr_read512..."); k_prln(1);
   
   (* Convert the disk abs address to a sector address *)
   _abs_32_to_512(disk_abs_addr, adr(sector_num));
   
   (* Convert the sector num to a string for use with the disk ctlr
    * Note we only care about the lower 16 bit word of the sector num *)
   num_to_hex_str(sector_num[1], adr(tmp_str));

   (* Send the read command *)
   p := DC_DATA_PORT;
   p^ := $72; (* Send the 'r' *)
    
   p^ := tmp_str[0];
   p^ := tmp_str[1];
   p^ := tmp_str[2];
   p^ := tmp_str[3];
   
   
   p^ := ASCII_LF;
   
   disk_ctlr_wait_for_ack();
   
   i := 0;
   SetES(dst_seg);
   while i < 512 do begin
      ch := p^;

      LongStore(dst_ptr, ch);
      dst_ptr := dst_ptr + 1;
      i := i + 1
   end ;
   
   k_pr("Leaving disk_ctlr_read512,"); k_prln(1)
    
end;

(*=================================================================*)



(*=================================================================*)
(* Write exactly 512 bytes  (a "sector")
 * We are given a seg:offset src pair in mem to read from
 * and  an absolute 32 bit value on disk to write to.
 *
 * Send the write  command to the disk_ctlr.
 * The disk_ctlr is connected to the high speed serial port
 * String is of form wXXXX - string must end in ASCII_LF
 *   XXXX is the sector num in hex
 *
 * The data is expected is immediately follow and the uart is assumed
 * to have a large fifo so no checks are made before writing data
 * AS FAST  AS POSSIBLE to uart without fear of over run. *)
procedure disk_ctlr_write_512(
   src_seg : integer,
   src_ptr : ^integer, 
   disk_abs_addr : ^array[2] of integer,
   status_ptr : ^integer
);

var
   i : integer,
   ch : integer,
    tmp_str : array[5] of integer,
    p : ^ integer,
    (* 32 bit sector num for use with disk ctlr *)
    sector_num : array[2] of integer;

begin
   (* Convert the disk abs address to a sector address *)
   _abs_32_to_512(disk_abs_addr, adr(sector_num));
   
   (* Convert the sector num to a string for use with the disk ctlr
    * Note we only care about the lower 16 bit word of the sector num *)
   num_to_hex_str(sector_num[1], adr(tmp_str));

   (* Send the read command *)
   p := DC_DATA_PORT;
   p^ := $77; (* Send the 'w' *)
    
   p^ := tmp_str[0];
   p^ := tmp_str[1];
   p^ := tmp_str[2];
   p^ := tmp_str[3];
   
   
   p^ := ASCII_LF;
   
  
   
   i := 0;
   SetES(src_seg);
   while i < 512 do begin
      LongFetch(src_ptr, adr(ch));
      p^ := ch;
      i := i + 1;
      src_ptr := src_ptr + 1
   end;
   

   disk_ctlr_wait_for_ack()
   
    
end;

(*=================================================================*)


(*===================================================================*)
procedure disk_ctlr_open_file(
   FileNamePtr : t_word_ptr, 
   status_ptr : t_word_ptr);

var
   p : ^integer,
   i : integer,
   stat : integer,
   s: array[9] of integer;

begin
   (* Send the OPEN file command
    * Ofilename followed by new line *)
   p := DC_DATA_PORT;
   p^ := $4F; (* Send the 'O' *)
    
   while (1) do begin
      if FileNamePtr^ = 0 then break;
      p^ := FileNamePtr^;
      FileNamePtr := FileNamePtr + 1   
   end; 
   p^ := ASCII_LF;
   
   (* Now that we have ve sent cmd; wait for response from dc *)
   disk_ctlr_wait_for_ack();
   
   (* Retrieve the one byte binary status; 0 == good *)
   stat := p^;
   if (stat <> 0) then begin
      k_pr("Could not open file..."); k_prln(1)
   end;
   
   i := 0;
   while (i <8) do begin
      s[i] := p^;
      i := i + 1
   end;
   s[i] := 0;
   k_pr(" Size str is : "); k_pr(adr(s)); k_prln(1);
   
   (* Initialize num_chars read every time we open a new file *)
   dc_num_chars_read := 256;
   
   status_ptr^ := stat
end;
(*===================================================================*)


(*===================================================================*)
procedure disk_ctlr_close_file(status_ptr : ^integer);
   
var
   p : ^integer,
   i : integer,
   stat : integer,
   s: array[9] of integer;

begin
   (* Send the CLOSE file command
    * C followed by new line *)
   p := DC_DATA_PORT;
   p^ := $43; (* Send the 'C' *)
   p^ := ASCII_LF;
   
   (* Now that we have sent cmd; wait for response from dc *)
   disk_ctlr_wait_for_ack();
   
   (* Retrieve the one byte binary status; 0 == good *)
   stat := p^;
   if (stat <> 0) then begin
      k_pr("Could not close file..."); k_prln(1)
   end; 
   
   k_pr("File has been closed in disk_ctlr_close_file."); k_prln(1);

   status_ptr^ := stat
end;
(*===================================================================*)



(*===================================================================*)
procedure disk_ctlr_read_file();
   
var
   p : ^integer,
   i : integer;

begin
   (* Send the READ file command
    * R followed by new line *)
   p := DC_DATA_PORT;
   p^ := $52; (* Send the 'R' *)
   p^ := ASCII_LF;
   
   (* Now that we have sent cmd; wait for response from dc 
    * indicating read has completed and data is in fifo  *)
   disk_ctlr_wait_for_ack();
   
   (* Please note; no status is returned.  Just FILE_BUFFER_SIZE bytes of data *)
   i := 0;
   while (i < FILE_BUFFER_SIZE) do begin
      dc_file_buffer[i] := p^;
      i := i + 1
   end

end;
(*===================================================================*)


(*===================================================================*)
function  dc_get_file_byte() : integer;
var
   b : integer;

begin
   (* If we have read to the end of the buffer 0 - FILE_BUFFER_SIZE - 1
    * the fill another buffer *)
   if (dc_num_chars_read = FILE_BUFFER_SIZE) then begin
      disk_ctlr_read_file();
      dc_num_chars_read := 0
   end;
   
   b := dc_file_buffer[dc_num_chars_read];
   dc_num_chars_read := dc_num_chars_read + 1;
   retval(b)
end;
(*===================================================================*)


(*===================================================================*)
function dc_get_file_word() : integer;
var
   msb : integer,
   lsb: integer;

begin
   msb := dc_get_file_byte();
   lsb := dc_get_file_byte();
   retval(msb * 256 + lsb)
end;
(*===================================================================*)


#endif