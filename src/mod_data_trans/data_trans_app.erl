%%% 

-module(data_trans_app).
-behaviour(application).
-export([start/2, start/0, stop/1]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([]).

%% ====================================================================
%% Behavioural functions
%% ====================================================================

start() ->
    try
        application:start(data_trans)
    catch
        X:Y -> io:format("~p|~p~n", [X, Y])
    end.

start(_, _) ->
    case data_trans_m_serv:start_link() of
		{ok, Pid} ->
			{ok, Pid};
		Error ->
			Error
    end.

stop(_State) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================


