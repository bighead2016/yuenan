%% Author: Administrator
%% Created: 2012-10-8
%% Description: TODO: Add description to guild_mod
-module(guild_mod).
%%
%% Exported Functions
%%
-include("../include/const.common.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/const.tip.hrl").
-include("../include/const.cost.hrl").
-include("../include/record.guild.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions 
%%
-export([
		 all_list/1,all_list/2, 
		 info/1,info_packet/1,
		 member_list/1, member_list_info/2,
		 apply_list/1,
		 create/3,
         kick_for_timeout/2,
		 disband/1,disband_handle/1,
		 
		 log_list/1,
		 apply/2,apply_cancel/2,deal_with_apply/3,
		 invite/2,deal_with_invite/3,
		 quit/1,kick_out/2, 
		 member_name/1,
		 request_cd_data/1,clean_cd/1,
		 
		 get_skill_add/2,get_skill_add2/2,
		 change_announce/3,
		 remove_duty/2,member_add_cb/2,member_leave_cb/2,
		 impeach_chief/1,change_chief/2,vice_chief/2,
		 promote/1,promote_cb/2,add_log/2,get_pos_num/2,
		 update_guild/2,update_member/2,init_guild_log/2,
		 request_cd_leave_time/1,
		 sup_apply/1,sup_apply_add/2,
         check_name_use/2
		 ]).

%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团列表
all_list(#player{user_id = UserId,guild = Guild}) ->
	GuildId 	= Guild#guild.guild_id,
	all_list(UserId,GuildId).

all_list(UserId,GuildId) ->
	GuildInfo 	= case ets_api:list(?CONST_ETS_GUILD_DATA) of
					[] -> [];
					GuildList ->
						all_list_info(UserId,GuildId,GuildList)
				  end,
	Packet 		= guild_api:msg_sc_list(GuildInfo),
	misc_packet:send(UserId, Packet). 

%% 军团列表信息
all_list_info(_UserId,_GuildId,[]) -> [];
all_list_info(UserId,GuildId,GuildList) ->
	IsCold = is_cold_time(UserId),
	Fun = fun(D) ->
			  Id			= D#guild_data.guild_id,		%% 军团id
			  GuildName 	= D#guild_data.guild_name,		%% 军团名
			  GuildManager	= player_api:get_name(D#guild_data.chief_id),%% 团长名		  
			  GuildLevel 	= D#guild_data.lv,				%% 军团等级
			  NumCurrent	= D#guild_data.num,				%% 人数
			  NumLimit		= D#guild_data.num_max,			%% 限制人数
			  Bulletin 		= D#guild_data.bulletin_out,	%% 对外公告		 
			  Apply			= D#guild_data.apply,
			  ApplyState 	= get_apply_state(UserId,GuildId,Id,Apply,NumCurrent,NumLimit,IsCold),%% 申请信息
              IsApplyFull   = is_apply_full(D#guild_data.apply),
			  % xxx
			  {Id,GuildName,GuildManager,GuildLevel,NumCurrent,NumLimit,Bulletin,ApplyState, IsApplyFull}
	  end,
	[Fun(D) || D <- GuildList].

is_apply_full(ApplyList) when length(ApplyList) >= ?CONST_GUILD_DEFAULT_APPLY_LIMIT -> ?CONST_SYS_TRUE;
is_apply_full(_ApplyList) -> ?CONST_SYS_FALSE.
	
%% 申请状态
get_apply_state(_UserId,GuildId,_GuildId,_ApplyList,_,_,_) when GuildId =/= 0 ->
	?CONST_GUILD_PALYER_STATE_JOIN; %% 已加入
get_apply_state(_,_,_,_,NumCurrent,NumLimit,_) when NumCurrent >= NumLimit ->
	?CONST_GUILD_PALYER_STATE_JOIN; %% 已加入
get_apply_state(UserId,_GuildId,_CheckId,ApplyList,_,_,IsCold) ->
	case lists:member(UserId,ApplyList)  of
		?false  -> %% 未申请
			case IsCold of
				?true -> 
					?CONST_GUILD_PLAYER_STATE_COLD; %% 冷却时间中
				_ -> 
					?CONST_GUILD_PALYER_STATE_APPLY_NO %% 未申请
			end;	
		_Other ->
			?CONST_GUILD_PALYER_STATE_APPLY_YES  %% 申请加入
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团信息 guild_mod:info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info(Player = #player{guild = Guild,net_pid = Pid}) ->
	try
		GuildId 		= Guild#guild.guild_id,
		{?ok,GuildData} = guild_api:get_guild_data(GuildId),
		Guild2			= guild_api:init_donate_guild(Guild),
		Packet 			= info_packet(GuildData),
		Packet2   		= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_DONATE, Guild2#guild.donate_gold),
		misc_packet:send(Pid, <<Packet/binary,Packet2/binary>>),
		{?ok,Player#player{guild = Guild2}}
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

info_packet(GuildData) ->
	GuildName 		= GuildData#guild_data.guild_name,	%% 军团名
	GuildLv 		= GuildData#guild_data.lv,			%% 军团等级
	Num 			= GuildData#guild_data.num,			%% 当前人数
	NumMax 			= GuildData#guild_data.num_max,		%% 最大人数
	
	CreateName 		= GuildData#guild_data.create_name, %% 创建者
	CreateTime 		= GuildData#guild_data.create_time, %% 创建时间
	ChiefName		= player_api:get_name(GuildData#guild_data.chief_id),%% 团长名

	AnnounceIn	 	= GuildData#guild_data.bulletin_in, %% 对内公告
	AnnounceOut 	= <<"">>,							%% 对外公告
	Money			= GuildData#guild_data.money,		%% 资金	
	KickMoney		= GuildData#guild_data.kick_money,	%% 资金
    KickDay         = GuildData#guild_data.remove_day,
	guild_api:msg_sc_data(GuildName,GuildLv,Num,NumMax,CreateName,CreateTime,
						  ChiefName,AnnounceIn,AnnounceOut,Money,KickMoney, KickDay).
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 成员列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
member_list(Player = #player{guild = Guild,net_pid = Pid}) ->
	try 
		GuildId 		= Guild#guild.guild_id,
		{?ok,GuildData} = guild_api:get_guild_data(GuildId),
		MemberList 		= GuildData#guild_data.member_list,
		
		List 			= member_list_info(MemberList,[]),
		Packet1 		= guild_api:msg_sc_member(List),
		Packet2 		= info_packet(GuildData),
		misc_packet:send(Pid, <<Packet1/binary,Packet2/binary>>)
		
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 成员信息
member_list_info([UserId|MemberList],InfoList) ->
	case guild_api:ets_guild_member(UserId) of
		?null ->
			member_list_info(MemberList,InfoList);
		GuildM  ->
			case player_api:get_player_field(UserId, #player.info) of
				{?ok, #info{user_name = Name, pro = Pro, sex = Sex, lv = Lv, time_active = Time}} ->
					DonateT		= GuildM#guild_member.donate_today, %% 今日贡献
					DonateS		= GuildM#guild_member.donate_sum,	%% 总贡献	
					Pos			= GuildM#guild_member.pos,			%% 军团职位
					Flag		= case player_api:check_online(UserId) of
									  ?true -> ?CONST_SYS_TRUE;
									  ?false -> ?CONST_SYS_FALSE
								  end,
					LastTime 	= get_last_time(Flag,Time),			%% 最后离线时间
					MemInfo 	= {UserId,Name,Pos,Lv,Sex,Pro,DonateT,DonateS,LastTime},
					member_list_info(MemberList,[MemInfo|InfoList]);
				_ -> 
					member_list_info(MemberList,InfoList)
			end
	end;
member_list_info([],InfoList) -> InfoList.

%% 取得最后离线时间
get_last_time(?CONST_PLAYER_ONLINE,_Time) -> 0;
get_last_time(_,Time) -> Time.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 申请列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
apply_list(#player{guild = Guild,net_pid = Pid}) ->
	try
		{?ok,GuildData} = guild_api:get_guild_data(Guild#guild.guild_id),
		List			= apply_list_info(GuildData#guild_data.apply),
		Packet 			= guild_api:msg_sc_apply_list(List),
		misc_packet:send(Pid, Packet)
	catch
		throw:{?error,ErrorCode} -> 					 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 申请信息
apply_list_info(ApplyList) ->
	apply_info(ApplyList,[]).

apply_info([UserId|ApplyList],Acc) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{user_name = Name, pro = Pro, sex = Sex, lv = Lv}} ->
            Power = partner_api:caculate_camp_power(UserId),
			apply_info(ApplyList,[{UserId, Name, Lv, Sex, Pro, Power}|Acc]);
		_ -> apply_info(ApplyList,Acc)
	end;
apply_info([],Acc) -> Acc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 创建
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
request_cd_data(UserId) -> 
	case is_cold_time(UserId) of
		?false ->
			guild_api:msg_sc_cd(?CONST_SYS_FALSE); 
		_ ->
			guild_api:msg_sc_cd(?CONST_SYS_TRUE)
	end.

request_cd_leave_time(UserId) ->
	Time 		= misc:seconds(),
	ColdTime 	= get_cold_time(UserId),
	ColdTime2	= ColdTime + ?CONST_GUILD_CD_TIME * 3600, 
	if
		Time >= ColdTime2 ->
			LTime 	= 0;
		?true ->
			LTime 	= ColdTime2 - Time
	end,
	Packet		= guild_api:msg_sc_cd_leave_time(LTime),
	misc_packet:send(UserId, Packet).

clean_cd(#player{user_id = UserId,net_pid = Pid}) ->
	try
		?ok			= check_apply_money(UserId),
		Packet		= guild_api:msg_sc_cd(?CONST_SYS_FALSE),
		misc_packet:send(Pid, Packet)
	catch
		throw:{?error,ErrorCode} -> 
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 创建
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create(Player,GuildName, IsUseCash) when is_record(Player,player) ->
	case check_create(Player,GuildName, IsUseCash) of
		{?error, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH} ->
			{?ok,Player};
		{?error,ErrorCode} ->
			guild_api:error_message(Player,ErrorCode);	
		{?ok, Player2} ->
			{?ok, Player2}
	end.	

%% 创建检查
check_create(Player = #player{info = Info,user_id = UserId,guild = Guild,sys_rank = Sys},GuildName, IsUseCash) ->
	try
		?ok				= check_cold_time(UserId),										%% 检查是否冷却时间内
		?ok				= check_not_in_guild(Guild#guild.guild_id), 					%% 检查不在军团
		?ok				= check_create_sys(Sys),										%% 检查开放系统
		?ok				= check_money(UserId, IsUseCash),											%% 检查金钱
		?ok				= check_create_name(GuildName),									%% 检查军团名			
		?ok				= check_name_use(GuildName,Info#info.user_name),				%% 检查军团名是否存在		
		
		GuildData0		= init_guild_data(UserId,Info,GuildName),
        GuildData = 
            case IsUseCash of
                false ->
                    GuildData0;
                _ ->
                    Skill = guild_skill_mod:skill_up2(1, GuildData0),
                    GuildData0#guild_data{exp = 54811, lv = 2, skill = Skill}
            end,
		{?ok,GuildId}	= guild_db_mod:guild_data_insert(GuildData),					%% 插入数据库
		GuildData2		= GuildData#guild_data{guild_id = GuildId},
		case check_create2(Player,GuildId,GuildName,GuildData2, IsUseCash) of
			{?ok,Player2} ->
				admin_log_api:log_guild_operate(Player2, GuildId, ?CONST_GUILD_OPERATE_CREATE, 0, 0, 0, 0, 0, 0),
				{?ok,Player2};
			{?error,Error} ->
				create_delete(UserId,GuildId),	%% 特殊处理--创建失败，从库中删除
				{?error,Error}
		end
	catch
		throw:{?error,ErrorCode} -> 
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%% 创建检查（出错了--从数据库中删除）
check_create2(Player = #player{user_id = UserId,info = Info,guild = Guild},GuildId,GuildName,GuildData, IsUseCash) ->
	try
		Postion			= ?CONST_GUILD_POSITION_CHIEF,	%% 职位
		DonateSum		= Guild#guild.donate_sum,
		GuildMember 	= init_guild_member(UserId,Info,GuildId,GuildName,Postion,DonateSum), 	%% 成员信息
		Guild2			= Guild#guild{guild_id = GuildId, guild_name = GuildName,guild_pos = Postion},				
		Packet1			= guild_api:msg_sc_create(GuildId),
		Packet2			= message_api:msg_notice(?TIP_GUILD_CREATE),
		Packet			= <<Packet1/binary,Packet2/binary>>,
		
		Player2			= Player#player{guild = Guild2},
		{?ok,Player3}	= member_add_state(Player2,Packet,GuildId,GuildName,Postion,GuildData#guild_data.lv),	%% 更新player
		?ok				= check_money_minus(UserId, IsUseCash),									%% 扣取金钱
%% 		BroPacket 		= message_api:msg_notice(?TIP_GUILD_CREATE_SUCCESS, [{?TIP_SYS_COMM,Info#info.user_name}, 
%% 																			 {?TIP_SYS_COMM,GuildName}]),
%% 		misc_app:broadcast_world(BroPacket),		%% 广播		
		delete_guild_apply(UserId),					%% 删除申请	
		insert_guild(GuildData),					%% 插入ets
		insert_member(GuildMember),					%% 插入ets、数据库
		{?ok,Player3}
	catch
		throw:{?error,ErrorCode} -> 
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%% 检查军团名
check_create_name(GuildName) ->
	List = misc:to_list(GuildName),
	if
		length(List) > 15 ->
			throw({?error,?TIP_GUILD_NAME_LONG});
		?true -> ?ok
	end.

%% 创建失败
create_delete(UserId,GuildId) ->
	ets_api:delete(?CONST_ETS_GUILD_MEMBER, UserId),
	ets_api:delete(?CONST_ETS_GUILD_DATA, GuildId),
	guild_db_mod:delete_member(UserId),
	guild_db_mod:delete_data(GuildId).

%% 扣取金钱
check_money_minus(UserId, IsUseCash) ->
	{CostType, Cost}	= 
        case IsUseCash of
            false ->
                {?CONST_SYS_GOLD_BIND, 1000000};
            true ->
                {?CONST_SYS_CASH, 20}
        end,
	case player_money_api:minus_money(UserId,CostType,Cost,?CONST_COST_GUILD_CREATE) of 
		?ok -> ?ok;
		{?error, _ErrorCode} -> 
			throw({?error, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH})
	end.
	
check_create_sys(Sys) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_GUILD) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_GUILD_SYS_NOT_OPEN})
    end.

%% 检查不在军团
check_not_in_guild(0) -> ?ok;
check_not_in_guild(_) ->
	throw({?error,?TIP_GUILD_JION}).

%% 检查金钱
check_money(UserId, IsUseCash) ->
    case IsUseCash of
        false ->
        	case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, 1000000) of %% 先判断金钱
        		{?error, ErrorCode} ->
        			 throw({?error, ErrorCode});
        		{?ok, _, ?false} ->
        			 throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH}); 
        		{?ok, _, _} -> ?ok
        	end;
        _ ->
            case player_money_api:check_money(UserId, ?CONST_SYS_CASH, 20) of %% 先判断金钱
                {?error, ErrorCode} ->
                     throw({?error, ErrorCode});
                {?ok, _, ?false} ->
                     throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH}); 
                {?ok, _, _} -> ?ok
            end
    end.

%% 检查名字是否被使用
check_name_use(GuildName,_UserName) ->
	MS = ets:fun2ms(fun(T) when T#guild_data.guild_name =:= GuildName
						 -> T end),
	case ets_api:select(?CONST_ETS_GUILD_DATA,MS) of
		[]-> ?ok;
		[_Value | _ ]->
			throw({?error,?TIP_GUILD_CREATE_NAME})
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 解散
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disband(Player = #player{guild = Guild}) ->
	try
		GuildId			= Guild#guild.guild_id,									%% 军团id
		?ok				= check_disband_pos(Guild#guild.guild_pos), 			%% 检查职位
		{?ok,GuildData} = guild_api:get_guild_data(GuildId),					%% 获取GuildData
		?ok				= check_disband_num(GuildData#guild_data.num), 			%% 检查军团人数
		guild_serv:disband_cast(GuildData),
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_DISBAND, 0, 0, 0, 0, 0, 0),
		{?ok,Player}
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

disband_handle(GuildData) ->
	GuildId		= GuildData#guild_data.guild_id,
	disband_apply(GuildData#guild_data.apply,GuildId), 	%% 删除申请列表
	disband_member(GuildData#guild_data.member_list), 	%% 删除军团成员
	delete_guild(GuildId),								%% 删除军团
	?ok.

%% 检查职位
check_disband_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_disband_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). 	%% 没有权限

%% 检查军团人数
check_disband_num(Num) when Num < ?CONST_GUILD_DISBAND_GUILD_NUM_LIMIT -> ?ok;
check_disband_num(_Num) ->
	throw({?error, ?TIP_GUILD_DISBAND_NUM}). %% 不能直接解散

%% 删除申请列表
disband_apply([],_GuildId) -> ?ok;
disband_apply([UserId|ApplyList],GuildId) ->
	delete_guild_apply(UserId,GuildId),
	disband_apply(ApplyList,GuildId).
	
%% guild_create_mod:disband_handle(1,10).
%% 删除军团成员
disband_member([]) -> ?ok;
disband_member([UserId|MemberList]) ->
	robot_world_api:leave_guild(UserId),
	party_api:quit_guild(UserId),		%% 宴会替身处理
	player_api:process_send(UserId, ?MODULE, member_leave_cb, [?TIP_GUILD_DISBAND_SUCCESS]),
	delete_member(UserId),
	disband_member(MemberList).

%% 设置状态(加入)
member_add_cb(Player,[TipPacket,GuildPos,GuildData]) ->	
	GuildId		= GuildData#guild_data.guild_id,
	GuildName	= GuildData#guild_data.guild_name,
	GuildLv		= GuildData#guild_data.lv,
	member_add_state(Player,TipPacket,GuildId,GuildName,GuildPos,GuildLv).
%% 设置状态
member_add_state(Player,TipPacket,GuildId,GuildName,GuildPos,GuildLv) ->
	Guild		= Player#player.guild,
	TaskData	= Player#player.task,
	Guild2		= Guild#guild{guild_id = GuildId,guild_name = GuildName,guild_pos = GuildPos}, 
	Player2 	= Player#player{guild = Guild2},									%% 设置#guild{}
	Player3		= task_api:update_guild(Player2),
    PacketTask 	= guild_api:msg_unshadow_task(TaskData),							%% 设置任务
	GPacket		= guild_api:msg_change(Guild2,GuildLv),								%% 军团信息
	Packet		= <<GPacket/binary,TipPacket/binary, PacketTask/binary>>,
	misc_packet:send(Player3#player.net_pid, Packet),
	map_api:change_guild(Player3),													%% 场景广播
	
	delete_cold_time(Player3#player.user_id),
	bless_api:send_be_blessed(Player3, ?CONST_RELATIONSHIP_BTYPE_GUILD, GuildName),	%% 祝福 
	{?ok,Player4} 	= achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_JOIN_GUILD, 0, 1),	%% 成就
	{?ok,Player5}	= welfare_api:add_pullulation(Player4, ?CONST_WELFARE_GUILD, 0, 1),
	{?ok,Player5}.

%% 设置状态(退出)
member_leave_cb(Player,[TipPacket]) ->	
	member_leave_state(Player,TipPacket).
%% 设置状态
member_leave_state(Player = #player{task = TaskData,guild = Guild,net_pid = Pid},MessageId) ->
	TipPacket	= message_api:msg_notice(MessageId), 
	Guild2		= guild_api:init_guild(Guild),
	Player2 	= Player#player{guild = Guild2},					%% 设置#guild{}

    PacketTask 	= guild_api:msg_shadow_task(TaskData),				%% 设置任务
	GPacket		= guild_api:msg_change(Guild2,0),					%% 军团信息
	Packet		= <<GPacket/binary,TipPacket/binary, PacketTask/binary>>,
	misc_packet:send(Pid, Packet),
	map_api:change_guild(Player2),	%% 场景广播
	{?ok,Player2}.		

%% 设置职位
promote_cb(Player = #player{guild = Guild,net_pid = Pid},[Pos]) ->
	Guild2 		= Guild#guild{guild_pos = Pos},%% 设置#guild{}
	Packet 		= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_POS, Pos),	%% 改变职位
	Player2		= Player#player{guild = Guild2},
	misc_packet:send(Pid, Packet),
	{?ok,Player2}.
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 申请
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
apply(Player = #player{user_id = UserId,guild = Guild,info = Info,net_pid = Pid,sys_rank =Sys},ApplyId) ->
	try	
		?ok				= check_apply_sys(Sys),											%% 检查模块
		?ok				= check_not_in_guild(Guild#guild.guild_id),						%% 检查是否不在军团
		{?ok,GuildData} = guild_api:get_guild_data(ApplyId),							%% 取得GuildData
		ApplyList 		= GuildData#guild_data.apply,									%% 申请列表
		
		?ok				= check_not_in_apply(UserId,ApplyList),							%% 是否在申请列表中
		?ok				= check_guild_num(GuildData),	 								%% 检查是否人数上限
		IsFull				= check_apply_num(ApplyList),									%% 检查申请人数
		?ok				= check_apply_money(UserId),
		
        GuildName = GuildData#guild_data.guild_name,
		ApplyList2 = [UserId|ApplyList],
        ApplyList3 = 
            case IsFull == ?ok of
                true ->
                    ApplyList2;											%% 加入列表
                false ->
                    [LastId] = lists:sublist(ApplyList2, length(ApplyList2), 1),
                    ?MSG_ERROR("LastId is ~w, ",[LastId]),
                    TipPacket1 = message_api:msg_notice(?TIP_GUILD_APPLY_FAILED,[{?TIP_SYS_COMM,GuildName}]),
                    misc_packet:send(LastId, TipPacket1),
                    ApplyList2 -- [LastId]
            end,
        ?MSG_ERROR("ApplyList3 is ~w, ",[ApplyList3]),
 		ChiefId			= GuildData#guild_data.chief_id,
 		PosList         = GuildData#guild_data.pos_list,
		
		Packet			= guild_api:msg_sc_apply(ApplyId,?CONST_GUILD_PALYER_STATE_APPLY_YES),
 		TipPacket 		= message_api:msg_notice(?TIP_GUILD_APPL_NOTICE,[{?TIP_SYS_COMM,Info#info.user_name}]),
		
		ets_api:update_element(?CONST_ETS_GUILD_DATA, ApplyId,[{#guild_data.apply, ApplyList3}]),
		add_guild_apply(UserId,Info,ApplyId),
 		
		misc_packet:send(Pid, Packet),
		apply_notice(ChiefId,PosList,TipPacket),
		admin_log_api:log_guild_operate(Player, ApplyId, ?CONST_GUILD_OPERATE_APPLY, 0, 0, 0, 0, 0, 0)
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} -> ?ok;
		throw:{?error,ErrorCode} -> 					 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 申请通知团长和副团长
apply_notice(ChiefId,PosList,Packet) ->
	case lists:keyfind(?CONST_GUILD_POSITION_VICE_CHIEF,1,PosList) of
		?false -> List = [];
		{_,List} -> ?ok
	end,
	List2 = [ChiefId|List],
	apply_notice2(List2,Packet).

apply_notice2([],_) -> ?ok;
apply_notice2([UserId|List],Packet) -> 
	misc_packet:send(UserId, Packet),
	apply_notice2(List,Packet).
	
%% 检查申请是否扣取元宝（冷却时间内需扣取元宝）
check_apply_money(UserId) ->
	case is_cold_time(UserId) of
		?true ->
			case player_money_api:minus_money(UserId,?CONST_SYS_CASH,?CONST_GUILD_CLEAN_CD,?CONST_COST_GUILD_RESET) of 
				?ok -> 
					delete_cold_time(UserId),
					Packet 	= guild_api:msg_sc_cd(?CONST_SYS_FALSE),
					misc_packet:send(UserId, Packet),
					?ok;
				{?error, _ErrorCode} -> 
					throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
			end;
		_ -> ?ok
	end.

%% 检查等级
check_apply_sys(Sys) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_GUILD) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_GUILD_SYS_NOT_OPEN})
    end.

%% 是否不在申请列表中
check_not_in_apply(UserId,ApplyList) ->
	case lists:member(UserId,ApplyList) of
		?false -> ?ok;
		?true ->
			throw({?error,?TIP_GUILD_IN_APPLY})
	end.

%% 是否在申请列表中
check_in_apply(UserId,ApplyList) ->
	case lists:member(UserId,ApplyList) of
		?false -> 
			throw({?error,?TIP_GUILD_NOT_IN_APPLY});
		?true -> ?ok
	end.

%% 检查申请人数
check_apply_num(ApplyList) when length(ApplyList) >= ?CONST_GUILD_DEFAULT_APPLY_LIMIT ->
	false; %% 成员已满
check_apply_num(_ApplyList) -> ?ok.	

%% 检查人数
check_guild_num(GuildData) ->
	NumCurrent 		= GuildData#guild_data.num,						%% 当前军团人数
	NumLimit 		= GuildData#guild_data.num_max,					%% 军团人数上限
	check_guild_num(NumCurrent,NumLimit).
check_guild_num(NumCurrent,NumLimit) when NumCurrent >= NumLimit ->
	throw({?error, ?TIP_GUILD_FULL}); %% 成员已满
check_guild_num(_,_) -> ?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 取消申请 cancel_apply(UserId,GuildId) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
apply_cancel(Player = #player{user_id = UserId,net_pid = Pid},GuildId) ->
	try
		{?ok,GuildData}	= guild_api:get_guild_data(GuildId),		%% 取得GuildData
		ApplyList 		= GuildData#guild_data.apply,				%% 申请列表
		?ok				= check_in_apply(UserId,ApplyList),			%% 检查是否在申请列表
		ApplyList2 		= lists:delete(UserId,ApplyList),			%% 从申请列表中删除
		 
		Packet			= guild_api:msg_sc_apply(GuildId,?CONST_GUILD_PALYER_STATE_APPLY_NO), 
		TipPacket		= message_api:msg_notice(?TIP_GUILD_APPLY_CANCLE),
		delete_guild_apply(UserId,GuildId),
		
		ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.apply, ApplyList2}]),
		misc_packet:send(Pid, <<Packet/binary,TipPacket/binary>>),
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_CANCEL_APPLY, 0, 0, 0, 0, 0, 0)
	catch
		throw:{?error,ErrorCode} -> 					 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 处理申请
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
deal_with_apply(Player,ApplyId,Res) when is_record(Player,player) ->
	try
		Guild			= Player#player.guild,
		GuildId 		= Guild#guild.guild_id,
		?ok 			= check_deal_apply_pos(Guild#guild.guild_pos), 	%% 检查职位
		{?ok,GuildData}	= guild_api:get_guild_data(GuildId),			%% 取得GuildData
		ApplyList 		= GuildData#guild_data.apply,					%% 申请列表
		?ok				= check_apply_lists(ApplyId,ApplyList),			%% 检查是否在申请列表
		deal_with_apply2(Player,GuildData,ApplyId,Res)
	catch
		throw:{?error,ErrorCode} -> 	
			apply_list(Player),
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查职位
check_deal_apply_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_deal_apply_pos(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
check_deal_apply_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 不是团长

%% 检查是否在申请列表
check_apply_lists(ApplyId,ApplyList) ->
	case lists:member(ApplyId,ApplyList) of
		?false ->
 			throw({?error, ?TIP_GUILD_MEM_CANCEL_APPLY}); %% 已经处理
		_ -> ?ok
	end.

deal_with_apply2(Player,GuildData,ApplyId,?CONST_SYS_FALSE) -> %% 拒绝
	GuildId				= GuildData#guild_data.guild_id,					%% 军团id
	GuildName			= GuildData#guild_data.guild_name,					%% 军团名
	ApplyList 			= GuildData#guild_data.apply,						%% 申请列表
	ApplyList2  		= lists:delete(ApplyId, ApplyList),					%% 从列表中删除

	List				= apply_list_info(ApplyList2),
	Packet 				= guild_api:msg_sc_apply_list(List),
	Packet2				= message_api:msg_notice(?TIP_GUILD_DEAL_DELETE), 
	misc_packet:send(Player#player.net_pid, <<Packet/binary,Packet2/binary>>),
	
	ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.apply, ApplyList2}]),	
	delete_guild_apply(ApplyId,GuildId),
	
	TipPacket 			= message_api:msg_notice(?TIP_GUILD_REFUSE_JOIN,[{?TIP_SYS_COMM,GuildName}]),
	Packet15524			= guild_api:msg_sc_apply(GuildId,?CONST_GUILD_PALYER_STATE_APPLY_NO),
	misc_packet:send(ApplyId, <<TipPacket/binary,Packet15524/binary>>),
	admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_REJECT_APPLY, ApplyId, 0, 0, 0, 0, 0),
	?ok;
deal_with_apply2(Player,GuildData,ApplyId,_) -> %% 同意
	?ok					= check_m_cold_time(ApplyId),					%% 检查对方是否在冷却时间
	{?ok,AddInfo,AddGuild}		= get_player_info(ApplyId),						%% 申请者信息
    {?ok,GuildData2}	= add_guild_member(GuildData,ApplyId,AddInfo,AddGuild),	%% 
	Pos					= ?CONST_GUILD_POSITION_COMMON,					%% 成员
	TipPacket 			= message_api:msg_notice(?TIP_GUILD_JOIN_SUCCESS,[{?TIP_SYS_COMM,GuildData2#guild_data.guild_name}]),
	ApplyList			= GuildData2#guild_data.apply, 					%% 申请列表
	List				= apply_list_info(ApplyList),
	
	Packet1 			= guild_api:msg_sc_apply_list(List),
	Packet2				= info_packet(GuildData2),
	Packet3				= message_api:msg_notice(?TIP_GUILD_DEAL_ADD),
	
	misc_packet:send(Player#player.net_pid, <<Packet1/binary,Packet2/binary,Packet3/binary>>),
	player_api:process_send(ApplyId, ?MODULE, member_add_cb, [TipPacket,Pos,GuildData2]),%% 通知对方
	admin_log_api:log_guild_operate(Player, GuildData#guild_data.guild_id, ?CONST_GUILD_OPERATE_AGREE_APPLY, ApplyId, 0, 0, 0, 0, 0),
	?ok.

get_player_info(UserId) -> 
	case player_api:get_player_fields(UserId, [#player.info, #player.guild]) of
		{?ok, [Info, Guild]} -> {?ok, Info, Guild};
		_ -> throw({?error,?TIP_COMMON_NO_THIS_PLAYER})
	end.
	
%% 成功加入 
add_guild_member(GuildData = #guild_data{guild_id = GuildId,log = Log,guild_name = GuildName,invite = InviteList,
										 num_max = NumLimit,member_online = MemOnline,apply = ApplyList,
										 num = NumCurrent, member_list = MemberList},AddId,AddInfo,AddGuild) ->
	
	?ok							= check_mem_not_in(AddId),					%% 检查是否加入军团
	?ok							= check_guild_num(NumCurrent,NumLimit),		%% 检查军团人数
	
	Pos							= ?CONST_GUILD_POSITION_COMMON,				%% 成员
	MemberList2					= [AddId|MemberList], 						%% 加入列表
	MemOnline2  				= get_mem_online(AddId,MemOnline), 			%% 在线成员
	ApplyList2  				= lists:delete(AddId,ApplyList),			%% 从申请列表中删除
	InviteList2 				= get_keytake_invite(AddId,InviteList), 	%% 邀请列表
	Content 					= init_guild_log(?CONST_GUILD_LOG_JOIN,[{2,AddInfo#info.user_name,AddId}]),
	Log2 						= add_log(Log,Content),						%% 日志
	NumCurrent2 				= length(MemberList2),						%% 人数
	
	GuildData2 					= GuildData#guild_data{
													    apply				= ApplyList2,
									   					invite				= InviteList2,
									   					log					= Log2,
									  					member_online		= MemOnline2,
									   					num 				= NumCurrent2,
									   					member_list 		= MemberList2},
	
	GuildMember 				= init_guild_member(AddId,AddInfo,GuildId,GuildName,Pos,AddGuild#guild.donate_sum),
	insert_member(GuildMember),	
	team_api:refresh_enter_guild_author(AddId, GuildId),
	guild_db_mod:update_data(GuildData2),
	insert_guild(GuildData2),
	delete_guild_apply(AddId),
	{?ok,GuildData2}.

%% 检查是否加入军团
check_mem_not_in(ApplyId) ->
	case guild_api:ets_guild_member(ApplyId) of
		?null -> ?ok;
		_ ->
			throw({?error,?TIP_GUILD_INVITE_IN}) 
	end.

%% 在线列表
get_mem_online(UserId,MemOnline) ->
	case player_api:check_online(UserId) of
		?true ->
			[UserId|MemOnline];
		?false ->
			MemOnline
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 邀请
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
invite(Player = #player{user_id = UserId,guild = Guild,info = Info},InviteId) ->
	try
		GuildId			= Guild#guild.guild_id,
		Country 		= Info#info.country,
		?ok				= check_invite_pos(Guild#guild.guild_pos),	%% 检查职位
		?ok				= check_invite_member(InviteId),			%% 检查对方是否加入军团
		?ok				= check_m_cold_time(InviteId),				%% 检查冷却时间
		
		{?ok,GuildData} = guild_api:get_guild_data(GuildId),		%% 取得GuildData
		?ok				= check_guild_num(GuildData), 				%% 检查军团人数
		{?ok,IList} 	= invite_check(UserId,Country,GuildData,InviteId), %% 检查是否在申请列表中
		GuildName		= GuildData#guild_data.guild_name,
		
		TipPacket		= message_api:msg_notice(?TIP_GUILD_INVITE_SUCCESS), 
		Packet 			= guild_api:msg_sc_invite(GuildId,GuildName,UserId,Info#info.user_name),
		misc_packet:send(InviteId, Packet),
		misc_packet:send(Player#player.net_pid, TipPacket),
		
		ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.invite, IList}]),
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_INVITE, InviteId, 0, 0, 0, 0, 0)
	catch
		throw:{?error,ErrorCode} -> 					 
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.


%% 邀请检查
invite_check(UserId,Country,#guild_data{invite = InviteList},InviteId) ->
	case lists:keytake(InviteId, #guild_invite.user_id, InviteList) of
		?false ->
			?ok				= check_invite_num(InviteList),				%% 检查邀请数量
			invite_check2(UserId,Country,InviteList,InviteId);			%% 不在列表中检查
		{value, GuildInvite = #guild_invite{invite_time = InviteTime}, InviteList2} ->
			Time 			= misc:seconds(),
			?ok				= check_invite_time(Time,InviteTime),
			GuildInvite2 	= GuildInvite#guild_invite{invite_time = Time},
			InviteList3 	= [GuildInvite2|InviteList2],
			{?ok,InviteList3}
	end.	

%% 检查职位
check_invite_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_invite_pos(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
check_invite_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 不是团长

%% 检查对方是否加入军团
check_invite_member(InviteId) ->
	case guild_api:ets_guild_member(InviteId) of
		?null -> ?ok;
		_ -> 
			throw({?error,?TIP_GUILD_INVITE_IN}) %% 已经加入军团
	end.

%% 检查邀请时间
check_invite_time(Time,InviteTime) when Time - InviteTime =< ?CONST_GUILD_INVITE_TIME -> 
	throw({?error, ?TIP_GUILD_INVITE_WAIT}); %% 刚邀请，请等玩家回复
check_invite_time(_Time,_InviteTime) -> ?ok.

%% 检查邀请人数
check_invite_num(InviteList) when length(InviteList) >= ?CONST_GUILD_DEFAULT_APPLY_LIMIT -> %% 邀请人数已满
	throw({?error,?TIP_GUILD_INVITE_FULL}); 
check_invite_num(_) -> ?ok.

%% 检查邀请等级
check_invite_sys(Sys) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_GUILD) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_GUILD_M_SYS_NOT_OPEN})
    end.

%% 检查邀请国家是否相同
check_invite_country(Country,Country) -> ?ok;
check_invite_country(_,_) ->
	throw({?error,?TIP_GUILD_COUNTRY}). %% 国家不同

get_invite_player(InviteId) ->
	case player_api:get_player_fields(InviteId, [#player.info, #player.sys_rank]) of
		{?ok, [MemInfo, Sys]} -> {?ok, MemInfo, Sys};
		_ -> throw({?error,?TIP_GUILD_NO_PLAYER}) %% 玩家不存在
	end.

%% 不在邀请列表中检查
invite_check2(_UserId,Country,InviteList,InviteId) ->
	{?ok,MemInfo,Sys} 	= get_invite_player(InviteId),							%% 被邀请信息
	?ok					= check_invite_sys(Sys),								%% 检查等级
	?ok					= check_invite_country(MemInfo#info.country,Country), 	%% 检查国家
	GuildInvite 		= init_guild_invite(InviteId,misc:seconds()),			%% GuildInvite
	{?ok,[GuildInvite|InviteList]}.

%% 检查是否在列表中
check_in_invite(UserId,InviteList) ->
	case lists:keytake(UserId, #guild_invite.user_id, InviteList) of 
		?false -> 
			throw({?error,?TIP_GUILD_NOT_INVITE}); %% 不在申请列表中;
		{value, _Tuple, InviteList2} ->
			{?ok,InviteList2}
	end.	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 处理邀请
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
deal_with_invite(Player = #player{user_id = UserId,guild = Guild},GuildId,?CONST_SYS_FALSE) -> %%不同意
	try
		?ok 				= check_not_in_guild(Guild#guild.guild_id),		%% 检查是否不在军团
		{?ok,GuildData} 	= guild_api:get_guild_data(GuildId),			%% 取得GuildData
		InviteList 			= GuildData#guild_data.invite,					%% 取得邀请列表
		{?ok,InviteList2} 	= check_in_invite(UserId,InviteList),			%% 检查是否在邀请列表中
		
		ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.invite, InviteList2}]),
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_REFUSE_INVITE, 0, 0, 0, 0, 0, 0),
		{?ok,Player}
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
deal_with_invite(Player = #player{user_id = UserId,info = Info,guild = Guild},GuildId,?CONST_SYS_TRUE) ->%% 同意
	try
		?ok 				= check_not_in_guild(Guild#guild.guild_id),				%% 检查是否不在军团
		?ok					= check_cold_time(UserId),
		
		{?ok,GuildData} 	= guild_api:get_guild_data(GuildId),					%% 取得GuildData
		{?ok,_InviteList2} 	= check_in_invite(UserId,GuildData#guild_data.invite), 	%% 检查是否在邀请列表中
		
		{?ok,GuildData2}	= add_guild_member(GuildData,UserId,Info,Guild),
		Pos					= ?CONST_GUILD_POSITION_COMMON,
		TipPacket 			= message_api:msg_notice(?TIP_GUILD_JOIN_SUCCESS,[{?TIP_SYS_COMM,GuildData2#guild_data.guild_name}]),
		GuildId				= GuildData2#guild_data.guild_id,
		GuildName			= GuildData2#guild_data.guild_name,
		GuildLv				= GuildData2#guild_data.lv,
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_AGREE_INVITE, 0, 0, 0, 0, 0, 0),
		member_add_state(Player,TipPacket,GuildId,GuildName,Pos,GuildLv)
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 申请加入
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_guild_apply(UserId,#info{user_name = UserName},GuildId) ->
	case guild_api:ets_guild_apply(UserId) of
		?null ->
			GuildApply 	= init_guild_apply(UserId,UserName,GuildId),
			insert_apply(GuildApply);
		GuildApply ->
			GuildList	= GuildApply#guild_apply.guild_list,
			GuildList2 	= case lists:member(GuildId, GuildList) of
							  ?false ->
								  [GuildId|GuildList];
							  _ ->
								  GuildList
						  end,
			GuildApply2	= GuildApply#guild_apply{guild_list = GuildList2},	
			insert_apply(GuildApply2)
	end.
%% 删除申请	
delete_guild_apply(UserId,GuildId) ->
	case guild_api:ets_guild_apply(UserId) of
		?null -> ?ok;
		GuildApply ->
			List		= GuildApply#guild_apply.guild_list,
			List2 		= lists:delete(GuildId, List),
			GuildApply2 = GuildApply#guild_apply{guild_list = List2},
			insert_apply(GuildApply2)
	end.

%% 删除申请
delete_guild_apply(UserId) ->
	case guild_api:ets_guild_apply(UserId) of
		?null -> ?ok;
		GuildApply ->
			List		= GuildApply#guild_apply.guild_list,
			delete_guild_apply2(UserId,List),
			delete_apply(UserId)
	end.
	
delete_guild_apply2(_,[]) -> ?ok;
delete_guild_apply2(UserId,[GuildId|List]) ->
	case guild_api:ets_guild_data(GuildId) of
		?null -> ?ok;
		GuildData ->
			ApplyList 	= GuildData#guild_data.apply,
			ApplyList2	= lists:delete(UserId,ApplyList),
			GuildData2	= GuildData#guild_data{apply = ApplyList2},
			insert_guild(GuildData2)
	end,
	delete_guild_apply2(UserId,List).

%% 邀请列表数据
get_keytake_invite(UserId,InviteList) ->
	case lists:keytake(UserId, #guild_invite.user_id, InviteList) of
		?false ->
			InviteList;
		{value,_,InviteList2} ->
			InviteList2
	end.	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 退出
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
quit(Player = #player{user_id = UserId,info = Info,guild = Guild}) ->
	try 
		?ok				= check_quit_pos(Guild#guild.guild_pos),			%% 检查职位
		{?ok,GuildData} = guild_api:get_guild_data(Guild#guild.guild_id),	%% 取得GuildData
		{?ok,GuildMember} 	= guild_api:get_guild_member(UserId),									%% 取得GuildMember
		Content 		= init_guild_log(?CONST_GUILD_LOG_QUIT,[{2,Info#info.user_name,UserId}]),
		
		member_leave(UserId,Guild#guild.guild_pos,GuildData,Content,GuildMember#guild_member.donate_money),
		{?ok,Player2} 	= member_leave_state(Player,?TIP_GUILD_LEAVE_SUCCESS),
 		insert_cold_time(UserId),
		admin_log_api:log_guild_operate(Player2, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_QUIT, 0, 0, 0, 0, 0, 0),
		robot_world_api:leave_guild(UserId),						%% 乱天下替身处理
		party_api:quit_guild(Player2),			%% 宴会替身处理
		{?ok,Player2}
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查职位
check_quit_pos(?CONST_GUILD_POSITION_CHIEF) ->
	throw({?error,?TIP_GUILD_NOT_LEAVE}); %% 军团长不能退出
check_quit_pos(_) -> ?ok.

%% 成员离开
member_leave(UserId,Pos,GuildData,Content,Money) ->
	MemberList2 	= lists:delete(UserId, GuildData#guild_data.member_list), 	%% 成员列表
	MemOnline2  	= lists:delete(UserId, GuildData#guild_data.member_online),	%% 在线成员
	NumCurrent2 	= length(MemberList2),										%% 人数
	PosList2		= promote_delete(UserId,Pos,GuildData#guild_data.pos_list), %% 职位数量
	Log2 			= add_log(GuildData#guild_data.log,Content),				%% 日志		
	KickMoney		= GuildData#guild_data.kick_money + Money,
	GuildData2		= GuildData#guild_data{member_list 		= MemberList2,
										   num		 		= NumCurrent2,
										   member_online 	= MemOnline2,
										   log 				= Log2,
										   pos_list 		= PosList2,
										   kick_money		= KickMoney},
    team_api:refresh_exit_guild_author(UserId, GuildData#guild_data.guild_id),
	delete_member(UserId), %% 删除成员
	update_guild(GuildData2,[{member_list,MemberList2},{num,NumCurrent2},
							 {log,Log2},{pos_list,PosList2},{kick_money,KickMoney}]), %% 更新军团信息
	{?ok,GuildData2}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 踢出成员
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kick_out(Player = #player{guild = Guild,info = Info,user_id = UserId},MemId) ->
	try
		?ok					= check_kick_out_id(UserId,MemId),
		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),						%% 取得GuildData
		{?ok,GuildMember} 	= guild_api:get_guild_member(MemId),									%% 取得GuildMember
		MPos				= GuildMember#guild_member.pos,
		MName				= player_api:get_name(MemId),
		KickMoney			= GuildMember#guild_member.donate_money,
		?ok					= check_kick_out_pos(Guild#guild.guild_pos,MPos),						%% 检查职位
		Content 			= init_guild_log(?CONST_GUILD_LOG_KICK,[{2,MName,MemId},{2,Info#info.user_name,UserId}]),%% 日志
		{?ok,GuildData2}	= member_leave(MemId,MPos,GuildData,Content,KickMoney),					%% 更新GuildData
		
		Packet1 			= message_api:msg_notice(?TIP_GUILD_TICK_OUT_SUCCESS),
		InfoList 			= member_list_info(GuildData2#guild_data.member_list,[]),
 		Packet2 			= guild_api:msg_sc_member(InfoList),
		Packet3				= info_packet(GuildData2),
 		Packet 				= <<Packet1/binary,Packet2/binary,Packet3/binary>>,
		misc_packet:send(Player#player.net_pid,Packet),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_KICK_OUT, MemId, 0, 0, 0, 0, 0),
		robot_world_api:leave_guild(MemId),
		party_api:quit_guild(MemId),			%% 宴会替身处理
		player_api:process_send(MemId, ?MODULE, member_leave_cb, [?TIP_GUILD_TICK_OUT])			%% 通知对方
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.


kick_for_timeout(GuildData, MemId) ->
    {?ok,GuildMember}   = guild_api:get_guild_member(MemId),                                    %% 取得GuildMember
    MPos                = GuildMember#guild_member.pos,
    KickMoney           = GuildMember#guild_member.donate_money,
    member_leave(MemId,MPos,GuildData, KickMoney).                 %% 更新GuildData

%% 成员离开
member_leave(UserId,Pos,GuildData,Money) ->
    MemberList2     = lists:delete(UserId, GuildData#guild_data.member_list),   %% 成员列表
    PosList2        = promote_delete(UserId,Pos,GuildData#guild_data.pos_list), %% 职位数量
    NumCurrent2     = length(MemberList2),
    KickMoney       = GuildData#guild_data.kick_money + Money,
    GuildData2      = GuildData#guild_data{member_list      = MemberList2,
                                           num              = NumCurrent2,
                                           pos_list         = PosList2,
                                           kick_money       = KickMoney},       
    delete_member(UserId), %% 删除成员
    GuildData2.

%% 检查踢出成员-不能踢出自己
check_kick_out_id(UserId,UserId) ->
	throw({?error,?TIP_GUILD_KICK_OUT_SELF});
check_kick_out_id(_,_) -> ?ok.
	
%% 检查职位-是否团长
check_kick_out_pos(?CONST_GUILD_POSITION_CHIEF,_) -> ?ok;
check_kick_out_pos(?CONST_GUILD_POSITION_VICE_CHIEF,?CONST_GUILD_POSITION_COMMON) -> ?ok;
check_kick_out_pos(?CONST_GUILD_POSITION_VICE_CHIEF,_) -> 
	throw({?error,?TIP_GUILD_VICE_TICK});%% 副团长只能踢出成员
check_kick_out_pos(_,_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 没有权限

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 修改公告
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_announce(Player = #player{net_pid = Pid,guild = Guild},Content,Type) ->
	try
		GuildId			= Guild#guild.guild_id,
		?ok				= check_announce_list(Content),						%% 检查字数	
		?ok				= check_change_announce_pos(Guild#guild.guild_pos),	%% 检查职位
		{?ok,GuildData}	= guild_api:get_guild_data(GuildId),				%% 取得GuildData
		case Type of
			1 -> % 1外部公告 
				GuildData2 	= GuildData#guild_data{bulletin_out = Content},
				List		= [{bulletin_out,Content}], 
				Packet		= guild_api:msg_sc_announce(Type,Content,GuildId);
			2 -> % 2内部公告
				GuildData2 	= GuildData#guild_data{bulletin_in = Content},
				List		= [{bulletin_in,Content}],	
				Packet1 	= message_api:msg_notice(?TIP_GUILD_MODIFY),
				Packet2 	= info_packet(GuildData2),
				Packet		= <<Packet1/binary,Packet2/binary>>	
		end,
		update_guild(GuildData2,List),
		misc_packet:send(Pid,Packet)
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Player#player.net_pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查公告字数
check_announce_list(Content) ->
	List = misc:to_list(Content),
	if
		length(List) > 240 ->
			throw({?error,?TIP_GUILD_ANNOUNCE_LENGTH}); 
		?true -> ?ok
	end.

%% 检查职位
check_change_announce_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_change_announce_pos(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
check_change_announce_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 没有权限

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 修改留言
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% change_message(Player,Content) when is_record(Player,player) ->
%% 	try
%% 		Guild 				= Player#player.guild,
%% 		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),		%% 取得GuildData
%% 		{?ok,GuildMember}	= guild_api:get_guild_member(Player#player.user_id),	%% 取得GuildMember
%% 		GuildMember2 		= GuildMember#guild_member{introduce=Content},			%% 更新GuildMember
%% 		update_member(GuildMember2,[{introduce,Content}]),
%% 		
%% 		MembetList 			= GuildData#guild_data.member_list,						%% 军团成员列表
%% 		List 				= member_list_info(MembetList,[]),						%% 成员信息
%% 		Packet 				= guild_api:msg_sc_member(List),
%% 		TipPacket 			= message_api:msg_notice(?TIP_GUILD_MODIFY),
%% 		misc_packet:send(Player#player.net_pid,<<Packet/binary,TipPacket/binary>>)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更换团长
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_chief(Player = #player{user_id = UserId},UserId) ->
	{?ok, Player};
change_chief(Player = #player{guild = Guild,user_id = UserId,net_pid = Pid},ChiefId) -> 
	try
		?ok				= chech_change_chief_pos(Guild#guild.guild_pos),			%% 检查职位
		{?ok,GuildData}	= guild_api:get_guild_data(Guild#guild.guild_id),			%% 取得GuildData
		{?ok,GuildM}	= guild_api:get_guild_member(UserId),						%% 取得GuildMember
		{?ok,ChiefM}	= guild_api:get_guild_member(ChiefId),						%% 取得对方的GuildMember
		?ok				= chech_change_chief_pos2(ChiefM#guild_member.pos),			%% 检查对方的职位	
		Guild2 			= Guild#guild{guild_pos = ?CONST_GUILD_POSITION_VICE_CHIEF},%% 更新职位
		ChiefName		= player_api:get_name(ChiefId),
		change_chief_success(UserId,ChiefId,ChiefName,ChiefM,GuildM,GuildData),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_CHANGE_CHIEF, ChiefId, 0, 0, 0, 0, 0),
		{?ok,Player#player{guild = Guild2}}
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查职位
chech_change_chief_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
chech_change_chief_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 不是团长 没有权限

%% 检查对方职位
chech_change_chief_pos2(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
chech_change_chief_pos2(_) ->
	throw({?error,?TIP_GUILD_NOT_VICE_CHIEF}). %% 对方不是副团长

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更换成功
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_chief_success(UserId,ChiefId,ChiefName,ChiefM,GuildM,GuildData) ->
	Pos1		= ?CONST_GUILD_POSITION_CHIEF,					%% 团长
	Pos2		= ?CONST_GUILD_POSITION_VICE_CHIEF,				%% 副团长
	ChiefM2 	= ChiefM#guild_member{pos = Pos1},				%% 更改职位	
	GuildM2		= GuildM#guild_member{pos = Pos2},				%% 更改职位	
	PosList		= GuildData#guild_data.pos_list,				%% 职位列表
	MembetList 	= GuildData#guild_data.member_list,				%% 成员列表
	
	PosList3 	= case lists:keytake(Pos2,1,PosList) of
					  ?false -> PosList;
					  {value,{_,List},PosList2} ->
						  List2 	= lists:delete(ChiefId, List),
						  List3 	= [UserId|List2],
						  [{Pos2,List3}|PosList2]
				  end,	
	Log			= promote_log(Pos1,ChiefName,ChiefId,GuildData#guild_data.log), %% 日志
	GuildData2 	= GuildData#guild_data{chief_id = ChiefId,chief_name = ChiefName,pos_list = PosList3,log = Log},
	player_api:process_send(ChiefId, ?MODULE, promote_cb, [Pos1]),
	update_member(ChiefM2,[{pos, Pos1}]),
	update_member(GuildM2,[{pos, Pos2}]),
	update_guild(GuildData2,[{chief_id,ChiefId},{chief_name,ChiefName},{pos_list,PosList3},{log,Log}]),
	
	InfoList 	= member_list_info(MembetList,[]),
	Packet1 	= guild_api:msg_sc_member(InfoList),
	Packet2 	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_POS, Pos2),	
	Packet3		= info_packet(GuildData2),
	TipPacket	= message_api:msg_notice(?TIP_GUILD_PROMOT_SUCCESS), 
	TipPacket2  = message_api:msg_notice(?TIP_GUILD_CHANGE_CHIEF,[{?TIP_SYS_COMM,GuildData#guild_data.guild_name}]),
	
	Packet		= <<Packet1/binary,Packet2/binary,Packet3/binary,TipPacket/binary>>,
	misc_packet:send(ChiefId,TipPacket2),
	misc_packet:send(UserId, Packet).

%% guild_create_mod:get_pos_num(1,1).
%% 取得职位限制人数
get_pos_num(Pos,KillLv) ->
	case data_guild:get_guild_position({Pos,KillLv}) of
		?null -> 0; 
		#rec_guild_position{num_limit = NumLimit} ->
			NumLimit 
	end.
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 移除职位
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
remove_duty(#player{user_id = UserId},UserId) ->
	?ok;
remove_duty(Player = #player{guild = Guild,net_pid = Pid},RemoveId) ->
	try				
  		?ok					= check_remove_duty_pos(Guild#guild.guild_pos),		%% 检查职位
		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),	%% 取得GuildData
		{?ok,GuildMember}	= guild_api:get_guild_member(RemoveId),				%% 取得GuildMember
		Pos2				= GuildMember#guild_member.pos,						%% 取得职位
		?ok					= check_remove_duty_pos2(Pos2),						%% 检查职位
		NewPos				= ?CONST_GUILD_POSITION_COMMON,
		GuildMember2 		= GuildMember#guild_member{pos = NewPos},			%% 更新GuildMember
		RemoveName			= player_api:get_name(RemoveId),
		remove_pos_list(GuildData,RemoveId,RemoveName,Pos2),								%% 从职位列表中删除
		player_api:process_send(RemoveId, ?MODULE, promote_cb, [NewPos]),		%% 通知对方
		update_member(GuildMember2,[{pos,NewPos}]),
		
		List 				= member_list_info(GuildData#guild_data.member_list,[]),
		Packet 				= guild_api:msg_sc_member(List),
		PacketTip			= message_api:msg_notice(?TIP_GUILD_REMOVE_POS),
		misc_packet:send(Pid, <<Packet/binary,PacketTip/binary>>),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_REMOVE_POS, RemoveId, 0, 0, 0, 0, 0)
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查职位
check_remove_duty_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_remove_duty_pos(_) -> 
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 没有权限

%% 检查对方职位
check_remove_duty_pos2(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
check_remove_duty_pos2(_) -> 
	throw({?error,?TIP_GUILD_NOT_POS}). %% 没有职位

%% 从列表中删除
remove_pos_list(GuildData,UserId,RemoveName,Pos) ->
	PosList2 	= promote_delete(UserId,Pos,GuildData#guild_data.pos_list),
	Content		= down_log(?CONST_GUILD_POSITION_COMMON,RemoveName,UserId),
	Log			= add_log(GuildData#guild_data.log,Content),
	GuildData2 	= GuildData#guild_data{pos_list = PosList2,
									   log		= Log},
	update_guild(GuildData2,[{pos_list,PosList2},
							 {log,Log}]).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 日志列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_list(#player{guild = Guild,net_pid = Pid}) ->
	try
		{?ok,GuildData}	= guild_api:get_guild_data(Guild#guild.guild_id),	%% 取得GuildData
		{?ok,List}		= log_list2(GuildData#guild_data.log),
		Packet 			= guild_api:msg_sc_log(List),
		misc_packet:send(Pid, Packet)
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

log_list2(Logs) ->
	log_list2(Logs,[]).

log_list2([],List) -> {?ok,List};
log_list2([Log|Logs],List) ->
	Time 		= Log#guild_log.time,
	Type		= Log#guild_log.type,
	Content		= Log#guild_log.list,
	log_list2(Logs,[{Time,Type,Content}|List]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 弹劾团长
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
impeach_chief(Player = #player{user_id = UserId,guild = Guild,info = Info}) ->
	try
		?ok					= check_impeach_chief(Guild#guild.guild_pos),			%% 检查职位
		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),		%% 取得GuildData

		ChiefId				= GuildData#guild_data.chief_id,						%% 团长id
		{?ok,LastTime}		= get_last_time(ChiefId),
		?ok					= check_impeach_rank(UserId,GuildData),					%% 检查军团功勋排名
		{?ok,ChiefMember} 	= guild_api:get_guild_member(ChiefId), 					%% 团长ChiefMember
		
		?ok					= check_date_limit(LastTime,?CONST_GUILD_IMPEACH_TIME),	%% 检查离线天数
		{?ok,GuildMember}	= guild_api:get_guild_member(UserId), 					%% 取得GuildMember
		{?ok,Guild2}		= impeach_success(UserId,Info#info.user_name,Guild,GuildData,ChiefMember,ChiefId,GuildMember),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_IMPEACH_CHIEF, ChiefId, 0, 0, 0, 0, 0),
		{?ok,Player#player{guild = Guild2}}
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 取得最后离线时间
get_last_time(UserId) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok,_,?CONST_PLAYER_ONLINE} -> throw({?error,?TIP_GUILD_IMPEACH_FAIL}); %% 不能弹劾
		{?ok, #info{time_active = 0}} -> 
			throw({?error,?TIP_GUILD_IMPEACH_FAIL}); %% 不能弹劾
		{?ok, #info{time_active = TimeActive}} -> {?ok, TimeActive};
		_ -> throw({?error,?TIP_GUILD_IMPEACH_FAIL}) %% 不能弹劾
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 弹劾成功
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
impeach_success(UserId,Name,Guild,GuildData,ChiefMember,ChiefId,GuildMember) ->
	Pos1			= ?CONST_GUILD_POSITION_CHIEF,
	Pos2			= ?CONST_GUILD_POSITION_COMMON,
	Pos3			= GuildMember#guild_member.pos,
	ChiefName		= player_api:get_name(ChiefId),
	ChiefMember2 	= ChiefMember#guild_member{pos = Pos2},					%% 更新旧团长的信息
	GuildMember2 	= GuildMember#guild_member{pos = Pos1},					%% 更新自己的成员信息
	PosList			= GuildData#guild_data.pos_list,						%% 职位列表			
	NewPosList		= case lists:keytake(Pos3, 1, PosList) of				%% 更新职位列表
						  ?false -> PosList;
						  {value,{_,List},PosList2} ->
								List2		= lists:delete(UserId, List),
								[{Pos2,List2}|PosList2]
					  end,	
	
	Guild2			= Guild#guild{guild_pos = Pos1},						%% 更新职位
 	Log				= init_guild_log(?CONST_GUILD_LOG_IMPACHIEF,[{2,ChiefName,ChiefId}]), 	%% 日志
	Logs			= add_log(GuildData#guild_data.log,Log),				%% 加入日志
	GuildData2		= GuildData#guild_data{chief_id = UserId, chief_name = Name,
										   pos_list = NewPosList,log = Logs}, %% 更新GuildData
	
	update_member(ChiefMember2,[{pos,Pos2}]),		
	update_member(GuildMember2,[{pos,Pos1}]),
	update_guild(GuildData2,[{chief_id,UserId},{chief_name,Name},{pos_list,NewPosList},{log,Logs}]),
	MemberList		= GuildData#guild_data.member_list,						%% 成员列表
	ListInfo 		= member_list_info(MemberList,[]),						%% 成员信息
	Packet1			= guild_api:msg_sc_member(ListInfo),
	Packet2 		= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_POS, Pos1),	
	Packet3			= info_packet(GuildData2),
	Packet			= <<Packet1/binary,Packet2/binary,Packet3/binary>>,
	misc_packet:send(UserId, Packet),
	player_api:process_send(ChiefId, ?MODULE, promote_cb, [Pos2]),
	{?ok,Guild2}.

%% 检查功勋排名是不是前3
check_impeach_rank(UserId,GuildData) -> 
	case is_rank(UserId,GuildData,3) of
		?true -> ?ok;
		_ ->
			throw({?error,?TIP_GUILD_IMPEACH})  
	end.

%% 检查弹劾职位
check_impeach_chief(?CONST_GUILD_POSITION_CHIEF) -> 
	throw({?error,?TIP_GUILD_IMPEACH_YOURSELF}); %% 团长不能弹劾
check_impeach_chief(_) -> ?ok.
	

%% 检查弹劾天数
check_date_limit(LastTime,Num) ->	
	Time  = misc:seconds(),
  	Time2 = (86400 * Num) + LastTime,
	if
		Time - Time2 >= 0 -> ?ok;
		?true ->
			throw({?error,?TIP_GUILD_IMPEACH_FAIL}) %% 不能弹劾
	end.
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 提升副团长
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vice_chief(Player = #player{guild = Guild,user_id = UserId,net_pid = Pid},ViceId) ->
	try
		?ok				= check_vice_chief_id(UserId,ViceId),
		?ok				= check_vice_chief_pos(Guild#guild.guild_pos),						%% 检查职位
		{?ok,GuildD}	= guild_api:get_guild_data(Guild#guild.guild_id),					%% 取得GuildData
		{?ok,ViceM}		= guild_api:get_guild_member(ViceId),								%% 取得对方GuildMember
		VicePos			= ViceM#guild_member.pos,											%% 对方职位
		?ok				= check_vice_chief_pos2(VicePos),									%% 检查对方职位
%% 		?ok				= check_vice_chief_rank(ViceId,GuildD),								%% 检查对方排名
		{?ok,PosList}	= check_vice_pos_list(GuildD#guild_data.pos_list,ViceId,VicePos), 	%% 检查职位列表
		Pos 			= ?CONST_GUILD_POSITION_VICE_CHIEF,
		vice_chief_success(Pid,Pos,ViceId,GuildD,ViceM,PosList),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_PROMOTE_POS, ViceId, 0, 0, 0, 0, Pos)
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
 
%% 检查id
check_vice_chief_id(UserId,UserId) ->
	throw({?error,?TIP_GUILD_CHEIF_PROMOTE_SELF}); %% 不是团长   
check_vice_chief_id(_,_) -> ?ok.

%% 检查职位
check_vice_chief_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_vice_chief_pos(_) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}). %% 不是团长

%% 检查对方职位
check_vice_chief_pos2(?CONST_GUILD_POSITION_CHIEF) -> 
	throw({?error,?TIP_GUILD_CHEIF_PROMOTE_SELF}); %% 不是团长
check_vice_chief_pos2(?CONST_GUILD_POSITION_VICE_CHIEF) -> 
	throw({?error,?TIP_GUILD_IS_VECH_CHIEF}); %% 对方是副团长
check_vice_chief_pos2(_) -> ?ok.
	
%% 检查排名
%% check_vice_chief_rank(ViceId,GuildData) ->
%% 	case is_rank(ViceId,GuildData,3) of
%% 		?true -> ?ok;
%% 		_ ->
%% 			throw({?error,?TIP_GUILD_EXPLOIT_RANK}) %% 功勋排名不是前3
%% 	end.

%% 检查职位列表
check_vice_pos_list(PosList,ViceId,VicePos) ->
	Pos 	= ?CONST_GUILD_POSITION_VICE_CHIEF,
	case lists:keytake(Pos,1,PosList) of
		?false ->
			PosList2 	= [{Pos,[ViceId]}|PosList],
			PosList3 	= promote_delete(ViceId,VicePos,PosList2),
			{?ok,PosList3};
		{value,{_,List},_} when length(List) >= 2  ->
			throw({?error,?TIP_GUILD_POS_FULL}); %% 职位已满
		{value,{_,List},PosList2} ->
			List2 		= [ViceId|List], 
			PosList3 	= [{Pos,List2}|PosList2],
			PosList4 	= promote_delete(ViceId,VicePos,PosList3),
			{?ok,PosList4}
	end.
	
%% 提升成功
vice_chief_success(Pid,Pos,ViceId,GuildData,ViceMember,PosList) ->
	MemberList		= GuildData#guild_data.member_list,
	ViceName		= player_api:get_name(ViceId), 
	Log				= promote_log(Pos,ViceName,ViceId,GuildData#guild_data.log),
	GuildData2		= GuildData#guild_data{pos_list = PosList,log = Log},
	ViceMember2 	= ViceMember#guild_member{pos = Pos},

	update_member(ViceMember2,[{pos,Pos}]),
	update_guild(GuildData2,[{pos_list,PosList}]),
	player_api:process_send(ViceId, ?MODULE, promote_cb, [Pos]),
	
	List 			= member_list_info(MemberList,[]),
	Packet 			= guild_api:msg_sc_member(List),
	TipPacket		= message_api:msg_notice(?TIP_GUILD_PROMOT_SUCCESS), 
	TipPacket2  	= message_api:msg_notice(?TIP_GUILD_VICE_CHIEF,[{?TIP_SYS_COMM,GuildData#guild_data.guild_name}]),
	
	misc_packet:send(ViceId, TipPacket2),
	misc_packet:send(Pid, <<Packet/binary,TipPacket/binary>>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 提升职位
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
promote(Player = #player{guild = Guild,user_id = UserId}) when is_record(Player,player) ->
	try
		?ok				= check_promote_pos(Guild#guild.guild_pos),								%% 检查职位
		{?ok,GuildD}	= guild_api:get_guild_data(Guild#guild.guild_id),						%% 取得guild_data
		{?ok,GuildM}	= guild_api:get_guild_member(UserId),									%% 取得guild_member
		
		?ok				= check_promote_donate(GuildM#guild_member.donate_sum), 				%% 检查排名
		GuildPos2 		= Guild#guild.guild_pos - 1,											%% 提升的职位
		PosList 		= GuildD#guild_data.pos_list,											%% 职位列表		
		KillLv			= get_skill_lv(GuildD#guild_data.skill,?CONST_GUILD_SKILL_TYPE_MEMBER), %% 府兵制等级	
		Num				= get_pos_num(GuildPos2,KillLv),										%% 职位人数
		case lists:keytake(GuildPos2, 1, PosList) of
			?false -> %% 直接提升
				promote_success(Player,UserId,Guild,[],PosList,GuildPos2,GuildM,GuildD,[]);
			{value,{_,List},PosList2} when length(List) >= Num -> %% 需要根据贡献排行
				promote2(Player,GuildPos2,List,PosList2,Num,GuildM,GuildD);
			{value,{_,List},PosList2} ->  %% 直接提升
				promote_success(Player,UserId,Guild,List,PosList2,GuildPos2,GuildM,GuildD,[])
		end
	catch
		throw:{?error,ErrorCode} -> 	
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
	
%% 需要根据贡献排行（很蛋疼）
promote2(Player,GuildPos,List,PosList,Num,GuildMember,GuildData) ->
 	Exploit 	= GuildMember#guild_member.donate_sum,
	UserId 		= Player#player.user_id,
	Guild		= Player#player.guild,
	case promote_split(UserId,Exploit,List,Num) of %% 根据贡献排行分列表
		{[],_} ->	
			promote_success(Player,UserId,Guild,List,PosList,GuildPos,GuildMember,GuildData,[]);
		{[{_,UserId}|_],_} ->
			throw({?error,?TIP_GUILD_PROMOTE_NOT_ENOUGH}); %% 功勋不够不能提升
		{[{Exploit2,_}|_],_} when Exploit =:= Exploit2 ->
			throw({?error,?TIP_GUILD_PROMOTE_NOT_ENOUGH}); %% 功勋不够不能提升
		{[{_,MemId}|_],_} ->
			GuildMem	= guild_api:ets_guild_member(MemId),
			GuildPos2	= GuildPos + 1,
			GuildMem2 	= GuildMem#guild_member{pos = GuildPos2},	
			update_member(GuildMem2,[{pos,GuildPos2}]),
			player_api:process_send(MemId, ?MODULE, promote_cb, [GuildPos2]),
			NewPosList	= promote_add(MemId,GuildPos2,PosList),
			List2 		= lists:delete(MemId, List),
			DName		= player_api:get_name(MemId), 
			Content		= down_log(GuildPos2,DName,MemId),
			promote_success(Player,UserId,Guild,List2,NewPosList,GuildPos,GuildMember,GuildData,Content)
	end. 

%% guild_create_mod:promote3(4,10,[],2).
%% 根据贡献排行分列表-列表1、列表2 （在列表1表示在排行的范围内）
promote_split(UserId,Exploit,List,Num) ->
 	RankList 	= promote_info(List,[]),
	RankList2	= [{Exploit,UserId}|RankList],
	RankList3 	= lists:sort(RankList2),
	Num2		= length(RankList3) - Num,
	lists:split(Num2, RankList3).

promote_delete(_UserId,?CONST_GUILD_POSITION_COMMON,PosList) ->
	PosList;
promote_delete(_UserId,?CONST_GUILD_POSITION_CHIEF,PosList) ->
	PosList;
promote_delete(UserId,Pos,PosList) ->
	case lists:keytake(Pos,1,PosList) of
		?false ->
			PosList;
		{value,{_,List},PosList2} ->
			List2 = lists:delete(UserId, List),
			[{Pos,List2}|PosList2]
	end.

promote_add(_UserId,?CONST_GUILD_POSITION_COMMON,PosList) -> PosList;
promote_add(_UserId,?CONST_GUILD_POSITION_CHIEF,PosList) -> PosList;
promote_add(UserId,Pos,PosList) ->
	case lists:keytake(Pos,1,PosList) of
		?false ->
			PosList;
		{value,{_,List},PosList2} ->
			List2 = [UserId|List],
			[{Pos,List2}|PosList2]
	end.
	
promote_info([],Acc) -> Acc;
promote_info([Uid|List],Acc) ->
	Exploit = get_exploit(Uid), 
	promote_info(List,[{Exploit,Uid}|Acc]).

%% 检查职位
check_promote_pos(Pos) when Pos =< ?CONST_GUILD_POSITION_ELDER ->
	throw({?error,?TIP_GUILD_NOT_PROMOT}); %% 不能提升
check_promote_pos(_) -> ?ok.

%% 检查功勋
check_promote_donate(CurrentDonate)  when CurrentDonate =< 0 -> 
	throw({?error,?TIP_GUILD_PROMOTE_NOT_ENOUGH}); %% 功勋不够不能提升
check_promote_donate(_) -> ?ok.

%% 提升成功
promote_success(Player,UserId,Guild,List,PosList,GuildPos,GuildMember,GuildData,Content) ->
	List2 		= [UserId|List],
	PosList2 	= [{GuildPos,List2}|PosList],
	PosList3 	= promote_delete(UserId,GuildPos+1,PosList2),
	MemberList  = GuildData#guild_data.member_list,
	DName		= player_api:get_name(UserId), 
	Log			= promote_log(GuildPos,DName,UserId,GuildData#guild_data.log),
	Log2		= case Content of
					  [] -> Log;
					  _ -> add_log(Log,Content)
				  end,

	GuildMemb2 	= GuildMember#guild_member{pos = GuildPos},
	GuildData2	= GuildData#guild_data{pos_list = PosList3,
									   log		= Log2},
	Guild2		= Guild#guild{guild_pos = GuildPos},
	
	update_member(GuildMemb2,[{pos,GuildPos}]),
	update_guild(GuildData2,[{pos_list,PosList3},
							 {log,Log2}]),
	
	ListInfo 	= member_list_info(MemberList,[]),
	Packet1 	= guild_api:msg_sc_member(ListInfo),
	Packet2 	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_POS, GuildPos),	
	TipPacket	= message_api:msg_notice(?TIP_GUILD_PROMOT_SUCCESS), 
	
	Packet		= <<Packet2/binary,Packet1/binary,TipPacket/binary>>,
	misc_packet:send(Player#player.net_pid, Packet),
	admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_PROMOTE_POS, 0, 0, 0, 0, 0, GuildPos),
	{?ok,Player#player{guild = Guild2}}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 增加一条日志
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_log(Logs,Log) ->
	N		= ?CONST_GUILD_LOGS_NUM,
	if
		length(Logs) >= N ->
			{Logs2,_} = lists:split(N-1, Logs),
			[Log|Logs2];
		?true ->
			[Log|Logs]
	end.

%% 提升职位日志 
promote_log(Pos,Name,UserId,Logs) ->
	Content	= case Pos of
				  ?CONST_GUILD_POSITION_CHIEF ->
					  init_guild_log(?CONST_GUILD_LOG_CHIEF,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_VICE_CHIEF ->
					  init_guild_log(?CONST_GUILD_LOG_VICE_CHIEF,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_ELDER ->
					  init_guild_log(?CONST_GUILD_LOG_ELDER,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_ELITE ->
					  init_guild_log(?CONST_GUILD_LOG_ELITE,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_EXECUTIVE ->
					  init_guild_log(?CONST_GUILD_LOG_EXECUTIVE,[{2,Name,UserId}]);
				  _ ->
					  init_guild_log(?CONST_GUILD_LOG_MEMBER,[{2,Name,UserId}])
			  end,
 	add_log(Logs,Content).

down_log(Pos,Name,UserId) -> 
	Content	= case Pos of
				  ?CONST_GUILD_POSITION_VICE_CHIEF ->
					  init_guild_log(?CONST_GUILD_LOG_DOWN_VICE_CHIEF,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_ELITE ->
					  init_guild_log(?CONST_GUILD_LOG_DOWN_ELITE,[{2,Name,UserId}]);
				  ?CONST_GUILD_POSITION_EXECUTIVE ->
					  init_guild_log(?CONST_GUILD_LOG_DOWN_EXECUTIVE,[{2,Name,UserId}]);
				  _ ->
					  init_guild_log(?CONST_GUILD_LOG_DOWN_MEMBER,[{2,Name,UserId}]) 
			  end,
	Content.

%% 获得技能加成的比例
get_skill_add(Player,Type) ->
	Guild 	= Player#player.guild,
	GuildId	= Guild#guild.guild_id,
	case guild_api:ets_guild_data(GuildId) of
		?null -> 0;
		GuildData ->
			Skill = GuildData#guild_data.skill,
			get_skill_add2(Skill,Type)
	end.

get_skill_add2(Skill,Type) when Type =:= ?CONST_GUILD_SKILL_TYPE_GROWTH -> %% 石工
	Lv =  get_skill_lv(Skill,Type),
	case data_guild:get_guild_skill({Type,Lv}) of
		?null -> 0;
		DataSkill ->
			DataSkill#rec_guild_skill.effect
	end;
get_skill_add2(Skill,Type) -> %% 除以10000
	Lv =  get_skill_lv(Skill,Type),
	case data_guild:get_guild_skill({Type,Lv}) of
		?null -> 0;
		DataSkill ->
			DataSkill#rec_guild_skill.effect/?CONST_SYS_NUMBER_TEN_THOUSAND
	end.

%% 获取技能等级
get_skill_lv(Skill,Type) ->
	case lists:keyfind(Type, #guild_skill.skill_id, Skill) of
		?false ->
			0;
		GuildSkill ->
			GuildSkill#guild_skill.skill_lv
	end.
	
%% 是否在排名内
is_rank(UserId,GuildData,Num) when Num > 0 ->
	MemberList 		= GuildData#guild_data.member_list,
	if
		length(MemberList) =< Num ->
			?true;
		?true ->
			RankList 		= get_rank_list(MemberList),
			RankList2		= lists:sort(RankList),
			{_,RankList3} 	= lists:split(length(MemberList) - Num, RankList2),
			is_rank2(UserId, 2, RankList3)
	end;
is_rank(_UserId,_GuildData,_Num) ->
	?false.

is_rank2(UserId, 2, RankList) ->
	case lists:keyfind(UserId, 2, RankList) of
		?false ->
			?false;
		_ ->
			?true
	end.
	
%% lists:sort([{2,1},{1,2},{3,1}]).
%% 贡献排行
get_rank_list(MemberList) ->
	get_rank_list(MemberList,[]).

get_rank_list([],Acc) -> Acc;
get_rank_list([Uid|MemberList],Acc) ->
	Exploit = get_exploit(Uid),
	get_rank_list(MemberList,[{Exploit,Uid}|Acc]).

%% 取得总贡献
get_exploit(Uid) ->
	case guild_api:ets_guild_member(Uid) of
		#guild_member{donate_sum = Exploit} ->
			Exploit;
		_ ->
			0
	end.

%% 初始技能
get_init_guild_skill() -> 
	case data_guild:get_guild_skill_init() of
		?null -> [];
		Data ->
			[ #guild_skill{skill_id 	= D#rec_guild_skill.skill_id,
						   skill_lv 	= D#rec_guild_skill.lv} 
							|| D <- Data,is_record(D,rec_guild_skill)
			]
	end.

member_name(#player{guild = Guild}) when Guild#guild.guild_pos =/= 1 ->
	?ok;
member_name(#player{guild = Guild,net_pid = Pid}) ->
	case guild_api:ets_guild_data(Guild#guild.guild_id) of
		?null -> ?ok;
		#guild_data{member_list = List} ->
			F = fun(Id,Acc) ->
						case guild_api:ets_guild_member(Id) of
							?null ->
								Acc;
							_ ->
								Name		= player_api:get_name(Id), 
								[{Name}|Acc]
						end
				end,
			NameList 	= lists:foldl(F, [], List),
			Packet		= guild_api:msg_sc_member_name(NameList),
			misc_packet:send(Pid, Packet)
	end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insert_guild(GuildData) ->
	guild_api:insert_guild_data(GuildData).

update_guild(GuildData,List) ->
	GuildId = GuildData#guild_data.guild_id,
	guild_api:insert_guild_data(GuildData),
	guild_db_mod:update_data(GuildId,List).

delete_guild(GuildId) ->
	ets_api:delete(?CONST_ETS_GUILD_DATA, GuildId),
	guild_db_mod:delete_data(GuildId).

insert_member(GuildMember) ->
	guild_api:insert_guild_member(GuildMember),
	guild_db_mod:guild_member_insert(GuildMember).

update_member(GuildMember,List) ->
	UserId	= GuildMember#guild_member.user_id,
	guild_api:insert_guild_member(GuildMember),
	guild_db_mod:update_member(UserId,List).
	
delete_member(UserId) ->
	guild_db_mod:delete_member(UserId),
	ets_api:delete(?CONST_ETS_GUILD_MEMBER, UserId).

insert_apply(GuildApply) ->
	ets_api:insert(?CONST_ETS_GUILD_APPLY, GuildApply).

delete_apply(UserId) ->
	ets_api:delete(?CONST_ETS_GUILD_APPLY, UserId).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_guild_data(ChiefId,Info,GuildName) ->
	{?ok,Ctn}		= ctn_api:init(100, 100),
	ChiefName		= Info#info.user_name,
	SkillList 		= get_init_guild_skill(),											%% 技能
	NumLimit		= ?CONST_GUILD_CRAETE_MEM_COUNT,									%% 人数上限
	CreatTime		= misc:seconds(),													%% 创建时间	
	Content 		= init_guild_log(?CONST_GUILD_LOG_CREATE,[{0,GuildName,0},
															  {2,ChiefName,ChiefId}]),	%% 日志内容
	Log 			= add_log([],Content),												%% 日志
	#guild_data{
				 guild_name 		= GuildName,       		%% 军团名称	
				 lv 				= 1,            		%% 军团等级	
				 num 				= 1,            		%% 军团当前人数	
				 num_max 			= NumLimit,        		%% 军团人数上限	
				 chief_id 			= ChiefId,          	%% 军团团长ID	
				 chief_name 		= ChiefName,       		%% 军团团长名字	
				 create_name 		= ChiefName,       		%% 军团创建玩家名
				 bulletin_in 		= <<"">>,    			%% 军团内部公告	
				 bulletin_out 		= <<"">>,    			%% 军团外部公告	
				 create_time 		= CreatTime,   			%% 军团创建时间

				 member_list		= [ChiefId],			%% 军团成员列表	
				 member_online		= [ChiefId],			%% 军团成员列表	
				 skill 				= SkillList,			%% 军团技能  
				 apply 				= [],					%% 军团邀请
 				 invite 			= [],					%% 军团申请
				 pos_list			= [],					%% 军团职位
				 log 				= Log,					%% 军团日志
				 ctn				= Ctn					%% 军团仓库
				}.

init_guild_member(UserId,Info,GuildId,GuildName,Postion,DonateSum) ->
	#guild_member{
				 user_id 			= UserId,           	%% 角色ID	
				 user_name 			= Info#info.user_name,  %% 角色昵称	
				 guild_id 			= GuildId,          	%% 军团ID	
				 guild_name	 		= GuildName,			%% 军团名称
				 donate_today 		= 0,            		%% 每天捐献的铜币总和	
 				 donate_sum 		= DonateSum,            %% 所有贡献总和	
				 power				= Info#info.power,		%% 战力	
				 pos	 			= Postion,          	%% 职位	
				 introduce 			= <<"">>	       		%% 内部留言			
				}.
	
init_guild_apply(UserId,UserName,GuildId) ->
	#guild_apply{
				 user_id 			= UserId,           	%% 申请角色ID	
				 user_name 			= UserName,         	%% 玩家名字	
				 guild_list			= [GuildId]				%% 申请军团列表
				}.	

init_guild_invite(UserId,InviteTime) ->
	#guild_invite{
				 user_id 			= UserId,          		%% 角色ID	
				 invite_time 		= InviteTime        	%% 邀请时间
				 }.

init_guild_log(Type,List) ->
	#guild_log{
			   type					= Type,					%% 日志类型
			   time					= misc:seconds(),		%% 时间	
			   list					= List					%% 内容列表
			  }.

%% 检查是否在冷却时间内
check_cold_time(UserId) ->
	case is_cold_time(UserId) of
		?true ->
			throw({?error,?TIP_GUILD_COLD_TIME});
		_ -> 
			?ok	
	end. 

%% 检查对方是否在冷却时间内
check_m_cold_time(UserId) ->
	case is_cold_time(UserId) of
		?true ->
			throw({?error,?TIP_GUILD_M_COLD_TIME}); 
		_ -> 
			?ok	
	end.

%% 是否冷却时间内
is_cold_time(UserId) ->
	Time 		= misc:seconds(),
	ColdTime 	= get_cold_time(UserId),
	if
		ColdTime =:= 0 -> 
			?false;
		(ColdTime + ?CONST_GUILD_CD_TIME * 3600) < Time ->
			?false;
		?true -> 
			?true
	end.

%% 取得冷却时间
get_cold_time(UserId) ->
	case ets_api:lookup(?CONST_ETS_GUILD_TIME, UserId) of 
		?null ->
			0;
		{_,Time} ->
			Time
	end.

%% 增加冷却时间
insert_cold_time(UserId) -> 
	Time = misc:seconds(),
	ets_api:insert(?CONST_ETS_GUILD_TIME, {UserId,Time}),
	guild_db_mod:replace_cold_time(UserId,Time).

%% 删除冷却时间
delete_cold_time(UserId) ->
	case ets_api:lookup(?CONST_ETS_GUILD_TIME, UserId) of
		?null -> ?ok;
		_ ->
			ets_api:delete(?CONST_ETS_GUILD_TIME,UserId),
			guild_db_mod:delete_cold_time(UserId)
	end.

%% 快速申请
sup_apply(Player) ->
	try
		Guild 			= Player#player.guild,
		?ok				= check_sup_apply_pos(Guild#guild.guild_pos),
		{?ok,GuildData} = guild_api:get_guild_data(Guild#guild.guild_id),				%% 取得GuildData
		?ok				= check_guild_num(GuildData),	 								%% 检查是否人数上限
		?ok				= check_apply_num(GuildData#guild_data.apply),					%% 检查申请人数
		Packet			= guild_api:msg_sc_sup_apply(?CONST_SYS_TRUE),
		misc_packet:send(Player#player.net_pid, Packet)
	catch
		throw:{?error,?TIP_COMMON_GOLD_NOT_ENOUGH} ->
			?ok;
		throw:{?error,ErrorCode} -> 	
			TipPacket 	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,110}
	end.
		
check_sup_apply_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;
check_sup_apply_pos(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok;
check_sup_apply_pos(_Pos) ->
	throw({?error,?TIP_GUILD_NOT_CHIEF}).

%% check_sup_apply_money(UserId) -> 
%% 	case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, ?CONST_GUILD_SUP_MONEY,?CONST_COST_GUILD_APPLY) of %% 先判断金钱
%% 		{?error, _ErrorCode} ->
%% 			 throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH});
%% 		_ ->
%% 			 ?ok
%% 	end.

sup_apply_add(Player,GuildId) ->
	try
		?ok				= check_cold_time(Player#player.user_id),										%% 检查是否冷却时间内
		guild_mod:apply(Player, GuildId)
	catch
		throw:{?error,ErrorCode} -> 	
			TipPacket 	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,110}
	end.
	
	
%%
%% Local Functions
%%

