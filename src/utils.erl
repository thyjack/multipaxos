%%% Oliver Wheeler (ow14) and Hongjiang Liu (hl5314)
-module(utils).
-export([set_foreach/2, set_min/1]).

set_foreach(Fun, Set) ->
  sets:fold(fun(E, _) -> begin Fun(E), ok end end, ok, Set).

set_min(Set) ->
  lists:min(sets:to_list(Set)).
