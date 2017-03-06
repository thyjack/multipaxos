-module(commander).
-export([start/4]).

start(Leader,Acceptors,Replicas,{B,S,C}) ->
    command(Leader, Acceptors, Replicas, {B,S,C}, Acceptors).

command(Leader,Acceptors,Replicas,{B,S,C}, WaitFor) ->
    [Acceptor ! {p2a, self(), {B,S,C}} ||Acceptor <- Acceptors],
    receive
        {p2b, Acceptor, AccBallotNum} ->
            if AccBallotNum == B ->
                NewWaitFor = sets:del_element(Acceptor, WaitFor),
                WaitForAccSize = sets:size(NewWaitFor),
                AcceptorsHalfSize = sets:size(Acceptors) / 2,
                if  WaitForAccSize < AcceptorsHalfSize  ->
                    [Replica ! {decision, S, C} || Replica <- Replicas],
                    exit(commander);
                true ->
                    command(Leader,Acceptors,Replicas,{B,S,C}, NewWaitFor)
                end;
            true ->
                Leader ! {preempted, AccBallotNum},
                exit(commander)
            end       
    end.