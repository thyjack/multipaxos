-module(leader).
-export([start/0]).

start() ->
  receive
    {Acceptors, Replicas} ->
      lead(Acceptors, Replicas, 0, false, sets:new())
  end.

lead(Acceptors, _Replicas, BallotNum, _Active, _Proposals) ->
  spawn(scout, start, [self(), Acceptors, BallotNum]).

%lead_loop(Acceptors, Replicas, BallotNum, Active, Proposals) ->
