#include <runtime.pas>
#include <com.inc>
#include <type.inc>
#include <mj_minix_app_runtime.pas>
#include <k_userio.inc>
#include <param.inc>
#include <const.inc>

CONST
   USER_COLOR = 31;

var
   sector_buffer : array[1024] of integer,
   ans : integer,
   file_buffer : array[513] of integer;


#include "fib.inc"
#include "h2.pas"

(********************************************************************)
procedure help() ;

begin
   pr("Help for demo program"); prln(2);

   pr("intense (a long running cpu hog)"); prln(1);
   pr("fib (a fibonacci printer) "); prln(1);
   pr("guess (a number guessing game) "); prln(1);
   pr("ham   (City Ruling Game) "); prln(1);
   pr("read_sec   (read a disk sector) "); prln(1);
   pr("write_sec   (write a disk sector) "); prln(1);
   pr("sys_copy  (copy using systask)"); prln(1);
   pr("clear_buff (clr the dest buffer)"); prln(1);
   pr("set_buff   (set the src buffer)"); prln(1);
   pr("fs_ping   (send chmod sys call to fs)"); prln(1);
   pr("open_file   fs open syscall"); prln(1);
   pr("creat_file   fs creat syscall"); prln(1);
   pr("sync_fs   sync_fs syscall"); prln(1);
   pr("read_file   fs read syscall"); prln(1);
   pr("cat_file   fs read syscall"); prln(1);
   pr("close_file   fs close syscall"); prln(1);
   pr("print_buff (print the dest buffer)"); prln(1)

end;
(********************************************************************)

(********************************************************************)
procedure read_sec() ;
var
   i : integer,
   buf_ptr : ^integer,
   num_sectors : integer,
   t_str : array[20] of integer,
   ans : integer,
   byte_num : integer,
   sector_num : integer;

begin

   pr("Enter first sector number to read >");
   get_num(adr(sector_num));
   pr("Enter num sectors to read>");
   get_num(adr(num_sectors));

   pr("(p) to print vals; any other char to not print>");
   gets(adr(t_str));
   compare_strings(adr(t_str), "p", adr(ans));


   buf_ptr := adr(sector_buffer);
   i := 0; 
   while i < num_sectors do begin

      read_sector(sector_num, adr(sector_buffer));
      if ans = 1 then  begin
         byte_num := 0;
         while byte_num < 512 do begin
            prnum(byte_num); pr("  "); prnum(sector_buffer[byte_num]); prln(1);
            byte_num := byte_num + 1
         end
      end;
      i := i + 1;
      sector_num := sector_num + 1

   end;

   pr("Done"); prln(1)

end;
(********************************************************************)

(********************************************************************)
procedure write_sec() ;
var
   i : integer,
   buf_ptr : ^integer,
   fill_val : integer,
   sector_num : integer;

begin

   pr("Enter sector number to write >");
   get_num(adr(sector_num));
   pr("Enter fill value to write >");
   get_num(adr(fill_val));

   i := 0;
   buf_ptr := adr(sector_buffer);
   while i < 512 do begin
      buf_ptr^ := fill_val;
      i := i + 1;
      buf_ptr := buf_ptr + 1
   end;

   write_sector(sector_num, adr(sector_buffer));

   pr("Done"); prln(1)

end;
(********************************************************************)


(********************************************************************)
procedure intense() ;
var
   i : integer,
   j : integer;

begin

   pr("This is a long running proc"); prln(1);
   i := 1000;
   while i <> 0 do begin
      i := i - 1;
      j := 8000;
      while j <> 0 do begin
         j := j - 1
      end
   end;
   pr("Done"); prln(1)

end;
(********************************************************************)

(********************************************************************)
procedure guess_game() ;

var
   t_str : array[10] of integer,
   counter : ^integer,
   user_guess : integer,
   num_to_be_guessed : integer;

begin
   counter := $F060;

   pr("This is the number guessing game."); prln(1);
   num_to_be_guessed := counter^;
   if num_to_be_guessed < 0 then
      num_to_be_guessed := -num_to_be_guessed;

   num_to_be_guessed := num_to_be_guessed MOD 10;
   pr("The num to be guessed is : ");
   prnum(num_to_be_guessed); prln(2);
   

   while (1) do begin
      pr("  Enter your guess>");
      gets(adr(t_str));
      str_to_num(adr(t_str), adr(user_guess));
      if (user_guess < num_to_be_guessed) then begin
         pr("  Your guess was too low!"); prln(1);
         continue
      end;

      if (user_guess > num_to_be_guessed) then begin
         pr("  Your guess was too high!"); prln(1);
         continue
      end;

      pr("  Congratulations.  Your guess was correct!"); prln(2);
      return
   end
