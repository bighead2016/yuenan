%% Author: Administrator
%% Created: 2012-8-11
%% Description: TODO: Add description to lottery_api
-module(lottery_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([initial_player_lottery/1,
		 msg_sc_lottery_info/2,
		 ctn_info/1,
		 msg_sc_draw_lottery/3,
         login_packet/2]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     初始化ets 
%% @spec     initial_ets_lottery/1
%% @param    无
%% @return   ?ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initial_player_lottery(UserId) ->
	lottery_mod:initial_player_lottery(UserId).

msg_sc_lottery_info(Status, LotteryInfo) ->
	Packet	= misc_packet:pack(?MSG_ID_LOTTERY_SCINTERFACE,
							   lottery_packet:packet_format(?MSG_ID_LOTTERY_SCINTERFACE),
							   LotteryInfo),
	misc_packet:send(Status#player.user_id, Packet).

ctn_info(Status) ->
	{?ok, BinCtnInfo, BinGoodsInfo, NewStatus} = lottery_mod:warehouse_info(Status),
	Packet	= <<BinCtnInfo/binary, BinGoodsInfo/binary>>,
	{?ok, NewStatus, Packet}.

login_packet(Player, Packet) ->
    {?ok, Player2, Packet2} = ctn_info(Player),
    {Player2, <<Packet/binary, Packet2/binary>>}.

msg_sc_draw_lottery(Status, Flag, GoodsList) ->
	?MSG_PRINT("~nCategory=~p~nGoodsList=~p~n", [Flag, GoodsList]),
	Packet	= misc_packet:pack(?MSG_ID_LOTTERY_SCDRAW,
							   lottery_packet:packet_format(?MSG_ID_LOTTERY_SCDRAW),
							   [Flag, GoodsList]),
	misc_packet:send(Status#player.user_id, Packet).
%%
%% Local Functions
%%

