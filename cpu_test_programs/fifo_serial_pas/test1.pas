#include <runtime.pas>
#include <k_userio.inc>

var
   x : integer;

begin
	k_pr("Hello World!"); k_prln(2);
	k_pr("Goodbye Cruel World!"); k_prln(2);
   asm
      HALT
   end
end.
	