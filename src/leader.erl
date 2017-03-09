%%% Oliver Wheeler (ow14) and Hongjiang Liu (hl5314)
-module(leader).
-export([start/0]).

start() ->
  receive
    {bind, Acceptors, Replicas} ->
      Ballot = {0, self()},
      spawn(scout, start, [self(), Acceptors, Ballot]),

      next(Acceptors, Replicas, Ballot, false, maps:new())
  end.

next(Acceptors, Replicas, Ballot, Active, Proposals) ->
  receive
    {preempted, {R, L}} ->
      case {R, L} > Ballot of
        true ->
          % io:format("[leader ~p] preempted ballot ~p ~n", [self(), {R, L}]),
          Ballot2 = {R + 1, self()},
          spawn(scout, start, [self(), Acceptors, Ballot2]),
          next(Acceptors, Replicas, Ballot2, false, Proposals);
        false ->
          next(Acceptors, Replicas, Ballot, Active, Proposals)
      end;
    {propose, S, C} ->
      case maps:find(S, Proposals) of
        error ->
          % io:format("[leader ~p] received proposal (active=~p): ~p => ~p ~n", [self(), Active, S, C]),
          Proposals2 = Proposals#{ S => C },
          if
            Active ->
              spawn(commander, start, [self(), Acceptors, Replicas, {Ballot, S, C}]);
            true ->
              pass
          end,
          next(Acceptors, Replicas, Ballot, Active, Proposals2);
        {ok, _} ->
          next(Acceptors, Replicas, Ballot, Active, Proposals)
      end;
    {adopted, B, PVal} when B == Ballot ->
      PMax = pmax(PVal),
      Proposals2 = maps:merge(Proposals, PMax),
      % io:format("[leader ~p] adpoted ~p for ballot ~p ~n", [self(), Proposals2, B]),
      maps:fold(
        fun(S, C, ok) -> spawn(commander, start, [self(), Acceptors, Replicas, {Ballot, S, C}]), ok end,
        ok,
        Proposals2),
      next(Acceptors, Replicas, Ballot, true, Proposals2)
  end.


pmax(PVals) ->
  PMax = pmax_helper(PVals),
  maps:map(fun(_, {_, C}) -> C end, PMax).
pmax_helper(PVals) ->
  sets:fold(
    fun({B, S, C}, Acc) ->
      case maps:find(S, Acc) of
        error -> Acc#{ S => {B, C} };
        {ok, {B2, _}} ->
          if
            B > B2 -> Acc#{ S => {B, C} };
            true -> Acc
          end
      end
    end,
    maps:new(),
    PVals).
