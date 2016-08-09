%% Author: php
%% Created: 
%% Description: TODO: Add description to gun_cash_msg
-module(gun_cash_msg).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([]).
%%
%% API Functions
%%
%% 滚服信息
%%[GunState,TotalCash,TodayCash]
msg_info(GunState,TotalCash,TodayCash) ->
	misc_packet:pack(?MSG_ID_GUN_CASH_INFO, ?MSG_FORMAT_GUN_CASH_INFO, [GunState,TotalCash,TodayCash]).
%%
%% Local Functions
%%
