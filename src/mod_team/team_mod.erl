%% Author: cobain
%% Created: 2012-11-5
%% Description: TODO: Add description to team_mod
-module(team_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([do_create/5, do_join/3, do_remove/3, do_quit/4, do_change_leader/4, do_invite/3,do_invite2/3,insert_member_to_team2/2,insert_member_to_team3/2,
		 do_reply/5, do_set_camp/3, do_set_camp_pos/4, do_set_team_state/3, do_set_team_param/3,insert_member_to_team/2,
		 do_play_start/2, do_play_over/2, do_quick_join/3, do_lock_and_unlock/3]).
-export([check_camp/2, check_team_exist/2, check_team_num/1,change_team/4, broad_delete_team2/3,broad_delete_team/3,
		 check_have_team/2, check_team_invited/2, check_leader/2, do_gold_invite2/3,
		 check_member/2, check_team_state/1, check_member_state/3,
		 check_password/2]).
-export([record_team_player/2, record_team_hall/1]).
%%
%% API Functions
%%
do_create(TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam) ->
    put(team_id, TeamId),
    put(team_type, TeamType),
	TeamParam2	= get_team_param(TeamType, TeamParam),
	TeamTmp		= #team{
						team_id 			= TeamId,							% 队伍ID
						team_pid			= self(),							% 队伍进程ID
						type              	= TeamType,     					% 队伍类型
						state				= ?CONST_TEAM_STATE_WAIT,     		% 队伍状态
						lock				= <<"">>,							% 加锁密码
						operate_mode		= ?CONST_TEAM_OPERATE_MODE_LEADER,	% 队伍操作模式(用于切换地图1:队长操作|2:成员操作)
						count		    	= 0, 								% 队伍人数
						count_max	    	= TeamParam2#team_param.count_max,	% 队伍人数上限
						leader_uid        	= TeamPlayer#team_player.uid,   	% 队长ID
						leader_name			= TeamPlayer#team_player.name,  	% 队长名称
						leader_pro        	= TeamPlayer#team_player.pro,   	% 队长职业
						leader_sex        	= TeamPlayer#team_player.sex,   	% 队长性别
						leader_lv         	= TeamPlayer#team_player.lv,    	% 队长等级
						camp              	= TeamCamp,     					% 阵型#camp{}
						param             	= TeamParam2	    				% 队伍参数#team_param{}
					   },
	case insert_member_to_team(TeamTmp, TeamPlayer) of
		{?ok, Team} ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
			}	= team_api:team_ets(TeamType),
			ets_api:insert(EtsTeamInfo, Team),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

get_team_param(_,TeamParam) ->
	TeamParam.

