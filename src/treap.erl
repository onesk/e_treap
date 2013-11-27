-module(treap).

-export_type([treap/3]).

-export([new/0,
		 store/4, erase/2,
		 extract_min/1,
		 decrease_priority/3, decrease_priority/4,
		 to_list/1, from_list/1,
		 find/2, fetch/2]).

%% Types

-type treap(S, P, V) :: nil | {S, P, V, treap(S, P, V), treap(S, P, V)}.

%% Operations

-spec new() -> treap(_S, _P, _V).
new() -> nil.

-spec store(S, P, V, treap(S, P, V)) -> treap(S, P, V).
store(S, P, V, nil) ->
	{S, P, V, nil, nil};
store(S, P, V, {SH, PH, VH, TL, TR}) ->
	if
		S < SH -> rotate_r({SH, PH, VH, store(S, P, V, TL), TR});
		S > SH -> rotate_l({SH, PH, VH, TL, store(S, P, V, TR)})
	end.

-spec erase(S, treap(S, P, V)) -> treap(S, P, V).
erase(_S, nil) ->
	nil;
erase(S, {SH, PH, VH, TL, TR}) ->
	if
		S < SH -> {SH, PH, VH, erase(S, TL), TR};
		S > SH -> {SH, PH, VH, TL, erase(S, TR)};
		true   -> disjoint_union(TL, TR)
	end.

-spec extract_min(treap(S, P, V)) -> {S, P, V, treap(S, P, V)}.
extract_min({S, P, V, TL, TR}) ->
	{S, P, V, disjoint_union(TL, TR)}.

-spec decrease_priority(S, P, V, treap(S, P, V)) -> treap(S, P, V).
decrease_priority(S, P, V, {SH, PH, VH, TL, TR}) ->
	if
		S  < SH -> rotate_r({SH, PH, VH, decrease_priority(S, P, V, TL), TR});
		S  > SH -> rotate_l({SH, PH, VH, TL, decrease_priority(S, P, V, TR)});
		P =< PH -> {S, P, V, TL, TR}
	end.

-spec decrease_priority(S, P, treap(S, P, V)) -> treap(S, P, V).
decrease_priority(S, P, {SH, PH, VH, TL, TR}) ->
	if
		S  < SH -> rotate_r({SH, PH, VH, decrease_priority(S, P, TL), TR});
		S  > SH -> rotate_l({SH, PH, VH, TL, decrease_priority(S, P, TR)});
	    P =< PH -> {S, P, VH, TL, TR}
	end.

-spec to_list(treap(S, P, V)) -> [{S, P, V}].
to_list(Treap) ->
	to_list(Treap, []).

to_list(nil, R) ->
	R;
to_list({S, P, V, TL, TR}, R) ->
	R1 = to_list(TR, R),
	to_list(TL, [{S, P, V} | R1]).

-spec from_list([{S, P, V}]) -> treap(S, P, V).
from_list(L) ->
	lists:foldl(fun ({S, P, V}, T) -> store(S, P, V, T) end, new(), L).

-spec find(S, treap(S, P, V)) -> {ok, P, V} | error.
find(_S, nil) ->
	error;
find(S, {SH, PH, VH, TL, TR}) ->
	if
		S < SH -> find(S, TL);
		S > SH -> find(S, TR);
		true   -> {ok, PH, VH}
	end.

-spec fetch(S, treap(S, P, V)) -> {P, V}.
fetch(S, T) ->
	{ok, P, V} = find(S, T),
	{P, V}.

%% Auxiliary

rotate_l({S, P, V, TL, {SR, PR, VR, TRL, TRR}}) when PR < P ->
	{SR, PR, VR, {S, P, V, TL, TRL}, TRR};
rotate_l(Node) -> Node.

rotate_r({S, P, V, {SL, PL, VL, TLL, TLR}, TR}) when PL < P ->
	{SL, PL, VL, TLL, {S, P, V, TLR, TR}};
rotate_r(Node) -> Node.

disjoint_union(T1, nil) -> T1;
disjoint_union(nil, T2) -> T2;
disjoint_union(T1 = {S1, P1, V1, TL1, TR1}, T2 = {S2, P2, V2, TL2, TR2}) ->
	if
		P1 =< P2 ->
			{S1, P1, V1, TL1, disjoint_union(TR1, T2)};
		true  ->
			{S2, P2, V2, disjoint_union(T1, TL2), TR2}
	end.
