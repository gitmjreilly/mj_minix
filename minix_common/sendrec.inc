#ifndef SENDREC_INC_INCLUDED
#define SENDREC_INC_INCLUDED


(*===================================================================
 * receive "library" routine - described in tanenbaum but not shown
 * Tanenbaum also has a #define "RECEIVE" so the procedure requires
 * a different name.
 *===================================================================*)
procedure receive_p(sender : integer, mess_ptr : integer);
begin
   asm
      2                   # RECV system call
      R_FETCH 2 - FETCH  # sender
      R_FETCH 1 - FETCH  # m_ptr
      SYSCALL
   end
end;
(*===================================================================*)


(*===================================================================
 * send "library" routine - described in tanenbaum but not shown.
 *===================================================================*)
procedure send_p(receiver : integer, mess_ptr : integer);
begin
   asm
      1 # SEND  system call
      R_FETCH 2 - FETCH  # receiver
      R_FETCH 1 - FETCH  # m_ptr
      SYSCALL
   end
end;
(*===================================================================*)

#endif