procedure fibonacci() ;
var
   prev : integer,
   prev_prev : integer,
   sum : integer,
   num_printed : integer,
   tmp_str : array[10] of integer,
   nums_should_be_printed : integer,
   ans : integer,
   num_to_print : integer;


begin
   pr("Fibonacci printer..."); prln(2);
   pr("Do you wish to print(p) your output or just show last(not p...)?");
   gets(adr(tmp_str));
   compare_strings(adr(tmp_str), "p", adr(ans));
   if ans = 1 then 
      nums_should_be_printed := 1
   else 
      nums_should_be_printed := 0;

   pr("How many Fibonacci numbers do you wish to print (2..1000)?");
   while (1) do begin
      get_num(adr(num_to_print));
      if (num_to_print >= 2 AND num_to_print <= 1000) then break
   end;
   pr("Your num is : "); prnum(num_to_print);

   prev_prev := 1;
   prev := 1;
   if nums_should_be_printed then begin
      pr("1"); prln(1); 
      pr("1"); prln(1)
   end;
   num_printed := 2;
   while (1) do begin
      sum := prev_prev + prev;
      if num_to_print = num_printed then break;

      if nums_should_be_printed then begin
         prnum(sum); prln(1)
      end;
      prev_prev := prev;
      prev := sum;
      num_printed := num_printed + 1
   end;
   prnum(sum); prln(1);
   pr("Done printing Fibonacci numbers."); prln(2)
end;

