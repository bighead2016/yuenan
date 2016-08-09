%% Author: cobain
%% Created: 2012-7-14
%% Description: TODO: Add description to map_mod
-module(map_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.base.data.hrl").
-include("record.player.hrl").
-include("record.map.hrl").
-include("record.data.hrl").
-include("const.tip.hrl").
-include("record.battle.hrl").
%%
%% Exported Functions
%%
-export([init/3]).
-export([
		 do_enter_map/7, do_exit_map/6, do_move/4, do_broadcast/1, 
         do_team_exit/0, regist_map_name/4, kick_all/0
         % do_broadcast_range/2, 
		]).

%% -export([calc_range/1, check_pos_range/2, check_same_cell/2]).
-export([record_map_player/1, record_map_player/3, record_map_player/4]).
%% 普通场景切磋
-export([request_pk/2, reply_pk/3, pk_start_cb/2]).
%%
%% API Functions
%%
%% 初始化Map数据
init(_MapId, MapType, Param) ->
	put(user_id_list, []),
    put(monster_id_list, []),
	{Handler, Data}	=
		case get_map_handler(MapType) of
			?null -> {?null, ?null};
			HandlerTemp ->
				DataTemp	= HandlerTemp:init_data(Param),
				{HandlerTemp, DataTemp}
		end,
	{?ok, Handler, Data}.

get_map_name(?CONST_MAP_TYPE_BOSS) -> "boss";
get_map_name(?CONST_MAP_TYPE_CITY) -> "city";
get_map_name(?CONST_MAP_TYPE_COLLECT) -> "collect";
get_map_name(?CONST_MAP_TYPE_GATHER) -> "gather";
get_map_name(?CONST_MAP_TYPE_GUARD) -> "guard";
get_map_name(?CONST_MAP_TYPE_GUILD) -> "guild";
get_map_name(?CONST_MAP_TYPE_SPRING) -> "spring";
get_map_name(?CONST_MAP_TYPE_MCOPY) -> "multicopy";
get_map_name(?CONST_MAP_TYPE_CAMP_PVP) -> "camp_pvp";
get_map_name(_MapType) -> "".

%% 注册个名 -- 因为原子量太大了，所以只好屏蔽掉
regist_map_name(MapId, Type, Pid, _Param) ->
    NameAtom = get_map_name(Type),
    ListPid  = pid_to_list(Pid),
    MapName  = lists:concat(["map_", NameAtom, "_", MapId, "_", ListPid]),
    MapNameAtom = misc:list_to_atom(MapName),
    erlang:register(MapNameAtom, Pid).

%% ets_api:lookup(ets_map_player, 149).
%% 角色进入地图
do_enter_map([{MType, UserId} = UserTuple|List], MapPid, MapId, X, Y, MapType, _Param) ->
	UserIdList	= get(user_id_list),
	UserIdList2	= case lists:member(UserTuple, UserIdList) of
					  ?true -> UserIdList;
					  ?false ->
						  [UserTuple|UserIdList]
				  end,
	put(user_id_list, UserIdList2),
	ets_api:update_element(?CONST_ETS_MAP, MapPid, {3, length(UserIdList2)}),
	% 各种消息通知客户端
	% 把主角广播给地图内其他玩家
	MapPlayer		= ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserTuple),
	PacketEnter 	= map_api:msg_map_enter_player(MapId, MapPlayer, X, Y),

	% 把地图内所有玩家(除自己)发送给主角|把地图内所有怪物数据发送给主角
	F = fun(OtherUserId, Acc) ->
				?MSG_DEBUG("33333333333333333333333333333~p", [OtherUserId]),
				OtherMapPlayer	= ets_api:lookup(?CONST_ETS_MAP_PLAYER, OtherUserId),
				?MSG_DEBUG("33333333333333333333333333333~p", [OtherMapPlayer]),
				Packet = map_api:msg_map_enter_player(MapId, OtherMapPlayer),
				<<Packet/binary, Acc/binary>>
		end,
    PacketPlayer = lists:foldl(F, <<>>, UserIdList),
    if
        MapType == ?CONST_MAP_TYPE_FACTION orelse MapType == ?CONST_MAP_TYPE_CAMP_PVP ->
           do_cross_broadcast(UserIdList2, PacketEnter),
           case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
               [] ->
                   ok;
               [#cross_in{node = NodeFrom}] ->
                   rpc:cast(NodeFrom, misc_packet, send, [UserId, PacketPlayer])
           end;
        MapType == ?CONST_MAP_TYPE_MCOPY orelse MapType == ?CONST_MAP_TYPE_GUARD ->
           do_cross_broadcast(UserIdList2, PacketEnter),
           case ?CONST_MAP_PTYPE_HUMAN =:= MType of
               true ->
                   case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                       [] ->
                           misc_packet:send(UserId, PacketPlayer);
                       [#cross_in{node = NodeFrom}] ->
                           rpc:cast(NodeFrom, misc_packet, send, [UserId, PacketPlayer])
                   end;
               _ ->
                   ?ok
           end;
		MapType == ?CONST_MAP_TYPE_BOSS ->
			?MSG_DEBUG("22", []),
			do_cross_broadcast1(UserIdList2, PacketEnter),
			do_cross_broadcast2(UserId, PacketPlayer);
%% 			case ets:lookup(?CONST_ETS_BOSS_CROSS_IN, UserId) of
%% 				[] ->
%% 					?MSG_DEBUG("22", []),
%% 					ok;
%% 				[#ets_boss_cross_in{node = NodeFrom}] ->
%% 					?MSG_DEBUG("22=~p", [{NodeFrom, UserId}]),
%% 					rpc:cast(NodeFrom, misc_packet, send, [UserId, PacketPlayer])
%% 			end;
        ?true ->
			?MSG_DEBUG("222222222222222", []),
           do_broadcast(UserIdList2, PacketEnter),
           if
               ?CONST_MAP_PTYPE_HUMAN =:= MType ->
                   misc_packet:send(UserId, PacketPlayer);
               is_atom(MType) ->
                   rpc:cast(MType, misc_packet, send, [UserId, PacketPlayer]);
               ?true ->
                   ?ok
           end
    end,
	do_enter_map(List, MapPid, MapId, X, Y, MapType, _Param);
do_enter_map([], _MapPid, _MapId, _X, _Y, _MapType, _Param) -> ?ok.

%% %% 人数+1
%% map_count_plus(MapPid) ->
%%     {_, _Mapid, Count} = ets_api:lookup(?CONST_ETS_MAP, MapPid),
%%     ets_api:update_element(?CONST_ETS_MAP, MapPid, {3, Count + 1}).
%% 
%% %% 人数-1
%% map_count_minus(MapPid) ->
%%     {_, _Mapid, Count} = ets_api:lookup(?CONST_ETS_MAP, MapPid),
%%     ets_api:update_element(?CONST_ETS_MAP, MapPid, {3, Count - 1}).

%% 角色离开地图
do_exit_map(UserId, MapPid, MapId, ?CONST_MAP_TYPE_BOSS, _Param, _MType) ->
	UserIdList	= get(user_id_list),
	UserIdList2 = lists:keydelete(UserId, 2, UserIdList),
	put(user_id_list, UserIdList2),
	Packet = map_api:msg_map_exit_player(MapId, UserId, 1),
	do_cross_broadcast1(UserIdList2, Packet),
    ets_api:update_element(?CONST_ETS_MAP, MapPid, {3, length(UserIdList2)});
do_exit_map(UserId, MapPid, MapId, MapType, _Param, _MType) ->
	UserIdList	= get(user_id_list),
	UserIdList2 = lists:keydelete(UserId, 2, UserIdList),
	put(user_id_list, UserIdList2),
    case MapType == ?CONST_MAP_TYPE_CAMP_PVP of
        true ->
            case camp_pvp_mod:check_camp_open() of
                false ->
                    ok;
                _ ->
                    camp_pvp_api:exit_camp_pvp_map(UserId)
            end;
        false ->
            ok
    end,
	Packet = map_api:msg_map_exit_player(MapId, UserId, 1),
	do_cross_broadcast(UserIdList2, Packet),
    ets_api:update_element(?CONST_ETS_MAP, MapPid, {3, length(UserIdList2)}).

%% 队伍离开地图
do_team_exit() ->
    UserIdList = get(user_id_list),
    F = fun(UserId) ->
            player_api:process_send(UserId, map_api, enter_map_cb, 0)
        end,
    lists:foreach(F, UserIdList).

%% 角色移动
do_move(UserId, PacketMove, MType, MapId) ->
	RecMap 		= map_api:read_map_info(MapId),
	UserIdList	= get(user_id_list),
	UserIdList2	= lists:delete({MType, UserId}, UserIdList),
	?MSG_DEBUG("UserIdList2=~p, UserIdList=~p", [UserIdList2, UserIdList]),
	case RecMap#rec_map.type of
		?CONST_MAP_TYPE_BOSS ->
			do_cross_broadcast1(UserIdList2, PacketMove);
		_ ->
			do_cross_broadcast(UserIdList2, PacketMove)
	end.

%% 地图广播
do_broadcast(Packet) ->
	UserIdList	= get(user_id_list),
	if length(UserIdList) >= 30 -> spawn(fun() -> do_broadcast(UserIdList, Packet) end);
	   ?true -> do_broadcast(UserIdList, Packet)
	end.
do_broadcast([{?CONST_MAP_PTYPE_HUMAN, UserId}|UserIdList], Packet) ->
	case ets_api:lookup(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_HUMAN, UserId}) of
		?null -> ?ok; 
		MapPlayer ->
            case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                [] ->
					?MSG_DEBUG("22", []),
					case ets_api:lookup(?CONST_ETS_BOSS_CROSS_IN, UserId) of
						?null -> misc_packet:send(MapPlayer#map_player.user_id, Packet);
						#ets_boss_cross_in{node = Node} ->
							?MSG_DEBUG("333333333333333", []),
							 rpc:cast(Node, misc_packet, send, [MapPlayer#map_player.user_id, Packet])
					end;
                [#cross_in{node = Node}] ->
					?MSG_DEBUG("22", []),
                    rpc:cast(Node, misc_packet, send, [MapPlayer#map_player.user_id, Packet])
            end
	end,
	do_broadcast(UserIdList, Packet);
do_broadcast([{_, _UserId}|UserIdList], Packet) -> % 不发包给机器人
	do_broadcast(UserIdList, Packet);
%% do_broadcast([UserId|UserIdList], Packet) ->
%% 	case ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserId) of
%% 		?null -> ?ok; 
%% 		MapPlayer -> misc_packet:send(MapPlayer#map_player.user_id, Packet)
%% 	end,
%% 	do_broadcast(UserIdList, Packet);
do_broadcast([], _Packet) -> ?ok.


do_cross_broadcast([{?CONST_MAP_PTYPE_HUMAN, UserId} = UserTuple|UserIdList], Packet) ->
    case ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserTuple) of
        ?null -> ?ok;
        MapPlayer -> 
            case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                [] ->
                    misc_packet:send(MapPlayer#map_player.user_id, Packet);
                [Rec] ->
                    NodeFrom = Rec#cross_in.node,
                    rpc:cast(NodeFrom, misc_packet, send, [UserId, Packet])
            end
    end,
    do_cross_broadcast(UserIdList, Packet);
do_cross_broadcast([_|UserIdList], Packet) ->
    do_cross_broadcast(UserIdList, Packet);
do_cross_broadcast([], _Packet) -> ?ok.

do_cross_broadcast1([{?CONST_MAP_PTYPE_HUMAN, UserId} = UserTuple|UserIdList], Packet) ->
    case ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserTuple) of
        ?null -> ?ok;
        MapPlayer -> 
            case ets:lookup(?CONST_ETS_BOSS_CROSS_IN, UserId) of
                [] ->
					?MSG_DEBUG("~n 444444444444444444444=~p", [{UserId}]),
                    misc_packet:send(MapPlayer#map_player.user_id, Packet);
                [Rec] ->
                    NodeFrom = Rec#ets_boss_cross_in.node,
					?MSG_DEBUG("~n 444444444444444444444=~p", [{NodeFrom, UserId}]),
                    rpc:cast(NodeFrom, misc_packet, send, [UserId, Packet])
            end
    end,
    do_cross_broadcast1(UserIdList, Packet);
do_cross_broadcast1([_|UserIdList], Packet) ->
    do_cross_broadcast1(UserIdList, Packet);
do_cross_broadcast1([], _Packet) -> ?ok.

do_cross_broadcast2(UserId, PacketPlayer) ->
	case ets:lookup(?CONST_ETS_BOSS_CROSS_IN, UserId) of
		[] ->
			?MSG_DEBUG("22", []),
			?ok;
		[#ets_boss_cross_in{node = NodeFrom}] ->
			case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
				#boss_player{robot = Robot} when Robot == ?false ->
					?MSG_DEBUG("22=~p", [{NodeFrom, UserId}]),
					rpc:cast(NodeFrom, misc_packet, send, [UserId, PacketPlayer]);
				_ ->
					?MSG_DEBUG("55555555555555555555555555555555555555", []),
					?ok
			end
	end.

%% %% 地图可视区域广播
%% do_broadcast_range(Packet, {Min, Max}) ->
%% 	UserIdList	= get(user_id_list),
%% 	do_broadcast_range(UserIdList, Packet, {Min, Max});
%% do_broadcast_range(UserId, Packet) ->
%% 	MapPlayer	= ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserId),
%% 	Range 		= calc_range(MapPlayer#map_player.x),
%% 	do_broadcast_range(Packet, Range).
%% do_broadcast_range([UserId|UserIdList], Packet, Range) ->
%% 	case ets_api:lookup(?CONST_ETS_MAP_PLAYER, UserId) of
%% 		?null -> ?ok;
%% 		MapPlayer ->
%% 			case check_pos_range(MapPlayer#map_player.x, Range) of
%% 				?true -> misc_packet:send(MapPlayer#map_player.user_id, Packet);
%% 				?false -> ?ok
%% 			end
%% 	end,
%% 	do_broadcast_range(UserIdList, Packet, Range);
%% do_broadcast_range([], _Packet, _Range) -> ?ok.

%%
%% Local Functions
%%
%% 
%% calc_range(X) -> % 一屏
%% 	XTemp = X div ?CONST_SYS_CELL_WIDTH * ?CONST_SYS_CELL_WIDTH,
%% 	{XTemp - ?CONST_SYS_CELL_WIDTH, XTemp + ?CONST_SYS_CELL_WIDTH * 2}.
%% check_pos_range(X, {XMin, XMax}) ->
%% 	if X >= XMin andalso X =< XMax -> ?true;
%% 	   ?true -> ?false
%% 	end.
%% check_same_cell(X1, X2) ->
%% 	SX1 = X1 div ?CONST_SYS_CELL_WIDTH,
%% 	SX2 = X2 div ?CONST_SYS_CELL_WIDTH,
%% 	if SX1 =:= SX2 -> ?true;
%% 	   ?true -> ?false
%% 	end.

record_map_player(Player) ->
	MapData = Player#player.maps,
	CurMapInfo = MapData#map_data.cur,
	record_map_player(Player, CurMapInfo#map_info.x, CurMapInfo#map_info.y).
record_map_player(Player, X, Y) ->
	record_map_player(Player, X, Y, ?CONST_MAP_PTYPE_HUMAN).
record_map_player(Player, X, Y, MapPType) ->
    Soul = Player#player.partner_soul,
    StarLv = Soul#partner_soul.star_lv,
	Info		= Player#player.info,
	HideFashion	= goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
	SkinFashion	= goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),  
	SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
	SkinWeapon	= goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),  
	HideRide	= goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
	SkinRide    = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_HORSE),
	Title		= Info#info.current_title,
	PositionId	= 
		case player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION) of
			?true ->
				PositionData = Player#player.position,
				PositionData#position_data.position;
			?false ->
				0
		end,
	UserState	= Player#player.user_state,
	PracState   = Player#player.practice_state,
	%%     UserState2  =
	%%         if
	%%             ?CONST_PLAYER_STATE_NORMAL =/= PracState ->
	%%                 PracState;
	%%             ?true ->
	%%                 UserState
	%%         end,
	Guild		= Player#player.guild,
	{_, GuildLv}= guild_api:get_guild_lv(Guild#guild.guild_id),
	PartnerData	= Player#player.partner,
	FollowId	= PartnerData#partner_data.follow_id,
	VipHide		= goods_style_api:get_cur_style(Player, ?CONST_GOODS_ATTR_VIP),
	#map_player{
				key                = {MapPType, Player#player.user_id}, % key
				user_id            = Player#player.user_id,				% 玩家Id
				user_name          = Info#info.user_name,         		% 昵称
				pro                = Info#info.pro,            			% 职业
				sex                = Info#info.sex,            			% 性别
				lv                 = Info#info.lv,            			% 等级
				vip                = player_api:get_vip_lv(Info),       % VIP
				state              = Player#player.state,            	% 状态
				leader             = Player#player.leader,            	% 队伍队长user_id
				
				x                  = X,            						% X坐标
				y                  = Y,            						% Y坐标
				
				skin_fashion	   = SkinFashion,   			      	% 装备武器特效
				skin_weapon        = SkinWeapon,         	            % 装备武器皮肤ID
				skin_armor         = SkinArmor,          	            % 装备衣服皮肤ID
				skin_ride          = SkinRide,           				% 坐骑皮肤ID
				hide_fashion	   = HideFashion,						% 隐藏时装
				hide_ride          = HideRide,         					% 隐藏坐骑
				title              = Title,                             % 称号
				guild_name         = Guild#guild.guild_name,            % 军团名称 
				guild_id           = Guild#guild.guild_id,              % 军团id
				guild_lv           = GuildLv,                           % 军团等级
				position           = PositionId,                        % 官衔id
				user_state         = UserState,                         % 玩家状态
				practice_state     = PracState,
				follow_id		   = FollowId,							% 跟随武将
				vip_hide		   = VipHide,							% vip等级隐藏标识
                star_lv =            StarLv
			   }.


get_map_handler(?CONST_MAP_TYPE_MCOPY) 		-> mcopy_api;		% 地图类型--多人副本
get_map_handler(_)    -> ?null.

%% 普通地图邀请pk
request_pk(#player{user_id = UserId, info = Info, play_state = PlayerState, user_state = UserState, maps = Maps, net_pid = NetPid}, MemId) ->
	try
		?ok			= check_user_play_state(PlayerState),
		?ok			= check_user_pk_state(UserState),
		MapId		= (Maps#map_data.cur)#map_info.map_id,
		IsDoll =
			case MapId =:= ?CONST_GUILD_PARTY_MAP of
				?true ->
					party_mod:is_doll(MemId);
				?false ->
					practice_mod:is_doll(MemId)
			end,
		case IsDoll of
			?true ->
				?ok;
			?false ->
				{?ok, TUserState, TPlayState, TMaps} = get_mem_player(MemId),
				?ok			= check_mem_pk_state(TUserState),
				?ok			= check_mem_play_state(TPlayState),
				?ok			= check_map_id((Maps#map_data.cur)#map_info.map_id, (TMaps#map_data.cur)#map_info.map_id),
				Packet		= map_api:msg_sc_invite_pk(UserId, Info#info.user_name),
				misc_packet:send(MemId, Packet)
		end,
		Packet2		= message_api:msg_notice(?TIP_MAP_INVITE_SUCCESS),
		misc_packet:send(NetPid, Packet2)
	catch
		throw:{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode), 
			misc_packet:send(NetPid, TipPacket);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Stacktrace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

check_user_play_state(?CONST_PLAYER_PLAY_CITY) -> ?ok;
check_user_play_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_user_play_state(_) ->
	throw({?error, ?TIP_MAP_IN_OTHER_PLAY}).

check_mem_play_state(?CONST_PLAYER_PLAY_CITY) -> ?ok;
check_mem_play_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_mem_play_state(_) ->
	throw({?error, ?TIP_MAP_IN_OTHER_PLAY}).

check_user_pk_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_user_pk_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_user_pk_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) -> ?ok;
check_user_pk_state(_) ->
	throw({?error, ?TIP_PARTY_USER_NOT_PK}).

check_mem_pk_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_mem_pk_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_mem_pk_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) -> ?ok;
check_mem_pk_state(_) ->
	throw({?error, ?TIP_PARTY_MEM_NOT_PK}). 

check_map_id(MapId, MapId) -> ?ok;
check_map_id(_Id1, _Id2) ->
	throw({?error, ?TIP_MAP_NOT_IN_SAME_MAP}).

%% 获取对方的玩家信息
get_mem_player(MemId) ->
	case player_api:check_online(MemId) of
		?true -> 
			case player_api:get_player_fields(MemId, [#player.user_state,#player.play_state,#player.maps]) of
				{?ok, [UserState, PlayState, Maps]} ->
					{?ok, UserState, PlayState, Maps};
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end;
		?false ->
			throw({?error, ?TIP_COMMON_OFF_LINE})
	end.

%% 普通地图回复邀请
reply_pk(Player, MemId, ?CONST_SYS_FALSE) ->
	TipPacket = message_api:msg_notice(?TIP_MAP_REJECT_PK_INVITE), 
	misc_packet:send(MemId, TipPacket),
	{?ok, Player};
reply_pk(#player{play_state = PlayState, user_state = UserState, maps = Maps, net_pid = NetPid} = Player, MemId, ?CONST_SYS_TRUE) ->
	try
		?ok			= check_user_play_state(PlayState),
		?ok			= check_user_pk_state(UserState),
		{?ok, TUserState, TPlayState, TMaps} = get_mem_player(MemId),
		?ok			= check_mem_pk_state(TUserState), 
 		?ok			= check_mem_play_state(TPlayState),
		?ok			= check_map_id((Maps#map_data.cur)#map_info.map_id, (TMaps#map_data.cur)#map_info.map_id),
		pk_battle_start(Player, MemId)
	catch
		throw:{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode), 
			misc_packet:send(NetPid, TipPacket);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Stacktrace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

pk_battle_start(Player,Id)  ->
	case battle_api:start(Player, Id, #param{battle_type = ?CONST_BATTLE_GENERAL_MAP}) of
		{?ok, Player2} ->
			player_api:process_send(Id, ?MODULE, pk_start_cb, []),
			{?ok, Player2};
		{?error, ErrorCode} -> 
			{?error, ErrorCode}
	end.

pk_start_cb(Player, []) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_FIGHTING) of
		 {?true, NewPlayer} ->
			 {?ok, NewPlayer};
		_ ->
			Player2 = Player#player{user_state = ?CONST_PLAYER_STATE_FIGHTING},
			map_api:change_user_state(Player2),
			{?ok, Player2}
	end.

kick_all() ->
    L = get(user_id_list),
    [player_serv:return_city(UserId)||{?CONST_MAP_PTYPE_HUMAN, UserId}<-L],
    ok.