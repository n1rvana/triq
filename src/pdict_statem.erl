-module(pdict_statem).

-include("triq.hrl").

-compile(export_all).

%%
%% A simple statem test for the process dictionary; tests the
%% operations erlang:put/2, erlang:get/1 and and erlang:erase/1.
%%

prop_pdict_statem() ->
    ?FORALL(Cmds, 
	    triq_statem:commands(pdict_statem),
	    begin
		triq_statem:run_commands(pdict_statem, Cmds),
		true
	    end).

-define(KEYS, [a,b,c,d]).
key() ->
    oneof(?KEYS).

initial_state() ->
    lists:filter(fun({Key,_}) -> lists:member(Key, ?KEYS) end,
		 erlang:get()).

command([]) ->
    {call, erlang, put, [key(), int()]};
command(Props) ->
    ?LET({Key,Value}, frequency([{5, elements(Props)},
				 {1, {key(),int()}}]),
	 oneof([{call, erlang, put,   [Key, Value]},
		{call, erlang, get,   [Key]},
		{call, erlang, erase, [Key]}
	       ])).

precondition(_, {call, erlang, put, [_,_]}) ->
    true;
precondition(Props, {call, erlang, get, [Key]}) ->
    proplists:is_defined(Key,Props);
precondition(Props, {call, erlang, erase, [Key]}) ->
    proplists:is_defined(Key,Props);
precondition(_,_) ->
    false.

postcondition(Props, {call, erlang, put, [Key,_]}, undefined) ->
    not proplists:is_defined(Key,Props);
postcondition(Props, {call, erlang, put, [Key,_]}, Old) ->
    {Key,Old} == proplists:lookup(Key,Props);
postcondition(Props, {call, erlang, get, [Key]}, Val) ->
    {Key,Val} == proplists:lookup(Key,Props);
postcondition(Props, {call, erlang, erase, [Key]}, Val) ->
    {Key,Val} == proplists:lookup(Key,Props);
postcondition(_,_,_) ->
    false.

next_state(Props, _Var, {call, erlang, put, [Key,Value]}) ->
    [{Key,Value}] ++ Props;
next_state(Props, _Var, {call, erlang, erase, [Key]}) ->
    proplists:delete(Key,Props);
next_state(Props, _Var, {call, erlang, get, [_]}) ->
    Props.

