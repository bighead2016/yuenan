
-module(security).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0, stop/0]).

%%
%% API Functions
%%
start() ->
    application:start(?MODULE).

stop() ->
    application:stop(?MODULE).


%%
%% Local Functions
%%