do_join(TeamId, TeamType, TeamPlayer) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case check_join(TeamId, TeamPlayer, EtsTeamInfo, EtsTeamPlayer) of
		{?ok, Team} ->
            {ok, Team11} = delete_member_from_team(Team, TeamPlayer#team_player.uid),
			case insert_member_to_team(Team11, TeamPlayer) of
				{?ok, Team2} ->
					ets_api:insert(EtsTeamInfo, Team2),
					?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
check_join(TeamId, TeamPlayer, EtsTeamInfo, EtsTeamPlayer) ->
	try
		{?ok, Team}	= check_team_exist(EtsTeamInfo, TeamId),
		?ok			= check_team_state(Team),
        case is_author(Team, TeamPlayer#team_player.uid) of
            false ->
		      ?ok			= check_team_num(Team);
            _ ->
                ok
        end,

		case check_have_team(EtsTeamPlayer, TeamPlayer#team_player.uid) of
			{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
			{?false, ?null} -> {?ok, Team}
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.


do_remove(TeamId, TeamType, UserId) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case check_remove(TeamId, UserId, EtsTeamInfo) of
		{?ok, Team} ->
			{?ok, Team2}	= delete_member_from_team(Team, UserId),
			ets_api:insert(EtsTeamInfo, Team2),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
check_remove(TeamId, UserId, EtsTeamInfo) ->
	try
		{?ok, Team}	= check_team_exist(EtsTeamInfo, TeamId),
		?ok			= check_member(Team, UserId),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.


is_cross(Team, Id) ->
    lists:keyfind(Id, #team_player.uid, Team#team.cross_list).

broad_delete_team2(EtsTeamPlayer, UserId, Packet) ->
    ets_api:delete(EtsTeamPlayer, UserId),
    team_api:update_player_team(UserId, {0,0}),
    misc_packet:send(UserId, Packet).

broad_delete_team(Team, EtsTeamPlayer, Packet) ->
    CrossList = Team#team.cross_list,
    Fun =
        fun(TeamPlayer) ->
                IndexFrom = TeamPlayer#team_player.index_from,
                NodeFrom = cross_api:get_node(IndexFrom),
                rpc:cast(NodeFrom, ?MODULE, broad_delete_team2, [EtsTeamPlayer, TeamPlayer#team_player.uid, Packet])
        end,
    lists:foreach(Fun, CrossList).
                

do_quit(TeamId, TeamType, UserId, Packet18540) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	{?ok, Team}	= team_api:get_team(EtsTeamInfo, TeamId),
	case select_team_leader(Team, EtsTeamPlayer, UserId) of
		{?ok, ?null} -> % 解散队伍
			ets_api:delete(EtsTeamInfo, TeamId),
			% 通知玩家退出队伍
			Packet18526 = team_api:msg_sc_quit_notice(2),
            broad_delete_team(Team, EtsTeamPlayer, <<Packet18526/binary, Packet18540/binary>>),
			misc_packet:send(UserId, <<Packet18526/binary, Packet18540/binary>>),
			% 大厅广播(协议18512:删除队伍通知)
			Packet18512	= team_api:msg_sc_team_delete_notice(TeamId),
			Packet		= <<Packet18512/binary>>,
			team_api:broadcast_hall(TeamType, Packet, EtsTeamHall),
			team_api:update_player_team(Team, 0, 0),
			?stop;
		{?ok, NewLeaderId} ->% 不解散队伍
			Team2	=
				case Team#team.leader_uid of
					UserId -> % 换队长后退出
						Camp	= camp_api:read_camp((Team#team.camp)#camp.camp_id, (Team#team.camp)#camp.lv),
                        case is_cross(Team, NewLeaderId) of
                            false ->
                                do_change_leader_ext(EtsTeamInfo, EtsTeamPlayer, Team, NewLeaderId, Camp);
                            _ ->
                                do_change_leader_ext_cross(EtsTeamInfo, EtsTeamPlayer, Team, NewLeaderId, Camp)
                        end;
					_ -> Team % 直接退出
				end,
			{?ok, Team3}	= delete_member_from_team(Team2, UserId),
			ets_api:insert(EtsTeamInfo, Team3),
            Packet18526 = team_api:msg_sc_quit_notice(2),
            case is_cross(Team, UserId) of
                TeamPlayer when is_record(TeamPlayer, team_player) ->
                    IndexFrom = TeamPlayer#team_player.index_from,
                    NodeFrom = cross_api:get_node(IndexFrom),
                    rpc:cast(NodeFrom, team_api, update_player_team, [UserId, {0, 0}]),
                    rpc:cast(NodeFrom, misc_packet, send, [UserId, <<Packet18526/binary, Packet18540/binary>>]);
                _ ->
                     misc_packet:send(UserId, <<Packet18526/binary, Packet18540/binary>>)
            end,
             
             team_api:update_player_team(Team3, TeamId, Team3#team.leader_uid),
			% 队伍广播队伍详细信息(协议18530:队伍详细信息)
			PacketTeam	= team_api:msg_sc_info(Team3, EtsTeamPlayer),
			team_api:broadcast_team(Team3, PacketTeam),
			% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
			Packet18510	= team_api:msg_sc_team_insert_notice(Team3),
			team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
			?ok;
		Any ->% 未知错误解散队伍
			?MSG_ERROR("Any:~p Team:~p", [Any, Team]),
			ets_api:delete(EtsTeamInfo, TeamId),
			% 通知玩家退出队伍
			Packet18526 = team_api:msg_sc_quit_notice(2),
			misc_packet:send(UserId, <<Packet18526/binary, Packet18540/binary>>),
			% 大厅广播(协议18512:删除队伍通知)
			Packet18512	= team_api:msg_sc_team_delete_notice(TeamId),
			Packet		= <<Packet18512/binary>>,
			team_api:broadcast_hall(TeamType, Packet, EtsTeamHall),
			team_api:update_player_team(Team, 0, 0),
			?stop
	end.


%% 选择新队长
select_team_leader(Team, EtsTeamPlayer, UserId) ->
	List	= misc:to_list((Team#team.camp)#camp.position),
    SortFun=
        fun(T1, T2) ->
                B1 = is_record(T1, camp_pos),
                B2 = is_record(T2, camp_pos),
                if
                    B1 == false ->
                        false;
                    B2 == false ->
                        true;
                    true ->
                        Id1 = T1#camp_pos.id,
                        case is_cross(Team, Id1) of
                            false ->
                                true;
                            _ ->
                                false
                        end
                end
        end,
    List2 = lists:sort(SortFun, List),
	select_team_leader2(Team, List2, UserId, EtsTeamPlayer, ?null).

select_team_leader2(Team, [#camp_pos{id = UserIdTemp}|List], UserId, EtsTeamPlayer, AccUserId)
  when UserIdTemp =/= UserId ->
	case ets_api:lookup(EtsTeamPlayer, UserIdTemp) of
		#team_player{} -> 
            case lists:keymember(UserIdTemp, #team_player.uid, Team#team.author_list)  of
                false ->
                    {?ok, UserIdTemp};
                _ ->
                    select_team_leader2(Team, List, UserId, EtsTeamPlayer, AccUserId)
            end;
		_ ->
            case is_cross(Team, UserIdTemp) of
                false ->
                    select_team_leader2(Team, List, UserId, EtsTeamPlayer, AccUserId);
                _ ->
                    case Team#team.state of
                        ?CONST_TEAM_STATE_WAIT ->
                            select_team_leader2(Team, List, UserId, EtsTeamPlayer, AccUserId);
                        _ ->
                            {?ok, UserIdTemp}
                    end
            end
	end;
select_team_leader2(Team, [_CampPos|List], UserId, EtsTeamPlayer, AccUserId) ->
	select_team_leader2(Team, List, UserId, EtsTeamPlayer, AccUserId);
select_team_leader2(_Team, [], _UserId, _EtsTeamPlayer, _AccUserId) -> {?ok, ?null}.% 选不出新队长，解散队伍

%% %% 选择新队长
%% select_team_leader(Team, UserId) ->
%% 	List	= misc:to_list((Team#team.camp)#camp.position),
%% 	select_team_leader2(List, UserId, ?null).
%% 
%% select_team_leader2([#camp_pos{id = UserIdTemp} = CampPos|List], UserId, AccUserId)
%%   when UserIdTemp =/= UserId ->
%% 	CampTemp	= camp_api:get_curent_camp(UserIdTemp),
%% 	case check_camp(CampTemp, 3) of
%% 		?ok ->
%% 			Camp	= camp_api:read_camp(CampTemp#camp.camp_id, CampTemp#camp.lv),
%% 			{?ok, UserIdTemp, Camp};
%% 		_ ->
%% 			AccUserId2	= case AccUserId of ?null -> CampPos#camp_pos.id; _ -> AccUserId end,
%% 			select_team_leader2(List, UserId, AccUserId2)
%% 	end;
%% select_team_leader2([_CampPos|List], UserId, AccUserId) ->
%% 	select_team_leader2(List, UserId, AccUserId);
%% select_team_leader2([], _UserId, AccUserId) -> {?ok, AccUserId, ?null}.% 不是队伍成员


%% 检查阵型位置总数是否大于N
%% check_camp(#camp{camp_id = CampId, lv = Lv}, N) ->
%% 	Count	= camp_api:camp_position_count(CampId, Lv),
%% 	if Count >= N -> ?ok; ?true -> {?error, ?TIP_TEAM_POSITION_COUNT_LESS} end;
%% check_camp(_Camp, _N) -> {?error, ?TIP_TEAM_POSITION_COUNT_LESS}.



do_change_leader(TeamId, TeamType, UserId, Camp) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case check_change_leader(TeamId, UserId, EtsTeamInfo) of
		{?ok, Team} ->
			case get_team_member(Team, UserId) of
				{?ok, _CampPos} ->
					Team2	= 
                        case is_cross(Team, UserId) of
                            false ->
                                do_change_leader_ext(EtsTeamInfo, EtsTeamPlayer, Team, UserId, Camp);
                            _ ->
                                do_change_leader_ext_cross(EtsTeamInfo, EtsTeamPlayer, Team, UserId, Camp)
                        end,
					team_api:update_player_team(Team2, Team2#team.team_id, Team2#team.leader_uid),
					% 大厅广播(协议18510:插入队伍信息)
					Packet18510	= team_api:msg_sc_team_insert_notice(Team2),
					team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
					?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

get_node_from(TeamPlayer) ->
    cross_api:get_node(TeamPlayer#team_player.index_from).

do_change_leader_ext_cross(EtsTeamInfo, EtsTeamPlayer, Team, UserId, Camp) ->
    remove_invite(Team#team.team_id, Team#team.invite),                 % 移除前任队长的邀请
    TeamPlayer  =lists:keyfind(UserId, #team_player.uid, Team#team.cross_list),
    State       = case TeamPlayer#team_player.state of
                      ?CONST_TEAM_PLAYER_STATE_WAIT -> ?CONST_TEAM_PLAYER_STATE_READY;
                      _ -> TeamPlayer#team_player.state
                  end,
    TeamPlayer2 = TeamPlayer#team_player{state = State},
    Node = get_node_from(TeamPlayer2),
    rpc:cast(Node, ets_api, insert, [EtsTeamPlayer, TeamPlayer2]),
    Team2       = Team#team{
                            count       = 0,                            % 队伍人数
                            leader_uid  = TeamPlayer#team_player.uid,   % 队长ID
                            leader_name = TeamPlayer#team_player.name,  % 队长名称
                            leader_pro  = TeamPlayer#team_player.pro,   % 队长职业
                            leader_sex  = TeamPlayer#team_player.sex,   % 队长性别
                            leader_lv   = TeamPlayer#team_player.lv,    % 队长等级
                            camp        = Camp,                         % #camp{},
                            invite      = [],
                            cross_list = Team#team.cross_list
                           },
    TeamPlayers = get_team_players(EtsTeamPlayer, Team),
    Team3       = init_camp(Team2, TeamPlayers),
    ets_api:insert(EtsTeamInfo, Team3),
    % 队伍广播队伍详细信息(协议18530:队伍详细信息)
    PacketTeam  = team_api:msg_sc_info(Team3, EtsTeamPlayer),
    PacketNotice= message_api:msg_notice(?TIP_TEAM_CHANGE_LEADER_NOTICE,
                                         [{Team3#team.leader_uid, Team3#team.leader_name}], [], []),
    team_api:broadcast_team(Team3, <<PacketTeam/binary, PacketNotice/binary>>),
    Team3.

do_change_leader_ext(EtsTeamInfo, EtsTeamPlayer, Team, UserId, Camp) ->
	remove_invite(Team#team.team_id, Team#team.invite),					% 移除前任队长的邀请
	TeamPlayer	= 
        case ets_api:lookup(EtsTeamPlayer, UserId) of
            null ->
                lists:keyfind(UserId, #team_player.uid, Team#team.cross_list);
            TeamP ->
                TeamP
        end,
	State		= case TeamPlayer#team_player.state of
					  ?CONST_TEAM_PLAYER_STATE_WAIT -> ?CONST_TEAM_PLAYER_STATE_READY;
					  _ -> TeamPlayer#team_player.state
				  end,
	TeamPlayer2	= TeamPlayer#team_player{state = State},
	ets_api:insert(EtsTeamPlayer, TeamPlayer2),
	Team2		= Team#team{
							count		= 0, 							% 队伍人数
							leader_uid 	= TeamPlayer#team_player.uid,	% 队长ID
							leader_name	= TeamPlayer#team_player.name,	% 队长名称
							leader_pro  = TeamPlayer#team_player.pro,   % 队长职业
							leader_sex  = TeamPlayer#team_player.sex,   % 队长性别
							leader_lv   = TeamPlayer#team_player.lv,	% 队长等级
							camp        = Camp,       					% #camp{},
							invite		= []
						   },
    case Team2#team.state == ?CONST_TEAM_STATE_START of
        true ->
            Team3 = Team2;
        _ ->
            Team3 = Team2#team{author_list = []}
    end,
	TeamPlayers	= get_team_players(EtsTeamPlayer, Team),
	Team4		= init_camp(Team3, TeamPlayers),
	ets_api:insert(EtsTeamInfo, Team4),
	% 队伍广播队伍详细信息(协议18530:队伍详细信息)
	PacketTeam	= team_api:msg_sc_info(Team4, EtsTeamPlayer),
	PacketNotice= message_api:msg_notice(?TIP_TEAM_CHANGE_LEADER_NOTICE,
										 [{Team4#team.leader_uid, Team4#team.leader_name}], [], []),
	team_api:broadcast_team(Team4, <<PacketTeam/binary, PacketNotice/binary>>),
	Team4.
check_change_leader(TeamId, UserId, EtsTeamInfo) ->
	try
		{?ok, Team}	= check_team_exist(EtsTeamInfo, TeamId),
		?ok			= check_member1(Team, UserId),
		{?ok, Team}
	catch
		throw:{?error, ?TIP_TEAM_NO_CAMP} -> {?error, ?TIP_TEAM_NO_CAMP_CHANGE_LEADER};
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.

remove_invite(TeamId, InviteList) ->
	Packet	= team_api:msg_sc_remove_invite(TeamId),
	[misc_packet:send(UserId, Packet) || UserId <- InviteList],
	?ok.

do_invite2(TeamId, TeamType, UserId) ->
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
    }           = team_api:team_ets(TeamType),
    case team_api:check_invite2(TeamId, UserId, EtsTeamInfo, EtsTeamPlayer, TeamType) of
        {?ok, _Team} ->
            ?ok;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

do_gold_invite2(TeamId, TeamType, UserId) ->
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
    }           = team_api:team_ets(TeamType),
    case team_api:check_invite_gold(TeamId, UserId, EtsTeamInfo, EtsTeamPlayer, TeamType) of
        {?ok, _Team} ->
            ?ok;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.



do_invite(TeamId, TeamType, UserId) ->
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
    }           = team_api:team_ets(TeamType),
    case check_invite(TeamId, UserId, EtsTeamInfo, EtsTeamPlayer) of
        {?ok, Team} ->
            case lists:member(UserId, Team#team.invite) of
                ?true -> {?error, ?TIP_TEAM_REPEAT_INVITE};
                ?false ->
                    Team2   = Team#team{invite = [UserId|Team#team.invite]},
                    ets_api:insert(EtsTeamInfo, Team2),
                    ?ok
            end;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

check_invite(TeamId, UserId, EtsTeamInfo, EtsTeamPlayer) ->
	try
		case team_mod:check_have_team(EtsTeamPlayer, UserId) of
			{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_PLAYER_ALREADY_IN_TEAM};
			{?false, ?null} ->
				{?ok, Team}	= check_team_exist(EtsTeamInfo, TeamId),
				?ok			= check_team_state(Team),
				?ok			= check_team_num(Team),
				{?ok, Team}
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.


do_reply(TeamId, TeamType, UserId, TeamPlayer, Flag) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Invite	= lists:delete(UserId, Team#team.invite),
			Team2	= Team#team{invite = Invite},
			case do_reply(Team2, TeamPlayer, EtsTeamPlayer, Flag) of
				{?ok, Team3} -> ets_api:insert(EtsTeamInfo, Team3), ?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
do_reply(Team, TeamPlayer, EtsTeamPlayer, ?true) ->
	ets_api:insert(EtsTeamPlayer, TeamPlayer),
    {ok, Team11} = delete_member_from_team(Team, TeamPlayer#team_player.uid),
	case insert_member_to_team(Team11, TeamPlayer) of
		{?ok, Team2} -> {?ok, Team2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
do_reply(Team, _TeamPlayer, _EtsTeamPlayer, ?false) ->
	{?ok, Team}.

do_set_camp(TeamId, TeamType, Camp) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			TeamPlayers	= get_team_players2(EtsTeamPlayer, Team),
			Team2		= init_camp(Team#team{count = 0, camp = Camp}, TeamPlayers),
			ets_api:insert(EtsTeamInfo, Team2),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_set_camp_pos(TeamId, TeamType, IdxFrom, IdxTo) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			case do_set_camp_pos(Team, IdxFrom, IdxTo) of
				{?ok, Team2} ->
					ets_api:insert(EtsTeamInfo, Team2),
					?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
do_set_camp_pos(Team, IdxFrom, IdxTo) ->
	Camp		= Team#team.camp,
	Position	= Camp#camp.position,
	From		= element(IdxFrom, Position),
	To			= element(IdxTo, Position),
	do_set_camp_pos(Team, Camp, Position, IdxFrom, From, IdxTo, To).

do_set_camp_pos(Team, Camp, Position, IdxFrom, From, IdxTo, ?CONST_SYS_TRUE)
  when is_record(From, camp_pos) ->
	Position2	= setelement(IdxFrom, Position, ?CONST_SYS_TRUE),
	Position3	= setelement(IdxTo, Position2, From#camp_pos{idx = IdxTo}),
	Camp2		= Camp#camp{position = Position3},
	Team2		= Team#team{camp = Camp2},
	{?ok, Team2};
do_set_camp_pos(Team, Camp, Position, IdxFrom, From, IdxTo, To)
  when is_record(From, camp_pos) andalso is_record(To, camp_pos)->
	Position2	= setelement(IdxFrom, Position, To#camp_pos{idx = IdxFrom}),
	Position3	= setelement(IdxTo, Position2, From#camp_pos{idx = IdxTo}),
	Camp2		= Camp#camp{position = Position3},
	Team2		= Team#team{camp = Camp2},
	{?ok, Team2};
do_set_camp_pos(_Team, _Camp, _Position, _IdxFrom, _From, _IdxTo, ?CONST_SYS_FALSE) ->% 位置不可用
	{?error, ?TIP_CAMP_DEST_ILLEGAL};
do_set_camp_pos(_Team, _Camp, _Position, _IdxFrom, _From, _IdxTo, _To) -> {?error, ?TIP_COMMON_BAD_ARG}.% 参数错误

do_set_team_state(TeamId, TeamType, TeamState) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Team2	= Team#team{state = TeamState},
			ets_api:insert(EtsTeamInfo, Team2);
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_set_team_param(TeamId, TeamType, TeamParam) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Team2	= Team#team{param = TeamParam},
			ets_api:insert(EtsTeamInfo, Team2);
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_play_start(TeamId, TeamType) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Team2	= Team#team{state = ?CONST_TEAM_STATE_START, operate_mode = ?CONST_TEAM_OPERATE_MODE_LEADER},
			ets_api:insert(EtsTeamInfo, Team2),
			Packet	= team_api:msg_sc_info(Team2, EtsTeamPlayer),
			team_api:broadcast_team(Team2, Packet),
			Packet18512	= team_api:msg_sc_team_delete_notice(Team2#team.team_id),
            CrossKey = team_api:get_cross_team_key(TeamId),
            ets:delete(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey),
			team_api:broadcast_hall(TeamType, Packet18512, EtsTeamHall),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_play_over(TeamId, TeamType) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Team2	= Team#team{state = ?CONST_TEAM_STATE_WAIT, operate_mode = ?CONST_TEAM_OPERATE_MODE_MEMBER},
            case TeamType == ?CONST_TEAM_TYPE_ARENA of
                true ->
                    ok;
                _ ->
                    CrossKey = team_api:get_cross_team_key(TeamId),
                    ets:insert(?CONST_ETS_TEAM_CROSS_LOCAL, #team_cross{team_type = TeamType, 
                                                                        copy_id = (Team#team.param)#team_param.id, 
                                                                        key = CrossKey, 
                                                                        count = #team.count, 
                                                                        max_count = Team#team.count_max,
                                                                        level = Team#team.avg_lv})
            end,
			ets_api:insert(EtsTeamInfo, Team2),
			Packet	= team_api:msg_sc_info(Team2, EtsTeamPlayer),
			team_api:broadcast_team(Team2, Packet),
			Packet18510	= team_api:msg_sc_team_insert_notice(Team2),
            case is_cross(Team2, Team2#team.leader_uid) of
                false ->
			        team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall);
                _ ->
                    ok
            end,
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_quick_join(TeamId, TeamType, TeamPlayer) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
            ets_api:insert(EtsTeamPlayer, TeamPlayer),
            {ok, Team11} = delete_member_from_team(Team, TeamPlayer#team_player.uid),
            case insert_member_to_team(Team11, TeamPlayer) of
				{?ok, Team2} ->
					ets_api:insert(EtsTeamInfo, Team2),
					?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

do_lock_and_unlock(TeamId, TeamType, Password) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			Team2	= Team#team{lock = Password},
			ets_api:insert(EtsTeamInfo, Team2),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

change_team(TeamId, TeamType, Id, TeamParam) ->
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
    }           = team_api:team_ets(TeamType),
    case team_api:get_team(EtsTeamInfo, TeamId) of
        {?ok, Team} ->
            Param = Team#team.param,
            NewParam = Param#team_param{id = Id, count_max = TeamParam#team_param.count_max},
            Team2   = Team#team{param = NewParam},
            ets_api:insert(EtsTeamInfo, Team2),
            {?ok, Team2};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

init_camp(Team, []) -> Team;
init_camp(Team, TeamPlayers) ->
	{
	 TeamPlayer, TeamPlayers2
	}				= select(TeamPlayers),
	{?ok, Team2}	= insert_member_to_team(Team, TeamPlayer),
	init_camp(Team2, TeamPlayers2).

select([H|T]) ->
	Fun		= fun(TeamPlayer = #team_player{pro = Pro, lv = Lv},
				  AccTeamPlayer = #team_player{pro = AccPro, lv = AccLv}) ->
					  if Pro < AccPro -> TeamPlayer; Pro > AccPro -> AccTeamPlayer;
						 ?true -> if Lv > AccLv -> TeamPlayer; ?true -> AccTeamPlayer end
					  end
			  end,
	E	= lists:foldl(Fun, H, T),
	{E, lists:delete(E, [H|T])}.


insert_member_to_team3(Team, TeamPlayer) when Team#team.count < Team#team.count_max ->
    Camp    = Team#team.camp,
    case camp_api:get_empty(Camp#camp.position, 1) of
        {?ok, Idx} ->
            CampPos     = #camp_pos{idx     = Idx,
                                    id      = TeamPlayer#team_player.uid,
                                    type    = ?CONST_SYS_PLAYER},
            Position    = setelement(Idx, Camp#camp.position, CampPos),
            Count       = Team#team.count + 1,
            Lv          = Team#team.count * Team#team.avg_lv  + TeamPlayer#team_player.lv,
            AvgLv       = case Count of 0 -> 0; _ -> misc:round(Lv div Count) end,
             ?MSG_DEBUG("lv is ~w", [AvgLv]),
            Camp2       = Camp#camp{position = Position},
            AuthorList = Team#team.author_list,
            TeamPlayer1 = TeamPlayer#team_player{state = ?CONST_TEAM_PLAYER_STATE_READY, is_gold_author = true},
            Team3       = Team#team{count = Count, avg_lv = AvgLv, camp = Camp2, author_list = [TeamPlayer1|AuthorList]},
            CrossKey = team_api:get_cross_team_key(Team#team.team_id),
            ets:update_element(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey, [{#team_cross.count, Count}, {#team_cross.level, AvgLv}]),
            {?ok, Team3};
        {?error, ErrorCode} -> {?error, ErrorCode}% 阵型空位不足
    end;
insert_member_to_team3(_Team, _TeamPlayer) ->
    {?error, ?TIP_TEAM_IS_FULL}.

insert_member_to_team2(Team, TeamPlayer) when Team#team.count < Team#team.count_max ->
    Camp    = Team#team.camp,
    case camp_api:get_empty(Camp#camp.position, 1) of
        {?ok, Idx} ->
            CampPos     = #camp_pos{idx     = Idx,
                                    id      = TeamPlayer#team_player.uid,
                                    type    = ?CONST_SYS_PLAYER},
            Position    = setelement(Idx, Camp#camp.position, CampPos),
            Count       = Team#team.count + 1,
            Lv          = Team#team.count * Team#team.avg_lv  + TeamPlayer#team_player.lv,
            AvgLv       = case Count of 0 -> 0; _ -> misc:round(Lv div Count) end,
             ?MSG_DEBUG("lv is ~w", [AvgLv]),
            Camp2       = Camp#camp{position = Position},
            AuthorList = Team#team.author_list,
            TeamPlayer1 = TeamPlayer#team_player{state = ?CONST_TEAM_PLAYER_STATE_READY},
            Team3       = Team#team{count = Count, avg_lv = AvgLv, camp = Camp2, author_list = [TeamPlayer1|AuthorList]},
            CrossKey = team_api:get_cross_team_key(Team#team.team_id),
            ets:update_element(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey, [{#team_cross.count, Count}, {#team_cross.level, AvgLv}]),
            {?ok, Team3};
        {?error, ErrorCode} -> {?error, ErrorCode}% 阵型空位不足
    end;
insert_member_to_team2(_Team, _TeamPlayer) ->
    {?error, ?TIP_TEAM_IS_FULL}.

insert_member_to_team(Team, TeamPlayer) when Team#team.count < Team#team.count_max ->
	Camp	= Team#team.camp,
	case camp_api:get_empty(Camp#camp.position, 1) of
		{?ok, Idx} ->
			CampPos		= #camp_pos{idx		= Idx,
									id 		= TeamPlayer#team_player.uid,
									type	= ?CONST_SYS_PLAYER},
			Position	= setelement(Idx, Camp#camp.position, CampPos),
			Count		= Team#team.count + 1,
			Lv			= Team#team.count * Team#team.avg_lv  + TeamPlayer#team_player.lv,
			AvgLv		= case Count of 0 -> 0; _ -> misc:round(Lv div Count) end,
             ?MSG_DEBUG("lv is ~w", [AvgLv]),
			Camp2		= Camp#camp{position = Position},
			Team3		= Team#team{count = Count, avg_lv = AvgLv, camp = Camp2},
            PlayerFromIndex = TeamPlayer#team_player.index_from,
            SelfIndex = cross_api:get_self_index(),
            case PlayerFromIndex == SelfIndex of
                true ->
                    Team4 = Team3;
                _ ->
                    OldCrossList = Team3#team.cross_list,
                    Team4 = 
                        case lists:keymember(TeamPlayer#team_player.uid, #team_player.uid, OldCrossList) of
                            false ->
                                Team3#team{cross_list = [TeamPlayer|OldCrossList]};
                            _ ->
                                Team3
                        end
            end,
            CrossKey = team_api:get_cross_team_key(Team#team.team_id),
            ets:update_element(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey, [{#team_cross.count, Count}, {#team_cross.level, AvgLv}]),
			{?ok, Team4};
		{?error, ErrorCode} -> {?error, ErrorCode}% 阵型空位不足
	end;

insert_member_to_team(_Team, _TeamPlayer) ->
    {?error, ?TIP_TEAM_IS_FULL}.

delete_member_from_team(Team, UserId) ->
	case get_team_member(Team, UserId) of
		{?ok, CampPos} ->
			Camp		= Team#team.camp,
			Position	= Camp#camp.position,
			Position2	= setelement(CampPos#camp_pos.idx, Position, ?CONST_SYS_TRUE),
			Camp2		= Camp#camp{position = Position2},
			Team2		= Team#team{camp = Camp2},
            AuthorList  = Team#team.author_list,
            AuthorList2 = lists:keydelete(UserId, #team_player.uid, AuthorList),
            CrossList = Team#team.cross_list,
            CrossList2 = lists:keydelete(UserId, #team_player.uid, CrossList),
            Team3 = Team2#team{author_list = AuthorList2, cross_list = CrossList2},
			Team4		= refresh_team_member(Team3),
            NewCrossList = lists:keydelete(UserId, #team_player.uid, Team4#team.cross_list),
			{?ok, Team4#team{cross_list = NewCrossList}};
		_ -> {?ok, Team}
	end.



refresh_team_member(Team) when is_record(Team, team) ->
	Camp		= Team#team.camp,
	Position	= Camp#camp.position,
	List		= misc:to_list(Position),
	{
	 _EtsTeamId, _EtsTeamHall, _EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(Team#team.type),
    AuthorList = Team#team.author_list,
    CrossList = Team#team.cross_list,
	{
	 Position2, Count, Lv
	}			= refresh_team_member(AuthorList ++ CrossList, List, EtsTeamPlayer, Position, 0, 0),
	Camp2		= Camp#camp{position = Position2},
	AvgLv		= case Count of 0 -> 0; _ -> misc:round(Lv div Count) end,
    CrossKey = team_api:get_cross_team_key(Team#team.team_id),
    ets:update_element(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey, [{#team_cross.count, Count}, {#team_cross.level, AvgLv}]),
	Team#team{count = Count, avg_lv = AvgLv, camp = Camp2}.

refresh_team_member(AuthorList, [#camp_pos{idx = Idx, id = UserId}|List], EtsTeamPlayer, AccPosition, AccCount, AccLv) ->
	case ets_api:lookup(EtsTeamPlayer, UserId) of
		TeamPlayer when is_record(TeamPlayer, team_player) ->
			refresh_team_member(AuthorList, List, EtsTeamPlayer, AccPosition, AccCount + 1, AccLv + TeamPlayer#team_player.lv);
		_ ->
            case lists:keyfind(UserId, #team_player.uid, AuthorList) of
                false ->
        			AccPosition2	= setelement(Idx, AccPosition, ?CONST_SYS_TRUE),
        			refresh_team_member(AuthorList, List, EtsTeamPlayer, AccPosition2, AccCount, AccLv);
                TeamPlayer ->
                    refresh_team_member(AuthorList, List, EtsTeamPlayer, AccPosition, AccCount + 1, AccLv + TeamPlayer#team_player.lv)
            end
	end;
refresh_team_member(AuthorList, [_CampPos|List], EtsTeamPlayer, AccPosition, AccCount, AccLv) ->
	refresh_team_member(AuthorList, List, EtsTeamPlayer, AccPosition, AccCount, AccLv);
refresh_team_member(_AuthorList, [], _EtsTeamPlayer, AccPosition, AccCount, AccLv) ->
	{AccPosition, AccCount, AccLv}.







%% 检查阵型位置总数是否大于N
check_camp(Camp, N) ->
	Count	= camp_api:camp_position_count(Camp#camp.camp_id, Camp#camp.lv),
	if Count >= N -> ?ok; ?true -> throw({?error, ?TIP_TEAM_NO_CAMP}) end.


check_team_exist(EtsTeamInfo, {TeamId, ServId}) ->
    NodeFrom = cross_api:get_node(ServId),
    case rpc:call(NodeFrom, team_api, get_team, [EtsTeamInfo, TeamId]) of
        {?ok, Team} -> {?ok, Team};
        _ -> throw({?error, ?TIP_TEAM_NO_THIS_TEAM})% 队伍不存在
    end;
%% 检查队伍是否存在
check_team_exist(EtsTeamInfo, TeamId) ->
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} -> {?ok, Team};
		_ -> throw({?error, ?TIP_TEAM_NO_THIS_TEAM})% 队伍不存在
	end.



%% 检查退伍人数是否达到上限
check_team_num(Team) ->
	if
		Team#team.count < (Team#team.param)#team_param.count_max -> ?ok;
		?true -> throw({?error, ?TIP_TEAM_IS_FULL})% 队伍人数已满
	end.
%% 检查某个角色是否已经有队伍
check_have_team(EtsTeamPlayer, UserId) ->
	case ets_api:lookup(EtsTeamPlayer, UserId) of
		TeamPlayer when is_record(TeamPlayer, team_player) -> {?true, TeamPlayer};
		_ -> {?false, ?null}
	end.
%% 检查某个角色是否已被邀请
check_team_invited(Team, UserId) ->
	case lists:member(UserId, Team#team.invite) of
		?true -> ?ok;
		?false -> throw({?error, ?TIP_TEAM_REPLY_TIMEOUT})% 邀请已过期
	end.
%% 检查某个角色是否是队长
check_leader(Team, UserId) ->
	case Team#team.leader_uid of
		UserId -> ?ok;
		_ -> throw({?error, ?TIP_TEAM_NOT_LEADER})% 不是队长，无权操作
	end.
%% 检查某个角色是否是该队伍成员
check_member1(Team, UserId) ->
	case get_team_member(Team, UserId) of
		{?ok, _CampPos} -> 
            case is_author(Team, UserId) of
                false ->
                    ?ok;
                _ ->
                    throw({?error, ?TIP_TEAM_IS_AUTHOR_PLAYER})
            end;
		{?error, ErrorCode} -> throw({?error, ErrorCode})% 不是队伍成员
	end.

check_member(Team, UserId) ->
    case get_team_member(Team, UserId) of
        {?ok, _CampPos} -> 
                ?ok;
        {?error, ErrorCode} -> throw({?error, ErrorCode})% 不是队伍成员
    end.


is_author(Team, UserId) ->
    AuthorList = Team#team.author_list,
    lists:keymember(UserId, #team_player.uid, AuthorList).

%% 检查某个队伍状态
check_team_state(Team) when is_record(Team, team)	->
	case Team#team.state of
		?CONST_TEAM_STATE_WAIT	->	?ok;
		_Other					->	throw({?error, ?TIP_TEAM_ALREADY_START})
	end.

check_member_state(Team, EtsTeamPlayer, State) when is_record(Team, team) ->
    AuthorLIst = Team#team.author_list,
    CrossList = Team#team.cross_list,
    Type = Team#team.type,
    List    = misc:to_list((Team#team.camp)#camp.position),
    check_member_state(Type, Team#team.leader_uid, {AuthorLIst, CrossList}, List, EtsTeamPlayer, State).

             

%% 检查每个队伍成员状态
check_member_state(Type, LeaderId, {AuthorLIst, CrossList}, [#camp_pos{id = Id}|List], EtsTeamPlayer, State) ->
    case lists:keyfind(Id, #team_player.uid, AuthorLIst) of
        TeamPlayer when is_record(TeamPlayer, team_player) ->
            case team_api:check_is_in_not_cd(LeaderId, Id, Type) orelse TeamPlayer#team_player.is_gold_author of
                true ->
                    check_member_state(Type, LeaderId, AuthorLIst, List, EtsTeamPlayer, State);
                _ ->
                    player_api:process_send(LeaderId, team_api, remove, Id),
                    throw({?error, ?TIP_TEAM_AUTHOR_IN_CD})
            end;
        _ ->
        	TeamPlayer	= 
                case ets_api:lookup(EtsTeamPlayer, Id) of
                    null ->
                        lists:keyfind(Id, #team_player.uid, CrossList);
                    TeamPlayer1 ->
                        TeamPlayer1
                end,
        	case TeamPlayer#team_player.state of
        		State -> check_member_state(Type, LeaderId, {AuthorLIst, CrossList}, List, EtsTeamPlayer, State);
        		_ -> throw({?error, ?TIP_TEAM_SOMEONE_NOT_READY, [{TeamPlayer#team_player.uid, TeamPlayer#team_player.name}]})
        	end
    end;
check_member_state(Type, LeaderId, AuthorLIst, [_CampPos|List], EtsTeamPlayer, State) ->
	check_member_state(Type, LeaderId, AuthorLIst, List, EtsTeamPlayer, State);

check_member_state(_Type, _LeaderId, _AuthorLIst, [], _EtsTeamPlayer, _State) -> ?ok.

%% 检查房间密码
check_password(#team{lock = <<"">>}, _Password) -> ?ok;
check_password(#team{lock = Password}, Password) -> ?ok;
check_password(_Team, _Password) -> throw({?error, ?TIP_TEAM_BAD_PASSWORD}).


%% 取出指定UserId的成员
get_team_member(Team, UserId) ->
	List	= misc:to_list((Team#team.camp)#camp.position),
	get_team_member2(List, UserId).

get_team_member2([#camp_pos{id = UserId} = CampPos|_List], UserId) -> {?ok, CampPos};
get_team_member2([_CampPos|List], UserId) ->
	get_team_member2(List, UserId);
get_team_member2([], _UserId) -> {?error, ?TIP_TEAM_NO_SAME_TEAM}.% 不是队伍成员

get_team_players(EtsTeamPlayer, Team) ->
	List	= misc:to_list((Team#team.camp)#camp.position),
	Fun		= fun(CampPos, Acc) when is_record(CampPos, camp_pos)->
					  case ets_api:lookup(EtsTeamPlayer, CampPos#camp_pos.id) of
						  TeamPlayer when is_record(TeamPlayer, team_player) ->
							  [TeamPlayer|Acc];
						  _ -> 
                              case is_cross(Team, CampPos#camp_pos.id) of
                                  false ->
                                      case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, Team#team.author_list) of
                                          false ->
                                             Acc;
                                          TeamPlayer ->
                                              case Team#team.state of
                                                  ?CONST_TEAM_STATE_START ->
                                                      [TeamPlayer|Acc];
                                                  _ ->
                                                      Acc
                                              end
                                      end;
                                  TeamPlayer ->
                                      [TeamPlayer|Acc]
                              end
					  end;
				 (_, Acc) -> Acc
			  end,
	lists:foldl(Fun, [], List).

get_team_players2(EtsTeamPlayer, Team) ->
    List    = misc:to_list((Team#team.camp)#camp.position),
    AuthorList = Team#team.author_list,
    CrossList = Team#team.cross_list,
    Fun     = fun(CampPos, Acc) when is_record(CampPos, camp_pos)->
                      case ets_api:lookup(EtsTeamPlayer, CampPos#camp_pos.id) of
                          TeamPlayer when is_record(TeamPlayer, team_player) ->
                              [TeamPlayer|Acc];
                          _ -> 
                              case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, AuthorList ++ CrossList) of
                                  TeamPlayer when is_record(TeamPlayer, team_player)->
                                      [TeamPlayer|Acc];
                                  _ ->
                                      Acc
                              end
                      end;
                 (_, Acc) -> Acc
              end,
    lists:foldl(Fun, [], List).

%%
%% Local Functions
%%
record_team_player(Player, State) ->
	Info		= Player#player.info,
	Partners	= [{X} || X <- partner_api:get_partner_id_list(Player, 0)],
    ServIndx = cross_api:get_self_index(),
	Position	= (Player#player.position)#position_data.position,
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    IsHideFashion = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
    IsHideHorse   = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
	#team_player{
                 index_from = ServIndx,
				 uid		        = Player#player.user_id,    		% 玩家ID
				 name               = Info#info.user_name,   			% 名称
				 pro                = Info#info.pro,        			% 职业
				 sex                = Info#info.sex,        			% 性别
				 lv                 = Info#info.lv,        				% 等级
				 state              = State,							% 状态
				 position			= Position,							% 官衔
				 power				= Info#info.power,					% 战力
				 partners			= Partners,							% 副将列表
				 skin_fashion		= SkinFashion,			            % 装备时装皮肤ID
				 skin_weapon		= SkinWeapon,			            % 装备武器皮肤ID
                 skin_armor         = SkinArmor,                        % 装备衣服皮肤ID
				 hide_fashion		= IsHideFashion,		            % 隐藏时装
				 hide_ride          = IsHideHorse                       % 隐藏坐骑
				}.
record_team_hall(Player) ->
	Info	= Player#player.info,
	#team_hall{
			   uid		        	= Player#player.user_id,    % 玩家ID
			   name               	= Info#info.user_name,   	% 名称
			   pro                	= Info#info.pro,        	% 职业
			   sex                	= Info#info.sex,        	% 性别
			   lv                 	= Info#info.lv        		% 等级
			  }.