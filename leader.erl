-module(leader).
-export([start/0]).

start() ->
  receive
    {Acceptors, Replicas} ->
      lead(Acceptors, Replicas, 0)
  end.

lead(Acceptors, Replicas, BallotNum) ->
  spawn(scout, start, [self(), Acceptors, BallotNum]),
  lead_loop(Acceptors, Replicas, 0, false, sets:new()).

lead_loop(Acceptors, Replicas, BallotNum, Active, Proposals) ->
  receive
    {propose, S, C} ->
      _ContainsCommand = contains_command(Proposals, C)
  end.


contains_command(Proposals, C) ->
  ProposalList = sets:to_list(Proposals),
  Commands = lists:unzip(ProposalList),
  lists:member(C, Commands).