end;
(********************************************************************)


var
   test_buff : array[20] of integer,
   dest_buff : array[20] of integer;
   
(********************************************************************)
procedure clear_buff() ;
begin
   dest_buff[0] := 0
end;
(********************************************************************)
   
   
(********************************************************************)
procedure set_buff() ;
begin
   pr("Enter string for test_buff> "); gets(adr(test_buff))
end;
(********************************************************************)
   
   
(********************************************************************)
procedure print_buff() ;
begin
   pr("Dest_buff : "); pr(adr(dest_buff)); prln(1)
end;
(********************************************************************)
   
   
(********************************************************************)
procedure sys_copy() ;

var
   t_str : array[10] of integer,
   umess : mess_5,
   user_guess : integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   num_to_be_guessed : integer;

begin

   while (1) do begin
      pr("Enter src proc num (4 or 5) >"); get_num(adr(src_proc_num));
      if (src_proc_num = 4) OR (src_proc_num = 5) then 
         break;
      pr("  Out of range try again!"); prln(1)
   end;
      
   while (1) do begin
      pr("Enter dst proc num (4 or 5) >"); get_num(adr(dst_proc_num));
      if (dst_proc_num = 4) OR (dst_proc_num = 5) then 
         break;
      pr("  Out of range try again!"); prln(1)
   end;
      
   k_pr("User Copying from src to dest proc"); k_prln(1);
   umess.SRC_PROC_NR := src_proc_num;
   umess.SRC_BUFFER[1] := adr(test_buff);
   umess.DST_PROC_NR := dst_proc_num;
   umess.DST_BUFFER[1] := adr(dest_buff);
   umess.COPY_BYTES[1] := 20;
   umess.m_type := SYS_COPY;
   
   send_p(SYSTASK, adr(umess));
   receive_p(SYSTASK, adr(umess))
end;
(********************************************************************)


   
(********************************************************************)
(* Use global message from app_runtime
 *)
procedure fs_ping() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   num_to_be_guessed : integer;

begin
   (* Please note:
    * name, pathname, name_length, mode are m3 message fields - see param.inc
    *)

   pr("Sending dummy message to FS"); prln(1);
   pr("Enter FQ path name >"); 
   gets(adr(t_str));
   pr("Your string is : "); pr(adr(t_str)); prln(1);
   str_len(adr(t_str) , adr(nl));
   pr("Length is : "); prnum(nl); prln(1);
   name := adr(t_str);
   mode := 7;
   
   name_length := nl;
   
   (* $000F is the type for chmod *)
   m3^.m_type := $000F;
   if (name_length <= M3_STRING) then begin
      (* We can store the name in the message... *)
      str_copy(adr(t_str), adr(pathname))
   end;
   mode := 7;
   
   send_p(FS_PROC_NR, m3);
   receive_p(FS_PROC_NR, m3)
end;
(********************************************************************)



(********************************************************************)
(* Use global message from app_runtime
 *)
procedure open_file() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   num_to_be_guessed : integer;

begin
   (* Please note:
    * name, pathname, name_length, mode are m3 message fields - see param.inc
    *)

   pr("Sending dummy message to FS"); prln(1);
   pr("Enter FQ path name >"); 
   gets(adr(t_str));
   pr("Your string is : "); pr(adr(t_str)); prln(1);
   str_len(adr(t_str) , adr(nl));
   pr("Length is : "); prnum(nl); prln(1);
   name := adr(t_str);
   
   name_length := nl;
   
   (* $0005 is the type for open *)
   m3^.m_type := $0005;
   if (name_length <= M3_STRING) then begin
      (* We can store the name in the message... *)
      str_copy(adr(t_str), adr(pathname))
   end;
   (* Mode is 0 for read *)
   mode := 0;
   
   send_p(FS_PROC_NR, m3);
   receive_p(FS_PROC_NR, adr(m4));
   pr("Returned file descriptor is : "); prnum(m4.m_type); prln(1)
