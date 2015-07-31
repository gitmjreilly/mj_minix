(* Runtime to be included with standalone programs used in mj_minix *)

(*
 * com.inc has message types.  This will have to be moved
 * (or copied) to a commonly available place.
 *)
#include <type.inc>
#include <math_32.inc>
#include <com.inc>
#include <sendrec.inc>
#include <strings.inc>
#include <param.inc>

var
   app_mess : message,
   m1 : ^mess_1,
   m2 : ^mess_2,
   m3 : ^mess_3;




(*
 * Colors to be used by various kernel components
 *)
const
   SHELL2_COLOR = 36;




type
   t_message_ptr = ^integer;




var
   Line: array [80] of integer,
   TmpNum : integer,
   Status: integer;


var
   debug_flag : integer;



(*=================================================================*
 * Shell - get an input line
 *=================================================================*)
procedure gets(s : ^integer);
var
   c : integer,
   orig_s : ^integer,
   p : ^t_pty_read_message,
   reply_mess : ^pty_message,
   tmp_array : array[20] of integer;

begin
   orig_s := s;
   p := adr(app_mess);
   reply_mess := adr(app_mess);

   while 1 do begin
      (* Receive a char, using the send/rec approach *)
      p^.m_type := PTY_READ;
      p^.DEVICE := 0;
      p^.COUNT := 1;
      p^.ADDRESS := adr(tmp_array);
      send_p(PTY, p);
      receive_p(PTY, p);

      c := tmp_array[0];

      (* Immediate echo *)
      p^.m_type := PTY_WRITE;
      p^.DEVICE := 0;
      p^.COUNT := 1;
      p^.ADDRESS := adr(tmp_array);
      send_p(PTY, p);
      receive_p(PTY, p);


      (* Do Unix style input translation *)
      (* if c = 13 then c := ASCII_LF; *)

      (* Echo CR LF, but do not store either *)
      (* CR was echod above - no we echo LF as well *)
      if c = 13 then begin
         c := 10;
         tmp_array[0] := 10;
         p^.m_type := PTY_WRITE;
         p^.DEVICE := 0;
         p^.COUNT := 1;
         p^.ADDRESS := adr(c);
         send_p(PTY, p);
         receive_p(PTY, p);
         s^ := 0;
         return
      end;

      s^ := c;
      s := s + 1

   end

end;
(*=================================================================*)


(*=================================================================
 * Print a string
(*=================================================================*)
procedure pr(s : ^integer);
var
   p : ^t_pty_write_message,
   reply_mess : ^pty_message,
   len : integer;

begin
   p := adr(app_mess);
   reply_mess := adr(app_mess);

   str_len(s, adr(len));

   p^.m_type := PTY_WRITE;
   (* Device is ignored - proc num determines comm channel *)
   p^.DEVICE := 0;
   p^.COUNT := len;
   p^.ADDRESS := s;
   send_p(PTY, p);
   receive_p(PTY, p)
end;
(*=================================================================*)


(*=================================================================
 * Print a bunch(n) of blanks
(*=================================================================*)
procedure prtab(n : integer);
var
   tmp_array : array[80] of integer,
   s : ^integer;

begin
   if n >79 then n := 79;

   s := adr(tmp_array);
   while (n > 0) do begin
      s^ := ASCII_SPACE;
      n := n - 1;
      s := s + 1
   end;
   s^ := 0;
   pr(adr(tmp_array))
end;
(*=================================================================*)


(*=================================================================
 * Print a bunch(n) of newlines
(*=================================================================*)
procedure prln(n : integer);
var
   tmp_array : array[10] of integer,
   s : ^integer;

begin
   s := adr(tmp_array);
   while (n > 0) do begin
      s^ := 13;
      s := s + 1;

      s^ := ASCII_LF;
      s := s + 1;

      n := n - 1
   end;
   s^ := 0;
   pr(adr(tmp_array))
end;
(*=================================================================*)


(*=================================================================
 * Print a decimal number
(*=================================================================*)
procedure prnum(n : integer);
var
   tmp_array : array[10] of integer;

begin
   num_to_str(n , adr(tmp_array));

   pr(adr(tmp_array))
end;
(*=================================================================*)


       
(*=================================================================
 * 
(*=================================================================*)
procedure get_num(n_ptr : ^integer) ;
var
   s : array[20] of integer;

begin
   while (1) do begin
      gets(adr(s));
      if str_is_num(adr(s)) then begin
         str_to_num(adr(s) , n_ptr);
         return
      end;

      pr("BAD! Enter a number>")
   end
end;
(*=================================================================*)


(*=================================================================
 * get a random int 0 <= i < n
(*=================================================================*)
function random_int(n : integer) : integer;
var
   counter : ^integer;

begin
   counter := $F060;
   n := counter^ MOD n;
   retval(n)
end;
(*=================================================================*)


(*=================================================================
 * Read a sector
(*=================================================================*)
procedure read_sector(sector_num : integer, buf_ptr : ^integer);
var
   p : ^block_message,
   reply_mess : ^pty_message,
   len : integer;

begin
   p := adr(app_mess);
   reply_mess := adr(app_mess);


   p^.m_type := DISK_READ;
   (* Device is ignored - assume SD card *)
   (* Count is  ignored - assume 512 bytes *)
   p^.DEVICE := 0;
   p^.COUNT := 512;

   p^.POSITION[0] := 0;
   p^.POSITION[1] := sector_num * 512;
   p^.ADDRESS := buf_ptr;
   send_p(FLOPPY, p);
   receive_p(FLOPPY, p)
end;
(*=================================================================*)


(*=================================================================
 * write a sector
(*=================================================================*)
procedure write_sector(sector_num : integer, buf_ptr : ^integer);
var
   p : ^block_message,
   reply_mess : ^pty_message,
   len : integer;

begin
   p := adr(app_mess);
   reply_mess := adr(app_mess);


   p^.m_type := DISK_WRITE;
   (* Device is ignored - assume SD card *)
   (* Count is  ignored - assume 512 bytes *)
   p^.DEVICE := 0;
   p^.COUNT := 512;

   p^.POSITION[0] := 0;
   p^.POSITION[1] := sector_num * 512;
   p^.ADDRESS := buf_ptr;
   send_p(FLOPPY, p);
   receive_p(FLOPPY, p)
end;
(*=================================================================*)


(*=================================================================
 * 
(*=================================================================*)
procedure get_s32(n_ptr : ^t_s32) ;
var
   s : array[20] of integer;

   
begin
   while (1) do begin
      gets(adr(s));
      prln(1);
      
      pr("Raw str is  : "); pr(adr(s)); prln(1);
      
      if str_is_num(adr(s)) then begin
         str_to_s32(adr(s) , n_ptr);
         return
      end;

      pr("BAD! Enter an s32>")
   end
end;
(*=================================================================*)

(*=================================================================
 * Print a (double) decimal number
(*=================================================================*)
procedure pr_s32(n : ^t_s32);
var
   tmp_array : array[10] of integer;

begin
   s32_to_str(n , adr(tmp_array));

   pr(adr(tmp_array))
end;
(*=================================================================*)


