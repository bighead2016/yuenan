%% Author: Administrator
%% Created: 2012-7-13
%% Description: TODO: Add description to achievement_api
-module(achievement_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([init_player_achievement/0, flush_offline/2,  current_title/1,
		 add_achievement/4, add_achievement_cb/2,
		 refresh_attr/1, delete_title/2, delete_title_cb/2,
		 refresh_title/1, login/1]).
-export([msg_sc_achievement_info/4,
		 msg_sc_get_achievement/4,
		 msg_sc_get_achievement_gift/2,
		 msg_sc_change_title/2,
		 msg_sc_title_list/2,
		 msg_sc_title_get_cancel/4]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   初始化成就系统
%% @name   init_player_achievement/0
%% @dep    
%% @return #achievement				成就记录
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_player_achievement() ->
	achievement_mod:init_player_achievement().

flush_offline(Player, Data) when is_record(Data, achievement_offline)
  andalso Data#achievement_offline.category =:= ?CONST_ACHIEVEMENT_ACHIEVEMENT	->
	Type		= Data#achievement_offline.type,
	MatchData	= Data#achievement_offline.matchdata,
	Times		= Data#achievement_offline.times,
	add_achievement(Player, Type, MatchData, Times);
flush_offline(Player, Data) when is_record(Data, achievement_offline)
  andalso Data#achievement_offline.category =:= ?CONST_ACHIEVEMENT_TITLE		->
	TitleId		= Data#achievement_offline.matchdata,
	delete_title_cb(Player, [TitleId]);
flush_offline(Player, Data) ->
	?MSG_ERROR("UserId =:~p~n, Data =:~p~n", [Player#player.user_id, Data]),
	{?ok, Player}.

login(Player) when is_record(Player, player)	->
%% 	{?ok, Player2} 	= refresh_title(Player),
	achievement_mod:login(Player).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新增成就次数
%% @name   add_achievement/4
%% @dep    
%% @parm   Player				玩家信息
%% @parm   Type					类型，在后台配置
%% @parm   MatchData			匹配的数据，后台配置
%% @parm   Times				本次调用接口时的完成次数
%% @return {?ok, NewPlayer}		NewPlayer为更新后的玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_achievement(UserId, Type, MatchData, Times) when is_integer(UserId) ->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, add_achievement_cb, [Type, MatchData, Times]);
		_	->
			AchievementOffLine	= #achievement_offline{category		= ?CONST_ACHIEVEMENT_ACHIEVEMENT,
													   type			= Type,
													   matchdata	= MatchData,
													   times		= Times},
			player_offline_api:offline(?MODULE, UserId, AchievementOffLine)
	end;
add_achievement(Player, Type, MatchData, Times) when is_record(Player, player) ->
	achievement_mod:add_achievement(Player, Type, MatchData, Times).

add_achievement_cb(Player, [Type, MatchData, Times])	->
	add_achievement(Player, Type, MatchData, Times).

current_title(Player) ->
	achievement_mod:current_title(Player).

refresh_attr(TitleId) ->
	achievement_mod:refresh_attr(TitleId).

delete_title(UserId, TitleId)	->
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, delete_title_cb, [TitleId]);
		_PlayerPid	->
			AchievementOffLine	= #achievement_offline{category		= ?CONST_ACHIEVEMENT_TITLE,
													   matchdata	= TitleId},
			player_offline_api:offline(?MODULE, UserId, AchievementOffLine)
	end.

delete_title_cb(Player, [TitleId])	->
	achievement_mod:delete_title(Player, TitleId).

refresh_title(Player) ->
	Achievement		= Player#player.achievement,
	TitleData		= Achievement#achievement.title_data,
	refresh_title(Player, TitleData).

refresh_title(Player, []) -> {?ok, Player};
refresh_title(Player, [#title_data{id = TitleId, flag = ?true, time = Time}|List]) ->
	{?ok, Player2}	 =
		case data_achievement:get_title_info(TitleId) of
			RecTitle when is_record(RecTitle, player_title) ->
				Now		 	= misc:seconds(),
				EffectTime 	= RecTitle#player_title.effect_time,
				case EffectTime > 0 andalso Now > Time + EffectTime of
					?true -> %% 过期
						achievement_mod:delete_title(Player, TitleId);
					?false ->
						{?ok ,Player}
				end;
			_ ->
				{?ok, Player}
		end,
	refresh_title(Player2, List);
refresh_title(Player, [_Title|List]) ->
	refresh_title(Player, List).

msg_sc_achievement_info(Player, Array, Gift, Titles) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SCARRIVALDATA,
							   achievement_packet:packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVALDATA),
							   [Array, Gift, Titles]),
	misc_packet:send(Player#player.net_pid, Packet).

msg_sc_get_achievement(Player, AchievementId, DoneTime, Points) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SCARRIVAL,
							   achievement_packet:packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVAL),
							   [AchievementId, DoneTime, Points]),
	misc_packet:send(Player#player.net_pid, Packet).

msg_sc_get_achievement_gift(Player, GiftId) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SCARRIVALGIFT,
							   achievement_packet:packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVALGIFT),
							   [GiftId]),
	misc_packet:send(Player#player.net_pid, Packet).

msg_sc_change_title(UserId, TitleId) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SCTITLECHANGE,
							   achievement_packet:packet_format(?MSG_ID_ACHIEVEMENT_SCTITLECHANGE),
							   [UserId, TitleId]),
	misc_packet:send(UserId, Packet).

msg_sc_title_list(UserId, TitleList) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SC_TITLE_LIST,
							   ?MSG_FORMAT_ACHIEVEMENT_SC_TITLE_LIST,
							   [TitleList]), 
	misc_packet:send(UserId, Packet).

msg_sc_title_get_cancel(UserId, TitleId, Flag, Time) ->
	Packet	= misc_packet:pack(?MSG_ID_ACHIEVEMENT_SC_TITLE_CHANGE,
							   ?MSG_FORMAT_ACHIEVEMENT_SC_TITLE_CHANGE,
							   [TitleId, Flag, Time]),
	misc_packet:send(UserId, Packet).
%% tips_
%%
%% Local Functions
%%

