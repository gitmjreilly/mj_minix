(* Based on fs/path.c AST1,10650 *)
#include <k_userio.inc>



#include "../h/const.inc"
#include "../h/type.inc"
#include "../h/error.inc"



(*==================================================================*)
(*
 * search_dir() based on AST1,10860
 *
 * DEV_STATUS:search_dir WIP
 * Look for string in ldir_ptr...
 * As of 19 October 2013, only support LOOKUP with 16 bit directory size...
 * For LOOKUP return inode number in numb.
 *
 *)
function search_dir(
   ldir_ptr : ^t_inode, 
   string : ^array[NAME_SIZE] of integer,
   numb : ^integer, (* inode number... *)
   flag : integer) : integer;
   
var
   i : integer,
   pos : array[2] of integer,
   bs : t_s32,
   b : integer,
   bp : ^t_buf,
   (* dir_struct defined AST1,8002 
    * The inode number is 16 bits
    * it occupies 2 bytes on disk, but 2 words in the in memory buffer
    * There is no separate in-mem directory buffer.
    *)
   dp : ^dir_struct,
   real_inum : integer,
   dir_ptr : ^t_b__dir,
   old_slots : integer,
   new_slots : integer,
   e_hit : integer,
   mnt_dev : integer;

begin
   bs[0] := 0;
   bs[1] := BLOCK_SIZE;
   
   k_cpr(MAP_COLOR, "Entered search_dir");  k_prln(1);
   k_cpr(MAP_COLOR, "  ldir_ptr: "); k_cpr_hex_num(MAP_COLOR, ldir_ptr); k_prln(1);
   k_cpr(MAP_COLOR, "   looking for string "); k_cpr(MAP_COLOR, string); k_prln(1);
   if (ldir_ptr^.i_mode AND I_TYPE) <> I_DIRECTORY then begin
      k_cpr(MAP_COLOR, "    ldir is NOT a directory!!! ");  k_prln(1);
      k_cpr(MAP_COLOR, "Leaving search_dir");  k_prln(1);
      retval(ENOTDIR)
   end;
   
   (* TODO
    * Ignoring forbidden tests for now..
    *)
   (* TODO use all 32 bits of i_size *)
   k_cpr(MAP_COLOR, "  the dir (file) size is : "); k_cprnum(MAP_COLOR, ldir_ptr^.i_size[1]); k_prln(1);
   old_slots := ldir_ptr^.i_size[1] / DIR_ENTRY_SIZE;
   new_slots := 0;
   e_hit := 0;
   k_cpr(MAP_COLOR, "  the number of dir slots is : "); k_cprnum(MAP_COLOR, old_slots); k_prln(1);
   
   pos[0] := 0;
   pos[1] := 0;
   k_cpr(MAP_COLOR, "  iterating thru all directory blocks..."); k_prln(1);
   while s32_l(adr(pos), adr(ldir_ptr^.i_size)) do begin
      b := read_map(ldir_ptr, adr(pos));
      k_cpr(MAP_COLOR, "  pos is : "); k_cprnum(MAP_COLOR, pos[1]); k_prln(1);
      k_cpr(MAP_COLOR, "    blk for pos is : "); k_cprnum(MAP_COLOR, b); k_prln(1);
      
      bp := get_block(ldir_ptr^.i_dev, b, NORMAL);
      (* bp points at data; treat as array of directory entries... 
       * We iterate over the directory entries directly in the buffer cache
       * Since the buffer cache directly represents the on disk form
       * the dir entry 16 bit inode num is stored in 2 separate locations
       * These 2 have to be combined into one when used in mem to get inode num
       *)
      dir_ptr := bp;
      i := 0;    
      while (__ul(adr(dir_ptr^[i]), adr(dir_ptr^[NR_DIR_ENTRIES]))) do begin
         dp := adr(dir_ptr^[i]);
         k_cpr(MAP_COLOR, " Checking dir entry : "); k_cprnum(MAP_COLOR, i); k_prln(1);
         k_cpr(MAP_COLOR, " dp : "); k_cpr_hex_num(MAP_COLOR, dp); k_prln(1);
         k_cpr(MAP_COLOR, "   name "); k_cpr(MAP_COLOR, adr(dp^.d_name)); k_prln(1);

         (* Check to see if we have exhausted the directory search *)
         new_slots := new_slots + 1;
         if (new_slots > old_slots) then begin
            if (flag = ENTER) then begin
               e_hit := 1
            end;
            break
         end;
         
         (* dp points directly into the buffer cache
          * the 16 bit inode number normally spans 2 8 bit bytes
          * which occupy 2 8 bit bytes in mem which AST treats as 1 16 bit word.
          * Because (here) dp points at 16 bit words, the inode number is split
          * across 2 16 bit words.  As a result, we need to calculate the 
          * real inode number.
          *)
         real_inum := dp^.d_inum_hi * 256 + dp^.d_inum_lo;
         if (flag <> ENTER) AND (real_inum <> 0) AND
            cmp_string(adr(dp^.d_name), string, NAME_SIZE) then begin
            k_cpr(MAP_COLOR, "  found string"); k_prln(1);
            numb^ := real_inum;
            k_cpr(MAP_COLOR, "  inode num is : "); k_cprnum(MAP_COLOR, numb^); k_prln(1);
            put_block(bp, DIRECTORY_BLOCK);
            retval(OK)
         end;
         
         if (flag = ENTER) AND (real_inum = 0) then begin
            e_hit := 1;
            break
         end;
      
         i := i + 1
      end;      
      
      put_block(bp, DIRECTORY_BLOCK);

      s32_add(adr(pos), adr(bs), adr(pos))
      (* pos[1] := pos[1] + BLOCK_SIZE *)
   end;

   if (flag <> ENTER) then begin
      k_cpr(MAP_COLOR, "Leaving search_dir - did not find dir");  k_prln(1);
      retval(ENOENT)
   end;

   (* If we got this far, the flag is ENTER *)
   if (e_hit = 0) then begin
      (* The dir was full and there was no room in the last block *)
      new_slots := new_slots + 1;
      if (new_slots = 0) then retval(EFBIG);
      
      bp := new_block(ldir_ptr, adr(ldir_ptr^.i_size));
      if (bp = NIL_BUF) then begin
         retval(err_code)      
      end;
      (* TODO Fix dir refs in buffers *)
      dp := adr(bp^.b__data[0])
   end;

   (* copy(adr(dp^.d_name), string, NAME_SIZE); *)
   i := 0;
   while (i < NAME_SIZE) do begin
      dp^.d_name[i] := string^[i];
      i := i + 1
   end;
   
   (* Put the inode number back into the directory structure
    * Remember the dir struct is in the buffer cache which is byte oriented *)
   GetUpper8(numb^, adr(dp^.d_inum_hi));
   GetLower8(numb^, adr(dp^.d_inum_lo));
   bp^.b_dirt := DIRTY;
   
   put_block(bp, DIRECTORY_BLOCK);
   (* TODO Add modtime *)
   (* TODO do full 32 bit calc for inode size
    * Please note the ldir_ptr is a ptr to inode table; it does not point
    * directly into buffer cache *)
   ldir_ptr^.i_dirt := DIRTY;
   if (new_slots > old_slots) then begin
      ldir_ptr^.i_size[0] := 0;
      ldir_ptr^.i_size[1] := new_slots * DIR_ENTRY_SIZE
   end;
   
   k_cpr(MAP_COLOR, "Leaving search_dir");  k_prln(1);
   
   retval(OK)

