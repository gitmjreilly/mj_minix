#ifndef H_TYPE_INC
#define H_TYPE_INC
(*
 * This file corresponds to h/type.h (line 500 Tanenbaum)
 * It has been translated to Jamet p-lite.
 * It is not a line for line translation!
 *
 * The message definition is NOT here even though it was
 * for Tanenbaum (line 554).  The reason for this is 
 * Tanenbaum used a union of structs with #defines in com.h.  
 * I (Jamet) am using record definitions to capture both the 
 * structs and the field names.  These can be found in com.h.
 *
 *)

type
   unshort = integer; (* line 510 *)

const
   NO_BLOCK = 0, (* line 507 indicates empty block in fs block cache *)
   NO_ENTRY = 0, (* line 511 *)
   NO_ZONE = 0;  (* line 515 *)

#define NO_DEV   $FFFF  (* line 524 indicates empty dev in fs block cache *)


#define M1 1
#define M3 3
#define M4 4
#define M3_STRING 14

type
   mess_1 = record
      m_source : integer;
      m_type : integer;
      m1i1 : integer;
      m1i2 : integer;
      m1p1 : ^integer;
      m1p2 : ^integer;
      m1p3 : ^integer;
      pad : array [ 13] of integer
   end;
   
type      
   mess_2 = record
      m_source : integer;
      m_type : integer;
      m2i1 : integer;
      m2i2 : integer;
      m2i3 : integer;
      m2l1 : array[2] of integer;
      m2l2 : array[2] of integer;
      m2p1 : ^integer;
      pad : array [ 10] of integer
   end;
      
type
   mess_3 = record
      m_source : integer;
      m_type : integer;
      m3i1 : integer;
      m3i2 : integer;
      m3p1 : ^integer;
      m3cal : array[M3_STRING] of integer;
      pad : integer
   end;

type
   mess_4 = record
      m_source : integer;
      m_type : integer;
      m4l1 : array[2] of integer;
      m4l2 : array[2] of integer;
      m4l3 : array[2] of integer;
      m4l4 : array[2] of integer;
      pad : array [ 10] of integer
   end;

type   
   mess_5 = record
      m_source : integer;
      m_type : integer;
      m5c1 : integer;
      m5c2 : integer;
      m5i1 : integer;
      m5i2 : integer;
      m5l1 : array[2] of integer;
      m5l2 : array[2] of integer;
      m5l3 : array[2] of integer;
      pad : array [ 8] of integer
   end;
      
            
            
#endif            