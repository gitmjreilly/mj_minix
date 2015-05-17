(* The purpose of this program is to test the disk controller software
 * 
 *)
         
#include <runtime.pas>
#include <term_colors.inc>
#include <k_userio.inc>
#include <disk_ctlr.inc>

#define SECTOR_SIZE 512

var
   i : integer,
   ans : integer,
   s: array[80] of integer,
   byte_num : integer,
   num_bytes_to_retrieve : integer,
   disk_ctlr_data_port : ^integer,
   sector_num : integer,
   sector_buffer : array[512] of integer,
   stat : integer,
   disk_abs_addr : array[2] of integer,
   p : ^integer,
   fill_val : integer,
   ch : integer;
   

   
(*=================================================================*)
(* Main Program *)

begin
   k_pr("Hello World! This is a two way terminal designed to exercise disk ctlr");
   k_prln(2);

   disk_ctlr_data_port := $F030;

   while (1) do begin
      k_cpr(ANSI_YELLOW, "Cmd?  (r or w)");
      k_gets(adr(s));
      compare_strings(adr(s), "r", adr(ans));
      
      if ans = 1 then begin
         k_cpr(ANSI_YELLOW, "Got read..");
         k_cpr(ANSI_YELLOW, "Enter a sector num (in hex) to read >");
         k_get_hex_num(adr(sector_num));


        disk_abs_addr[0] := 0;
        disk_abs_addr[1] := 512 * sector_num;

        disk_ctlr_read_512(
           adr(disk_abs_addr),
           0,
           adr(sector_buffer),
           adr(stat) 
        );
         

         i := SECTOR_SIZE;
         p := adr(sector_buffer);
         while (i <> 0) do begin
            ch := p^;
            k_pr_ch(ch);
            i := i - 1;
            p := p + 1
         end;
         k_prln(2);
         continue
      end;

      compare_strings(adr(s), "w", adr(ans));
      
      if ans = 1 then begin
         k_cpr(ANSI_YELLOW, "Got write..");
         k_cpr(ANSI_YELLOW, "Enter a sector num (in hex) to write >");
         k_get_hex_num(adr(sector_num));

         k_cpr(ANSI_YELLOW, "Enter a fill val (in hex) to write >");
         k_get_hex_num(adr(fill_val));
         
        i := SECTOR_SIZE;
        p := adr(sector_buffer);
        while (i <> 0) do begin
            p^ := fill_val;
            p := p + 1;
            i := i - 1
        end;


        disk_abs_addr[0] := 0;
        disk_abs_addr[1] := 512 * sector_num;

        disk_ctlr_write_512(
           0,
           adr(sector_buffer),
           adr(disk_abs_addr),
           adr(stat) 
        );
         
         continue
      end


   end

end.
(*=================================================================*)