end;
(*==================================================================*)


(*==================================================================*)
(*
 * advance() based on AST1,10792
 *
 * DEV_STATUS:advance Complete excluding support for mounted file systems.
 * 
 *
 *)
function advance(dirp : ^t_inode, string : ^array[NAME_SIZE] of integer) : ^t_inode;
var
   rip : ^t_inode,
   sp : ^t_super_block,
   r : integer,
   mnt_dev : integer,
   numb : integer;  (* inode number... *)

begin
   k_cpr(MAP_COLOR, "    Entered advance() : ");  k_prln(1);
   k_cpr(MAP_COLOR, "      dir to advance to is : "); k_cpr(MAP_COLOR, string); k_prln(1);

   if (string^[0] = 0) then begin
      retval(get_inode(dirp^.i_dev, dirp^.i_num))
   end;
   
   r := search_dir(dirp, string, adr(numb), LOOK_UP);
   k_cpr(MAP_COLOR, " advance() returned from search_dir..."); k_prln(1);
   k_cpr(MAP_COLOR, "   numb is : "); k_cpr_hex_num(MAP_COLOR, numb); k_prln(1);
   if (r <> OK) then begin
      k_cpr(MAP_COLOR, "    advance() return from search_dir is NOT OK ");  k_prln(1);
      err_code := r;
      retval(NIL_INODE)
   end;
   
   (* The component was found in the dir.  Get the inode *)
   rip := get_inode(dirp^.i_dev, numb);
   if rip = NIL_INODE then begin
      retval(NIL_INODE)
   end;
   k_cpr(MAP_COLOR, "   inode rip is : "); k_cpr_hex_num(MAP_COLOR, rip); k_prln(1);
   retval(rip);
      
   dirp := dirp
end;
(*==================================================================*)


(*==================================================================*)
(*
 * get_name() based on AST1,10749
 *
 * DEV_STATUS:last_dir WIP
 * get_name is ONLY called by last_dir (see below) which is why it can
 * make direct reference to user_path.  Its OK but Ugly.
 * 
 * Given old_name, copy leftmost component to string
 * Return remainder old_name with leftmost component removed.
 * Example given /usr/ast
 *    old_name becomes /ast
 *    string becomes usr
 *
 *)
