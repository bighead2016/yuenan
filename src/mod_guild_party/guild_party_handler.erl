%% Author: Administrator
%% Created: 2013-4-7
%% Description: TODO: Add description to guild_party_handler
-module(guild_party_handler).
%% 
%% %%
%% %% Include files
%% %%
%% -include("../../include/const.common.hrl").
%% -include("../../include/record.player.hrl").
%% -include("../../include/record.guild.hrl").
%% -include("../../include/record.goods.data.hrl").
%% -include("../../include/record.base.data.hrl").
%% -include("../../include/const.protocol.hrl").
%% -include("../../include/const.define.hrl").
%% -include("../../include/const.tip.hrl").
%% %%
%% %% Exported Functions
%% %%
%% -export([handler/3]). 
%% 
%% %%
%% %% API Functions
%% %%
%% 
%% %% 进入军团宴会 
%% handler(?MSG_ID_GUILD_PARTY_CS_ENTER_PARTY, Player, {}) ->
%% 	guild_party_mod:enter(Player);
%% 
%% %% 宴会倒计时到点
%% handler(?MSG_ID_GUILD_PARTY_CS_END_TIME, Player, {}) ->
%% %% 	guild_party_mod:party_time(Player),
%% 	{?ok,Player};
%% 	
%% %% 退出宴会
%% handler(?MSG_ID_GUILD_PARTY_CS_LEAVE_PARTY, Player, {}) ->
%% 	guild_party_mod:exit(Player);
%% 
%% %% 邀请玩家猜拳
%% handler(?MSG_ID_GUILD_PARTY_CS_INVITE_GUESS, Player, {InviteId}) ->
%% 	guild_party_mod:invite_guess(Player,InviteId),
%% 	{?ok, Player};
%% 
%% %% 同意或者拒绝被邀请玩家
%% handler(?MSG_ID_GUILD_PARTY_CS_AGREE_REFUSE, Player, {Type,InviteId}) ->
%% 	guild_party_mod:deal_with_invite_guess(Player,InviteId,Type),
%% 	{?ok, Player};
%% 
%% %% 玩家出猜拳
%% handler(?MSG_ID_GUILD_PARTY_CS_OUT_GUESS, Player, {Type}) ->
%% 	guild_party_mod:guess(Player,Type);
%% 
%% %% 退出猜拳
%% handler(?MSG_ID_GUILD_PARTY_CS_EXIT_GUESS, Player, {}) ->
%% 	guild_party_mod:guess_exit_request(Player),
%% 	{?ok, Player};
%% 
%% %% 邀请玩家摇色子
%% handler(?MSG_ID_GUILD_PARTY_CS_INVITE_ROCK, Player, {InviteId}) ->
%% 	guild_party_mod:invite_rock(Player,InviteId),
%% 	{?ok, Player};
%% 
%% %% 邀请摇色子处理
%% handler(?MSG_ID_GUILD_PARTY_CS_ROCK_AGREE, Player, {Type,InviteId}) ->
%% 	guild_party_mod:deal_with_invite_rock(Player,InviteId,Type),
%% 	{?ok, Player};
%% 
%% %% 玩家请求摇色子
%% handler(?MSG_ID_GUILD_PARTY_CS_ROCK, Player, {}) ->
%% 	guild_party_mod:rock(Player);
%% 
%% %% 退出摇色子
%% handler(?MSG_ID_GUILD_PARTY_CS_EXIT_ROCK, Player, {}) ->
%% 	guild_party_mod:rock_exit_request(Player),
%% 	{?ok, Player};
%% 
%% %% 请求宴会桌子次数
%% handler(?MSG_ID_GUILD_PARTY_CS_DESK_TIMES, Player, {}) ->
%% 	guild_party_mod:desk_data(Player),
%% 	{?ok, Player};
%% 
%% %% 领取宴会桌子的奖励
%% handler(?MSG_ID_GUILD_PARTY_CS_GET_DESKREWARD, Player, {}) ->
%% 	guild_party_mod:desk_reward(Player);
%% 
%% %% 重置宴会桌子次数
%% handler(?MSG_ID_GUILD_PARTY_CS_RESET_TIMES, Player, {}) ->
%% 	guild_party_mod:reset_desk_times(Player);
%% 
%% %% 宴会结束请求退出
%% handler(?MSG_ID_GUILD_PARTY_CS_PARTY_END_QUIT, Player, {}) ->
%% 	case guild_party_mod:exit(Player) of
%% 		{?ok,Player2} ->
%% 			{?ok, NewPlayer} 	= task_api:update_active(Player2, {?CONST_ACTIVE_TYPE_PARTY, 1}),
%% 			{?ok, NewPlayer};
%% 		_ ->
%% 			{?ok, Player}
%% 	end;
%% handler(MsgId,Player,Datas) ->
%% 	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
%% 	{?ok, Player}.
%% 
%% %%
%% %% Local Functions
%% %%
%% 
