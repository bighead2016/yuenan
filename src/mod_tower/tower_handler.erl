%% Author: php
%% Created: 2012-09-13 16
%% Description: TODO: Add description to tower_handler
-module(tower_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.tower.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").
-include("const.tip.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 打开闯塔
handler(?MSG_ID_TOWER_SC_OPEN_TOWER, Player, {}) ->
	tower_mod:open_tower(Player),
	?ok;

%% 选择大阵
handler(?MSG_ID_TOWER_CS_SELECT_CAMP, Player, {CampId}) ->
	tower_mod:get_camp_info(Player, CampId),
	?ok;

%% 进入闯塔
handler(?MSG_ID_TOWER_CS_START_RUSH, Player, {CampId}) ->
	{?ok, NewPlayer} = tower_mod:enter_tower(Player, CampId),
	{?ok, NewPlayer};

%% 占卜
handler(?MSG_ID_TOWER_CS_DIVINE, _Player, {}) ->  %% 策划暂时要求屏蔽此功能		
	?ok;

%% 闯塔扫荡
handler(?MSG_ID_TOWER_CS_AUTO_RUSH, Player, {CampId, Type}) -> 
	{?ok, NewPlayer} = tower_mod:start_sweep(Player, CampId, Type),
	{?ok, NewPlayer};

%% 终止扫荡
handler(?MSG_ID_TOWER_CS_STOP_RUSH, Player, {}) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, NewPlayer} ->
			tower_mod:stop_sweep(NewPlayer),
			{?ok, NewPlayer};
		{?false, NewPlayer, _} ->
			{?ok, NewPlayer}
	end;

%% 重置
handler(?MSG_ID_TOWER_CS_RESET, Player, {CampId}) ->
	tower_mod:reset_sweep_times(Player, CampId),
	?ok;

%% 选择关卡
handler(?MSG_ID_TOWER_CS_CARD, Player, {PassId}) ->
	tower_mod:get_pass_first_info(Player, PassId),
	?ok;

%% 破阵奖励
handler(?MSG_ID_TOWER_CS_AWARD, Player, {CampId}) ->
	tower_mod:get_tower_reward(Player, CampId),
	?ok;

%% 发起战斗
handler(?MSG_ID_TOWER_CS_START_BATTLE, Player, {MonsterId}) ->
	{?ok, NewPlayer} = tower_mod:start_battle(Player, MonsterId),
	{?ok, NewPlayer};

%% 加速类型
handler(?MSG_ID_TOWER_CS_SPEED_TYPE, Player, {Type}) ->
	PlayerId 		= Player#player.user_id,
	Tower 			= tower_mod_create:get_tower_player(PlayerId),
	TowerSweep  	= Tower#ets_tower_player.sweep,
	SweepList		= TowerSweep#towersweep.sweep_list,
	case erlang:length(SweepList) =:= ?CONST_SYS_FALSE of
		?true  -> {?error, ?TIP_TOWER_SWEEP_OVER};
		?false ->
			NewPlayer1 		= tower_mod:speed_sweep(Player, Type),
			{?ok, NewPlayer1}
	
	end;
	

%% 确认扫荡结束
handler(?MSG_ID_TOWER_CS_RUSH_OVER, Player, {}) ->
	{_, NewPlayer} = tower_mod:check_sweep_end(Player),
	{?ok, NewPlayer};
	

%% VIP翻牌奖励
handler(?MSG_ID_TOWER_CS_VIP_AWARD, Player, {}) ->
	{?ok, NewPlayer} = tower_mod:get_vip_award(Player),
	{?ok, NewPlayer};

%% 退出闯塔
handler(?MSG_ID_TOWER_CS_QUIT_TOWER, Player, {}) ->
	{?ok, NewPlayer} = tower_mod:quit_tower(Player),
	{?ok, NewPlayer};

%% VIP购买重置次数
handler(?MSG_ID_TOWER_CS_BUY_TIMES, Player, {}) ->
	tower_mod:buy_reset_times(Player),
	?ok;

%% 请求占卜信息
handler(?MSG_ID_TOWER_CS_DIVINE_INFO, _Player, {}) ->
	?ok;

%% 请求战报列表
handler(?MSG_ID_TOWER_CS_REPORT_LIST, Player, {PassId}) ->
    UserId = Player#player.user_id,
    Packet = tower_mdo_report:list_all(PassId),
    misc_packet:send(UserId, Packet),
    ?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
