a%% Author: Administrator
%% Created: 2012-8-1
%% Description: TODO: Add description to mall_api
-module(mall_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([
		 mall_interval/0,
		 start/0,
		 msg_data_recv/2
		]).

%% 开服启动 CONST_MALL_DISCOUNT_TIME
%% mall_api:start().
start() -> 
	mall_interval(),
	crond_api:interval_del(mall_interval),
	crond_api:interval_add(mall_interval, ?CONST_MALL_DISCOUNT_TIME, mall_api, mall_interval, []).

%% 定时刷新物品
%% mall_api:mall_interval().
mall_interval() ->
	% 随机数种子
	?RANDOM_SEED, 
	Datas 	= data_mall:get_discount_list(?CONST_MALL_DISCOUNT),%% 取得物品数据列表
	List  	= misc_random:odds_list_norepeat(Datas, ?CONST_MALL_DISCOUNT_COUNT), %% 随机物品
	Time  	= misc:seconds() + ?CONST_MALL_DISCOUNT_TIME, %% 结束时间 
	mall_mod:insert_mall({?CONST_MALL_DISCOUNT,Time,List}),
	ets:delete_all_objects(?CONST_ETS_MALL_DISCOUNT).
%%
%% API Functions
%%
%% 限时抢购数据返回
msg_data_recv(Time,List1) ->
	misc_packet:pack(?MSG_ID_MALL_DATA_RECV, ?MSG_FORMAT_MALL_DATA_RECV, [Time,List1]).

%%
%% Local Functions
%%

