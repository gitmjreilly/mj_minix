#ifndef UTILITY_INC_INCLUDED
#define UTILITY_INC_INCLUDED


(*===================================================================
 * General mem to mem copy routine
 *===================================================================*)
procedure phys_copy(src_seg : integer, src_offset : integer,
                    dst_seg : integer, dst_offset : integer,
                    size : integer);
var
   tmp : integer,
   i : integer;

begin
   i := 0;
   while i < size do begin
      SetES(src_seg);
      LongFetch(src_offset, adr(tmp));

      SetES(dst_seg);
      LongStore(dst_offset, tmp);

      i := i + 1;
      src_offset := src_offset + 1;
      dst_offset := dst_offset + 1
   end

end;
(*===================================================================*)

#endif