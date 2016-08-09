%% Author: php
%% Created: 
%% Description: TODO: Add description to invasion_handler
-module(invasion_handler).

%%
%% Include files 
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.cost.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 守关开始
handler(?MSG_ID_INVASION_CS_START_GUARD, Player, {Copy}) ->
	invasion_mod:start(Player, Copy);

%% 退出副本
handler(?MSG_ID_INVASION_CS_END, Player, {}) ->
	invasion_mod:quit(Player);
%% 发起战斗
handler(?MSG_ID_INVASION_CS_START_BATTLE, Player, {Id})	->
    case player_state_api:is_death(Player) of
	   ?true ->
           {?error, ?TIP_COMMON_PLAYER_IS_DEATH};
        _ ->
			{?ok, Player2} = invasion_api:start_battle(Player, Id),
			schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_INVASION)
	end;

%% 清复活cd
handler(?MSG_ID_INVASION_CS_CLEAR_REBORN_CD, Player, {}) ->
	UserId = Player#player.user_id,
	case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, ?CONST_INVASION_CD_SUM, ?CONST_COST_INVASION_CLEAR_CD) of
		?ok ->
			case invasion_api:reborn(Player) of
				{?ok, NewPlayer} when is_record(NewPlayer, player)	->
					{?ok, NewPlayer};
				_Other	->	?ok
			end;
		{?error, _ErrorCode} ->
			?error
	end;

%% 复活时间到点
handler(?MSG_ID_INVASION_CS_I_WANA_REBORN, Player, {}) ->
	case invasion_api:check_reborn(Player) of
		?false	->	?ok;
		?true	->
			case invasion_api:reborn(Player) of
				{?ok, NewPlayer} when is_record(NewPlayer, player)	->
					{?ok, NewPlayer};
				_Other	->	?ok
			end
	end;

%% 大厅信息
handler(?MSG_ID_INVASION_CSHALLINFO, Player, {}) ->
	UserId 		= Player#player.user_id,
	case invasion_api:get_auto(UserId) of
		[] ->
			invasion_mod:hall_info(Player);
		_ ->
            {?error, ?TIP_INVASION_DOLL}
	end;

%% 评价
handler(?MSG_ID_INVASION_CSEVALUATION, Player, {}) ->
%% 	invasion_mod:evaluation(Player);
	?ok;
%% 翻牌
handler(?MSG_ID_INVASION_CSTURNCARD, Player, {}) ->
	UserId	= Player#player.user_id,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_INVASION_TURNCARD_SUM, ?CONST_COST_INVASION_CARD) of
		?ok -> invasion_mod:turn_card(Player);
		{?error, _ErrorCode} -> ?error
	end;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
