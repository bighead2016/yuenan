%% Author: cobain
%% Created: 2012-7-14
%% Description: TODO: Add description to map_api
-module(map_api).
%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.guild.hrl").
-include("record.map.hrl").
%%
%% Exported Functions
%%
-export([stat_map_player/0, get_map_pid/3, is_opened/2, return_last_city/1, get_cur_map_info/1, change_star_lv/1,
         enter_null_map/1, create/4, record_map_player/1, insert_map_player/1, enter_map_robot/3,
         move_robot/5, teleport/4, enter_map_robot/4, get_user_id_list/1]).
-export([
         enter_map/2, enter_map_defualt/3, enter_map_update_player_cb/2, enter_map/3, request_for_cb/2,
         exit_map/1, exit_map/2, move/4, teleport/2, teleport/3, get_random_point/3, kick_all/1,
         broadcast/2, broadcast_range/2,
         read_map_info/1, login_init/1,change_team/3,
         get_map_player/1, get_user_id_list_lv/2,
         clean_maps_cb/1, check_goods/2, check_map/2,
         open_map/2, close_map/2, enter_map/4, get_map_pid_cross/4,
         logout/1, update_player_map_cb/2, get_boss_cross_map_pid/5,check_is_spec_map/1,
         team_exit/1, enter_map_cb/2, get_max_city_npc_id/2, faction_init_boss/2,
         clean_maps/0, mcopy_battle_over/7, monster_move/4, start_q/1, login_packet/2,
         update_task/3, do_update_task/2, open_position/1, get_cur_map_id/1,
		 start_mcopy_battle/1
        ]).
-export([
         change_level/1, change_vip/1, change_state/1, change_leader/1, 
         change_skin_fashion/1, change_skin_weapon/1, change_skin_armor/1, change_skin_ride/1,
		 change_vip_hide/1,
         change_guild/1, change_title/1, change_position/1, change_user_state/1, 
         change_double/3, change_double/5, change_guild_lv/1, change_team/1, change_name/1,
         change_follow/1,
         change_user_state/2, change_guild/2, change_guild_lv/2, change_name/2, 
         change_position/2, change_skin_armor/2, change_skin_fashion/2, 
         change_skin_ride/2, change_skin_weapon/2, change_team/2, change_title/2,
         change_vip/2, change_follow/2, change_skin_step/1, change_skin_step/2,
		 change_vip_hide/2
        ]).
-export([
		 msg_map_enter_player/2, msg_map_enter_player/4,
		 msg_map_exit_player/3,
         msg_map_player_move_notice/3,
         msg_map_sc_change_lv/2,
         msg_map_sc_change_vip/2,
         msg_star_lv_change/3,
         msg_map_sc_change_state/2,
         msg_map_sc_change_skin_fashion/2,
         msg_map_sc_change_skin_weapon/2,
         msg_map_sc_change_skin_armor/2,
         msg_map_sc_change_skin_ride/2,
         msg_sc_change_skin_step/2,
         
         msg_sc_monster_info/4,
         msg_sc_monster_move/6,
		 msg_sc_change_team/2,
         msg_map_sc_monster_remove/1,
         msg_sc_opened_map_list/1,
         msg_sc_update_map/1,
         msg_sc_change_title/2,
         msg_sc_change_position/2,
         msg_sc_change_guild/3,
         msg_cs_change_info_state/2,
         msg_sc_player_teleport/3,
         msg_sc_change_double/2,
         msg_sc_change_guild_lv/2,
         msg_sc_show_map/2,
         fly/2,
         fly/4,
         whereis1/1,
         test_fly/1,
		 msg_sc_invite_pk/2
        ]).

-export([get_user_id_list/1, invasion_close/2, invasion_robot/2, invasion_progress/1, init_map_name/0,
		 invasion_mon_battle_start/4, invasion_battle_over/9, broadcast_show/2]).
%%
%% API Functions
%%

%% @doc 瞬移

