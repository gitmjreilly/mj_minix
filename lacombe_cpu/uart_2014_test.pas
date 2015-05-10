#include <runtime.pas>
#include <k_userio_lacombe.inc>

var
   s : array[20] of integer,
   x : integer;

begin (* Main Program *)
   init_k_userio();
   set_default_uart(1);

   ConsolePrintStr("Starting Test Program...", 1);
   k_pr("Hi Mom!"); k_prln(1);
   k_pr("This is a big test!"); k_prln(1);
   k_cpr(ANSI_BLUE, "And now for a color test..."); k_prln(1);

   k_cpr(ANSI_BLUE, "Enter a string >");
   k_gets(adr(s));
   k_cpr(ANSI_BLUE, "Your string is : ");
   k_cpr(ANSI_WHITE, adr(s));

   
   while (1) do
      x := x
   

end.