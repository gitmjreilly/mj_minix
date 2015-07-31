
(********************************************************************)
procedure h1_cannot_do() ;
begin
   pr("I cannot do as you wish.  Get yourself a new steward!"); prln(2)
end;
(********************************************************************)

(********************************************************************)
procedure h1_bye() ;
begin
   pr("Bye for now."); prln(2)
end;
(********************************************************************)


(********************************************************************)
procedure HamurabiGame() ;
var
   ans : integer,
   year_num : integer,
   num_bushels_in_store : integer,
   harvest : integer,
   num_bushels_eaten_by_rats : integer,
   num_bushels_harvested_per_acre : integer,
   population : integer,
   num_acres_owned : integer,
   num_new_people : integer,
   num_people_starved : integer,
   total_starved : integer,
   num_acres_to_buy : integer,
   num_acres_to_sell : integer,
   num_acres_to_plant : integer,
   cost_per_acre : integer,
   num_bushels_to_feed_the_people : integer,
   tmp_str : array[30] of integer;


begin
   prtab(32); pr("Hamurabi"); prln(2);
   prln(3);
   pr("Try your hand at governing Ancient Sumeria"); prln(1);
   pr("for a 10 year term of office"); prln(1);

   year_num := 0;
   population := 95;

   harvest := 3000; 
   num_bushels_in_store := 2800;
   num_bushels_eaten_by_rats := harvest - num_bushels_in_store;

   cost_per_acre := 3;
   num_acres_owned := harvest / cost_per_acre;
   num_new_people := 5;
   num_acres_to_plant := 0;
   total_starved := 0;
   num_people_starved := 0;
   num_bushels_harvested_per_acre := 3;


   (* Game Main Loop *)
   while (1) do begin
      (* 215 *)
      prln(3);
      pr("======== ANNUAL Report ========"); prln(1);
      pr("Ham I beg to report to you, "); 
      pr("in year "); prnum(year_num); pr(" ,");  prnum(num_people_starved); pr(" people starved, "); prln(1);
      pr("and "); prnum(num_new_people); pr(" came to the City, "); prln(2);
   
      pr("Population is now "); prnum(population); prln(1);
      pr("City owns ");        prnum(num_acres_owned); pr(" acres."); prln(1);
      pr("You harvested ");    prnum(num_bushels_harvested_per_acre); pr(" bushels per acre. "); prln(1);
      pr("The rats ate ");     prnum(num_bushels_eaten_by_rats); pr(" bushels. "); prln(1);
      pr("You now have ");     prnum(num_bushels_in_store); pr(" bushels in store. "); prln(1);

      year_num := year_num + 1;
      if year_num = 5 then break;

      (* Adjust the population count *)
      population := population + num_new_people;
   

      pr("Land is trading at "); prnum(cost_per_acre); pr(" bushels per acre"); prln(1);

      prln(1);


      (* Buying or selling land? *)
      pr("Do you want to buy land(1), sell land(2), or do neither(3)?"); 
      while (1) do begin
         get_num(adr(ans));
         if ((ans >= 1) AND (ans <= 3)) then break;
         pr("Try again>")
      end;

      if ans = 1 then begin
         pr("You've chosen to buy land..."); prln(1);
         pr("How many acres do you wish to buy?");
         while (1) do begin
            get_num(adr(num_acres_to_buy));
            if (num_acres_to_buy < 0) then begin
                h1_cannot_do();
                h1_bye();
                return
            end;
            if (num_acres_to_buy * cost_per_acre > num_bushels_in_store) then begin
               pr("You are trying to buy more acres than you can afford!"); prln(1);
               pr("Try again>");
               continue
            end;
            break
         end;
         num_acres_owned := num_acres_owned + num_acres_to_buy;
         num_bushels_in_store := num_bushels_in_store - num_acres_to_buy * cost_per_acre
      end
      else if ans = 2 then begin
         pr("You've chosen to sell land..."); prln(1);
         pr("How many acres do you wish to sell?");
         while (1) do begin
            get_num(adr(num_acres_to_sell));
            if (num_acres_to_sell < 0) then begin
                h1_cannot_do();
                h1_bye();
                return
            end;
            if (num_acres_to_sell > num_acres_owned) then begin
               pr("You are trying to sell more acres than you have !"); prln(1);
               pr("Try again>");
               continue
            end;
            break
         end;
         num_acres_owned := num_acres_owned - num_acres_to_sell;
         num_bushels_in_store := num_bushels_in_store + num_acres_to_sell * cost_per_acre
      end;
      (* If we got this far, weve possibly bought or sold land *)

      (* Feeding the people? 410  *)
      while 1 do begin
         prln(1); pr("How many bushels do you wish to feed the people?");
         get_num(adr(num_bushels_to_feed_the_people));

         if num_bushels_to_feed_the_people < 0 then begin
            h1_cannot_do();
            h1_bye();
            return
         end;

         if (num_bushels_to_feed_the_people > num_bushels_in_store) then begin
            pr("Hamurabi, think again.");prln(1);
            pr("You are trying to feed the people more than you have.");prln(1);
            pr("Admiral, but misguided!"); prln(1);
            continue
         end;

         (* If we've gotten this far, we've met all of the 
          * conditions necessary to plant seed.
          *)
         break
      end;


      (* Planting acres with seed?  440 *)
      while 1 do begin
         prln(1); pr("How many acres do you wish to plant with seed ? ");
         get_num(adr(num_acres_to_plant));

         if num_acres_to_plant < 0 then begin
            h1_cannot_do();
            h1_bye();
            return
         end;

         if (num_acres_to_plant > num_acres_owned) then begin
            pr("Hamurabi, think again. You are trying to plant on more ");prln(1);
            pr("acres than you have."); prln(1);
            continue
         end;

         (* Need 2 bushels per acre for planting *)
         if num_acres_to_plant  > (num_bushels_in_store * 2) then begin
            pr("Hamurabi, think again. You do not have enough bushels of grain."); prln(1);
            pr("on this many acres..."); prln(1);
            continue
         end;

         if (num_acres_to_plant ) > population * 10 then begin
            pr("Hamurabi, think again. You do not have people to plant all of those acres."); prln(1);
            continue
         end;

         (* If we've gotten this far, we've met all of the 
          * conditions necessary to plant seed.
          *)
         break
      end;

      num_bushels_harvested_per_acre := random_int(4) + 1;
      (* harvest is in bushels *)
      harvest := num_acres_to_plant * num_bushels_harvested_per_acre;

      (* Figure out what the rats have done. *)
      if (random_int(2) = 1) then begin
         num_bushels_eaten_by_rats := num_bushels_in_store / (random_int(5) + 1)
      end
      else begin
         num_bushels_eaten_by_rats := 0
      end;
      num_bushels_in_store := num_bushels_in_store - num_bushels_eaten_by_rats + harvest;

      (* Figure out population change... 532  *)   
      num_new_people := (random_int(5) * (20 * num_acres_owned + num_bushels_in_store) / population / 100 + 1 );
      num_new_people := 3;

      (* Full tummies? ... 539 *)   
      if num_bushels_to_feed_the_people >  (population * 20) then begin
         num_people_starved := 0;
         continue
      end;

      (* Figure out how many people starved this year... *)
      num_people_starved := population - (num_bushels_to_feed_the_people / 20);
      total_starved := total_starved + num_people_starved


   end; (* End of game Loop *)

   prln(3);
   pr("Here is a summary of your years of service."); prln(1);
   pr("You started with 10 acres per person."); prln(1);
   pr("You ended with "); prnum(num_acres_owned / population); pr(" acres per person."); prln(1);
   pr("You starved "); prnum(total_starved); pr(" people.");

   pr("The game is over!"); prln(2)

end;

