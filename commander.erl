-module(commander).
-export([start/4]).

start(Leader,Acceptors,Replicas,{B,S,C}) ->
  command(Leader, Acceptors, Replicas, {B,S,C}).

command(Leader,Acceptors,Replicas,{B,S,C}) ->
  utils:set_foreach(fun(Acceptor) -> Acceptor ! {p2a, self(), {B, S, C}} end, Acceptors),
  command_loop(Leader, Acceptors, Replicas, {B,S,C}, Acceptors).

command_loop(Leader, Acceptors, Replicas, {B,S,C}, WaitFor) ->
  receive
    {p2b, Acceptor, AccBallotNum} ->
      % io:format("[commander ~p] p2b ~n", [Leader]),
      if AccBallotNum == B ->
        NewWaitFor = sets:del_element(Acceptor, WaitFor),
        WaitForAccSize = sets:size(NewWaitFor),
        AcceptorsHalfSize = sets:size(Acceptors) / 2,
        if  WaitForAccSize < AcceptorsHalfSize  ->
          % io:format("[commander ~p] consensus reached, decision = ~p => ~p ~n", [Leader, S, C]),
          utils:set_foreach(fun(Replica) -> Replica ! {decision, S, C} end, Replicas),
          exit(commander);
        true ->
          command_loop(Leader,Acceptors,Replicas,{B,S,C}, NewWaitFor)
        end;
      true ->
        Leader ! {preempted, AccBallotNum},
        exit(commander)
      end
  end.