function get_name(old_name : ^integer, string : ^array[NAME_SIZE] of integer) : ^integer;
var
   string_pos : integer,
   c : integer,
   np : ^integer,
   rnp : ^integer;
   
begin
   k_cpr(MAP_COLOR, "  Entered get_name"); k_prln(1);
   k_cpr(MAP_COLOR, "      string is  "); k_cpr(MAP_COLOR, string); k_prln(1);
   k_cpr(MAP_COLOR, "      old_name is  "); k_cpr(MAP_COLOR, old_name); k_prln(1);
   np := string;
   rnp := old_name;
   k_cpr(MAP_COLOR, "      rnp as str is  "); k_cpr(MAP_COLOR, rnp); k_prln(1);
   (* Skip over the Leading slashes in old_name 
    * rnp will point at the first char after the slashes.
    *)
   k_cpr(MAP_COLOR, "   skipping over slashes in old_name ");  k_prln(1);
   while (1) do begin
      c := rnp^;
      if (c <> ASCII_SLASH) then break;
      rnp := rnp + 1         
   end;
   k_cpr(MAP_COLOR, "   finished skipping over slashes in old_name ");  k_prln(1);
   k_cpr(MAP_COLOR, "       c is  : "); k_cpr_hex_num(MAP_COLOR, c); k_prln(1);
   
   (* AST1,10770
    * Now, having skipped the slashes, copy from old_name to string 
    * c points at the first char after the slashes
    * Please note, MAX_PATH is the size of global user_path
    *)
   k_cpr(MAP_COLOR, "       top of loop"); k_prln(1);
   while (1) do begin
      k_cpr(MAP_COLOR, "       c is  : "); k_cpr_hex_num(MAP_COLOR, c); k_prln(1);
      if __uge(rnp, adr(user_path[MAX_PATH])) then begin
         k_cpr(MAP_COLOR, "  rnp __UGE adr(user_path[MAX_PATH)"); k_prln(1);
         k_cpr(MAP_COLOR, "  rnp : "); k_cpr_hex_num(MAP_COLOR, rnp); k_prln(1);
         k_cpr(MAP_COLOR, "  adr(user_path[max] : "); k_cpr_hex_num(MAP_COLOR, adr(user_path[MAX_PATH])); k_prln(1);
         k_cpr(MAP_COLOR, "  breaking out of while looop"); k_prln(1);
         break
      end; 
      
      if (c = ASCII_SLASH) then begin
         k_cpr(MAP_COLOR, "c is a slash breaking"); k_prln(1);
         break
      end;
      if (c = 0) then begin 
         k_cpr(MAP_COLOR, "c is 0 breaking"); k_prln(1);
         break
      end;
       
      (* if weve gotten this far, we know we can still move right across old_name.*)
      k_cpr(MAP_COLOR, "  np __UL adr(string[NAME_SIZE]"); k_prln(1);
      k_cpr(MAP_COLOR, "     np : "); k_cpr_hex_num(MAP_COLOR, np); k_prln(1);
      k_cpr(MAP_COLOR, "     adr(string^[NAME_SIZE] : "); k_cpr_hex_num(MAP_COLOR, adr(string^[NAME_SIZE]) ); k_prln(1);
      if __ul(np, adr(string^[NAME_SIZE]) ) then begin
         k_cpr(MAP_COLOR, "   ADDING char to string - IMPORTANT");
         np^ := c;
         np := np + 1
      end
      else begin
         k_cpr(MAP_COLOR, "    NOT Adding char to string - IMPORTANT")      
      end;
      rnp := rnp + 1;
      c := rnp^
   end;
   
   (* AST1,10775
    * np now points past leftmost component
    * c contains matching char
    * np points past end of match
   (* Now we want to skip trailing slashes *)
   while (1) do begin
      if c <> ASCII_SLASH then break;
      if __uge(rnp, adr(user_path[MAX_PATH])) then break;
      rnp := rnp + 1;
      c := rnp^
   end;
   
   (* AST1,10779 Pad string with nulls *)
   while (__ul(np, adr(string^[NAME_SIZE]))) do begin
      np^ := 0;
      np := np + 1
   end;
   
   (* AST1,10781 *)
   if __uge(rnp, adr(user_path[MAX_PATH])) then begin
      err_code := E_LONG_STRING;
      retval(0)
   end;
   
   k_cpr(MAP_COLOR, "Leaving get_name"); k_prln(1);
   retval(rnp)
end;
(*==================================================================*)


(*==================================================================*)
(*
 * last_dir() based on AST1,10703
 * 
 * DEV_STATUS:last_dir Looks done 23 Oct 2013
 *
 * There are 4 cases when last_dir is called.
 *    The 4 cases are new_node, eat_path, do_link, do_unlink.
 *
 *    In all 4 parameter path is set to the global user_path
 *    This is important to note because there are mixed references to 
 *       path, and 
 *       user_path (user_path is refd in get_name which is called by this func)
 *
 * Return last_dir given a path with a file name e.g
 *    if path = /d1/d2/f1, return inode to path "/d1/d2"
 *       set string to f1
 *)
function last_dir(path : ^integer, string : ^array[NAME_SIZE] of integer) : ^t_inode;
var
   (* new_name always points within user_path *)
   new_name : ^integer,
   new_ip : ^t_inode,
   rip : ^t_inode;
   
begin
   k_cpr(MAP_COLOR, "  Entered last_dir"); k_prln(1);
   k_cpr(MAP_COLOR, "    path is : "); k_cpr(MAP_COLOR, path); k_prln(1);
   
   (* Is the path relative or absolute? *)
   if path^ = ASCII_SLASH then begin
      k_cpr(MAP_COLOR, "  rip is rootdir..."); k_prln(1);
      rip := fp^.fp_rootdir
   end
   else begin
      k_cpr(MAP_COLOR, "  rip is work dir..."); k_prln(1);
      rip := fp^.fp_workdir
   end;
   dup_inode(rip);
   
   (* Start moving right across the path *)
   while (1) do begin
      (* path is always in user_path
       * string becomes leftmost component of the path.
       * new_name becomes the remainder to the right.
       *)
      new_name := get_name(path, string);
      k_cpr(MAP_COLOR, " back from get_name :"); k_prln(1);
      k_cpr(MAP_COLOR, "    path     is : "); k_cpr(MAP_COLOR, path); k_prln(1);
      k_cpr(MAP_COLOR, "    string     is : "); k_cpr(MAP_COLOR, string); k_prln(1);

      k_cpr(MAP_COLOR, "    new_name is : "); k_cpr(MAP_COLOR, new_name); k_prln(1);
      if new_name = 0 then begin
         k_cpr(MAP_COLOR, "  new_name is nil after call to get_name means bad path"); k_prln(1);
         put_inode(rip);
         k_cpr(MAP_COLOR, "  Leaving last_dir"); k_prln(1);
         retval(NIL_INODE)
      end;
      
      if new_name^ = 0 then begin
         k_cpr(MAP_COLOR, "  new_name^ is NIL this is a good outcome. leaving last_dir returning to_eat_path.."); k_prln(1);
         retval(rip)
      end;
      (* We need to advance into the dir named string *)
      k_cpr(MAP_COLOR, "    string (advance dir)  is : "); k_cpr(MAP_COLOR, string); k_prln(1);      
      k_cpr(MAP_COLOR, "      rip : "); k_cpr_hex_num(MAP_COLOR, rip); k_prln(1);
      new_ip := advance(rip, string);
      k_cpr(MAP_COLOR, "      new_ip after advance : "); k_cpr_hex_num(MAP_COLOR, new_ip); k_prln(1);
      
      put_inode(rip);
      if (new_ip = NIL_INODE) then begin
         k_cpr(MAP_COLOR, "  rip is NIL returning "); k_prln(1);      
         retval(NIL_INODE)
      end;         
   
      path := new_name;
      rip := new_ip
   end;
      
   k_cpr(MAP_COLOR, "  Leaving last_dir"); k_prln(1)
end;
(*==================================================================*)


(*==================================================================*)
(*
 * eat_path() based on AST1,10675
 * 
 * DEV_STATUS:eat_path looks done 23 Oct 2013f
 *)

function eat_path(path : ^integer) : ^t_inode;

var
   ldip : ^t_inode,
   r : integer,
   string : array[NAME_SIZE] of integer,
   rip : ^t_inode;
   

begin
   k_cpr(MAP_COLOR, "Entered do_eat_path"); k_prln(1);
   k_cpr(MAP_COLOR, "  path is  is : "); k_cpr(MAP_COLOR, path); k_prln(1);
   
   ldip := last_dir(path, adr(string));
   
   if (ldip = NIL_INODE) then begin
      k_cpr(MAP_COLOR, "  ldip is NIL after last_dir()"); k_prln(1);
      retval(NIL_INODE)
   end;
   
   k_cpr(MAP_COLOR, " in eat_path final string to advance to is : ");
   k_cpr(MAP_COLOR, adr(string)); k_prln(1);
   
   if (string[0] = 0) then retval(ldip);
   
   rip := advance(ldip, adr(string));
   put_inode(ldip);
   
  
   k_cpr(MAP_COLOR, "Leaving eat_path"); k_prln(1);
   retval(rip)
end;
(*==================================================================*)

