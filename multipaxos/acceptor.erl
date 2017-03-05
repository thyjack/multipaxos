-module(acceptor).
-export([start/0]).

start() ->
    accept(0, sets:new()).

accept(BallotNum, Accepted) ->
  receive
        {p1a, Leader, Ballot} ->      
            if b > BallotNum ->
                Leader ! {p1b, self(), Ballot, Accepted},
                accept(b, Accepted);
            true ->
                Leader ! {p1b, self(), BallotNum, Accepted}
            end;
        {p2a, Leader, {B, S, C}} ->
            if b == BallotNum ->
                NewSet = sets:add_element(Accepted, {B, S, C}),
                Leader ! {p2b, self(), b, NewSet},
                accept(b, NewSet);
            true ->
                Leader ! {p2b, self(), BallotNum}
            end
    end.