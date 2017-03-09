%%% Oliver Wheeler (ow14) and Hongjiang Liu (hl5314)
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
      if AccBallotNum == B ->
        NewWaitFor = sets:del_element(Acceptor, WaitFor),
        WaitForAccSize = sets:size(NewWaitFor),
        AcceptorsHalfSize = sets:size(Acceptors) / 2,
        % io:format("[commander ~p (~p)] p2b decision (~p/~p) ~n", [Leader, self(), sets:size(Acceptors) - WaitForAccSize, sets:size(Acceptors)]),
        if  WaitForAccSize < AcceptorsHalfSize  ->
          % io:format("[commander ~p (~p)] consensus reached, decision = ~p => ~p ~n", [Leader, self(), S, C]),
          utils:set_foreach(fun(Replica) -> Replica ! {decision, S, C} end, Replicas),
          exit(commander);
        true ->
          command_loop(Leader,Acceptors,Replicas,{B,S,C}, NewWaitFor)
        end;
      true ->
        % io:format("[commander ~p (~p)] p2b preempt ~n", [Leader, self()]),
        Leader ! {preempted, AccBallotNum},
        exit(commander)
      end
  end.
