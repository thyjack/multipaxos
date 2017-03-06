-module(commander).
-export([start/4]).

start(Leader,Acceptors,Replicas,{B,S,C}) ->
    [Acceptor ! {p2a, self(), {B,S,C}} ||Acceptor <- Acceptors],
    receive
        {p2b, Acceptor, AccBallotNum} ->
            if AccBallotNum == B ->
                NewWaitFor = sets:del_element(Acceptor, Acceptors),
                WaitForAccSize = sets:size(NewWaitFor),
                AcceptorsHalfSize = sets:size(Acceptors) / 2,
                if  WaitForAccSize < AcceptorsHalfSize  ->
                    [Replica ! {decision, S, C} || Replica <- Replicas];
                true ->
                    ok
                end;
            true ->
                Leader ! {preempted, AccBallotNum}
            end
                
    end,
    exit(commander).