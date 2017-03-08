-module(scout).
-export([start/3]).

start(Leader, Acceptors, BallotNum) ->
  scout(Leader, Acceptors, BallotNum).


scout(Leader, Acceptors, BallotNum) ->
  utils:set_foreach(fun(Acceptor) -> Acceptor ! {p1a, self(), BallotNum} end, Acceptors),
  scout_loop(Leader, Acceptors, BallotNum, Acceptors, sets:new()).


scout_loop(Leader, Acceptors, BallotNum, WaitFor, PValues) ->
  receive
    {p1b, Acceptor, BallotAcc, Accepted} ->
      % io:format("[scout ~p] p1b ~n", [self()]),
      if BallotAcc == BallotNum ->
        NewPValues = sets:union(PValues, Accepted),
        NewWaitFor = sets:del_element(Acceptor, WaitFor),
        WaitForAccSize = sets:size(NewWaitFor),
        AcceptorsHalfSize = sets:size(Acceptors) / 2,
        if 
          WaitForAccSize < AcceptorsHalfSize ->
            Leader ! {adopted, BallotNum, NewPValues},
            exit(scout);
          true ->
            scout_loop(Leader, Acceptors, BallotNum, NewWaitFor, NewPValues)
        end;
      true ->
        Leader ! {preempted, BallotAcc},
        exit(scout)
      end
  end.
