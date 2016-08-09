%% %%%--------------------------------------
%% %%% @Module  : db_agent_group
%% %%% @Created : 2012.5.25
%% %%% @Description: 组队（加成）的数据库操作
%% %%%--------------------------------------
%% 
-module(group_db_mod).
%% 
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%% 
-export([creat_group/2, apply_join_group/2, update_join_group/3,kick_out_group/2, quit_group/2, apply_wating_group/1,
		 cancel_apply_waiting/1,invite_group/2]).

%% -export([select_all_group2player/0, select_all_player2group/0, select_player2group/1]).
%% -export([insert_group/1, insert_player2group/1]).
%% -export([delete_group/1]).
%% -export([update_player2group/1, update_group2player/1]).
%% 

%% %% -------------------------------------------------------
%% %% @desc    创建队伍
%% %% @parm    队伍信息
%% %% @return  创建成功的队伍信息
%% %% --------------------------------------------------------
creat_group(#player{user_id = UserId, 
                    guild   = #guild{guild_id= GuildId, guild_name = GuildName},
                    info    = #info{country = Country, lv = Lv, pro = Pro, user_name=UserName}
                   }, 
            Limit) ->
    MemberList        = [{UserId}],
    OnlineMemberList  = [{UserId}],
	ProListTemp		  = [{Pro}],
	ProList			  = misc:encode([{Pro}]),
	MemberListE 	  =	misc:encode(MemberList),
	OnLineMemberListE =  misc:encode(OnlineMemberList),
	case mysql_api:insert(game_group, [                                           %% 插入创建信息
								  {name, UserName}, 
								  {lv, Lv}, 
								  {online_num, 1}, 
								  {in_group_num, 1}, 
								  {leader_id, UserId},
								  {country, Country},
								  {guild_id, GuildId}, 
								  {guild_name, GuildName},
								  {member_list, MemberListE},
								  {online_member_list, OnLineMemberListE},
								  {limit, Limit}, 
								  {apply_mount, 0},
								  {pro_list, ProList}
								 ]) of
		{?ok, _, Id} ->
			GroupInfo = group_api:record_group(Id, UserName, Lv, 1, 1, UserId, Country, GuildId, GuildName, MemberList,
					 				           OnlineMemberList, Limit, 0, ProListTemp),
			group_api:ets_insert_group(?CONST_ETS_GROUP, GroupInfo),
			case mysql_api:insert(game_group_apply, [
										{user_id,  UserId},
                                        {lv,       Lv},
                                        {pro,      Pro},
										{type,	   1},
										{group_id, Id},
										{state,    2}
										]) of
				{?ok, _, ApplyId} ->
					GroupApplyInfo = group_api:record_group_apply(ApplyId, UserId, Lv, Pro, 1, Id, 2),
					group_api:ets_insert_group(?CONST_ETS_GROUP_APPLY, GroupApplyInfo);
				{?error, _ErrorCode} ->
					?ok
			end,
			GroupApplyList= get_group_list(UserId, 2),
			F = fun(GroupApply) when is_record(GroupApply, group_apply)->
    				mysql_api:delete(game_group_apply, "id = "++misc:to_list(GroupApply#group_apply.id)),
    				ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApply#group_apply.id)
				end,
			lists:foreach(F, GroupApplyList),
			{?ok, GroupInfo};
		{?error, _ErrorCode} ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

get_group_list(UserId, State) ->
	List		= ets_api:list(?CONST_ETS_GROUP_APPLY),
	get_group_list1(List, UserId, State, []).

get_group_list1([GroupApply|RestList], UserId, State, Acc) when is_record(GroupApply, group_apply) ->
	OtherId		= GroupApply#group_apply.user_id,
	OtherState	= GroupApply#group_apply.state,
	case {OtherId =:= UserId, OtherState =/= State} of
		{?true, ?true} -> 
			NewAcc = [GroupApply|Acc],
			get_group_list1(RestList, UserId, State, NewAcc);
		{_, _} -> 
			get_group_list1(RestList, UserId, State, Acc)
	end;
get_group_list1([_|RestList], UserId, State, Acc) ->
	get_group_list1(RestList, UserId, State, Acc);
get_group_list1([], _, _, Acc) -> Acc.
	
%% 申请加入队伍
apply_join_group(Player, GroupId) ->
	UserId 		= Player#player.user_id,
    Info 		= Player#player.info,
    Lv 			= Info#info.lv,
    Pro 		= Info#info.pro,
	Field		= [id, user_id, lv, pro,type, group_id, state],
	case mysql_api:select(Field, game_group_apply, [{user_id, UserId}, {group_id, GroupId}]) of
		{?ok, []} ->        		%% 第一次申请该队伍 插入记录
			case mysql_api:insert(game_group_apply, [
												{user_id, UserId},
												{lv, Lv},
												{pro, Pro},
												{type,	1},
												{group_id,	GroupId},
												{state, 	3}
											   ]) of
				{?ok, _, ApplyId} ->
					GroupApplyInfo = group_api:record_group_apply(ApplyId, UserId, Lv, Pro, 1, GroupId, 3),
					group_api:ets_insert_group(?CONST_ETS_GROUP_APPLY, GroupApplyInfo),
					?ok;
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
					{?error, ErrorCode}
			end;
		{?ok, _} ->        %% 有申请过该队伍 不做插入处理
			?ok;
		{?error, Error}->
			?MSG_ERROR("", [Error,erlang:get_stacktrace()])
	end.
%% 	case mysql_api:update(game_group, [{apply_mount, ApplyMount}], [{id, GroupId}]) of
%% 		{?ok, _Result} ->
%% 			ets:update_element(?CONST_ETS_GROUP, GroupId, [{#group.apply_mount, ApplyMount}]),
%% 			?ok;
%% 		{?error, Error} ->
%% 			?MSG_ERROR("Error:~p",[Error]),
%% 			{?error, 110}
%% 	end.

%% 同意申请加入队伍
update_join_group(Group, ApplyGroup, ReqUserId) when is_record(Group, group) andalso is_record(ApplyGroup, group_apply)->
	Pro			= case player_api:get_player_field(ReqUserId, #player.info) of
					  {?ok, Info} when is_record(Info, info) -> Info#info.pro;
					  _ -> ?CONST_SYS_PRO_NULL
				  end,
	OnLineNum	=	Group#group.online_num + 1,
	InGroupNum	=	Group#group.in_group_num +1,
	ProList		=	Group#group.pro_list,
	NewProList	=	[{Pro}|ProList],
	MemberList	=	Group#group.member_list ++ [{ReqUserId}],
	OnLineList	=	Group#group.online_member_list ++ [{ReqUserId}],
	GroupId		=	Group#group.id,
	ApplyGroupId=   ApplyGroup#group_apply.id,
	case mysql_api:update(game_group, [
								  {online_num,          OnLineNum}, 
								  {in_group_num,        InGroupNum}, 
								  {member_list,         misc:encode(MemberList)},
								  {online_member_list,  misc:encode(OnLineList)},
								  {pro_list,		    misc:encode(NewProList)}		
								 ], [{id, GroupId}]) of
		{?ok, _} ->
			ets:update_element(?CONST_ETS_GROUP, GroupId,   [{#group.online_num, OnLineNum}, {#group.in_group_num, InGroupNum},
															 {#group.member_list, MemberList},{#group.online_member_list, OnLineList},
															 {#group.pro_list, NewProList}]);
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
			?ok
	end,
	case mysql_api:update(game_group_apply, [{state, 2}], [{id, ApplyGroupId}]) of
		{?ok, _Result} ->
			ets:update_element(?CONST_ETS_GROUP_APPLY, ApplyGroupId, [{#group_apply.state, 2}]),
			GroupApplyList=	get_group_list(ReqUserId, 2),
			F = fun(GroupApply) when is_record(GroupApply, group_apply)->
				mysql_api:delete(game_group_apply, "id = "++misc:to_list(GroupApply#group_apply.id)),
				ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApply#group_apply.id)
				end,
			lists:foreach(F, GroupApplyList),
			{?ok, MemberList};
		{?error, Error} ->
			?MSG_ERROR("Error:~p",[Error]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%%  踢出队伍
kick_out_group(Player, KickOutId) ->
	UserId		= Player#player.user_id,
	Pro			= case player_api:get_player_field(KickOutId, #player.info) of
					  {?ok, Info} when is_record(Info, info) -> Info#info.pro;
					  _ -> ?CONST_SYS_PRO_NULL
				  end,
	case group_mod:get_group_apply_list(UserId, 2) of
		[]    -> {?error, ?TIP_COMMON_SYS_ERROR};
		Group ->
			GroupId			= Group#group_apply.group_id,
			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
				?null -> {?error, ?TIP_COMMON_SYS_ERROR};
				Group1 ->
					OnLineNum		= Group1#group.online_num - 1,
					InGroupNum		= Group1#group.in_group_num - 1,
					MemberList		= Group1#group.member_list,
					OnLineList		= Group1#group.online_member_list,
					ProList			= Group1#group.pro_list,
					NewProList		= lists:keydelete(Pro, 1, ProList),
					NewMemberList	= lists:delete({KickOutId}, MemberList),
					NewOnLineList	= lists:delete({KickOutId}, OnLineList),
					case mysql_api:update(game_group,  [
														{online_num, 		OnLineNum}, 
														{in_group_num, 		InGroupNum}, 
														{member_list, 	    misc:encode(NewMemberList)},
														{online_member_list, misc:encode(NewOnLineList)},
														{pro_list,           misc:encode(NewProList)}			
													   ], [{id, GroupId}])  of
						{?ok, _} ->
							ets:update_element(?CONST_ETS_GROUP, GroupId,   
											   [{#group.online_num, OnLineNum}, 
												{#group.in_group_num, InGroupNum},
												{#group.member_list, NewMemberList},
												{#group.online_member_list, NewOnLineList},
												{#group.pro_list, NewProList}]);
						{?error, ErrorCode} ->
							?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
							?ok
					end,
					case group_mod:get_group_apply_list(KickOutId, 2) of
						[] 		-> {?error, ?TIP_COMMON_SYS_ERROR};
						Group2  -> 
							Id		    = Group2#group_apply.id,
							WhereList	= "id = "++misc:to_list(Id)++" and user_id="++misc:to_list(KickOutId),
							case mysql_api:delete(game_group_apply, WhereList) of
								{?ok, _, _} ->
									ets_api:delete(?CONST_ETS_GROUP_APPLY, Id),
									{?ok, NewMemberList};
								{?error, ErrorReason} ->
									?MSG_ERROR("Error:~p",[ErrorReason]),
									{?error, ErrorReason}
							end
					end
			end
	end.

%% 退出队伍
quit_group(Player, Group) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Pro				= Info#info.pro,
	GroupId			= Group#group.id,
	OnLineNum		= Group#group.online_num -1,
	InGroupNum		= Group#group.in_group_num - 1,
	MemberList		= Group#group.member_list,
	OnLineList		= Group#group.online_member_list,
	ProList			= Group#group.pro_list,
	NewProList		= lists:keydelete(Pro, 1, ProList),
	NewMemberList	= lists:delete({UserId}, MemberList),
	NewOnLineList	= lists:delete({UserId}, OnLineList),
	Pattern			= #group_apply{user_id = UserId, state = 2, group_id = GroupId, _='_'},
	Temp			= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern),
	case Temp of
		[GroupApply] when is_record(GroupApply, group_apply) -> 
			GroupApplyId	= GroupApply#group_apply.id,
			case mysql_api:delete(game_group_apply, "id = "++misc:to_list(GroupApplyId)) of
				{?ok, _, _} ->
					ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApplyId);
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
					?ok
			end,
			case mysql_api:update(game_group, [{online_num,     OnLineNum},
											   {in_group_num,        InGroupNum},
											   {member_list,         misc:encode(NewMemberList)},
											   {online_member_list,  misc:encode(NewOnLineList)},
											   {pro_list,			misc:encode(NewProList)}
											  ], [{id, GroupId}]) of
				{?ok,_} ->
					ets:update_element(?CONST_ETS_GROUP, GroupId, 
									   [{#group.online_num, OnLineNum}, 
										{#group.in_group_num, InGroupNum},
										{#group.member_list, NewMemberList}, 
										{#group.online_member_list, NewOnLineList},
										{#group.pro_list, NewProList}]),
					{?ok, NewMemberList};
				{?error, ErrorReason} ->
					?MSG_PRINT("ErrorCode=~p~n", [ErrorReason]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		_ -> {?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 成为待组玩家
apply_wating_group(Player) ->
	UserId = Player#player.user_id,
    Info   = Player#player.info,
    Lv     = Info#info.lv,
    Pro    = Info#info.pro,
	case mysql_api:insert(game_group_apply,  [
										 {user_id,  UserId},
                                         {lv,       Lv},
                                         {pro,      Pro},
						   				 {type,	    1},
						   				 {group_id,	0},
						   				 {state, 	4}
						                ]) of
		{?ok, _, ApplyId} ->
			GroupApplyInfo = group_api:record_group_apply(ApplyId, UserId, Lv, Pro, 1, 0, 4),
			group_api:ets_insert_group(?CONST_ETS_GROUP_APPLY, GroupApplyInfo),
			?ok;
		{?error, ErrorCode} ->
            ?MSG_ERROR("insert:~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 取消申请待组状态
cancel_apply_waiting(Player) ->
	Pattern			= #group_apply{user_id = Player#player.user_id, state = 4, _='_'},
	GroupTemp		= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern),
	case GroupTemp of
		[Group] when is_record(Group, group_apply) -> 
			GroupApplyId	= Group#group_apply.id,
			case mysql_api:delete(game_group_apply, "id = "++misc:to_list(GroupApplyId)) of
				{?ok, _, _} ->
					ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApplyId),
					?ok;
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		_ -> ?ok
	end.
	
%% 被邀请玩家同意加入队伍
invite_group(GroupId, Player) ->
    UserId       = Player#player.user_id,
    Info         = Player#player.info,
    Lv           = Info#info.lv,
    Pro          = Info#info.pro,
	Group		 = ets_api:lookup(?CONST_ETS_GROUP, GroupId),
	OnLineNum	 = Group#group.online_num + 1,
	InGroupNum	 = Group#group.in_group_num +1,
	ProList		 = Group#group.pro_list,
	NewProList	 = [{Pro}|ProList],
	NewMemberList= Group#group.member_list ++ [{UserId}],
	NewOnLineList= Group#group.online_member_list ++ [{UserId}],
	case mysql_api:update(game_group, [{online_num,    OnLineNum},
								  {in_group_num,       InGroupNum},
								  {member_list,        misc:encode(NewMemberList)},
								  {online_member_list, misc:encode(NewOnLineList)},
								  {pro_list,           misc:encode(NewProList)}	
								 ], [{id, GroupId}]) of
		{?ok,_} ->
			ets:update_element(?CONST_ETS_GROUP, GroupId,
							   [{#group.online_num, OnLineNum},
								{#group.in_group_num, InGroupNum},
								{#group.member_list, NewMemberList}, 
								{#group.online_member_list, NewOnLineList},
								{#group.pro_list, NewProList}]),
			?ok;
		{?error, ErrorReason} ->
            ?MSG_ERROR("~p", [ErrorReason])
	end,
	case mysql_api:insert(game_group_apply,  [
										 {user_id, UserId},
                                         {lv, Lv},
                                         {pro, Pro},
										 {type,	1},
										 {group_id,	GroupId},
										 {state, 	2}
										]) of
		{?ok, _, ApplyId} ->
			GroupApplyInfo = group_api:record_group_apply(ApplyId, UserId, Lv, Pro, 1, GroupId, 2),
			group_api:ets_insert_group(?CONST_ETS_GROUP_APPLY, GroupApplyInfo),
			GroupApplyList = get_group_list(UserId, 2),
			F = fun(GroupApply) when is_record(GroupApply, group_apply)->
						mysql_api:delete(game_group_apply, "id = "++misc:to_list(GroupApply#group_apply.id)),
						ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApply#group_apply.id)
				end,
			lists:foreach(F, GroupApplyList),
			{?ok, NewMemberList};
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode= ~p ~n", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.	
	
	
	
	
	
	
	
	
	
	
	
	
	
