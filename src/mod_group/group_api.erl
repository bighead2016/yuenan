%% %% 常规组队
-module(group_api).
%% 
%% %%
%% %% Include files
%% %%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%% 
%% %%
%% %% Exported Functions
%% %%
-export([initial_ets/0]).
-export([record_group/1,record_group_apply/1,record_group/14,record_group_apply/7]).
-export([ets_insert_group/2,ets_insert_list/2, login_packet/2]).
-export([msg_sc_list_group/11,msg_sc_change_leader/2,msg_sc_join_group/3, msg_sc_cancel_apply/1,msg_sc_kick_out/2,
		 msg_sc_disband/0,msg_sc_recommand_list/2, msg_sc_search_info/2, msg_sc_quit/2, msg_sc_apply_waiting/1,
		 msg_sc_waiting_list/2, msg_sc_reply_invite/2, msg_sc_buffer/2, msg_sc_logout/1,msg_sc_login/1,
         msg_sc_buffer/1, msg_sc_temp_buffer/6, msg_reply_join_group/4, msg_sc_reply_invitor/2, msg_sc_delete_waiter/1,
		 msg_sc_member_power/2]).

-export([logout/1, login/1, broadcast_to_member/2, refresh_reflect_attr/1, level_up/1, calc_group_buffer_cb/2, refresh_buffer/0,
		 refresh_buffer1/2, get_group_times/1]).
%% -export([create_group_cb/5]). % 回调
%% 
%% %%
%% %% API Functions
%% %%
%% 
%% 初始化
initial_ets() ->
	case initial_ets_group() of
		?ok -> ?ok;
		{?error, _ErrorCode} ->  ?ok
	end,
	case initial_ets_group_apply() of
		?ok -> ?ok;
		{?error, _ErrorReason} -> ?ok
	end.

initial_ets_group() ->
	ets:delete_all_objects(?CONST_ETS_GROUP),
	Fields = [id, name, lv, online_num, in_group_num, leader_id, country, guild_id, guild_name, member_list, online_member_list,
			 limit,apply_mount, pro_list],
	case mysql_api:select(Fields, game_group) of
			{?ok, GroupInfo} ->
			F = fun([Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberListTemp, OnLineMemberTemp, Limit, ApplyMount, ProListTemp]) ->
						MemberList 	 = misc:decode(MemberListTemp),
						OnLineMember = misc:decode(OnLineMemberTemp),
						ProList		 = misc:decode(ProListTemp),
						record_group([Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList]) 
				end,
			GroupInfoList = lists:map(F, GroupInfo),
			ets_insert_list(?CONST_ETS_GROUP, GroupInfoList);
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

