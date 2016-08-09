%% author: xjg
%% create: 2014-1-10
%% desc:   encroach_api
%%

-module(encroach_api).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 gm_set_point/2,
		 gm_rest/1,
		 battle_over/4,
		 zero_refresh/1,
		 login/1,
		 logout/1,
		 rest_encroach_rank/0,
		 save_rank_data/0,
		 init_rank_data/0,
		 
		 msg_sc_init_info/6,
		 msg_sc_move/1,
		 msg_sc_rest_point/2,
		 msg_sc_event_reward/2,
		 msg_sc_rank_info/1,
		 msg_sc_reset/1,
		 msg_sc_settlement/4,
		 msg_sc_buy_point/1,
		 msg_sc_lottery_times/1,
		 msg_sc_target/1,
		 msg_sc_reply/1,
		 msg_sc_award_goods/1,
		 msg_sc_chk_can_mov/1,
		 msg_sc_rest_times/1
		 ]).

%% gm设置移动力
gm_set_point(Player, Value) ->
	encroach_mod:gm_set_point(Player, Value).

%% gm重置
gm_rest(Player) ->
	encroach_mod:gm_rest(Player).

%% 战斗结束
battle_over(LeftId, RightId, WinSide, BattleType) ->
	encroach_mod:battle_over(LeftId, RightId, WinSide, BattleType).

%% 零点刷新
zero_refresh(Player) ->
	encroach_mod:refresh(Player).

%% 上线
login(Player) ->
	encroach_mod:login(Player).

%% 下线
logout(Player) ->
	encroach_mod:logout(Player).

%% 零点重置排行榜
rest_encroach_rank() ->
	encroach_mod:rest_rank_data().

%% 保存排行榜数据
save_rank_data() ->
	encroach_mod:save_rank_data().

%% 加载排行榜数据
init_rank_data() ->
	encroach_mod:init_rank_data().

%% 初始化信息
%%[{Pos,Event,State},RestPoint,CurPos,Exp,RestTimes,BuyPoint]
msg_sc_init_info(List1,RestPoint,CurPos,Exp,RestTimes,BuyPoint) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_INIT_INFO, ?MSG_FORMAT_ENCROACH_SC_INIT_INFO, [List1,RestPoint,CurPos,Exp,RestTimes,BuyPoint]).
%% 移动结果
%%[Event]
msg_sc_move(Event) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_MOVE, ?MSG_FORMAT_ENCROACH_SC_MOVE, [Event]).
%% 剩余行动力
%%[Point,BuyPoint]
msg_sc_rest_point(Point,BuyPoint) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_REST_POINT, ?MSG_FORMAT_ENCROACH_SC_REST_POINT, [Point,BuyPoint]).
%% 事件奖励
%%[Exp,{GoodsId,Num}]
msg_sc_event_reward(Exp,List1) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_EVENT_REWARD, ?MSG_FORMAT_ENCROACH_SC_EVENT_REWARD, [Exp,List1]).
%% 排行榜信息
%%[{UserId,Rank,UserName,Lv,Exp}]
msg_sc_rank_info(List1) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_RANK_INFO, ?MSG_FORMAT_ENCROACH_SC_RANK_INFO, [List1]).
%% 重置结果
%%[Result]
msg_sc_reset(Result) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_RESET, ?MSG_FORMAT_ENCROACH_SC_RESET, [Result]).
%% 结算
%%[{Event,Finish,All},{GoodsId,Num},Exp,IsPerfect]
msg_sc_settlement(List1,List2,Exp,IsPerfect) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_SETTLEMENT, ?MSG_FORMAT_ENCROACH_SC_SETTLEMENT, [List1,List2,Exp,IsPerfect]).
%% 购买移动力结果
%%[Result]
msg_sc_buy_point(Result) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_BUY_POINT, ?MSG_FORMAT_ENCROACH_SC_BUY_POINT, [Result]).
%% 可抽奖次数
%%[Times]
msg_sc_lottery_times(Times) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_LOTTERY_TIMES, ?MSG_FORMAT_ENCROACH_SC_LOTTERY_TIMES, [Times]).
%% 目标
%%[Idx]
msg_sc_target(Idx) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_TARGET, ?MSG_FORMAT_ENCROACH_SC_TARGET, [Idx]).
%% 到背包
%%[Idx]
msg_sc_reply(Idx) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_REPLY, ?MSG_FORMAT_ENCROACH_SC_REPLY, [Idx]).
%% 查看获得物品
%%[{GoodsId,Num,IsEquip}]
msg_sc_award_goods(List1) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_AWARD_GOODS, ?MSG_FORMAT_ENCROACH_SC_AWARD_GOODS, [List1]).
%% 检查是否可移动结果
%%[Result]
msg_sc_chk_can_mov(Result) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_CHK_CAN_MOV, ?MSG_FORMAT_ENCROACH_SC_CHK_CAN_MOV, [Result]).
%% 剩余次数
%%[RestTimes]
msg_sc_rest_times(RestTimes) ->
	misc_packet:pack(?MSG_ID_ENCROACH_SC_REST_TIMES, ?MSG_FORMAT_ENCROACH_SC_REST_TIMES, [RestTimes]).
%%
%% Local Functions
%%