whereis1(UserId) ->
    {ok, MapData} = player_api:get_player_field(UserId, #player.maps),
    MapInfo = MapData#map_data.cur,
    {MapInfo#map_info.map_id, MapInfo#map_info.x, MapInfo#map_info.y}.

test_fly(UserId) ->
    {MapId, X0, Y0} = whereis1(UserId),
    Fun =
        fun(XX) ->
                fly(UserId, MapId, X0 + XX * 10, Y0)
        end,
    lists:foreach(Fun, lists:seq(1, 20)).

fly(Player, {MapId, X, Y}) ->
    fly(Player,MapId, X, Y).

fly(UserId, MapId, X, Y) when is_integer(UserId)->
    player_api:process_send(UserId, ?MODULE, fly, {MapId, X, Y});

fly(Player,MapId, X, Y) ->
    MapRec = Player#player.maps,
    CurMapInfo = MapRec#map_data.cur,
    NowId = CurMapInfo#map_info.map_id,
    case NowId == MapId of
        false ->
            Player2 = enter_map(Player, MapId, X, Y),
            {ok, Player2};
        _ ->
            teleport(Player, {X, Y})
    end.

create(MapIdList, MapId, X, Y) ->
    CurMapInfo = #map_info{map_id = MapId, x = X, y = Y},
    #map_data{cur = CurMapInfo, last = CurMapInfo, opened = MapIdList}.

%% 登录修改副本的地图id
%% 1.如果是在中立地图中
%%  1.1 已开启。不处理
%%  1.2 未开启。返回默认地图
%% 2.不在中立地图，或者不在地图中，则返回默认地图
login_init(Player) ->
    Info        = Player#player.info,
    Pro         = Info#info.pro,
    Sex         = Info#info.sex,
    MapData     = Player#player.maps,
    CurMapInfo  = MapData#map_data.cur,
    DefaultMapInfo = player_default_api:get_default_map_info(Pro, Sex),
    
    try
        case CurMapInfo of
            #map_info{map_id = CurMapId} ->
                GuildPvpMap = guild_pvp_api:get_guild_pvp_map_id(),
                case read_map_info(CurMapId) of
                    #rec_map{map_id = GuildPvpMap} ->
                        case guild_pvp_mod:check_open() of
                            true ->
                                update_cur_map_info(Player, DefaultMapInfo#map_info.map_id);
                            false ->
                                Player
                        end;
                    #rec_map{type = ?CONST_MAP_TYPE_CITY} -> % 中立地图
                        case is_opened(CurMapInfo#map_info.map_id, Player) of
                            ?true ->
                                Player;
                            ?false ->
                                update_cur_map_info(Player, DefaultMapInfo#map_info.map_id)
                        end;
                    _ ->
                         update_cur_map_info(Player, DefaultMapInfo#map_info.map_id)
                end;
            _ ->
                update_cur_map_info(Player, DefaultMapInfo#map_info.map_id)
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            update_cur_map_info(Player, DefaultMapInfo#map_info.map_id)
    end.

%% 登录
login_packet(Player, Packet) ->
    MapData = Player#player.maps,
    Packet2 = map_api:msg_sc_update_map(MapData#map_data.opened),
    {Player, <<Packet/binary, Packet2/binary>>}.

enter_map(Player, MapId, X, Y) ->
    MapData = data_map:get_map(MapId),
    MapType = MapData#rec_map.type,
    Param2  = #map_param{ad1=MapId},
    enter_map(Player, MapId, MapType, Param2, X, Y, ?true).

%% 机器人进入地图
enter_map_robot(Player, MapId, MType) when is_record(Player, player) ->
	enter_map_robot(Player, MapId, 0, MType);
enter_map_robot(UserId, MapId, MType) ->
    enter_map_robot(UserId, MapId, 0, MType).

enter_map_robot(Player, MapId, GuildId, MType) when is_record(Player, player)->
	UserId	= Player#player.user_id,
	MapData = data_map:get_map(MapId),
    MapType = MapData#rec_map.type,  
	Lv			= (Player#player.info)#info.lv,
    case get_random_point(MapType) of
        {X, Y} ->
            case robot_api:record_map_player(UserId, MapId, X, Y, MType) of
                #map_player{} = MapPlayer ->
					{MasterNode, _Room, _Lv} = cross_api:get_boss_master(UserId, Lv, ?true),
					case node() of
						MasterNode ->  insert_map_player(MapPlayer);
						_ -> rpc:cast(MasterNode, ?MODULE, insert_map_player, [MapPlayer])
					end,
					{_, MapPid} = case MType == ?CONST_MAP_PTYPE_BOSS_ROBOT of
									  ?true -> 
										  MapParam = #map_param{ad1 = MapId, ad5 = ?true},
										  case get_cross_map_pid(Player, MapType, MapId, MapParam) of
											  {?ok, MapPid1} ->
												  {?ok, MapPid1};
											  {?ok, MapPid1, _Nx, _Ny} ->
												  {?ok, MapPid1}
										  end;
									  ?false ->
										  get_map_pid(MapType, MapId, #map_param{ad1=MapId, ad2 = GuildId})
								  end,
					?MSG_DEBUG("44444444444444444444444", []),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, X, Y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end;
        ?null ->
            case robot_api:record_map_player(UserId, MapId, MapData#rec_map.x, MapData#rec_map.y, MType) of
                #map_player{} = MapPlayer ->
                    {MasterNode, _Room, _Lv} = cross_api:get_boss_master(UserId, Lv, ?true),
					case node() of
						MasterNode ->  
							?MSG_DEBUG("44444444444444444444444", []),
							insert_map_player(MapPlayer);
						_ -> 
							?MSG_DEBUG("44444444444444444444444~p", [{MasterNode, MapPlayer}]),
							rpc:cast(MasterNode, ?MODULE, insert_map_player, [MapPlayer])
					end,
                    {_, MapPid} = case MType == ?CONST_MAP_PTYPE_BOSS_ROBOT of
									  ?true -> 
										  MapParam = #map_param{ad1 = MapId, ad5 = ?true},
										  case get_cross_map_pid(Player, MapType, MapId, MapParam) of
											  {?ok, MapPid1} ->
												  {?ok, MapPid1};
											  {?ok, MapPid1, _Nx, _Ny} ->
												  {?ok, MapPid1}
										  end;
									  ?false ->
										  get_map_pid(MapType, MapId, #map_param{ad1=MapId, ad2 = GuildId})
								  end,
					?MSG_DEBUG("44444444444444444444444", []),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, MapData#rec_map.x, MapData#rec_map.y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end
    end;
enter_map_robot(UserId, MapId, GuildId, MType) ->
    MapData = data_map:get_map(MapId),
    MapType = MapData#rec_map.type,  
    case get_random_point(MapType) of
        {X, Y} ->
            case robot_api:record_map_player(UserId, MapId, X, Y, MType) of
                #map_player{} = MapPlayer ->
                    insert_map_player(MapPlayer),
					{_, MapPid} = get_map_pid(MapType, MapId, #map_param{ad1=MapId, ad2 = GuildId}),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, X, Y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end;
        ?null ->
            case robot_api:record_map_player(UserId, MapId, MapData#rec_map.x, MapData#rec_map.y, MType) of
                #map_player{} = MapPlayer ->
                    insert_map_player(MapPlayer),
                    {_, MapPid} = get_map_pid(MapType, MapId, #map_param{ad1=MapId, ad2=GuildId}),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, MapData#rec_map.x, MapData#rec_map.y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end
    end.

enter_map_robot_update(UserId, MapPid, MapId, MType) ->
    MapData = data_map:get_map(MapId),
    MapType = MapData#rec_map.type,  
    case get_random_point(MapType) of
        {X, Y} ->
            case robot_api:record_map_player(UserId, MapId, X, Y, MType) of
                #map_player{} = MapPlayer ->
                    insert_map_player(MapPlayer),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, X, Y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end;
        ?null ->
            case robot_api:record_map_player(UserId, MapId, MapData#rec_map.x, MapData#rec_map.y, MType) of
                #map_player{} = MapPlayer ->
                    insert_map_player(MapPlayer),
                    map_serv:enter_map_cast(MapPid, [{MType, UserId}], MapId, MapData#rec_map.x, MapData#rec_map.y),
                    {?ok, MapPid};
                _ ->
                    ?ok
            end
    end.

%% 角色进入地图
enter_map(Player, 0) ->
    MapData     = Player#player.maps,
    CurMapInfo  = MapData#map_data.cur,
    {NewX, NewY} = get_point(CurMapInfo#map_info.map_id, ?CONST_MAP_TYPE_CITY, CurMapInfo#map_info.x, CurMapInfo#map_info.y),
    TargetMapInfo = 
        case read_map_info(CurMapInfo#map_info.map_id) of
            #rec_map{type = ?CONST_MAP_TYPE_CITY} ->
                CurMapInfo#map_info{x = NewX, y = NewY};
            _ ->
                get_last_city_map_info(Player)
        end,
    #map_info{map_id = MapId, x = X, y = Y} = TargetMapInfo,
    Param   = #map_param{ad1 = MapId, ad2 = 1},
    enter_map(Player, MapId, ?CONST_MAP_TYPE_CITY, Param, X, Y, ?false);

enter_map(Player, MapId) ->
    UserId = Player#player.user_id,
    MapData = Player#player.maps,
    CurMapInfo = MapData#map_data.cur,
    if
        MapId =:= CurMapInfo#map_info.map_id ->
            Player;
        ?true ->
            RecMap = read_map_info(MapId),
            case is_record(RecMap,rec_map) of
                false ->
                    ?MSG_ERROR("MapId = ~w,RecMap = ~p",[MapId,RecMap]);
                true ->
                    void
            end,
            MapType  = RecMap#rec_map.type,
            X        = RecMap#rec_map.x,
            Y        = RecMap#rec_map.y,
            {NewX, NewY} = get_point(MapId, MapType, X, Y),
            case RecMap#rec_map.type of
                ?CONST_MAP_TYPE_COPY ->
                    Player;
                ?CONST_MAP_TYPE_GUILD ->
                    Guild    = Player#player.guild,
                    GuildId  = Guild#guild.guild_id,
                    MapParam = #map_param{ad1 = MapId, ad2 = GuildId},
                    enter_map(Player, MapId, MapType, MapParam, NewX, NewY, ?true); 
                ?CONST_MAP_TYPE_CAMP_PVP ->
                    case camp_pvp_mod:check_camp_start() of
                        false ->
                            Camp_data   = ets_api:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data),
                            TimeLeft    = misc:max(1, Camp_data#camp_pvp_data.start_time - misc:seconds()),
                            PacketTips  = message_api:msg_notice(?TIP_CAMP_PVP_START_LEFT,
                             [{?TIP_SYS_COMM, misc:to_list(TimeLeft)}]),
                            misc_packet:send(Player#player.user_id, PacketTips),
                            Player;
                        true->
                            {NewX2, NewY2} = 
                                case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
                                    [#camp_pvp_player{camp_id = CampId}] ->
                                        camp_pvp_api:get_camp_born_point(CampId);
                                    _ ->
                                        {NewX, NewY}
                                end,
                            MapType = RecMap#rec_map.type,
                            Param2  = #map_param{ad1=MapId, ad2 = UserId},
                            enter_map(Player, MapId, MapType, Param2, NewX2, NewY2, ?true)
                    end;
                ?CONST_MAP_GUILD_PVP_BATTLE ->
                    case guild_pvp_mod:check_start() of
                        false ->
                            misc_packet:send_tips(Player#player.user_id, ?TIP_GUILD_PVP_NOT_START_CAN_NOT_ENTER),
                            Player;
                        true->
                            {NewX2, NewY2} = 
                                case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                                    [#guild_pvp_player{camp_id = CampId}] ->
                                        guild_pvp_api:get_camp_born_point(CampId);
                                    _ ->
                                        {NewX, NewY}
                                end,
                            MapType = RecMap#rec_map.type,
                            Param2  = #map_param{ad1=MapId},
                            enter_map(Player, MapId, MapType, Param2, NewX2, NewY2, ?true)
                    end;
                ?CONST_MAP_TYPE_WORLD -> 
                    Guild    = Player#player.guild,
                    GuildId  = Guild#guild.guild_id,
                    MapParam = #map_param{ad1 = MapId, ad2 = GuildId},
                    enter_map(Player, MapId, MapType, MapParam, NewX, NewY, ?true); 
                ?CONST_MAP_TYPE_MCOPY -> % 多人副本
                    case mcopy_api:get_current_mcopy_ser(Player) of
                        {?ok, MCopySer} ->
                            TimesInfo= mcopy_api:get_enter_times(Player, MapId),
                            MapParam = #map_param{ad1 = MapId, ad2 = MCopySer, ad4 = TimesInfo}, % ad1为副本id, ad2保存副本信息，没有的话为null
                            enter_map(Player, MapId, MapType, MapParam, NewX, NewY, ?true);
                        _ ->
                            Player
                    end;
                ?CONST_MAP_TYPE_CITY -> 
                    MapParam = #map_param{ad1 = MapId},
                    enter_map(Player, MapId, MapType, MapParam, NewX, NewY, ?true);
                _ ->
                    Param2  = #map_param{ad1=MapId, ad2 = UserId, ad5 = ?false},
                    enter_map(Player, MapId, MapType, Param2, NewX, NewY, ?true)
            end
    end.


%% 进入默认的地图 MaxCount 地图最大的同屏人数
enter_map_defualt(Player, MapId, MaxCount) ->
    RecMap  = read_map_info(MapId),
    Param   = #map_param{ad1 = MapId},
    MapType = RecMap#rec_map.type,
    X       = RecMap#rec_map.x,
    Y       = RecMap#rec_map.y,
    enter_map(Player, MapId, MapType, Param, X, Y, ?true, MaxCount).

%% 军团攻城地图
enter_map(Player, MapId, GuildId) ->
    RecMap 	= read_map_info(MapId),
    Param	= #map_param{ad1 = MapId, ad2 = GuildId},
    MapType = RecMap#rec_map.type,
    X 		= RecMap#rec_map.x,
    Y 		= RecMap#rec_map.y,
    enter_map(Player, MapId, MapType, Param, X, Y, ?true).

%% 角色进入地图
enter_map(Player, MapId, MapType, Param, X, Y, FlagExit, MaxCount) ->
    UserId      = Player#player.user_id,
    IsRaiding   = player_state_api:is_raiding(UserId),
    practice_api:cancel(Player),
    if
        ?true =:= IsRaiding -> % 扫荡中不能切换
            UserId = Player#player.user_id,
            PacketErr = message_api:msg_notice(?TIP_COMMON_NOT_4_RAIDING),
            misc_packet:send(UserId, PacketErr),
            Player;
        true ->
            {?ok, MapPid}   = get_map_pid(MapType, MapId, Param, MaxCount),
            UserId          = Player#player.user_id,
            Result          =
                case team_api:check_enter_map(Player) of
                    ?null -> {?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 未组队
                    {?ok, ?CONST_TEAM_OPERATE_MODE_LEADER, [UserTuple|UserIdListTemp]} ->
                        {?ok, [UserTuple|UserIdListTemp], ?false};% 组队,队伍是队长操作模式,并且是队长
                    {?ok, ?CONST_TEAM_OPERATE_MODE_MEMBER, _UserIdListTemp} ->
                        {?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 组队,队伍是成员操作模式,并且是队伍成员
                    Error ->
                        ?MSG_DEBUG("Error:~p", [Error]),
                        {?error, ?TIP_COMMON_BAD_ARG}% 组队,队伍是队长操作模式,但非队长
                end,
            case Result of
                {?ok, UserIdList, FlagRandom} ->
                    Player2 = enter_map_update_players(UserIdList, Player, MapPid, MapId, X, Y, FlagExit, FlagRandom),
                    map_serv:enter_map_cast(MapPid, UserIdList, MapId, X, Y),
                    Player2;
                {?error, _ErrorCode} ->
                    Player
            end
    end.

%% 角色进入地图
enter_map(Player, MapId, MapType, Param, X, Y, FlagExit) ->
    UserId 		= Player#player.user_id,
    IsRaiding 	= player_state_api:is_raiding(UserId),
	practice_api:cancel(Player),
    case MapType of
        ?CONST_MAP_TYPE_CITY ->
            case is_opened(MapId, Player) of
                ?true ->
                    {?ok, MapPid}   = get_map_pid(MapType, MapId, Param),
                    Result          =
                        case team_api:check_enter_map(Player) of
							?null -> {?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 未组队
							{?ok, ?CONST_TEAM_OPERATE_MODE_LEADER, [UserTuple|UserIdListTemp]} ->
								{?ok, [UserTuple|UserIdListTemp], ?false};% 组队,队伍是队长操作模式,并且是队长
                            {?ok, ?CONST_TEAM_OPERATE_MODE_MEMBER, _UserIdListTemp} ->
								{?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 组队,队伍是成员操作模式,并且是队伍成员
							Error ->
								?MSG_DEBUG("Error:~p", [Error]),
								{?error, ?TIP_COMMON_BAD_ARG}% 组队,队伍是队长操作模式,但非队长
                        end,
                    case Result of
                        {?ok, UserIdList, FlagRandom} ->
                            Player2 = enter_map_update_players(UserIdList, Player, MapPid, MapId, X, Y, FlagExit, FlagRandom),
                            map_serv:enter_map_cast(MapPid, UserIdList, MapId, X, Y),
                            Player2;
                        {?error, _ErrorCode} ->
                            Player
                    end;
                ?false ->
                    UserId = Player#player.user_id,
                    PacketErr = message_api:msg_notice(?TIP_MAP_NOT_OPENED),
                    misc_packet:send(UserId, PacketErr),
                    Player
            end;
        _ when ?true =:= IsRaiding -> % 扫荡中不能切换
            UserId = Player#player.user_id,
            PacketErr = message_api:msg_notice(?TIP_COMMON_NOT_4_RAIDING),
            misc_packet:send(UserId, PacketErr),
            Player;
        _ ->
            {MapPid, X1, Y1}   = 
                case get_cross_map_pid(Player, MapType, MapId, Param) of
                    {?ok, MapPid1} ->
                        {MapPid1, X, Y};
                    {?ok, MapPid1, Nx, Ny} ->
                        {MapPid1, Nx, Ny}
                end,
            UserId          = Player#player.user_id,
			Result          =
				case team_api:check_enter_map(Player) of
					?null -> 
                        {?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 未组队
					{?ok, ?CONST_TEAM_OPERATE_MODE_LEADER, [UserTuple|UserIdListTemp]} ->
						{?ok, [UserTuple|UserIdListTemp], ?false};% 组队,队伍是队长操作模式,并且是队长
					{?ok, ?CONST_TEAM_OPERATE_MODE_MEMBER, _UserIdListTemp} ->
						{?ok, [{?CONST_MAP_PTYPE_HUMAN, UserId}], ?true};% 组队,队伍是成员操作模式,并且是队伍成员
					Error ->
						?MSG_DEBUG("Error:~p", [Error]),
						{?error, ?TIP_COMMON_BAD_ARG}% 组队,队伍是队长操作模式,但非队长
				end,
			?MSG_DEBUG("3333333333333333333333333=~p", [{MapPid}]),
            case Result of
                {?ok, UserIdList, FlagRandom} ->
                    Player2 = enter_map_update_players(UserIdList, Player, MapPid, MapId, X1, Y1,  FlagExit, FlagRandom),
                    map_serv:enter_map_cast(MapPid, UserIdList, MapId, X1, Y1),
                    Player2;
                {?error, _ErrorCode} ->
                    Player
            end
    end.

%% 跨服获取pid
get_cross_map_pid(Player, ?CONST_MAP_TYPE_BOSS, MapId, Param) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	IsRobot			= Param#map_param.ad5,
	{MasterNode, Room, _Lv}    = cross_api:get_boss_master(UserId, Lv, IsRobot),
%% 	MasterNode		= cross_api:get_master_node(),	
	?MSG_DEBUG("~n 111111111111111=~p", [{MapId, node(), MasterNode}]),
	case rpc:call(MasterNode, ?MODULE, get_boss_cross_map_pid, [?CONST_MAP_TYPE_BOSS, UserId, MapId, Room, Param]) of
		{?ok, Pid} when is_pid(Pid)->
			{?ok, {Pid, MasterNode}};
		{?ok, {Pid, X, Y}} ->
			{?ok, {Pid, MasterNode}, X, Y}
	end;
get_cross_map_pid(Player, MapType, MapId , Param) ->
    case MapType == ?CONST_MAP_TYPE_FACTION orelse MapType == ?CONST_MAP_TYPE_CAMP_PVP of
        false ->
            case Player#player.team_id of
                {_TeamId, ServId} ->
                    Node = cross_api:get_node(ServId),
                    {ok, Pid} = rpc:call(Node, ?MODULE, get_map_pid, [MapType, MapId, Param]),
                    {ok, {Pid, Node}};
                _ ->
                    get_map_pid(MapType, MapId, Param)
            end;
        _ ->
            Id = Player#player.user_id,
            Info = Player#player.info,
            Lv = Info#info.lv,
            {MasterNode, _Room} = cross_api:get_camp_master(Id, Lv),
            case rpc:call(MasterNode, ?MODULE, get_map_pid_cross, [MapType, Param#map_param.ad2,  MapId, Param]) of
                {ok, Pid} when is_pid(Pid)->
                    {ok, {Pid, MasterNode}};
                {ok, {Pid, X, Y}} ->
                    {ok, {Pid, MasterNode}, X, Y}
            end
    end.
        
enter_map_update_players([{_MType, UserId}|UserIdList], Player, MapPid, MapId, X, Y, FlagExit, FlagRandom)
  when UserId =:= Player#player.user_id ->
	?MSG_DEBUG("3333333333333333333333333=~p", [{MapPid}]),
    Player2     = enter_map_update_player(Player, MapPid, MapId, X, Y, FlagExit, FlagRandom),
    enter_map_update_players(UserIdList, Player2, MapPid, MapId, X, Y, FlagExit, FlagRandom);
enter_map_update_players([{?CONST_MAP_PTYPE_HUMAN, UserId}|UserIdList], Player, MapPid, MapId, X, Y, FlagExit, FlagRandom) when is_integer(Player#player.team_id)->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
			?MSG_DEBUG("3333333333333333333333333=~p", [{MapPid}]),
            player_api:process_send(UserId, ?MODULE, enter_map_update_player_cb, {MapPid, MapId, X, Y, FlagExit, FlagRandom});
        [#cross_in{node = Node}] ->
			?MSG_DEBUG("3333333333333333333333333=~p", [{MapPid}]),
            rpc:call(Node, player_api, process_call, [UserId, ?MODULE, enter_map_update_player_cb, {{MapPid, node()}, MapId, X, Y, FlagExit, FlagRandom}])
    end,
    enter_map_update_players(UserIdList, Player, MapPid, MapId, X, Y, FlagExit, FlagRandom);
enter_map_update_players([{?CONST_MAP_PTYPE_HUMAN, UserId}|UserIdList], Player, MapPid, MapId, X, Y, FlagExit, FlagRandom)->
    {_TeamId, ServId} = Player#player.team_id,
    Node1 = cross_api:get_node(ServId),
    case rpc:call(Node1, ets, lookup, [?CONST_ETS_CROSS_IN, UserId]) of
        [] ->
            player_api:process_send(UserId, ?MODULE, enter_map_update_player_cb, {MapPid, MapId, X, Y, FlagExit, FlagRandom});
        [#cross_in{node = Node}] ->
            rpc:call(Node, player_api, process_call, [UserId, ?MODULE, enter_map_update_player_cb, {MapPid, MapId, X, Y, FlagExit, FlagRandom}])
    end,
    enter_map_update_players(UserIdList, Player, MapPid, MapId, X, Y, FlagExit, FlagRandom);
enter_map_update_players([{MType, UserId}|UserIdList], Player, MapPid, MapId, X, Y, FlagExit, FlagRandom) ->
    enter_map_update_player_robot(UserId, MapPid, MapId, X, Y, FlagExit, FlagRandom, MType),
    enter_map_update_players(UserIdList, Player, MapPid, MapId, X, Y, FlagExit, FlagRandom);
enter_map_update_players([], Player, _MapPid, _MapId, _X, _Y, _FlagExit, _FlagRandom) -> Player.

enter_map_update_player_robot(UserId, MapPid, MapId, X, Y, _FlagExit, _FlagRandom, MType) ->
%%     case FlagExit of ?true -> exit_map(Player); ?false -> ?ok end,
    
    MapPlayer   = robot_api:record_map_player(UserId, 0, X, Y, MType),
    case MapPid of
        {_, Node} ->
            rpc:call(Node, ets_api, insert, [?CONST_ETS_MAP_PLAYER, MapPlayer]);
        _ ->
            ets_api:insert(?CONST_ETS_MAP_PLAYER, MapPlayer)
    end.
enter_map_update_player(Player, MapPid, MapId, X, Y, FlagExit, _FlagRandom) ->
    % 退出前一张地图
    case FlagExit of 
        ?true -> 
            exit_map(Player); 
        ?false -> 
            ?ok 
    end,
    MapData = Player#player.maps,
    LastMapInfo = MapData#map_data.last,
    MapIdLast   = LastMapInfo#map_info.map_id,
    CurMapInfo  = MapData#map_data.cur,
    NewMapInfo  = #map_info{map_id = MapId, x = X, y = Y}, 
    MapData2    = 
        case check_is_spec_map(CurMapInfo#map_info.map_id) of
            false ->
                MapData#map_data{cur = NewMapInfo, last = CurMapInfo};
            _ ->
                MapData#map_data{cur = NewMapInfo, last = LastMapInfo}
        end,
    Player2     = Player#player{map_pid = MapPid, maps = MapData2},
    MapPlayer   = map_mod:record_map_player(Player2, X, Y),
    ?MSG_DEBUG("user_id=~p~nmap_id_last=~p~nmap_id=~p~nx2=~p~nmap_x=~p~n", 
               [Player#player.user_id, MapIdLast, MapId, {X, Y}, {MapPlayer#map_player.x, MapPlayer#map_player.y}]),
    case MapPid of
        {_, Node} ->
            rpc:call(Node, ets_api, insert, [?CONST_ETS_MAP_PLAYER, MapPlayer]);
        _ ->
            ets_api:insert(?CONST_ETS_MAP_PLAYER, MapPlayer)
    end,
    case player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_NORMAL) of
        {?true, Player3} ->
            Player3;
        {?false, _Player} ->
            Player2
    end.
enter_map_update_player_cb(Player, {MapPid, MapId, X, Y, FlagExit, FlagRandom}) ->
    Player2 = enter_map_update_player(Player, MapPid, MapId, X, Y, FlagExit, FlagRandom),
    {?ok, Player2}.

%% 强制玩家进入之前的中立地图
enter_map_cb(Player, _) ->
    NewPlayer = return_last_city(Player),
    {?ok, NewPlayer}.

%% 进入空地图
enter_null_map(Player) ->
    map_api:exit_map(Player),
    MapData       = Player#player.maps,
    CurMapInfo    = MapData#map_data.cur,
    NewCurMapInfo = #map_info{map_id = 0, x = 0, y = 0},
    NewMapData    = 
        if
            0 =/= CurMapInfo#map_info.map_id ->
                MapData#map_data{last = CurMapInfo, cur = NewCurMapInfo};
            ?true ->
                MapData
        end,
    Player#player{map_pid = 0, maps = NewMapData}.

%% 更新活动任务
update_task(MapPid, Type, Id) ->
    map_serv:update_task(MapPid, Type, Id).

do_update_task(Type, Id) ->
    UserIdList = get_local_user_list(),
    [player_api:process_send(UserId, task_api, update_active, {Type, Id})||UserId <- UserIdList].

%% 读取本地图的玩家id列表
get_local_user_list() ->
    case get(user_id_list) of
        ?undefined ->
            [];
        List ->
            List
    end.

get_point(MapId, Type, X, Y) ->
    case guild_pvp_api:get_guild_pvp_map_id() of
        MapId ->
            {600, 630};
        _ ->
            get_point(Type, X, Y)
    end.
        

%% 读取x,y
get_point(?CONST_MAP_TYPE_CITY, _X, _Y) ->
    get_random_point(?CONST_MAP_TYPE_CITY);
get_point(?CONST_MAP_TYPE_SPRING, _X, _Y) ->
    get_random_point(?CONST_MAP_TYPE_SPRING);
get_point(_, X, Y) ->
    {X, Y}.

%% 读取随机点
get_random_point(X, Y, MapLast) ->
    RoundX = MapLast#rec_map.r_x,
    RoundY = MapLast#rec_map.r_y,
    RX = misc_random:random(-RoundX, RoundX),
    RY = misc_random:random(-RoundY, RoundY),
    X2 = X + RX,
    Y2 = Y + RY,
    {X2, Y2}.

%% 1.（600，630）2.（1100,630）3.（1530，630）4.（2220,600）z
get_random_point(?CONST_MAP_TYPE_CITY) ->
    PointList = [{600,630}, {1100,630}, {1530,630}, {2220, 600}],
    R = misc_random:random(1,4),
    {X2, Y2} = lists:nth(R, PointList),
    {X2, Y2};
%% 1.（610,490）2.（1245,520）3.（1875,585）5.（2355,610）6.（2800,430）7.（3310,340）8.（3760,525）9.（4030,280）
get_random_point(?CONST_MAP_TYPE_SPRING) ->
    PointList = [{610,490}, {1245,520}, {1875,585}, {2355, 610}, {2800,430}, {3310,340}, {3760,525}, {4030,280}],
    R = misc_random:random(1,8),
    {X2, Y2} = lists:nth(R, PointList),
    {X2, Y2};
get_random_point(_) ->
    ?null.


%% CONST_MAP_TYPE_FACTION      39      地图类型--阵营战
get_map_pid_cross(MapType, UserId,  MapId, Param) ->
    MapPid = camp_pvp_api:get_room_pid(UserId, MapType, MapId, Param),
    {ok, MapPid}.

%% 获取跨服boss地图pid
get_boss_cross_map_pid(?CONST_MAP_TYPE_BOSS, UserId, MapId, Room, Param) ->
	?MSG_DEBUG("~n 111111111111111=~p", [{MapId}]),
	MapPid			= boss_api:get_room_pid(UserId, MapId, Room, Param),
	{?ok, MapPid}.

get_map_pid(Type, MapId, Param, MaxAmount) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'<','$3',MaxAmount}}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, Type, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            {?ok, MapPid}
    end.

%% CONST_MAP_TYPE_TOWER        32      地图类型--闯塔
%% CONST_MAP_TYPE_MCOPY        40      地图类型--多人副本
%% 原先的每200人建一张图
%% CONST_MAP_TYPE_CITY         1       地图类型--城市
get_map_pid(?CONST_MAP_TYPE_CITY, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> 
            case erlang:is_process_alive(MapPid) of
                ?true ->    
                    {?ok, MapPid};
                ?false ->
                    case ets_api:lookup(?CONST_ETS_MAP, MapPid) of
                        {_, _, CountXXXX} when CountXXXX =< 0 ->
                            ets:delete(?CONST_ETS_MAP, MapPid);
                        _ ->
                            ?ok
                    end,
                    {?ok, MapPid2} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_CITY, Param),
                    ets_api:insert(?CONST_ETS_MAP, {MapPid2, MapId, 0}),
                    map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_CITY, MapPid2, Param),
                    {?ok, MapPid2}
            end;
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_CITY, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_CITY, MapPid, Param),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_GATHER       34      地图类型--采集
get_map_pid(?CONST_MAP_TYPE_GATHER, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}],
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GATHER, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_GATHER, MapPid, Param),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_SPRING       31      地图类型--温泉
get_map_pid(?CONST_MAP_TYPE_SPRING, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}],
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_SPRING, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_SPRING, MapPid, Param),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_GUILD        35      地图类型--军团宴会
get_map_pid(?CONST_MAP_TYPE_GUILD, MapId, Param) -> % 每个军团有一张地图
    GuildId = Param#map_param.ad2,
    case ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId) of 
        Guild when is_record(Guild, guild_data) -> % 军团地图已有
            GuildMapPid = Guild#guild_data.map_pid,
            case ets_api:lookup(?CONST_ETS_MAP, GuildMapPid) of
                ?null -> % 但是这地图已经销毁，另建一张
                    {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GUILD, Param),
                    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
                    ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId, [{#guild_data.map_pid, MapPid}]),
                    {?ok, MapPid};
                _ -> % 还在，就继续用
                    {?ok, GuildMapPid}
            end;
        ?null -> % 没有地图，那就新建一张
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GUILD, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
			ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId, [{#guild_data.map_pid, MapPid}]),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_COLLECT      36      地图类型--采集玩法
get_map_pid(?CONST_MAP_TYPE_COLLECT, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'=<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}],
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_COLLECT, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_BOSS         33      地图类型--世界BOSS
get_map_pid(?CONST_MAP_TYPE_BOSS, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'=<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}],
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_BOSS, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_BOSS, MapPid, Param),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_GUARD        37      地图类型--守关
get_map_pid(?CONST_MAP_TYPE_GUARD, MapId, Param) ->
    {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GUARD, Param),
    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
    map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_GUARD, MapPid, Param),
    {?ok, MapPid};
%% CONST_MAP_TYPE_WORLD        38      地图类型--乱天下 
get_map_pid(?CONST_MAP_TYPE_WORLD, MapId, Param) ->
    GuildId = Param#map_param.ad2,
    case world_api:get_world_map_pid(GuildId) of 
        GuildMapPid when is_pid(GuildMapPid) -> % 军团地图已有
            case ets_api:lookup(?CONST_ETS_MAP, GuildMapPid) of
                ?null -> % 但是这地图已经销毁，另建一张
                    {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GUILD, Param),
                    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
                    world_api:set_world_map_pid(GuildId, MapPid),
                    map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_GUILD, MapPid, Param),
                    {?ok, MapPid};
                _ -> 
                    {?ok, GuildMapPid}% 还在，就继续用
            end;
        _ -> % 没有地图，那就新建一张
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_GUILD, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
			world_api:set_world_map_pid(GuildId, MapPid),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_GUILD, MapPid, Param),
            {?ok, MapPid}
    end;
%% CONST_MAP_TYPE_FACTION      39      地图类型--阵营战
get_map_pid(?CONST_MAP_TYPE_FACTION, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'=:=','$2',MapId}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_FACTION, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_FACTION, MapPid, Param),
            {?ok, MapPid}
    end;

%% CONST_MAP_TYPE_FACTION      41      地图类型--阵营战交战区
get_map_pid(?CONST_MAP_TYPE_CAMP_PVP, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'=:=','$2',MapId}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_CAMP_PVP, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_CAMP_PVP, MapPid, Param),
            {?ok, MapPid}
    end;

%% CONST_MAP_TYPE_FACTION      42      地图类型--阵营战交战区
get_map_pid(?CONST_MAP_GUILD_PVP_HOME, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'=:=','$2',MapId}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_GUILD_PVP_HOME, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_GUILD_PVP_HOME, MapPid, Param),
            {?ok, MapPid}
    end;

%% CONST_MAP_TYPE_FACTION      43      地图类型--军团战交战区
get_map_pid(?CONST_MAP_GUILD_PVP_BATTLE, MapId, Param) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'=:=','$2',MapId}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_GUILD_PVP_BATTLE, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_GUILD_PVP_BATTLE, MapPid, Param),
            {?ok, MapPid}
    end;

%% CONST_MAP_TYPE_MCOPY      40      地图类型--多人副本
get_map_pid(?CONST_MAP_TYPE_MCOPY, MapId, Param) ->
    {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_MCOPY, Param),
    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
    map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_MCOPY, MapPid, Param),
    {?ok, MapPid};
%% CONST_MAP_TYPE_COPY         2       地图类型--副本
get_map_pid(?CONST_MAP_TYPE_COPY, MapId, Param) ->
    map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_COPY, Param);
get_map_pid(_, MapId, _Param) ->
    ?MSG_ERROR("can not find map ~w's defualt max enter amouont, please call enter_map_defualt/3 !!!!!", [MapId]),
	PlayerInit  = data_player:get_player_init({?CONST_SYS_PRO_XZ, ?CONST_SYS_SEX_MALE}),
    MapId		= PlayerInit#rec_player_init.map,
	Param		= #map_param{ad1 = MapId},
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId},{'=<','$3',?CONST_MAP_MAX_MEMBER}}], ['$1']}], 
    case ets_api:select(?CONST_ETS_MAP, MatchSpec) of
        [MapPid|_] -> {?ok, MapPid};
        [] ->
            {?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_CITY, Param),
            ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
            map_name_api:regist_map_name(MapId, ?CONST_MAP_TYPE_CITY, MapPid, Param),
            {?ok, MapPid}
    end.
%% 角色离开地图
exit_map(#player{map_pid = 0}) -> ?ok;
exit_map(Player) -> exit_map(Player, ?CONST_MAP_PTYPE_HUMAN).
exit_map(#player{user_id = UserId, map_pid = MapPid}, MType) ->
    map_serv:exit_map_cast(MapPid, UserId, MType).

%% 角色移动
move(Player, UserId, X, Y) ->
    case Player#player.map_pid of
        MapPid when is_pid(MapPid) ->
			%?MSG_DEBUG("11111111111", []),
            Packet  = msg_map_player_move_notice(UserId, X, Y),
			%?MSG_DEBUG("11111111111", []),
            ets_api:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_HUMAN, UserId}, [{#map_player.x, X}, {#map_player.y, Y}]),
			%?MSG_DEBUG("11111111111", []),
            map_serv:move_cast(MapPid, UserId, Packet, ?CONST_MAP_PTYPE_HUMAN),
			%?MSG_DEBUG("11111111111", []),
            update_xy(Player, X, Y);
        {MapPid, Node} ->
			%?MSG_DEBUG("11111111111", []),
            rpc:cast(Node, ?MODULE, move, [#player{map_pid = MapPid, maps = Player#player.maps}, UserId, X, Y]),
            update_xy(Player, X, Y);
        _ ->
			%?MSG_DEBUG("11111111111", []),
            Packet = message_api:msg_notice(?TIP_MAP_NO_MAP),
            misc_packet:send(Player#player.user_id, Packet),
            Player
    end.
%% 角色移动
move_robot(Player, UserId, X, Y, MType) ->
    case Player#player.map_pid of
        MapPid when is_pid(MapPid) ->
			%?MSG_DEBUG("11111111111", []),
            Packet  = msg_map_player_move_notice(UserId, X, Y),
			%?MSG_DEBUG("~p", [MapPid]),
            ets_api:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.x, X}, {#map_player.y, Y}]),
            map_serv:move_cast(MapPid, UserId, Packet, MType);
        {MapPid, Node} ->
			%?MSG_DEBUG("11111111111~p", [Node]),
            rpc:cast(Node, ?MODULE, move, [Player#player{map_pid = MapPid}, UserId, X, Y]),
            update_xy(Player, X, Y);
        _ ->
			%?MSG_DEBUG("11111111111", []),
            Packet = message_api:msg_notice(?TIP_MAP_NO_MAP),
            misc_packet:send(Player#player.user_id, Packet),
            Player
    end.

%% 更新xy
update_xy(Player, X, Y) ->
    MapData = Player#player.maps,
	%?MSG_DEBUG("~n 5555555555555555555~p", [MapData]),
    CurMapInfo = MapData#map_data.cur,
    NewCurMapInfo = CurMapInfo#map_info{x = X, y = Y},
    NewMapData = MapData#map_data{cur = NewCurMapInfo},
    Player#player{maps = NewMapData}.

%% 同场景内瞬移
teleport(Player, {X, Y}) -> teleport(Player, X, Y, ?CONST_SYS_FALSE).
teleport(Player, {X, Y}, IsRobot) -> teleport(Player, X, Y, IsRobot);
teleport(Player, X, Y) -> teleport(Player, X, Y, ?CONST_SYS_FALSE).

teleport(Player, X, Y, IsRobot) when is_record(Player, player) ->
	UserId	= Player#player.user_id,
    case Player#player.map_pid of
        {MapPid, Node} ->
            Packet  = msg_sc_player_teleport(UserId, X, Y),
            rpc:cast(Node, ets_api, update_element, [?CONST_ETS_MAP_PLAYER, UserId, [{#map_player.x, X}, {#map_player.y, Y}]]),
            map_serv:broadcast_cast({MapPid, Node}, Packet),
            NewPlayer = 
                if
                    ?CONST_SYS_TRUE =:= IsRobot ->
                        ?ok;
                    ?true ->
                        update_xy(Player, X, Y)
                end,
            {?ok, NewPlayer}; 
        MapPid when is_pid(MapPid) ->
            Packet  = msg_sc_player_teleport(UserId, X, Y),
            ets_api:update_element(?CONST_ETS_MAP_PLAYER, UserId, [{#map_player.x, X}, {#map_player.y, Y}]),
			map_serv:broadcast_cast(MapPid, Packet),
            NewPlayer = 
                if
                    ?CONST_SYS_TRUE =:= IsRobot ->
                        ?ok;
                    ?true ->
                        update_xy(Player, X, Y)
                end,
            {?ok, NewPlayer};
        _ -> {?ok, Player}
    end;
teleport(UserId, X, Y, IsRobot) when is_number(UserId) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
	       player_api:process_send(UserId, ?MODULE, teleport, {X, Y});
        [Rec] ->
            Node = Rec#cross_in.node,
            rpc:cast(Node, player_api, process_send, [UserId, ?MODULE, teleport, {X, Y}])
    end.

%% 场景物品检查
check_goods(MapId,GoodsId) ->
    case data_map:get_map(MapId) of
        #rec_map{flag_goods = FlagGoods} ->
            case lists:member(GoodsId, FlagGoods) of
                ?true -> ?false;
                _ -> ?true
            end;
        _ -> ?true
    end.

check_map(UserId, MapId) ->
    case player_api:check_online(UserId) of
        ?true ->
            case player_api:get_player_field(UserId, #player.maps) of
                {?ok, #map_data{cur = #map_info{map_id = PlayerMapId}}} ->
                    MapId =:= PlayerMapId;
                _ -> ?false %%系统错误：玩家在线但不存在？
            end;
        ?false -> ?false
    end.

%% 地图广播
%% 不要监听返回值，监听了没用
broadcast(_, <<>>) ->
    ?CONST_SYS_FALSE;
broadcast(MapPid, Packet) when is_pid(MapPid) ->
    map_serv:broadcast_cast(MapPid, Packet);
broadcast(Player, Packet) when is_record(Player, player) ->
    UserId = Player#player.user_id,
    MapPid  = Player#player.map_pid,
    if
        0 =:= MapPid ->
            misc_packet:send(UserId, Packet);
        ?true ->
            map_serv:broadcast_cast(MapPid, Packet)
    end;
broadcast(MapPid, Packet) when is_tuple(MapPid) ->
    map_serv:broadcast_cast(MapPid, Packet); 
broadcast(0, _Packet) ->
    ?CONST_SYS_FALSE;
broadcast(MapId, Packet) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId}}], ['$1']}], 
    MapPidList = ets_api:select(?CONST_ETS_MAP, MatchSpec),
    BroadFun =
        fun(MapPid) ->
            broadcast(MapPid, Packet)
        end,
    lists:foreach(BroadFun, MapPidList).
       
%% 地图可视区域广播
broadcast_range(Player, Packet) ->
    UserId  = Player#player.user_id,
    MapPid  = Player#player.map_pid,
    map_serv:broadcast_range_cast(MapPid, UserId, Packet).

%% 地图广播升级
change_level(Player) ->
    UserId  = Player#player.user_id,
    Info    = Player#player.info,
    Lv      = Info#info.lv,
    Packet  = msg_map_sc_change_lv(UserId, Lv),
    broadcast(Player, Packet).
%% 地图广播VIP改变
change_vip(Player) ->
    change_vip(Player, ?CONST_MAP_PTYPE_HUMAN).
change_vip(Player, MType) ->
    UserId      = Player#player.user_id,
    Vip         = player_api:get_vip_lv(Player),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.vip =/=  Vip ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.vip, Vip}]),
            Packet = msg_map_sc_change_vip(UserId, Vip),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播状态改变
change_state(Player) ->
    UserId  = Player#player.user_id,
    State   = Player#player.state,
    Packet  = msg_map_sc_change_state(UserId, State),
    broadcast(Player, Packet).
%% 地图广播队伍队长改变
change_leader(Player) ->
    Packet  = <<>>,
    broadcast(Player, Packet).

%% 地图广播时装特效改变
change_skin_fashion(Player) ->
    change_skin_fashion(Player, ?CONST_MAP_PTYPE_HUMAN).
change_skin_fashion(Player, MType) ->
    UserId      = Player#player.user_id,
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.skin_fashion =/=  SkinFashion ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.skin_fashion, SkinFashion}]),
            Packet = msg_map_sc_change_skin_fashion(UserId, SkinFashion),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播装备武器皮肤改变
change_skin_weapon(Player) ->
    change_skin_weapon(Player, ?CONST_MAP_PTYPE_HUMAN).
change_skin_weapon(Player, MType) ->
    UserId      = Player#player.user_id,
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.skin_weapon =/= SkinWeapon ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.skin_weapon, SkinWeapon}]),
            Packet = msg_map_sc_change_skin_weapon(UserId, SkinWeapon),
            broadcast(Player, Packet);
        ?true ->
			?ok
    end.
%% 地图广播装备足迹皮肤改变
change_skin_step(Player) ->
    change_skin_step(Player, ?CONST_MAP_PTYPE_HUMAN).
change_skin_step(Player, MType) ->
    UserId      = Player#player.user_id,
    SkinStep	= goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_STEP),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.skin_step =/= SkinStep ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.skin_step, SkinStep}]),
            Packet = msg_sc_change_skin_step(UserId, SkinStep),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播装备衣服皮肤改变
change_skin_armor(Player) ->
    change_skin_armor(Player, ?CONST_MAP_PTYPE_HUMAN).
change_skin_armor(Player, MType) ->
    UserId      = Player#player.user_id,
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.skin_armor =/= SkinArmor ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.skin_armor, SkinArmor}]),
            Packet = msg_map_sc_change_skin_armor(UserId, SkinArmor),
            broadcast(Player, Packet);
        ?true ->
			?ok
    end.
%% 地图广播坐骑皮肤改变
change_skin_ride(Player) ->
    change_skin_ride(Player, ?CONST_MAP_PTYPE_HUMAN).
change_skin_ride(Player, MType) ->
    UserId      = Player#player.user_id,
	SkinRide    = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_HORSE),
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.skin_ride =/= SkinRide ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.skin_ride, SkinRide}]),
            Packet = msg_map_sc_change_skin_ride(UserId, SkinRide),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播vip等级隐藏
change_vip_hide(Player) ->
	change_vip_hide(Player, ?CONST_MAP_PTYPE_HUMAN).
change_vip_hide(Player,	MType) ->
	UserId = Player#player.user_id,
	SkinVip = goods_style_api:get_cur_style(Player, ?CONST_GOODS_ATTR_VIP),
	MapPlayer = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
	if
		MapPlayer#map_player.vip_hide =/= SkinVip ->
			ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.vip_hide, SkinVip}]),
			Packet = msg_sc_vip_hide(UserId, SkinVip),
			broadcast(Player, Packet);
		?true -> ?ok
	end.
		
%% 地图广播称号改变
change_title(Player) ->
    change_title(Player, ?CONST_MAP_PTYPE_HUMAN).
change_title(Player, MType) ->
    UserId      = Player#player.user_id,
    Info        = Player#player.info,
    Title       = Info#info.current_title,
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.title =/= Title ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.title, Title}]),
            Packet = msg_sc_change_title(UserId, Title),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播军团改变
change_guild(Player) ->
    change_guild(Player, ?CONST_MAP_PTYPE_HUMAN).
change_guild(Player, MType) ->
    UserId      = Player#player.user_id,
    Guild       = Player#player.guild,
    GuildId     = Guild#guild.guild_id,
    GuildName   = Guild#guild.guild_name,
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.guild_name =/= GuildName ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.guild_name, GuildName}, 
                                                               {#map_player.guild_id,   GuildId}]),
            Packet = msg_sc_change_guild(UserId, GuildId, GuildName),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播官衔改变
change_position(Player) ->
    change_position(Player, ?CONST_MAP_PTYPE_HUMAN).
change_position(Player, MType) ->
    UserId       = Player#player.user_id,
    PositionData = Player#player.position,
    PositionId   = PositionData#position_data.position,
    IsOpenedPosition = player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION),
    MapPlayer    = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.position =/= PositionId andalso ?true =:= IsOpenedPosition ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.position, PositionId}]),
            Packet = msg_sc_change_position(UserId, PositionId),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.
