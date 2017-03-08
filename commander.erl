-module(commander).
-export([start/4]).

start(Leader,Acceptors,Replicas,{B,S,C}) ->
  command(Leader, Acceptors, Replicas, {B,S,C}).

command(Leader,Acceptors,Replicas,{B,S,C}) ->
  [Acceptor ! {p2a, self(), {B,S,C}} ||Acceptor <- Acceptors],
  command_loop(Leader, Acceptors, Replicas, {B,S,C}, Acceptors).

command_loop(Leader, Acceptors, Replicas, {B,S,C}, WaitFor) ->
  receive
    {p2b, Acceptor, AccBallotNum} ->
      if AccBallotNum == B ->
        NewWaitFor = sets:del_element(WaitFor, Acceptor),
        WaitForAccSize = sets:size(NewWaitFor),
        AcceptorsHalfSize = sets:size(Acceptors) / 2,
        if  WaitForAccSize < AcceptorsHalfSize  ->
          [Replica ! {decision, S, C} || Replica <- Replicas],
          exit(commander);
        true ->
          command_loop(Leader,Acceptors,Replicas,{B,S,C}, NewWaitFor)
        end;
      true ->
        Leader ! {preempted, AccBallotNum},
        exit(commander)
      end
  end.
