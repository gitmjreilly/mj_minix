#ifndef LINK_INC
#define LINK_INC

(*
 * Based on fs/link.c
 *)

 
 
(*******************************************************************)
(* truncate based on AST1, 11388
 * DEV_STATUS : WIP
 * See Jamet's FS copy of AST1 for lots of notes about what's happening 
 *)
procedure truncate(rip : ^t_inode);

var
   position : array[2] of integer,
   zone_size : array[2] of integer,
   i : integer,
   z : integer,
   iz : ^integer,
   b : integer,
   dev : integer,
   scale : integer,
   bp : ^t_buf;
   
begin
   k_cpr(FS_COLOR, "Entered truncate"); k_prln(1);

   dev := rip^.i_dev;
   (* scale := scale_factor(rip); TODO figure out scale or throw it away *)
   
   (* Had to make zone size 32 bits so it could
    * be used in arithmetic with 32 bit position *)
   zone_size[1] := BLOCK_SIZE (* << scale *) ; 
   zone_size[0] := 0;
   
   if (rip^.i_pipe = I_PIPE) then begin
      rip^.i_size[0] := 0;
      rip^.i_size[1] := PIPE_SIZE
   end;
   
   (* AST1, 11409 *)
   (* This loop is confusing.  Here's why...
    * read_map returns a BLOCK num given a position, but we allocate/deallocate
    * by ZONES.  So what we do is skip ahead in the file a zone_size at a time
    * getting block num b but then having to convert it back to a zone num z
    * for use with free_zone.
    *
    * Ultimately, this look frees all of the data zones, but none of the -
    * indirect or doubly indirect blocks; those are cleared later in this function
    *)
   s32_set_zero(adr(position));
   while ( s32_l( adr(position), adr(rip^.i_size)) ) do begin
      b := read_map(rip, adr(position));
      if (b <> NO_BLOCK) then begin
         z := b (* >> scale *) ;
         free_zone(dev, z)
      end;
   
      s32_add( adr(position), adr(zone_size), adr(position) )
   end;
   
   (* AST1, 11417 *)
   (* free the zone with singly indirect pointers 
    * It worth noting a few things about zone numbers in inodes
    * There are NR_DZONE_NUM direct zone numbers in an inode 0..(NR_DZONE_NUM - 1)
    * So the block with the indirect pointers is pointed at by i_zone[NR_DZONE_NUM].
    * We have already cleared all of the data, so now we can get rid of the 
    * zone with indirect pointers.
    *)
   free_zone(dev, rip^.i_zone[NR_DZONE_NUM]);
   
   
   (* AST1,11418 *)
   z := rip^.i_zone[NR_DZONE_NUM + 1];
   if (z <> NO_ZONE) then begin
      b := z (* << scale *) ;
      
      (* bp is the block with pointers to the doubly indirect pointer blocks
       * all of the doubly indirect blocks will now be freed *)
      bp :=  get_block(dev, b, NORMAL);

      i := 0;
      while (i < 1024) do begin
         iz := bp^.b__data[i] * 256 + bp^.b__data[i + 1];
         free_zone(dev, iz^);
         i := i + 2
      end;
      
      put_block(bp, INDIRECT_BLOCK);
      free_zone(dev, z)
   end;
   
   wipe_inode(rip)
   
end;
(*******************************************************************)



#endif
