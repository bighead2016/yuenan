%%% 机器人处理
-module(robot_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").

-include("record.data.hrl").
-include("record.player.hrl").
-include("record.map.hrl").

%%
%% Exported Functions
%%
-export([doll_enter/1, go/1]).

%%
%% API Functions
%%

%% Arg = spring|practice
go(Arg) ->
    go(Arg, 10),
    doll_enter(Arg).

go(Arg, Count) when Count > 0 ->
	case misc:where_is({local, misc_app:net_name(Count)}) of
		?undefined ->
			case Arg of
				spring ->
					ets_api:insert(?CONST_ETS_SPRING_DOLL, #spring_doll{spring_ids = [], time = 0, user_id = Count});
				practice ->
					ets_api:insert(?CONST_ETS_PRACTICE_DOLL, #practice_doll{
																			user_id = Count,
																			type = ?CONST_PRACTICE_TODAY,
																			total_time = 5 * 3600,
																			set_time = misc:date_time()
																		   });
				party ->
					ets_api:insert(?CONST_ETS_PARTY_DOLL, #party_doll{
																	  user_id = Count,
																	  guild_id = Count rem 3 + 1,
																	  party_ids = []
																	  })
			end;
		_ ->
			?ignore
	end,
	go(Arg, Count-1);
go(_,_) ->
	?ok.

doll_enter(Arg) ->
	MapId =
		case Arg of
			spring ->
				?CONST_SPRING_MAP_ID;
			practice ->
				10001;
			party ->
				?CONST_GUILD_PARTY_MAP
		end,
	DollList = get_all_doll(Arg),
	doll_enter(Arg, DollList, MapId).

doll_enter(Arg, [#spring_doll{user_id = UserId}|Tail], MapId) ->
	{?ok, MapPid} = map_api:enter_map_robot(UserId, MapId, ?CONST_MAP_PTYPE_ROBOT),
	ets_api:update_element(?CONST_ETS_SPRING_DOLL, UserId, [{#spring_doll.map_pid, MapPid}]),
	ets_api:insert(?CONST_ETS_SPRING_INFO, #spring_info{user_id = UserId, state = ?CONST_PLAYER_STATE_NORMAL, auto = ?CONST_SYS_TRUE,
														enter_time = misc:seconds()}),
	schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_SPRING),		%% 资源找回
    catch yunying_activity_mod:update_shuangdan_activity_info(UserId,1001,1),         %双旦活动骊山汤替身参加检测
    player_money_api:handle_minus(UserId, ?CONST_COST_SPRING_AUTO_CASH, ?CONST_SPRING_AUTO_COST), % 开始进入时再算
	doll_enter(Arg, Tail, MapId);
doll_enter(Arg, [#practice_doll{user_id = UserId}|Tail], MapId) ->
	map_api:enter_map_robot(UserId, MapId, ?CONST_MAP_PTYPE_PRACTICE_ROBOT),
	ets_api:insert(?CONST_ETS_PRACTICE_USER, #practice_user{user_id = UserId}),
	ets_api:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_PRACTICE_ROBOT, UserId},
						   [{#map_player.user_state, ?CONST_PLAYER_STATE_NORMAL},
							{#map_player.practice_state, ?CONST_PRACTICE_SINGLE},
							{#map_player.other_user_id, 0}]),
	doll_enter(Arg, Tail, MapId);
doll_enter(Arg, [#party_doll{user_id = UserId, guild_id = GuildId, user_name = UserName}|Tail], MapId) ->
	{?ok, MapPid} = map_api:enter_map_robot(UserId, MapId, GuildId, ?CONST_MAP_PTYPE_PARTY_ROBOT),
	ets_api:update_element(?CONST_ETS_PARTY_DOLL, UserId, [{#party_doll.map_pid, MapPid}]),
	party_mod:set_doll_data(#player{user_id = UserId, guild = #guild{guild_id = GuildId}, info = #info{user_name = UserName}}),
	schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_PARTY), 		%% 资源找回
    player_money_api:handle_minus(UserId, ?CONST_COST_PARTY_AUTO, ?CONST_GUILD_PARTY_AUTO_COST), % 开始进入时再算
	doll_enter(Arg, Tail, MapId);
doll_enter(_, [], _) ->
	?ok.

get_all_doll(Arg) ->
	case Arg of
		spring -> 
			ets:tab2list(?CONST_ETS_SPRING_DOLL);
		practice ->
			ets:tab2list(?CONST_ETS_PRACTICE_DOLL);
		party ->
			party_api:get_doll_list()
	end.

%%
%% Local Functions
%%

