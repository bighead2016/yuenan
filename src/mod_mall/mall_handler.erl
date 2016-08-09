%% Author: Administrator
%% Created: 2012-8-1
%% Description: TODO: Add description to mall_handler
-module(mall_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions 
%%
-export([handler/3]).

%%
%% API Functions 
%%

%% 商城数据请求
handler(?MSG_ID_MALL_DATA_REQUEST, Player, {}) ->
    Packet  = 
    	case mall_mod:discount_data() of
    		{?error,ErrorCode} ->
    			message_api:msg_notice(ErrorCode);
    		{?ok,Time,List2} ->
    			mall_api:msg_data_recv(Time,List2)
    	end,
	Pid		= Player#player.net_pid,
	misc_packet:send(Pid, Packet),	
	?ok;

%% 请求购买
handler(?MSG_ID_MALL_BUY, Player, {Type,GoodsId,Num, CostType}) ->
	case mall_mod:buy(Player,Type,GoodsId,Num, CostType) of
		{?error, ErrorCode} -> {?error, ErrorCode};
		{?ok, Player2}      -> {?ok, Player2}
	end;

%% 请求购买折扣物品
handler(?MSG_ID_MALL_CS_BUY_SALE, Player, {Id,GoodsId,Num, CostType}) ->
	case mall_mod:buy_sale(Player,Id,GoodsId,Num, CostType) of
		{?error, ErrorCode} -> {?error, ErrorCode};
		{?ok, Player2}      -> {?ok, Player2}
	end;

%% 请求坐骑升级
handler(?MSG_ID_MALL_CS_RIDE_UP, Player, {CtnType,Grid,Type,GoodsId}) ->
	case mall_mod:ride_up(Player,CtnType,Grid,Type,GoodsId) of
		{?error, ErrorCode} -> {?error, ErrorCode};
		{?ok, Player2}      -> {?ok, Player2}
	end;

handler(_MsgId, _Player, _Datas) -> ?undefined.


%%
%% Local Functions
%%