end;
(********************************************************************)


(********************************************************************)
(* Use global message from app_runtime
 *)
procedure creat_file() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   num_to_be_guessed : integer;

begin
   (* Please note:
    * name, pathname, name_length, mode are m3 message fields - see param.inc
    *)

   pr("Sending creat message to FS"); prln(1);
   pr("Enter FQ path name >"); 
   gets(adr(t_str));
   pr("Your string is : "); pr(adr(t_str)); prln(1);
   str_len(adr(t_str) , adr(nl));
   pr("Length is : "); prnum(nl); prln(1);
   name := adr(t_str);
   
   name_length := nl;
   
   (* $0005 is the type for open *)
   m3^.m_type := $0008;
   if (name_length <= M3_STRING) then begin
      (* We can store the name in the message... *)
      str_copy(adr(t_str), adr(pathname))
   end;
   (* TODO fix mode in do_creat *)
   (* Mode is 0 for read *)
   mode := 0;
   
   send_p(FS_PROC_NR, m3);
   receive_p(FS_PROC_NR, adr(m4));
   pr("Returned file descriptor is : "); prnum(m4.m_type); prln(1)
end;
(********************************************************************)


(********************************************************************)
(* Use global message from app_runtime
 *)
procedure sync_fs() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   num_to_be_guessed : integer;

begin
   (* Please note:
    * name, pathname, name_length, mode are m3 message fields - see param.inc
    *)

   pr("Sending sync_fs message to FS"); prln(1);
   (* $0005 is the type for open *)
   m3^.m_type := 36;
   
   send_p(FS_PROC_NR, m3);
   receive_p(FS_PROC_NR, adr(m4))
end;
(********************************************************************)


(********************************************************************)
(* Use global message from app_runtime
 * Please note the following fields come from the input message:
 *    nbytes : integer
 *    buffer : pointer to mem location
 *    fd : integer
 *
 *)
procedure read_file() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   the_msg : mess_1,
   m1: ^mess_1,
   num_to_be_guessed : integer;

begin
   (* Please note:
    *    fd is a param.inc field.
    *)

   m1 := adr(the_msg);
   pr("Enter FD for file to read >"); 
   get_num(adr(fd));
   pr("Your fd is : "); prnum(fd); prln(1);
   
   (* $0003 is the type for read *)
   m1^.m_type := $0003;
   nbytes := 500;
   buffer := adr(file_buffer);

   send_p(FS_PROC_NR, m1);
   receive_p(FS_PROC_NR, adr(m4));
   pr("Returned func val is : "); prnum(m4.m_type); prln(1);
   file_buffer[10] := 0;
   pr("File buffer up to 10 is : ["); pr(adr(file_buffer)); pr("]"); prln(1)
end;
(********************************************************************)


(********************************************************************)
(* Use global message from app_runtime
 * Please note the following fields come from the input message:
 *    nbytes : integer
 *    buffer : pointer to mem location
 *    fd : integer
 *
 *)
procedure cat_file() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   the_msg : mess_1,
   m1: ^mess_1,
   num_bytes_read : integer;

begin
   (* Please note:
    *    fd is a param.inc field.
    *    buffer is a param.inc field
    *    nbytes is a param.inc field
    *)

   m1 := adr(the_msg);
   pr("Enter FD for file to cat >"); 
   get_num(adr(fd));
   pr("Your fd is : "); prnum(fd); prln(1);

   while (1) do begin
      (* $0003 is the type for read *)
      m1^.m_type := $0003; 
      nbytes := $200;
      buffer := adr(file_buffer);

      send_p(FS_PROC_NR, m1);
      receive_p(FS_PROC_NR, adr(m4));

      num_bytes_read := m4.m_type;
      pr("Returned func val is : "); prnum(num_bytes_read); prln(1);
      if (num_bytes_read <= 0) then begin
         pr("  num_bytes_read <= 0 - breaking out of loop"); prln(1);
         break
      end;

      file_buffer[num_bytes_read] := 0;
      pr(adr(file_buffer))
   end;
   
   if (num_bytes_read < 0) then begin
      pr("  Got negative return from read..."); prln(1)
   end
   else begin
      pr("  Got ZERO (good) return from read..."); prln(1)   
   end
      
end;
(********************************************************************)