%% 地图广播玩家状态改变
change_user_state(Player) ->
    change_user_state(Player, ?CONST_MAP_PTYPE_HUMAN).
change_user_state(Player, MType) ->
    UserId      = Player#player.user_id,
    UserState   = Player#player.user_state,
    PracState   = Player#player.practice_state,
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.practice_state =/= PracState ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.practice_state, PracState},
                                                               {#map_player.other_user_id, 0}]),
            Packet = msg_cs_change_info_state(UserId, PracState),
            broadcast(Player, Packet);
        ?true ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.user_state, UserState},
                                                               {#map_player.other_user_id, 0}]),
            Packet = msg_cs_change_info_state(UserId, UserState),
            broadcast(Player, Packet)
    end.

%% 地图广播玩家状态改变
change_double(Player, State, OtherUserId) ->
    change_double(Player, State, OtherUserId, ?CONST_MAP_PTYPE_HUMAN, ?CONST_MAP_PTYPE_HUMAN).
change_double(Player, State, OtherUserId, MType1, MType2) ->
    UserId      	= Player#player.user_id,
	ets:update_element(?CONST_ETS_MAP_PLAYER, {MType1, UserId}, [{#map_player.user_state, State},
													   {#map_player.other_user_id, OtherUserId}]),
	ets:update_element(?CONST_ETS_MAP_PLAYER, {MType2, OtherUserId}, [{#map_player.user_state, State},
															{#map_player.other_user_id, UserId}]).
%% 地图广播玩家主将将星等级变化
change_star_lv(Player) ->
    UserId = Player#player.user_id,
    Soul = Player#player.partner_soul,
    Lv = Soul#partner_soul.star_lv,
    ets:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_HUMAN, UserId}, [{#map_player.star_lv, Lv}]),
    Packet = msg_star_lv_change(UserId,0,Lv),
    broadcast(Player, Packet).

%% 地图广播官衔改变
change_guild_lv(Player) ->
    change_guild_lv(Player, ?CONST_MAP_PTYPE_HUMAN).
change_guild_lv(Player, MType) ->
    UserId       = Player#player.user_id,
    GuildData    = Player#player.guild,
    GuildId      = GuildData#guild.guild_id,
    {?ok, GuildLv} = guild_api:get_guild_lv(GuildId),
    MapPlayer    = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.guild_lv =/= GuildLv ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.guild_lv, GuildLv}]),
            Packet = msg_sc_change_guild_lv(UserId, GuildLv),
            broadcast(Player, Packet);
        ?true ->
            skip
    end.


    

change_team(Player) ->
    change_team(Player, ?CONST_MAP_PTYPE_HUMAN).
change_team(Player, MType) ->
    UserId		= Player#player.user_id,
	Leader		= Player#player.leader,
    case Player#player.map_pid of
        {_Pid, Node} ->
            rpc:cast(Node, ?MODULE, change_team, [MType, UserId, Leader]);
        _Pid ->
            change_team(MType, UserId, Leader)
    end.

change_team(MType, UserId, Leader) ->
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.leader =/= Leader ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.leader, Leader}]),
            ?ok;
        ?true ->
            skip
    end.

%% 改名
change_name(Player) ->
    change_name(Player, ?CONST_MAP_PTYPE_HUMAN).
change_name(Player, MType) ->
    UserId      = Player#player.user_id,
    Info        = Player#player.info,
    UserName    = Info#info.user_name,
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.user_name =/= UserName ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.user_name, UserName}]),
            Packet = msg_sc_change_name(UserId,UserName),
            broadcast(Player, Packet);
        ?true -> ?ok
    end.

%% 地图广播称号改变
change_follow(Player) ->
    change_follow(Player, ?CONST_MAP_PTYPE_HUMAN).
change_follow(Player, MType) ->
    UserId      = Player#player.user_id,
    Partner		= Player#player.partner,
    FollowId    = Partner#partner_data.follow_id,
    MapPlayer   = ets_api:lookup(?CONST_ETS_MAP_PLAYER, {MType, UserId}),
    if
        MapPlayer#map_player.follow_id =/= FollowId ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, {MType, UserId}, [{#map_player.follow_id, FollowId}]),
			MapData = Player#player.maps,
			Cur		= MapData#map_data.cur,
			MapId	= Cur#map_info.map_id,
			case lists:member(MapId, [31001, 41000, 41001, 41002, 41003, 41004, 41005, 41006]) of
				?true -> %% 温泉和阵营战不显示跟随武将
					?ok;
				?false ->
		            Packet = msg_sc_change_follow(UserId, FollowId),
		            broadcast(Player, Packet)
			end;
        ?true -> ?ok
    end.

%% 全屏特效
broadcast_show(Player, Type) ->
    UserId = Player#player.user_id,
    Packet = msg_sc_show_map(UserId, Type),
    broadcast(Player, Packet).

%% 读取相应地图中的玩家列表
%% [UserId, UserId...]
get_user_id_list(Pid) when is_pid(Pid) -> % 不在地图进程中
    case map_serv:get_user_id_list(Pid) of
        L when is_list(L) -> L;
        _ -> []
    end.

%% 读取相应地图中的玩家列表
%% [UserId, UserId...]
get_user_id_list_lv(_MapId, _Lv) -> % 不在地图进程中
%%     List = ets_api:match(?CONST_ETS_PLAYER_ONLINE, #player{user_id = '$1', info = #info{map_id = MapId, lv = '$2', _ = '_'}, _ = '_'}),
%%     F = fun([UserId, LvUser], OldList) when LvUser >= Lv ->
%%                 [UserId|OldList];
%%            (_, OldList) ->
%%                 OldList
%%         end,
%%     lists:foldl(F, [], List).
    [].

%% 下线时处理
logout(Player) ->
	exit_map(Player),
	practice_api:check_doll_info(Player),
    ets_api:delete(?CONST_ETS_MAP_PLAYER, Player#player.user_id).

%% 更新玩家地图信息
update_player_map_cb(Player, {X, Y, MapId, MapPid}) ->
    OldMapPid = Player#player.map_pid,
    OldMapData = Player#player.maps,
    OldMapInfo = OldMapData#map_data.cur,
    OldMapInfo2 = get_eff_city_map_info(Player, OldMapInfo),
    NewMapInfo = #map_info{map_id = MapId, x = X, y = Y},
 
    NewMapData = OldMapData#map_data{cur = NewMapInfo, last = OldMapInfo2},
    NewPlayer = Player#player{map_pid = MapPid, maps = NewMapData},
    UserId = Player#player.user_id,
    map_serv:exit_map_cast(OldMapPid, UserId),
    {?ok, NewPlayer}.

%% 队伍离开地图
team_exit(MapPid) ->
    map_serv:team_exit(MapPid).

%% 最大城市地图npc号
get_max_city_npc_id([MapId|Tail], MaxMapId) when MaxMapId < MapId ->
    case read_map_info(MapId) of
        _RecMap = #rec_map{type = ?CONST_MAP_TYPE_CITY} ->
            get_max_city_npc_id(Tail, MapId);
        _ ->
            get_max_city_npc_id(Tail, MaxMapId)
    end;
get_max_city_npc_id([_MapId|Tail], MaxMapId) ->
    get_max_city_npc_id(Tail, MaxMapId);
get_max_city_npc_id([], MaxMapId) ->
    data_shop:get_shop_npc(MaxMapId).

%% 初始化将领
faction_init_boss(MapPid, MonsterId) ->
    map_serv:faction_init_boss(MapPid, MonsterId).

%% 地图广播官衔改变
open_position(Player) ->
    UserId       = Player#player.user_id,
    PositionData = Player#player.position,
    PositionId   = PositionData#position_data.position,
    IsOpenedPosition = player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION),
    MapPlayer    = ets_api:lookup(?CONST_ETS_MAP_PLAYER, Player#player.user_id),
    if
        MapPlayer#map_player.position =/= PositionId andalso ?true =:= IsOpenedPosition ->
            ets:update_element(?CONST_ETS_MAP_PLAYER, UserId, [{#map_player.position, PositionId}]),
            Packet = msg_sc_change_position(UserId, PositionId),
            broadcast(Player, Packet);
        ?true ->
            Packet = msg_sc_change_position(UserId, PositionId),
            broadcast(Player, Packet)
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 移除怪物
mcopy_battle_over(MapPid, UserId, UniqueId, AtkPoint, DefPoint, TeamId, RobotList) ->
    map_serv:mcopy_battle_over(MapPid, UserId, UniqueId, AtkPoint, DefPoint, TeamId, RobotList).

%% 怪物移动
monster_move(UniqId, X, Y, MapPid) ->
    map_serv:monster_move(UniqId, X, Y, MapPid).

start_q(Player) ->
    map_serv:start_q(Player).

start_mcopy_battle(Player) ->
	map_serv:start_mcopy_battle(Player).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 消除多余的地图进程 -- crontab进程调map_serv
clean_maps() ->
    ChildList = supervisor:which_children(map_sup),  % XXX 地图管理进程
    F = fun({_, ChildPid, _, _}) ->
                map_serv:clean_map_cast(ChildPid)
        end,
    lists:foreach(F, ChildList),
    ?ok.

request_for_cb(MapPid, {Mod, Func, Param}) ->
    map_serv:request_for_cb(MapPid, {Mod, Func, Param}).

%% 异民族相关
invasion_close(MapPid, TeamId) ->
	map_serv:invasion_close(MapPid, TeamId).

invasion_robot(MapPid, TeamId) ->
	map_serv:invasion_robot(MapPid, TeamId).

invasion_progress(MapPid) ->
	map_serv:invasion_progress(MapPid).

invasion_mon_battle_start(MapPid, TeamId, UniqueId, UserId) ->
	map_serv:invasion_mon_battle_start(MapPid, TeamId, UniqueId, UserId).

invasion_battle_over(Result, UserId, BattleType, UniqueId, MapPid, TeamId, RightUnits, HurtLeft, HurtRight) ->
	map_serv:invasion_battle_over(Result, UserId, BattleType, UniqueId, MapPid, TeamId, RightUnits, HurtLeft, HurtRight).

%% 踢所有地图中的人
kick_all(MapId) ->
    MatchSpec = [{{'$1','$2','$3'}, [{'andalso',{'=:=','$2',MapId}}], ['$1']}], 
    MapPidList = ets_api:select(?CONST_ETS_MAP, MatchSpec),
    [map_serv:kick_all_cast(MapPid)||MapPid<-MapPidList].



%%
%% Local Functions
%%

%% 清除多余的地图进程 -- map_serv
clean_maps_cb(MapType) ->
    case get(user_id_list) of
        [] ->  % 让没人的地图进程自杀
            case MapType of
                ?CONST_MAP_TYPE_FACTION ->
                    ?ok;
                _ ->
                    ?stop
            end;
        ?undefined -> % 让没人的地图进程自杀
            ?stop;
        UserIdList when is_list(UserIdList) -> 
			List		= [UserId || {Type, UserId} <- UserIdList, Type =:= ?CONST_MAP_PTYPE_HUMAN orelse (is_atom(Type) andalso Type =/= ?undefined)],
            Len 		= erlang:length(UserIdList),
            Pid 		= self(),
			case List of
				[] when MapType =:= ?CONST_MAP_TYPE_GUARD orelse 
						MapType =:= ?CONST_MAP_TYPE_MCOPY orelse
						MapType =:= ?CONST_MAP_TYPE_BOSS -> 
					?stop;
				_ ->
					case ets_api:lookup(?CONST_ETS_MAP, Pid) of
						[Pid, _MapId, Count] when 0 < Count ->
							?stop;
						[Pid, MapId, Count] when Count =< 0 ->
							ets:insert(?CONST_ETS_MAP, {Pid, MapId, Len}),
							?ok;
						_ ->
							?ok
					end
			end;
        _ -> % 数据异常
            ?ok
    end.

%%====================================地图信息==============================================
%% 地图信息
read_map_info(MapId) ->
    data_map:get_map(MapId).

%% 统计地图人数
stat_map_player() ->
    Fun     = fun({_, Id, Num}, Acc) ->
                      case lists:keytake(Id, 1, Acc) of
                          {value, {Id, AccNum}, Acc2} -> [{Id, AccNum + Num}|Acc2];
                          ?false -> [{Id, Num}|Acc]
                      end
              end,
    MapList = lists:foldl(Fun, [], ets_api:list(?CONST_ETS_MAP)),
    FunDB   = fun({MapId, Count}) ->
                      SQL       = "INSERT INTO `techcenter_map_online` (`time`, `map_id`, `count`) VALUES ('" ++ misc:to_list(misc:seconds()) ++ "', '" ++
                                      misc:to_list(MapId) ++ "', '" ++ misc:to_list(Count) ++ "');",
                      mysql_api:execute_sql(SQL)
              end,
    lists:foreach(FunDB, MapList),
    ?ok.

%% 开启地图
open_map(Player = #player{maps = MapData}, MapId) when is_number(MapId) ->
    case read_map_info(MapId) of 
        RecMap when is_record(RecMap, rec_map) -> % map_id存在
            case is_opened(MapId, Player) of
                ?true ->
                    {Player, <<>>};
                ?false ->
                    OpenedMapList = MapData#map_data.opened,
                    NewOpenedMapList = [MapId|OpenedMapList],
                    MapData2 = MapData#map_data{opened = NewOpenedMapList},
                    PacketUpdate = msg_sc_update_map(MapId),
                    {Player#player{maps = MapData2}, PacketUpdate}
            end;
        _ ->
            {Player, <<>>}
    end;
open_map(Player, _) ->
    {Player, <<>>}.

%% 关闭地图
close_map(Player = #player{maps = MapData}, MapId) when is_number(MapId) ->
    OpenedMapList = MapData#map_data.opened,
    NewOpenedMapList = lists:delete(MapId, OpenedMapList),
    Player#player{maps = MapData#map_data{opened = NewOpenedMapList}};
close_map(Player, _) ->
    Player.

%% 获取地图中的玩家信息
get_map_player(UserId) ->
    case ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserId) of
        MapPlayer when is_record(MapPlayer, map_player) ->
            MapPlayer;
        ?null ->
            ?null
    end.

%% 读取当前mapId
get_cur_map_id(Player) ->
    MapData    = Player#player.maps,
    CurMapInfo = MapData#map_data.cur,
    CurMapInfo#map_info.map_id.

%%------------------------------------工具-----------------------------------------------
%% 是否开启
is_opened(MapId, #player{maps = MapData}) ->
    case MapId == guild_pvp_api:get_guild_pvp_map_id() of
        true ->
            true;
        false ->
            MapList = MapData#map_data.opened,
            lists:member(MapId, MapList)
    end;
is_opened(MapId, #map_data{opened = MapList}) ->
    case MapId == guild_pvp_api:get_guild_pvp_map_id() of
        true ->
            true;
        false ->
            lists:member(MapId, MapList)
    end.

%% 更新玩家地图信息
update_cur_map_info(Player, MapId) ->
    MapData     = Player#player.maps,
    CurMapInfo  = MapData#map_data.cur,
    case read_map_info(MapId) of
        #rec_map{x = OldX, y = OldY} ->
            {X, Y}      = get_point(MapId, OldX, OldY),
            CurMapInfo2 = CurMapInfo#map_info{map_id = MapId, x = X, y = Y},
            MapData2    = MapData#map_data{cur = CurMapInfo2},
            Player#player{maps = MapData2};
        _ ->
            Info        = Player#player.info,
            Pro         = Info#info.pro,
            Sex         = Info#info.sex,
            DefaultMapInfo = player_default_api:get_default_map_info(Pro, Sex),
            MapData2    = MapData#map_data{cur = DefaultMapInfo},
            Player#player{maps = MapData2}
    end.

%% 返回上张中立地图
%% Player
return_last_city(Player) ->
    MapInfo = get_last_city_map_info(Player),
	?MSG_DEBUG("~n MapInfo=~p", [MapInfo]),
    enter_map(Player, MapInfo#map_info.map_id).

%% 获取上张地图
get_last_city_map_info(Player) ->
    Info = Player#player.info,
    Pro  = Info#info.pro,
    Sex  = Info#info.sex,
    MapData     = Player#player.maps,
    LastMapInfo = MapData#map_data.last,
    {NewX, NewY} = get_point(?CONST_MAP_TYPE_CITY, LastMapInfo#map_info.x, LastMapInfo#map_info.y),
    
    case read_map_info(LastMapInfo#map_info.map_id) of
        #rec_map{type = ?CONST_MAP_TYPE_CITY} ->
            LastMapInfo#map_info{x = NewX, y = NewY};
        _ ->
            MapInfo = player_default_api:get_default_map_info(Pro, Sex),
            MapInfo#map_info{x = NewX, y = NewY}
    end.
    
%% 读取可用地图
get_eff_city_map_info(Player, MapInfo) ->
    Info = Player#player.info,
    Pro  = Info#info.pro,
    Sex  = Info#info.sex,
    {NewX, NewY} = get_point(?CONST_MAP_TYPE_CITY, MapInfo#map_info.x, MapInfo#map_info.y),
    case read_map_info(MapInfo#map_info.map_id) of
        #rec_map{type = ?CONST_MAP_TYPE_CITY} ->
            MapInfo#map_info{x = NewX, y = NewY};
        _ ->
            MapInfo = player_default_api:get_default_map_info(Pro, Sex),
            MapInfo#map_info{x = NewX, y = NewY}
    end.

%% 读取当前map_info
get_cur_map_info(Player) ->
    MapData = Player#player.maps,
    MapData#map_data.cur.

%% 
record_map_player(Player) ->
    map_mod:record_map_player(Player).

insert_map_player(#player{} = Player) ->
    MapPlayer = record_map_player(Player),
    ets_api:insert(?CONST_ETS_MAP_PLAYER, MapPlayer);
insert_map_player(#map_player{} = MapPlayer) ->
    ets_api:insert(?CONST_ETS_MAP_PLAYER, MapPlayer).

init_map_name() ->
    try
        Head = 
            "-module(map_name_api).
             -export([regist_map_name/4]). 
            ",
        Body = 
            case config:read_deep([server, base, debug]) of
            ?CONST_SYS_TRUE ->
                " regist_map_name(MapId, Type, Pid, Param) -> map_mod:regist_map_name(MapId, Type, Pid, Param). ";
            _ ->
               " regist_map_name(_MapId, _Type, _Pid, _Param) -> ok. "
            end,
        {Mod, Code} = dynamic_compile:from_string(Head++Body),
        code:load_binary(Mod, "map_name_api.erl", Code),
        ?ok
    catch
        Type:Error -> ?MSG_ERROR("Error compiling map_name_api Type:~p Error:~p Stack:~p~n", 
                                 [Type, Error, erlang:get_stacktrace()])
    end.

%% 检查是否是不需要更新上一张地图的地图，如团队战场和异民族
check_is_spec_map(MapId) ->
    RecMap = read_map_info(MapId),
    case is_record(RecMap, rec_map) of
        false ->
            false;
        _ ->
            MapType = RecMap#rec_map.type,
            MapType == ?CONST_MAP_TYPE_MCOPY 
            orelse MapType == ?CONST_MAP_GUILD_PVP_BATTLE
            orelse MapType == ?CONST_MAP_GUILD_PVP_HOME
            orelse MapType == ?CONST_MAP_TYPE_GUARD
    end.

%%====================================地图信息==============================================

%% 5010 进入地图角色数据
msg_map_enter_player(MapId, MapPlayer) when is_record(MapPlayer, map_player) ->
	msg_map_enter_player(MapId, MapPlayer, MapPlayer#map_player.x, MapPlayer#map_player.y);
msg_map_enter_player(MapId, MapPlayer) ->
	?MSG_ERROR("MapId:~p MapPlayer:~p", [MapId, MapPlayer]),
	<<>>.
msg_map_enter_player(MapId, MapPlayer, X, Y) when is_record(MapPlayer, map_player) ->
	SkinFashion	= case MapPlayer#map_player.hide_fashion of
					  ?CONST_SYS_TRUE -> 0;
					  ?CONST_SYS_FALSE -> MapPlayer#map_player.skin_fashion
				  end,
	SkinRide	= case MapPlayer#map_player.hide_ride of
					  ?CONST_SYS_TRUE -> 0;
					  ?CONST_SYS_FALSE -> MapPlayer#map_player.skin_ride
				  end,
    PracState   = MapPlayer#map_player.practice_state,
    UserState   = MapPlayer#map_player.user_state,
    UserState2  =
        if
            ?CONST_PLAYER_STATE_NORMAL =/= PracState orelse 0 =/= PracState ->
                PracState;
            ?true ->
                UserState
        end,
	RecMap	= data_map:get_map(MapId),
	MapType	= RecMap#rec_map.type,
	FollowId	= 
		case lists:member(MapType, [?CONST_MAP_TYPE_SPRING, ?CONST_MAP_TYPE_FACTION, 
                                    ?CONST_MAP_TYPE_CAMP_PVP, ?CONST_MAP_GUILD_PVP_BATTLE, 
                                    ?CONST_MAP_GUILD_PVP_HOME]) of
			?true -> %% 温泉和阵营战不显示跟随武将
				0;
			?false ->
				MapPlayer#map_player.follow_id
		end,
	VipHide = MapPlayer#map_player.vip_hide,
    Datas = [
             MapId,
             MapPlayer#map_player.user_id,
             MapPlayer#map_player.user_name,
             MapPlayer#map_player.pro,
             MapPlayer#map_player.sex,
             MapPlayer#map_player.lv,
             MapPlayer#map_player.vip,
             MapPlayer#map_player.state,
             MapPlayer#map_player.leader,
             X,
             Y,
             0,
             SkinFashion,
             MapPlayer#map_player.skin_weapon,
             MapPlayer#map_player.skin_armor,
             SkinRide,
             MapPlayer#map_player.title,
             MapPlayer#map_player.guild_id,
             MapPlayer#map_player.guild_name,
             MapPlayer#map_player.position,
             UserState2,
             MapPlayer#map_player.other_user_id,
             MapPlayer#map_player.guild_lv,
             guild_api:get_guild_rank(MapPlayer#map_player.guild_id),
			 FollowId,
             cross_api:get_index_from(MapPlayer#map_player.user_id),
			 VipHide,
             MapPlayer#map_player.star_lv
            ],
    misc_packet:pack(?MSG_ID_MAP_ENTER_PLAYER, ?MSG_FORMAT_MAP_ENTER_PLAYER, Datas);
msg_map_enter_player(MapId, MapPlayer, _X, _Y) ->
	?MSG_ERROR("MapId:~p MapPlayer:~p", [MapId, MapPlayer]),
	<<>>.

%% 5012 离开
msg_map_exit_player(MapId, UserId, Reason) ->
    Datas = [MapId, UserId, Reason],
    misc_packet:pack(?MSG_ID_MAP_EXIT, ?MSG_FORMAT_MAP_EXIT, Datas).

%% 5022 角色移动通知  
msg_map_player_move_notice(UserId, X, Y) ->
    Datas = [UserId, X, Y],
    misc_packet:pack(?MSG_ID_MAP_PLAYER_MOVE_NOTICE, ?MSG_FORMAT_MAP_PLAYER_MOVE_NOTICE, Datas).

%% 5030     角色等级改变广播 
msg_map_sc_change_lv(UserId,Lv) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_LV, ?MSG_FORMAT_MAP_SC_CHANGE_LV, [UserId,Lv]).
%% 5040     角色VIP改变广播
msg_map_sc_change_vip(UserId,Vip) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_VIP, ?MSG_FORMAT_MAP_SC_CHANGE_VIP, [UserId,Vip]).
%% 5050     角色状态改变广播
msg_map_sc_change_state(UserId,State) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_STATE, ?MSG_FORMAT_MAP_SC_CHANGE_STATE, [UserId,State]).
%% 5060     角色时装皮肤改变广播
msg_map_sc_change_skin_fashion(UserId,SkinWeapon) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_SKIN_FASHION, ?MSG_FORMAT_MAP_SC_CHANGE_SKIN_FASHION, [UserId,SkinWeapon]).
%% 5070     角色武器皮肤改变广播
msg_map_sc_change_skin_weapon(UserId,SkinWeapon) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_SKIN_WEAPON, ?MSG_FORMAT_MAP_SC_CHANGE_SKIN_WEAPON, [UserId,SkinWeapon]).
%% 5080     角色护甲皮肤改变广播
msg_map_sc_change_skin_armor(UserId,SkinArmor) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_SKIN_ARMOR, ?MSG_FORMAT_MAP_SC_CHANGE_SKIN_ARMOR, [UserId,SkinArmor]).
%% 角色足迹皮肤改变广播
%%[UserId,SkinStep]
msg_sc_change_skin_step(UserId,SkinStep) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_SKIN_STEP, ?MSG_FORMAT_MAP_SC_CHANGE_SKIN_STEP, [UserId,SkinStep]).
%% 5088     双修时玩家状态改变
%%[UserId,UserId2]
msg_sc_change_double(UserId,UserId2) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_DOUBLE, ?MSG_FORMAT_MAP_SC_CHANGE_DOUBLE, [UserId,UserId2]).
%% 5090     角色坐骑皮肤改变广播
msg_map_sc_change_skin_ride(UserId,SkinRide) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_SKIN_RIDE, ?MSG_FORMAT_MAP_SC_CHANGE_SKIN_RIDE, [UserId,SkinRide]).
%% 角色称号改变广播
%%[UserId,TitleId,Title]
msg_sc_change_title(UserId,TitleId) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_TITLE, ?MSG_FORMAT_MAP_SC_CHANGE_TITLE, [UserId,TitleId]).
%% 角色军团改变广播
%%[UserId,GuildId,GuildName]
msg_sc_change_guild(UserId,GuildId,GuildName) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_GUILD, ?MSG_FORMAT_MAP_SC_CHANGE_GUILD, [UserId,GuildId,GuildName]).
%% 角色官衔改变广播
%%[UserId,Position]
msg_sc_change_position(UserId,Position) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_POSITION, ?MSG_FORMAT_MAP_SC_CHANGE_POSITION, [UserId,Position]).
%% 玩家状态改变
%%[UserId,State]
msg_cs_change_info_state(UserId,State) ->
    misc_packet:pack(?MSG_ID_MAP_CS_CHANGE_INFO_STATE, ?MSG_FORMAT_MAP_CS_CHANGE_INFO_STATE, [UserId,State]).

%% 怪物信息
%%[MonsterId,MonsterUniqueId,X,Y]
msg_sc_monster_info(MonsterId,MonsterUniqueId,X,Y) ->
    misc_packet:pack(?MSG_ID_MAP_SC_MONSTER_INFO, ?MSG_FORMAT_MAP_SC_MONSTER_INFO, [MonsterId,MonsterUniqueId,X,Y]).
%% 怪物移动广播
%%[MonsterUniqueId,X,Y,TargetX,TargetY]
msg_sc_monster_move(MonsterUniqueId,X,Y,TargetX,TargetY,Speed) ->
    misc_packet:pack(?MSG_ID_MAP_SC_MONSTER_MOVE, ?MSG_FORMAT_MAP_SC_MONSTER_MOVE, [MonsterUniqueId,X,Y,TargetX,TargetY,Speed]).
%% 组队状态改变广播
msg_sc_change_team(UserId,Leader) ->
	misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_TEAM, ?MSG_FORMAT_MAP_SC_CHANGE_TEAM, [UserId,Leader]).
%% 5110     移除怪物
msg_map_sc_monster_remove(MonsterUniqueId) ->
    misc_packet:pack(?MSG_ID_MAP_SC_MONSTER_REMOVE, ?MSG_FORMAT_MAP_SC_MONSTER_REMOVE, [MonsterUniqueId]).
%% 隐藏vip等级广播
%%[UserId,VipHide]
msg_sc_vip_hide(UserId,VipHide) ->
	misc_packet:pack(?MSG_ID_MAP_SC_VIP_HIDE, ?MSG_FORMAT_MAP_SC_VIP_HIDE, [UserId,VipHide]).
%% 开启地图列表
%%[{MapId}]
msg_sc_opened_map_list(List1) ->
    F = fun(MapId, OldMapList) ->
                [{MapId}|OldMapList]
        end,
    List2 = lists:foldl(F, [], List1),
    misc_packet:pack(?MSG_ID_MAP_SC_OPENED_MAP_LIST, ?MSG_FORMAT_MAP_SC_OPENED_MAP_LIST, [List2]).
%% 更新开启地图列表
%%[MapId]
msg_sc_update_map([MapId|Tail], Packet) ->
    Packet2 = misc_packet:pack(?MSG_ID_MAP_SC_UPDATE_MAP, ?MSG_FORMAT_MAP_SC_UPDATE_MAP, [MapId]),
    msg_sc_update_map(Tail, <<Packet/binary, Packet2/binary>>);
msg_sc_update_map([], Packet) ->
    Packet.
    
msg_sc_update_map(MapIdList) when is_list(MapIdList) ->
    msg_sc_update_map(MapIdList, <<>>);
msg_sc_update_map(MapId) ->
    misc_packet:pack(?MSG_ID_MAP_SC_UPDATE_MAP, ?MSG_FORMAT_MAP_SC_UPDATE_MAP, [MapId]).
%% 角色瞬移广播
%%[UserId,X,Y]
msg_sc_player_teleport(UserId,X,Y) ->
    misc_packet:pack(?MSG_ID_MAP_SC_PLAYER_MOVE, ?MSG_FORMAT_MAP_SC_PLAYER_MOVE, [UserId,X,Y]).
%% 军团等级改变
%%[UserId,GuildLv]
msg_sc_change_guild_lv(UserId,GuildLv) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_GUILD_LV, ?MSG_FORMAT_MAP_SC_CHANGE_GUILD_LV, [UserId,GuildLv]).

%% 玩家名字改变广播
%%[UserId,UserName]
msg_sc_change_name(UserId,UserName) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_NAME, ?MSG_FORMAT_MAP_SC_CHANGE_NAME, [UserId,UserName]).

%% 全屏效果
%%[UserId,Type]
msg_sc_show_map(UserId,Type) ->
    misc_packet:pack(?MSG_ID_MAP_SC_SHOW_MAP, ?MSG_FORMAT_MAP_SC_SHOW_MAP, [UserId,Type]).

%% 全屏效果
%%[UserId,FollowId]
msg_sc_change_follow(UserId,FollowId) ->
    misc_packet:pack(?MSG_ID_MAP_SC_CHANGE_FOLLOW, ?MSG_FORMAT_MAP_SC_CHANGE_FOLLOW, [UserId,FollowId]).

%% 发起pk邀请回复
%%[UserId,UserName]
msg_sc_invite_pk(UserId,UserName) ->
	misc_packet:pack(?MSG_ID_MAP_SC_INVITE_PK, ?MSG_FORMAT_MAP_SC_INVITE_PK, [UserId,UserName]).

%% 将星等级变化
%%[UserId,PartnerId,NewStarLv]
msg_star_lv_change(UserId,PartnerId,NewStarLv) ->
    misc_packet:pack(?MSG_ID_MAP_STAR_LV_CHANGE, ?MSG_FORMAT_MAP_STAR_LV_CHANGE, [UserId,PartnerId,NewStarLv]).