
%%% distributed algorithms, n.dulay 27 feb 17
%%% coursework 2, paxos made moderately complex

-module(replica).
-export([start/1]).

start(Database) ->
  receive
    {bind, Leaders} -> 
       next(Database, Leaders, 1, 1, [], maps:new())
  end.

next(Database, Leaders, SlotIn, SlotOut, Requests, Scroll) ->
  receive
    {request, C} ->      % request from client
      Requests2 = [C | Requests],
      propose_next(Database, Leaders, SlotIn, SlotOut, Requests2, Scroll);
    {decision, S, C} ->  % decision from commander
      case maps:find(Scroll, S) of
        {ok, {proposal, C2}} -> 
          Requests2 = [C2 | Requests];
        error -> 
          Requests2 = Requests
      end,

      Scroll2 = Scroll#{ S := {decision, C} },
      SlotOut2 = update_slot_out(SlotOut, Scroll2),
      perform(Database, SlotOut, SlotOut2, Scroll2),
      propose_next(Database, Leaders, SlotIn, SlotOut2, Requests2, Scroll2)
  end. % receive

update_slot_out(SlotOut, Scroll) ->
  case maps:find(Scroll, SlotOut) of
    error -> SlotOut;
    {ok, {proposal, _}} -> SlotOut;
    {ok, {decision, _}} -> update_slot_out(SlotOut + 1, Scroll)
   end.

propose_next(Database, Leaders, SlotIn, SlotOut, [], Scroll) ->
  next(Database, Leaders, SlotIn, SlotOut, [], Scroll);
propose_next(Database, Leaders, SlotIn, SlotOut, Requests, Scroll) ->
  WINDOW = 5,
  
  case (SlotIn < SlotOut + WINDOW) of
    false -> next(Database, Leaders, SlotIn, SlotOut, Requests, Scroll);
    true -> 
      case maps:find(Scroll, SlotIn) of
        {ok, _} -> propose_next(Database, Leaders, SlotIn + 1, SlotOut, Requests, Scroll);
        error ->
          C = lists:min(Requests),
          Requests2 = lists:delete(C, Requests),
          Scroll2 = Scroll#{ SlotIn := {proposal, C} },
          [Leader ! {propose, SlotIn, C} || Leader <- Leaders],
          propose_next(Database, Leaders, SlotIn + 1, SlotOut, Requests2, Scroll2)
      end
  end.

perform(_, Start, Start, _) -> stop;
perform(Database, Start, End, Scroll) ->
  case maps:find(Scroll, Start) of
    {ok, {decision, {Client, Cid, Op}}} ->
      Database ! {execute, Op},
      Client ! {response, Cid, ok}
  end,
  
  perform(Database, Start + 1, End, Scroll).

