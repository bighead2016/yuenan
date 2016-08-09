%%% 
-module(robot_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.map.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([
		 init/0,
		 record_map_player/5,
		 
		 doll_enter_spring/0,
		 quit_spring/2,
		 double_cancel/3,
		 
		 doll_enter_practice/1,
		 doll_cancel_double/1,
		 doll_quit_practice/1,
		 
		 doll_enter_party/0,
		 
		 is_open_robot/1
		]).

%%
%% API Functions
%%
%% 初始化数据
init() ->
	practice_api:load_doll().

%%===================================温泉机器人===================================
%% 机器人进入温泉
doll_enter_spring() ->
    case is_open_robot(spring) of
        ?CONST_SYS_TRUE ->
            robot_mod:doll_enter(spring);
        _ ->
            ?ok
    end.

%% 退出温泉
quit_spring(UserId, MemId) ->
    case is_open_robot(spring) of
        ?CONST_SYS_TRUE ->
            Packet = map_api:msg_cs_change_info_state(UserId, ?CONST_PLAYER_STATE_NORMAL),
            ets:delete(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_ROBOT, UserId}),
            misc_packet:send(MemId, Packet);
        _ ->
            ?ok
    end.

%% 取消温泉双修
double_cancel(MapPid, MemId, _UserId) ->
	case is_open_robot(spring) of
		?CONST_SYS_TRUE ->
			ets_api:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_ROBOT, MemId},
								   [{#map_player.user_state, ?CONST_PLAYER_STATE_NORMAL},
									{#map_player.practice_state, ?CONST_PLAYER_STATE_NORMAL},
									{#map_player.other_user_id, 0}]),
			Packet = map_api:msg_cs_change_info_state(MemId, ?CONST_PLAYER_STATE_NORMAL),
			map_api:broadcast(MapPid, Packet);
		_ ->
			?ok
	end.

%%===================================修炼机器人===================================
%% 替身进入离线修炼
doll_enter_practice(#player{user_id = UserId, maps = Maps}) ->
	MapId = hd(Maps#map_data.opened),
	map_api:enter_map_robot(UserId, MapId, ?CONST_MAP_PTYPE_PRACTICE_ROBOT),
	ets_api:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_PRACTICE_ROBOT, UserId},
						   [{#map_player.user_state, ?CONST_PLAYER_STATE_NORMAL},
							{#map_player.practice_state, ?CONST_PRACTICE_SINGLE},
							{#map_player.other_user_id, 0}]),
	ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.practice_state, ?CONST_PRACTICE_SINGLE},
															  {#practice_doll.map_id, MapId}]),
	ets_api:delete(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_HUMAN, UserId}),
	Packet = map_api:msg_cs_change_info_state(UserId, ?CONST_PRACTICE_SINGLE),
	map_api:broadcast(MapId, Packet),
	?ok.

%% 替身取消双修
doll_cancel_double(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
		?null ->
			?ignore;
		PracticeDoll ->
			MapId = PracticeDoll#practice_doll.map_id,
			ets_api:update_element(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_PRACTICE_ROBOT, UserId},
								   [{#map_player.user_state, ?CONST_PLAYER_STATE_NORMAL},
									{#map_player.practice_state, ?CONST_PRACTICE_SINGLE},
									{#map_player.other_user_id, 0}]),
			ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.practice_state, ?CONST_PRACTICE_SINGLE}]),
			Packet = map_api:msg_cs_change_info_state(UserId, ?CONST_PRACTICE_SINGLE),
			map_api:broadcast(MapId, Packet)
	end.

%% 替身退出离线修炼
doll_quit_practice(#player{user_id = UserId}) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
		?null ->
			?ignore;
		PracticeDoll ->
			MapId = PracticeDoll#practice_doll.map_id,
			MapData = data_map:get_map(MapId),
			MapType = MapData#rec_map.type, 
			{_, MapPid} = map_api:get_map_pid(MapType, MapId, #map_param{ad1=MapId}),
			map_api:exit_map(#player{user_id = UserId, map_pid = MapPid}, ?CONST_MAP_PTYPE_PRACTICE_ROBOT),
			ets_api:delete(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_PRACTICE_ROBOT, UserId})
	end.
%%===================================军团宴会机器人===================================
doll_enter_party() ->
	case is_open_robot(party) of
		?CONST_SYS_TRUE ->
			robot_mod:doll_enter(party);
		_ ->
			?ok
	end.
%%================================================================================
record_map_player(UserId, _MapId, X, Y, MType) ->
    case player_api:get_player_fields(UserId, [#player.info, #player.style, #player.sys_rank, #player.position, #player.guild]) of
        {?ok, [Info, StyleData, SysRank, PositionData, Guild]} ->
            HideFashion = goods_style_api:is_hide(StyleData, ?CONST_GOODS_EQUIP_FUSION),
            SkinFashion = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION),  
            SkinWeapon  = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION_WEAPON),  
            HideRide    = goods_style_api:is_hide(StyleData, ?CONST_GOODS_EQUIP_HORSE),
            SkinRide    = goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_HORSE),
            PositionId  = 
                case SysRank >= data_guide:get_task_rank(?CONST_MODULE_POSITION) of
                    ?true ->
                        PositionData#position_data.position;
                    ?false ->
                        0
                end,
            {_, GuildLv}= guild_api:get_guild_lv(Guild#guild.guild_id),
            record_map_player(MType, UserId, Info#info.user_name, Info#info.pro, Info#info.sex, 
                              Info#info.lv, player_api:get_vip_lv(Info), 
                              ?CONST_SYS_USER_STATE_NORMAL, 0, X, Y, SkinFashion, 
                              SkinWeapon, 0, SkinRide, HideFashion, HideRide, 
                              Info#info.current_title, Guild#guild.guild_name, 
                              Guild#guild.guild_id, GuildLv, PositionId, ?CONST_PLAYER_STATE_NORMAL);
        _ ->
            ?error
    end.
    

%%
%% Local Functions
%%
record_map_player(MType, UserId, UserName, Pro, Sex, Lv, Vip, State, Leader, X, Y, SkinFashion,
                  SkinWeapon, SkinArmor, SkinRide, HideFashion, HideRide, Title, GuildName, 
                  GuildId, GuildLv, PositionId, UserState) ->
    #map_player{
                key                = {MType, UserId},
                user_id            = UserId,                  % 玩家Id
                user_name          = UserName,                % 昵称
                pro                = Pro,                     % 职业
                sex                = Sex,                     % 性别
                lv                 = Lv,                      % 等级
                vip                = Vip,                     % VIP
                state              = State,               % 状态
                leader             = Leader,              % 队伍队长user_id
                
                x                  = X,                                 % X坐标
                y                  = Y,                                 % Y坐标
                
                skin_fashion       = SkinFashion,                       % 装备武器特效
                skin_weapon        = SkinWeapon,                        % 装备武器皮肤ID
                skin_armor         = SkinArmor,                                 % 装备衣服皮肤ID
                skin_ride          = SkinRide,                          % 坐骑皮肤ID
                hide_fashion       = HideFashion,                       % 隐藏时装
                hide_ride          = HideRide,                          % 隐藏坐骑
                title              = Title,                             % 称号
                guild_name         = GuildName,            % 军团名称 
                guild_id           = GuildId,              % 军团id
                guild_lv           = GuildLv,                           % 军团等级
                position           = PositionId,                        % 官衔id
                user_state         = UserState,                         % 玩家状态
                practice_state     = ?CONST_PLAYER_STATE_NORMAL
               }.

%% 检查是否开放机器人
is_open_robot(_Function) -> ?CONST_SYS_TRUE.
