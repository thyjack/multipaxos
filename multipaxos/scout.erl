-module(scout).
-export([start/3]).

start(Leader, Acceptors, BallotNum) ->
    scout(Leader, Acceptors, BallotNum, Acceptors).


scout(Leader, Acceptors, BallotNum, WaitFor) ->
    [Acceptor ! {p1a, self(), BallotNum} ||Acceptor <- Acceptors],
    receive
        {p1b, Acceptor, BallotAcc, Accepted} ->
            if BallotAcc == BallotNum ->
                NewWaitFor = sets:del_element(Acceptor, WaitFor),
                WaitForAccSize = sets:size(NewWaitFor),
                AcceptorsHalfSize = sets:size(Acceptors) / 2,
                if  WaitForAccSize < AcceptorsHalfSize ->
                    Leader ! {adopted, BallotNum, };
                true ->
                    ok
                end;
    end.