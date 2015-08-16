#include <strings.inc>

var
   shell2_mess : message;


(*=================================================================*
 * Shell - get an input line
 *=================================================================*)
procedure shell2_gets(s : ^integer);
var
   c : integer,
   c2 : integer,
   orig_s : ^integer,
   p : ^t_pty_read_message,
   reply_mess : ^pty_message,
   tmp_array : array[20] of integer;

begin
   orig_s := s;
   p := adr(shell2_mess);
   reply_mess := adr(shell2_mess);

   while 1 do begin
      (* Receive a char, using the send/rec approach *)
      p^.m_type := PTY_READ;
      p^.DEVICE := 0;
      p^.COUNT := 1;
      p^.ADDRESS := adr(tmp_array[0]);
      send_p(PTY, p);
      tmp_array[1] := 0;

      receive_p(PTY, p);
      c := tmp_array[0];
      c2 := c;
      (* Do Unix style input translation *)
      if c2 = 13 then c2 := ASCII_LF;

      if c2 = ASCII_LF then begin
         s^ := 0;
         return
      end;
      s^ := c2;
      s := s + 1;


      (* Now that we've received a char and ack'd it,
       * we should store it, echo it, return...
       *)
      
      p^.m_type := PTY_WRITE;
      p^.DEVICE := 0;
      p^.COUNT := 1;
      p^.ADDRESS := adr(c);
      send_p(PTY, p);
   
      receive_p(PTY, p)

   end


end;
(*=================================================================*)

(*=================================================================*)
procedure shell2_puts(s : ^integer);
var
   p : ^t_pty_read_message,
   reply_mess : ^pty_message,
   len : integer,
   tmp_array : array[20] of integer;

begin
   p := adr(shell2_mess);
   reply_mess := adr(shell2_mess);

   BIOS_StrLen(s, adr(len));

   p^.m_type := PTY_WRITE;
   p^.DEVICE := 0;
   p^.COUNT := len;
   p^.ADDRESS := s;
   send_p(PTY, p);

   receive_p(PTY, p)


end;
(*=================================================================*)

(*=================================================================*
 * Shell for testing purposes
 *=================================================================*)
procedure shell2_proc();
var
   p : ^t_pty_read_message,
   reply_mess : ^pty_message,
   tmp_str : array[40] of integer;

begin
   ConsoleOut(SHELL2_COLOR, "(Kernel ) Shell 22222  is starting now...", 1);

   p := adr(shell2_mess);
   reply_mess := adr(shell2_mess);

   while (1) do begin
      shell2_gets(adr(tmp_str));
      shell2_puts("Your String was : ");
      shell2_puts(adr(tmp_str))
   end

end;   