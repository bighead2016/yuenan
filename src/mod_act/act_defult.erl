%%% 转盘

-module(act_defult).
-behaviour(act_bhv).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

%%
%% Exported Functions
%%
-export([init/1, join/2, over/1, login/1, login_packet/1, offline/2]).

%%
%% API Functions
%%

login(OldPlayer) ->
    OldPlayer.

login_packet(OldPlayer) ->
    {OldPlayer, <<>>}.

init(Id) ->
    ?MSG_ERROR("init:~p...", [Id]),
    ok.

join(cash_in, [UserId, Cash, Point, ActInfo]) ->
    ?MSG_ERROR("join:~p|~p|~p|~p...", [UserId, Cash, Point, ActInfo]),
    ok;
join(_, [UserId, Cash, Point, ActInfo]) ->
    ?MSG_ERROR("join:~p|~p|~p|~p...", [UserId, Cash, Point, ActInfo]),
    ok.

over(Id) ->
    ?MSG_ERROR("over:~p...", [Id]),
    ok.

offline(Player, _Data) ->
    {?ok, Player}.

%%
%% Local Functions
%%

