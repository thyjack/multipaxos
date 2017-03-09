%%% Oliver Wheeler (ow14) and Hongjiang Liu (hl5314)
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
      % io:format("[replica ~p] request: ~p ~n", [self(), C]),
      Requests2 = [C | Requests],
      propose_next(Database, Leaders, SlotIn, SlotOut, Requests2, Scroll);
    {decision, S, C} ->  % decision from commander
      % io:format("[replica ~p] decision made: ~p => ~p ~n", [self(), S, C]),
      case maps:find(S, Scroll) of
        {ok, {proposal, C2}} when C /= C2 ->
          Requests2 = [C2 | Requests];
        {ok, {proposal, C3}} when C == C3 ->
          Requests2 = Requests;
        {ok, {decision, C4}} when C == C4 ->
          Requests2 = Requests;
        error ->
          Requests2 = Requests
      end,

      Scroll2 = Scroll#{ S => {decision, C} },
      SlotOut2 = update_slot_out(SlotOut, Scroll2),
      perform(Database, SlotOut, SlotOut2, Scroll2),

      Scroll3 = lists:foldl(fun(Slot, Scr) -> maps:remove(Slot, Scr) end, Scroll2, lists:seq(SlotOut, SlotOut2 - 1)),
      propose_next(Database, Leaders, SlotIn, SlotOut2, Requests2, Scroll3)
  end. % receive

update_slot_out(SlotOut, Scroll) ->
  case maps:find(SlotOut, Scroll) of
    error -> SlotOut;
    {ok, {proposal, _}} -> SlotOut;
    {ok, {decision, _}} -> update_slot_out(SlotOut + 1, Scroll)
   end.

propose_next(Database, Leaders, SlotIn, SlotOut, Requests, Scroll) ->
  WINDOW = 5,

  case (SlotIn < SlotOut + WINDOW) and (Requests /= []) of
    false -> next(Database, Leaders, SlotIn, SlotOut, Requests, Scroll);
    true ->
      case maps:find(SlotIn, Scroll) of
        {ok, _} -> propose_next(Database, Leaders, SlotIn + 1, SlotOut, Requests, Scroll);
        error ->
          [C | Requests2] = Requests,
          Scroll2 = Scroll#{ SlotIn => {proposal, C} },
          % io:format("[replica ~p] New proposal: ~p => ~p ~n", [self(), SlotIn, C]),
          utils:set_foreach(fun(Leader) -> Leader ! {propose, SlotIn, C} end, Leaders),
          propose_next(Database, Leaders, SlotIn + 1, SlotOut, Requests2, Scroll2)
      end
  end.

perform(_, Start, Start, _) -> stop;
perform(Database, Start, End, Scroll) ->
  case maps:find(Start, Scroll) of
    {ok, {decision, {Client, Cid, Op}}} ->
      Database ! {execute, Op},
      Client ! {response, Cid, ok}
  end,

  perform(Database, Start + 1, End, Scroll).