(********************************************************************)
(* Use global message from app_runtime
 *)
procedure close_file() ;

var
   t_str : array[40] of integer,
   src_proc_num : integer,
   dst_proc_num : integer,
   nl : integer,
   m4 : mess_3,
   the_msg : mess_1,
   m1: ^mess_1,
   num_to_be_guessed : integer;

begin
   (* Please note:
    *    fd is a param.inc field.
    *)

   m1 := adr(the_msg);
   pr("Enter FD for file to close >"); 
   get_num(adr(fd));
   pr("Your fd is : "); prnum(fd); prln(1);
   
   (* $0006 is the type for close *)
   m1^.m_type := $0006;

   send_p(FS_PROC_NR, m1);
   receive_p(FS_PROC_NR, adr(m4));
   pr("Returned func val is : "); prnum(m4.m_type); prln(1)
end;
(********************************************************************)



var
   x : integer,
   t_str : array[40] of integer,
   p_stack : array[800] of integer,
   r_stack : array[50] of integer,
   counter : ^integer;

(* MAIN Program *)
begin
   asm
      p_stack SP_STORE
      r_stack RP_STORE
   end;
   
   (* There's a single message, app_mess, and we cast it
    * with different pointers.
    *)
   m3 := adr(app_mess); 

   clear_buff();
   
   counter := $F060;

   k_pr("Starting user1..."); k_prln(1);
   k_pr("Forced to gets before printing first str..."); k_prln(1);
   gets(adr(t_str));
   (*
   while (1) do begin
      pr("Type a string >");
      gets(adr(t_str));
      
      pr("Your string was : "); pr(adr(t_str)); prln(1);


      pr("Your random number is : ");
      x := counter^;
      prnum(x); prln(2)

   end;
   *)



   while (1) do begin
      pr("minix user demo (h for help)>");
      gets(adr(t_str));

      compare_strings(adr(t_str), "h", adr(ans));
      if ans = 1 then begin
         help();
         continue
      end;

      compare_strings(adr(t_str), "intense", adr(ans));
      if ans = 1 then begin
         intense();
         continue
      end;
      compare_strings(adr(t_str), "read_sec", adr(ans));
      if ans = 1 then begin
         read_sec();
         continue
      end;
      compare_strings(adr(t_str), "write_sec", adr(ans));
      if ans = 1 then begin
         write_sec();
         continue
      end;
      compare_strings(adr(t_str), "fib", adr(ans));
      if ans = 1 then begin
         fibonacci();
         continue
      end;
      compare_strings(adr(t_str), "guess", adr(ans));
      if ans = 1 then begin
         guess_game();
         continue
      end;
      
      compare_strings(adr(t_str), "sys_copy", adr(ans));
      if ans = 1 then begin
         sys_copy();
         continue
      end;
      
      compare_strings(adr(t_str), "clear_buff", adr(ans));
      if ans = 1 then begin
         clear_buff();
         continue
      end;
      
      compare_strings(adr(t_str), "set_buff", adr(ans));
      if ans = 1 then begin
         set_buff();
         continue
      end;
      
      compare_strings(adr(t_str), "print_buff", adr(ans));
      if ans = 1 then begin
         print_buff();
         continue
      end;
      
      compare_strings(adr(t_str), "fs_ping", adr(ans));
      if ans = 1 then begin
         fs_ping();
         continue
      end;
      
      compare_strings(adr(t_str), "open_file", adr(ans));
      if ans = 1 then begin
         open_file();
         continue
      end;
      
      compare_strings(adr(t_str), "creat_file", adr(ans));
      if ans = 1 then begin
         creat_file();
         continue
      end;
      
      compare_strings(adr(t_str), "sync_fs", adr(ans));
      if ans = 1 then begin
         sync_fs();
         continue
      end;
      
      compare_strings(adr(t_str), "read_file", adr(ans));
      if ans = 1 then begin
         read_file();
         continue
      end;
      
      compare_strings(adr(t_str), "cat_file", adr(ans));
      if ans = 1 then begin
         cat_file();
         continue
      end;
      
      compare_strings(adr(t_str), "close_file", adr(ans));
      if ans = 1 then begin
         close_file();
         continue
      end;
      
      
      compare_strings(adr(t_str), "ham", adr(ans));
      if ans = 1 then begin
         HamurabiGame();
         continue
      end

   end
end.