initial_ets_group_apply() ->
	ets:delete_all_objects(?CONST_ETS_GROUP_APPLY),
	Fields = [id, user_id, lv, pro, type, group_id, state],
	case mysql_api:select(Fields, game_group_apply) of
		{?ok, GroupApplyInfo} ->
			F = fun([Id, UserId, Lv, Pro, Type, GroupId, State]) ->
						record_group_apply([Id, UserId, Lv, Pro, Type, GroupId, State])
				end,
			GroupApplyList = lists:map(F, GroupApplyInfo),
			ets_insert_list(?CONST_ETS_GROUP_APPLY, GroupApplyList);
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%% 更新玩家组队信息
level_up(Player) ->
    UserId = Player#player.user_id,
    case ets:match_object(?CONST_ETS_GROUP_APPLY, #group_apply{user_id = UserId, _ = '_'}) of
        [] -> Player;
        GroupApplyList ->
            F = fun(GroupApply) ->
                    Info = Player#player.info,
                    Lv   = Info#info.lv,
                    ets_api:insert(?CONST_ETS_GROUP_APPLY, GroupApply#group_apply{lv = Lv})
                end,
            lists:foreach(F, GroupApplyList),
			case group_mod:get_group_apply_list(UserId, 2) of
				[]         -> Player;
				GroupApply ->
					GroupId		= GroupApply#group_apply.group_id,
					case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
						?null -> Player;
						Group ->
							MemberList		= Group#group.member_list,
							{?ok, Player2}  = group_mod:calc_group_buffer(Player, MemberList, MemberList),
							Player2
					end
			end
    end.

%% 定时刷新组队加成
refresh_buffer() ->            %% 每5分钟进行一次刷新buff
	GroupApplyList		= ets_api:list(?CONST_ETS_GROUP_APPLY),
	F = fun(GroupApply) when is_record(GroupApply, group_apply) andalso GroupApply#group_apply.state =:= 2 ->
				UserId		= GroupApply#group_apply.user_id,
				GroupId		= GroupApply#group_apply.group_id,
				Group		= group_mod:get_group(GroupId),
				OnLineMember= Group#group.online_member_list,
				case player_api:get_player_first(UserId) of
					{?ok, ?null, _} -> ?ok;
					{?ok, NewPlayer, ?CONST_PLAYER_ONLINE} ->
						BuffList = refresh_reflect_attr(NewPlayer),
						player_api:process_send(UserId, group_api, refresh_buffer1, [BuffList, OnLineMember]);
					{?ok, _, ?CONST_PLAYER_OFFLINE} -> ?ok
				end;
		   (_X) -> ?ok
		end,
	[F(GroupApply) || GroupApply <- GroupApplyList].

 refresh_buffer1(Player, [BuffList, Member]) ->
	NewPlayer 	= player_attr_api:refresh_group(Player, BuffList),
	Packet 		= msg_sc_buffer(NewPlayer),
    broadcast_to_member(Member, Packet),
	{?ok, NewPlayer}.
	

%% 刷新buffer加成
refresh_reflect_attr(_Player) -> [].
%%     UserId   	= Player#player.user_id,
%%     Info     	= Player#player.info,
%% 	case player_api:check_online(UserId) of
%% 		?true ->
%% 			BuffList 	= group_mod:calculate_group_buff(UserId, Info),
%% 			group_mod:get_group_buff(BuffList, []);
%% 		?false -> []
%% 	end.

%% 上线通知
login(UserId) ->
	Data		= group_mod:get_group_apply_list(UserId, 2),
	case Data of
		[] -> ?ok;
		GroupInfo when is_record(GroupInfo, group_apply) ->
			GroupId			= GroupInfo#group_apply.group_id,
			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
				Group when is_record(Group, group) ->
					OnLineList		= Group#group.online_member_list,
					NewOnLine		= case lists:keymember(UserId, 1, OnLineList) of
										  ?false -> [{UserId}|OnLineList];
										  ?true  -> OnLineList
									  end,
					case mysql_api:update(game_group, [{online_member_list, misc:encode(NewOnLine)}], [{id, GroupId}]) of
						{?ok, _} ->
							ets:update_element(?CONST_ETS_GROUP, GroupId, [{#group.online_member_list, NewOnLine}]);
						{?error, _} -> ?ok
					end,	
					Packet		= msg_sc_login(UserId),
					broadcast_to_member(OnLineList, Packet);
				_ -> ?ok
			end;
		_ -> ?ok
	end.

%% 下线通知
logout(Player) ->
	UserId		= Player#player.user_id,
	Data		= group_mod:get_group_apply_list(UserId, 2),
	case Data of
		[] -> ?ok;
		GroupInfo when is_record(GroupInfo, group_apply) ->
			GroupId			= GroupInfo#group_apply.group_id,
			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
				Group when is_record(Group, group) ->
					OnLineList		= Group#group.online_member_list,
					NewOnLine		= lists:delete({UserId}, OnLineList),
					case mysql_api:update(game_group, [{online_member_list, misc:encode(NewOnLine)}], [{id, GroupId}]) of
						{?ok, _} ->
							ets:update_element(?CONST_ETS_GROUP, GroupId, [{#group.online_member_list, NewOnLine}]),
							Packet		= msg_sc_logout(UserId),
							broadcast_to_member(OnLineList, Packet);
						{?error, ErrorCode} ->
							{?error, ErrorCode}
					end;
				_ -> ?ok
			end;
		_ -> ?ok
	end.

%% 一登录请求返回的信息
login_packet(Player, Packet) ->
	UserId		= Player#player.user_id,
    Packet2 	= group_mod:search_member_info(Player, ?CONST_SYS_FALSE),
	Data		= group_mod:get_group_apply_list(UserId, 2),
	case Data of
		[] ->
			{Player, <<Packet/binary, Packet2/binary>>};
		Group when is_record(Group, group_apply) ->
			BuffList 	 = refresh_reflect_attr(Player),
			NewPlayer 	 = player_attr_api:refresh_group(Player, BuffList),
			BuffList1	 = [{Type, Value} || {_UserId, Type, Value} <- BuffList],
			Packet3		 = msg_sc_buffer(UserId, BuffList1),
    		{NewPlayer, <<Packet/binary, Packet2/binary, Packet3/binary>>};
		_ ->
			{Player, <<Packet/binary, Packet2/binary>>}
	end.

%% 常规组队剩余人数
get_group_times(Player) ->
	UserId		= Player#player.user_id,
	case player_sys_api:is_open_sys(UserId, ?CONST_MODULE_GROUP) of
		?true ->
			case group_mod:get_group_by_user_id(UserId) of
				Group when is_record(Group, group) ->
					List		= Group#group.member_list,
					Num			= erlang:length(List),
					case Num < 3 of
						?true  -> 3 - Num;
						?false -> ?CONST_SYS_FALSE
					end;
				_ -> 2
			end;
		?false -> ?CONST_SYS_FALSE
	end.

%% 回调,计算队伍加成
calc_group_buffer_cb(Player, [MemberList]) ->
    UserId 		= Player#player.user_id,
    Info 		= Player#player.info,
    BuffList 	= group_mod:calculate_group_buff(UserId, Info),
	NewBuffList = group_mod:get_group_buff(BuffList, []),
	?MSG_DEBUG("NewBuffList=~p", [NewBuffList]),
    AttrReflect = Player#player.attr_reflect,
    AttrReflect2= AttrReflect#attr_reflect{group = NewBuffList},
    Player2 	= Player#player{attr_reflect = AttrReflect2},
    Player3 	= player_attr_api:refresh_group(Player2, NewBuffList),
    Packet 		= msg_sc_buffer(Player3),
	?MSG_DEBUG("MemberList=~p Packet=~p", [MemberList, Packet]),
    broadcast_to_member(MemberList, Packet),
    {?ok, Player3}.

%% 
%% Local Functions
%% 
%% 团队信息(19002)
msg_sc_list_group(UserId, Name, Lv, IsOnline, GuildName, Pro, Sex, IsLeader, SkinWeapon, SkinArmor, Position) ->
    misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, 
                     [UserId, Name, Lv, IsOnline, GuildName, Pro, Sex, IsLeader, SkinWeapon, SkinArmor, Position]).   
%% 查询团队信息(调用19002)
msg_sc_search_info([{PlayerId, PlayerName, PlayerLv, IsOnline, GuildName, Pro, Sex, IsLeader, SkinWeapon, SkinArmor, Position}|MemberList], 
				   Packet) ->
	Packet1		=	msg_sc_list_group(PlayerId, PlayerName, PlayerLv, IsOnline, GuildName, Pro, Sex, IsLeader, SkinWeapon, SkinArmor,
									  Position),
	msg_sc_search_info(MemberList, <<Packet/binary, Packet1/binary>>);
msg_sc_search_info([], Packet) ->
	Packet.
	
%% 主动更换队长返回(调用19002)         
msg_sc_change_leader(Player, NewPlayer) ->
	UserId1		=	Player#player.user_id,
	case group_mod:get_group_apply_list(UserId1, 2) of
		[] -> ?ok;
		GroupApply ->
			GroupId		=	GroupApply#group_apply.group_id,
			Group		=	ets_api:lookup(?CONST_ETS_GROUP, GroupId),
			MemberList	=	Group#group.member_list,
			Info		=   Player#player.info,
			UserName1	=	Info#info.user_name,
			Lv1			=	Info#info.lv,
			GuildName1	=   (Player#player.guild)#guild.guild_name,
			Pro1		=	Info#info.pro,
			Sex1		=	Info#info.sex,
			SkinWeapon	=   0, %Info#info.skin_weapon,
			SkinArmor	= 	0, %Info#info.skin_armor,
			Position	=	Player#player.position,
			PositionId	=   Position#position_data.position,
			case player_api:check_online(UserId1)of
				?true -> 
					IsOnline1 	= ?CONST_SYS_TRUE,
					Packet1 	= msg_sc_list_group(UserId1, UserName1, Lv1, IsOnline1, GuildName1, Pro1, Sex1, 0, SkinWeapon, SkinArmor,
													PositionId),
					broadcast_to_member(MemberList, Packet1);
				?false -> _IsOnline1 = ?CONST_SYS_FALSE
			end,
			NewPlayerId = NewPlayer#player.user_id,
			NewInfo		= NewPlayer#player.info,
			UserName2	= NewInfo#info.user_name,
			Lv2			= NewInfo#info.lv,
			GuildName2	= (NewPlayer#player.guild)#guild.guild_name,
			Pro2		= NewInfo#info.pro,
			Sex2		= NewInfo#info.sex,
			SkinWeapon2 = 0, %NewInfo#info.skin_weapon,
			SkinArmor2	= 0, %NewInfo#info.skin_armor,
			Position2	= NewPlayer#player.position,
			PositionId2	= Position2#position_data.position,
			case player_api:check_online(NewPlayerId)of
				?true -> 
					IsOnline2 	= ?CONST_SYS_TRUE,
					Packet2 	= msg_sc_list_group(NewPlayerId, UserName2, Lv2, IsOnline2, GuildName2, Pro2, Sex2, 1, SkinWeapon2, SkinArmor2,
													PositionId2),
					broadcast_to_member(MemberList, Packet2);
				?false -> _IsOnline2 = ?CONST_SYS_FALSE
			end
	end.

%%[回复]申请加入团队
msg_reply_join_group(UserName, Type, UserId, GroupId) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_REQ2JOIN, ?MSG_FORMAT_GROUP_SC_REQ2JOIN, [UserName, Type, UserId, GroupId]).

%% 申请加入队伍返回(同意加入队伍后调用19002)
msg_sc_join_group(Group, _GroupApply, ReqUserId) ->
	LeaderId			= Group#group.leader_id,
	OnLineMemberList 	= Group#group.online_member_list,
	MemberList			= Group#group.member_list,
	case player_api:get_player_fields(ReqUserId, [#player.info, #player.guild, #player.position]) of
		{?ok, [#info{user_name = UserName2, lv = Lv2, pro = Pro2, sex = Sex2}, 
			   #guild{guild_name = GuildName2}, #position_data{position = PositionId2}]} ->
			Packet 		= msg_sc_list_group(ReqUserId, UserName2, Lv2, 1, GuildName2, Pro2, Sex2, 0, 0, 0,
											PositionId2),
			misc_packet:send(ReqUserId, Packet),						  %% 把申请人信息广播给自己
			broadcast_to_member(OnLineMemberList, Packet),				  %% 把申请人信息广播给队伍里的玩家
			broadcast_to_requstmember(MemberList, LeaderId, ReqUserId);   %% 把队伍里的玩家信息发送给申请人
		_ ->
			{?error, ?TIP_COMMON_NO_THIS_PLAYER}
	end.

%% 把申请人信息广播给队伍里的玩家
broadcast_to_member([{Member}|MemberList], Packet) ->
	misc_packet:send(Member, Packet),
	broadcast_to_member(MemberList, Packet);
broadcast_to_member([], _Packet) ->
	?ok.

 %% 把队伍里的玩家信息发送给申请人
broadcast_to_requstmember([{Member}|MemberList],LeaderId,ReqUserId) ->
	case player_api:get_player_fields(Member, [#player.info, #player.guild, #player.position]) of
		{?ok, [#info{user_name = UserName, lv = Lv, pro = Pro, sex = Sex}, 
			   #guild{guild_name = GuildName}, #position_data{position = PositionId}]} ->
			IsOnline	= case player_api:check_online(Member) of
							  ?true  -> ?CONST_SYS_TRUE;
							  ?false -> ?CONST_SYS_FALSE
						  end,
			if
				Member =:= LeaderId ->
					Packet 		= msg_sc_list_group(Member, UserName, Lv, IsOnline, GuildName, Pro, Sex, 1, 0, 0,
													PositionId),
					misc_packet:send(ReqUserId, Packet);
				?true ->
					Packet 		= msg_sc_list_group(Member, UserName, Lv, IsOnline, GuildName, Pro, Sex, 0, 0, 0,
													PositionId),
					misc_packet:send(ReqUserId, Packet)
			end;
		_ -> ?ok
	end,
	broadcast_to_requstmember(MemberList,LeaderId, ReqUserId);
broadcast_to_requstmember([], _LeaderId, _ReqUserId) ->
	?ok.
			
%% 取消申请返回(19016)
msg_sc_cancel_apply(GroupId) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_CANCEL2JOIN, ?MSG_FORMAT_GROUP_SC_CANCEL2JOIN, [GroupId]).

%% 踢出队伍返回(19014)
msg_sc_kick_out(Player, KickOutId) ->
	Packet		= misc_packet:pack(?MSG_ID_GROUP_SC_KICKOUT, ?MSG_FORMAT_GROUP_SC_KICKOUT, [KickOutId]),
	Packet1		= msg_sc_disband(),
	misc_packet:send(KickOutId, Packet1),
	misc_packet:send(Player#player.net_pid, Packet),
	UserId		= Player#player.user_id,
	case group_mod:get_group_apply_list(UserId, 2) of
		[] -> ?ok;
		Group ->
			GroupId		= Group#group_apply.group_id,
			Group1		= ets_api:lookup(?CONST_ETS_GROUP, GroupId),
			OnLineList	= Group1#group.online_member_list,
			NewList		= lists:delete({KickOutId}, OnLineList),
			NewOnLiner	= lists:delete({Player#player.user_id}, NewList),
			if
				is_list(NewOnLiner) andalso erlang:length(NewOnLiner) > ?CONST_SYS_FALSE ->
					[{NewOnLineId}]		= NewOnLiner,
					misc_packet:send(NewOnLineId, Packet);
				?true ->
					?ok
			end
	end.
		
%% 退出队伍返回(19014)
msg_sc_quit(Player, OnLineList) ->
%% 	?MSG_PRINT("uer_id=~p, onlinelist=~p", [Player#player.user_id, OnLineList]),
	Packet		= 	misc_packet:pack(?MSG_ID_GROUP_SC_KICKOUT, ?MSG_FORMAT_GROUP_SC_KICKOUT, [Player#player.user_id]),
	Packet1		=	msg_sc_disband(),
	misc_packet:send(Player#player.net_pid, Packet1),
	broadcast_to_member(OnLineList, Packet).
	
%% 获取推荐列表(19030)
msg_sc_recommand_list(GroupList, MemberList) ->
	F1 	= fun(Group) ->
				  msg_sc_recommand_group(Group)
		  end,
	List1			= [F1(Group) ||Group <- GroupList],
	NewMemberList	= lists:flatten(MemberList),
	F2	= fun(Member) ->
				  msg_sc_recommand_member(Member)
		  end,
	List2			= [F2(Member) || Member <- NewMemberList],
	misc_packet:pack(?MSG_ID_GROUP_SC_RECOMMEND ,?MSG_FORMAT_GROUP_SC_RECOMMEND, [List1, List2]).

msg_sc_recommand_group({GroupId, GroupName, InGroupNum, GuildName, State}) ->
	 {GroupId, GroupName, InGroupNum, GuildName, State}.

msg_sc_recommand_member({GroupId, PlayerId, PlayerName, PlayerLv, IsOnline, GuildName, Career, Sex}) ->
	{GroupId, PlayerId, PlayerName, PlayerLv, IsOnline, GuildName, Career, Sex}.
	
%% 删除加入队伍的待组玩家
msg_sc_delete_waiter(UserId) ->
	misc_packet:pack(?MSG_ID_GROUP_DELETE_WAITER, ?MSG_FORMAT_GROUP_DELETE_WAITER, [UserId]).
	
%% 申请成为待组玩家(19026)
msg_sc_apply_waiting(Player) ->   %% 直接返回自身待组信息
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Name		= Info#info.user_name,
	Lv			= Info#info.lv,
	GuildName	= (Player#player.guild)#guild.guild_name,
	Pro			= Info#info.pro,
	Sex			= Info#info.sex,
	List		= [{UserId, Name, Lv, GuildName, Pro, Sex}],
	Packet		= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_WAIT, ?MSG_FORMAT_GROUP_SC_LIST_WAIT, [List]),
	misc_packet:send(Player#player.net_pid, Packet).
	
%% 待组玩家列表返回(19026)
msg_sc_waiting_list(Type, UserIdList) ->
	F = fun(UserId) ->
				case player_api:get_player_fields(UserId, [#player.info, #player.guild]) of
					{?ok, [#info{user_name = Name, lv = Lv, pro = Pro, sex = Sex}, Guild]} ->
						GuildName 	= guild_api:get_guild_name(Guild),
						{UserId, Name, Lv, GuildName, Pro, Sex};
					_ ->
						{}
				end
		end,
	List		= [F(UserId) || UserId <- UserIdList],
	misc_packet:pack(?MSG_ID_GROUP_SC_LIST_WAIT, ?MSG_FORMAT_GROUP_SC_LIST_WAIT, [Type, List]).

%% 邀请回复
msg_sc_reply_invite(GroupId, UserId) ->
	Group		 =	ets_api:lookup(?CONST_ETS_GROUP, GroupId),
	LeaderId	 =	Group#group.leader_id,
	NewOnLineList=	Group#group.online_member_list,
	OnLineList	 =	lists:delete({UserId}, NewOnLineList),
	OnLine		 = 	lists:delete({LeaderId}, OnLineList),
	Data1 = 
    	case player_api:get_player_first(LeaderId) of
    			{?ok, ?null, _IsOnline} ->
    			[];
    		{?ok, NewPlayer, _IsOnline} ->
    			msg_get_member_info(NewPlayer, LeaderId)
    	end,
    Data2 =  
    	case player_api:get_player_first(UserId) of
    		{?ok, ?null, _IsOnline1} ->
    			[];
    		{?ok, NewPlayer1, _IsOnline1} ->
    			msg_get_member_info(NewPlayer1, LeaderId)
    	end,		
	if
		erlang:length(OnLine) =:= ?CONST_SYS_FALSE ->
			?MSG_DEBUG("Data1=~p", [Data1]),
			Packet	= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, Data1),
			misc_packet:send(LeaderId, Packet),
			misc_packet:send(UserId, Packet),
			Packet1	= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, Data2),
			misc_packet:send(LeaderId, Packet1),
			misc_packet:send(UserId, Packet1);
		?true ->
			[{OnLineId}]	=	OnLine,	
            Data3 = 
    			case player_api:get_player_first(OnLineId) of
    				{?ok, ?null, _IsOnline2} ->
    					[];
    				{?ok, NewPlayer2, _IsOnline2} ->
    					msg_get_member_info(NewPlayer2, LeaderId)
    			end,
			Packet	= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, Data1),
			broadcast_to_member(NewOnLineList, Packet),
			Packet1	= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, Data2),
			broadcast_to_member(NewOnLineList, Packet1),
			Packet2	= misc_packet:pack(?MSG_ID_GROUP_SC_LIST_GROUP, ?MSG_FORMAT_GROUP_SC_LIST_GROUP, Data3),
			broadcast_to_member(NewOnLineList, Packet2)
	end.
			
msg_get_member_info(Player, LeaderId) ->
	Info		=	Player#player.info,
	UserId		=	Player#player.user_id,
	Name		=	Info#info.user_name,
	Lv			=	Info#info.lv,
	GuildName	=	(Player#player.guild)#guild.guild_name,
	Pro			=	Info#info.pro,
	Sex			=	Info#info.sex,
	SkinWeapon	= 	0, %Info#info.skin_weapon,
	SkinArmor	=	0, %Info#info.skin_armor,
	Position	=	Player#player.position,
	PositionId	=   Position#position_data.position,
	IsOnline	= case player_api:check_online(UserId) of
					  ?true -> ?CONST_SYS_TRUE;
					  ?false -> ?CONST_SYS_FALSE
				  end,
	IsLeader 	= if
					  UserId	=:= LeaderId -> ?CONST_SYS_TRUE;
					  ?true -> ?CONST_SYS_FALSE
				  end,
	[UserId,Name,Lv,IsOnline,GuildName,Pro,Sex, IsLeader, SkinWeapon, SkinArmor, PositionId].


%% 下线通知(19028)
msg_sc_logout(UserId) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_UPD_ON_OFF, ?MSG_FORMAT_GROUP_SC_UPD_ON_OFF, [UserId, ?CONST_SYS_FALSE]).
%% 上线通知
msg_sc_login(UserId) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_UPD_ON_OFF, ?MSG_FORMAT_GROUP_SC_UPD_ON_OFF, [UserId, ?CONST_SYS_TRUE]).

%% [回复]邀请玩家(19024)
msg_sc_reply_invitor(GroupName, GroupId) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_INVITE, ?MSG_FORMAT_GROUP_SC_INVITE, [GroupName, GroupId]).

%% 解散队伍(19032)
msg_sc_disband() ->
    misc_packet:pack(?MSG_ID_GROUP_SC_DISBAND, ?MSG_FORMAT_GROUP_SC_DISBAND, [0]).

%% buffer加成(19034)
%%[UserId,{Type,Value}]
msg_sc_buffer(Player) when is_record(Player, player) ->
    UserId 		= Player#player.user_id,
    AttrReflect = Player#player.attr_reflect,
    BuffList	= 
        if
            [] =/= AttrReflect ->
                [{Type, Value}||{_UserId, Type, Value} <- AttrReflect#attr_reflect.group];
            ?true -> []
        end,
	case player_api:check_online(UserId) of
		?true  ->
			case BuffList =/= [] of
				?true  -> msg_sc_buffer(UserId, BuffList);
				?false -> <<>>
			end;
		?false -> <<>>
	end.

msg_sc_buffer(UserId, List1) ->
    misc_packet:pack(?MSG_ID_GROUP_SC_BUFFER, ?MSG_FORMAT_GROUP_SC_BUFFER, [UserId, List1]).

%% 属性加成(19036)
%%[ShowType,UserId1,Name,Type,Value,LvBuffType]
msg_sc_temp_buffer(ShowType,UserId1,Name,Type,Value,LvBuffType) ->
    misc_packet:pack(?MSG_ID_GROUP_SC_TEMP_BUFFER, ?MSG_FORMAT_GROUP_SC_TEMP_BUFFER, [ShowType,UserId1,Name,Type,Value,LvBuffType]).

%% 成员战力返回(19038)
msg_sc_member_power(UserId, Power) ->
	misc_packet:pack(?MSG_ID_GROUP_SC_MEMBER_POWER, ?MSG_FORMAT_GROUP_SC_MEMBER_POWER, [UserId, Power]).

%%-------------------------------------------------------------------------------------------------------------------------------	
%% 转换数据
record_group([Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList]) ->
	record_group(Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList);
record_group({Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList}) ->
	record_group(Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList).

record_group(Id, Name, Lv, OnLineNum, CurrentNum, LeaderId, Country, GuildId, GuildName,
				 MemberList, OnLineMember, Limit, ApplyMount, ProList) ->
	#group{                                                                   
		                id                      =           Id,                 %% 自增id	
                        name                    =           Name,               %% 队伍名=队长名	
                        lv                      =           Lv,       			%% 队伍等级=队长等级	
                        online_num              =           OnLineNum,          %% 在线人数	
                        in_group_num            =           CurrentNum,         %% 队中已加人数	
                        leader_id               =           LeaderId,           %% 队长id	
                        country                 =           Country,            %% 队伍国家=队长国家	
                        guild_id                =           GuildId,            %% 队伍军团=队长军团
						guild_name				=			GuildName,			%% 军团名	
                        member_list             =           MemberList,         %% 成员列表	
                        online_member_list      =           OnLineMember,       %% 在线成员列表	
                        limit	          		=           Limit,	      		%% 1无限制 2所在国家 3所在军团
						apply_mount				=			ApplyMount,			%% 申请总数
						pro_list				=			ProList				%% 队伍中人员职业列表	
		   }.                                                                 

record_group_apply([Id, UserId, Lv, Pro, Type, GroupId, State]) ->
	record_group_apply(Id, UserId, Lv, Pro, Type, GroupId, State);
record_group_apply({Id, UserId, Lv, Pro, Type, GroupId, State}) ->
	record_group_apply(Id, UserId, Lv, Pro, Type, GroupId, State).

record_group_apply(Id, UserId, Lv, Pro, Type, GroupId, State) ->
	#group_apply{         
				 id								=			 Id,				 %% 自增id                                                      
				 user_id				        =            UserId, 		     %% 申请玩家id
                 lv                             =            Lv,                 %% 等级
                 pro                            =            Pro,                %% 职业
				 type			                =            Type, 		         %% 申请类型 1.player->group;2.group->player
				 group_id		                =            GroupId, 	         %% 申请组队ID
				 state							=			 State				 %% 玩家状态
				 }.

%% ETS操作
ets_insert_group(Tab, GroupInfo) ->
	ets_api:insert(Tab, GroupInfo).

ets_insert_list(Tab, [GroupInfo|GroupList]) ->
	ets_insert_group(Tab, GroupInfo),
	ets_insert_list(Tab, GroupList);
ets_insert_list(_Tab, []) ->
	?ok.