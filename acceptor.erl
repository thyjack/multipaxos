-module(acceptor).
-export([start/0]).

start() ->
  accept(0, sets:new()).

accept(BallotNum, Accepted) ->
  receive
    {p1a, Leader, Ballot} ->      
      if Ballot > BallotNum ->
        Leader ! {p1b, self(), Ballot, Accepted},
        accept(Ballot, Accepted);
      true ->
        Leader ! {p1b, self(), BallotNum, Accepted},
        accept(BallotNum, Accepted)
      end;
    {p2a, Leader, {B, S, C}} ->
      if B == BallotNum ->
        NewSet = sets:add_element({B, S, C}, Accepted),
        Leader ! {p2b, self(), B, NewSet},
        accept(B, NewSet);
      true ->
        Leader ! {p2b, self(), BallotNum},
        accept(BallotNum, Accepted)
      end
  end.