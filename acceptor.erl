-module(acceptor).
-export([start/0]).

start() ->
  accept(none, sets:new()).

accept(BallotNum, Accepted) ->
  receive
    {p1a, Leader, Ballot} ->      
      % io:format("[acceptor ~p] p1a ~n", [self()]),
      if (BallotNum == none) or (Ballot > BallotNum) ->
        Leader ! {p1b, self(), Ballot, Accepted},
        accept(Ballot, Accepted);
      true ->
        Leader ! {p1b, self(), BallotNum, Accepted},
        accept(BallotNum, Accepted)
      end;
    {p2a, Leader, {B, S, C}} ->
      % io:format("[acceptor ~p] p2a ~n", [self()]),
      if B == BallotNum ->
        NewSet = sets:add_element({B, S, C}, Accepted),
        Leader ! {p2b, self(), B},
        accept(B, NewSet);
      true ->
        Leader ! {p2b, self(), BallotNum},
        accept(BallotNum, Accepted)
      end
  end.