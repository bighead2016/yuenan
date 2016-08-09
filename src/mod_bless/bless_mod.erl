%% Author: Administrator
%% Created: 2013-4-8
%% Description: TODO: Add description to bless_mod
-module(bless_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([
		 bless/3,
		 get_bottle_exp/1,
		 broadcast_bless/5,
		 broadcast_bless_cd/2,
		 onkey_bless/1,
		 read_bless/1,
		 bottle_data/1,
		 bless_notice_cb/2,
		 
		 ets_bless_user/1,
		 ets_bless_info/1,
		 insert_bless_user/1,
		 insert_bless_info/1
		 ]).

%%
%% API Functions
%%
%% 祝福
bless(#player{user_id = UserId,info = Info,net_pid = Pid},BlessId, MemId) ->
	try
		{?ok,BlessUser} = ets_bless_user(UserId),
		Count			= BlessUser#bless_user.count,
		?ok				= check_bless_count(Count),
		{?ok,Bless,BlessInfo2} = get_bless(UserId,MemId,BlessId),
		
		{?ok,AddExp} 	= get_exp(Info#info.lv),
		Exp				= get_add_exp(BlessUser#bless_user.exp + AddExp),
		Count2			= Count + 1,
		BlessUser2		= BlessUser#bless_user{count 	= Count + 1,
											   time		= misc:seconds(),
											   exp		= Exp},
		Packet14802		= bless_api:msg_sc_bless(?CONST_RELATIONSHIP_BLESS,AddExp),
		Packet14816		= bless_api:msg_sc_battle_data(Exp,Count2),
		
		insert_bless_info(BlessInfo2),
		insert_bless_user(BlessUser2),
		bless_notice(UserId,Info,Bless),
		misc_packet:send(Pid, <<Packet14802/binary,Packet14816/binary>>)
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

get_bless(UserId,MemId,BlessId) ->
	{?ok,BlessInfo} 	= ets_bless_info(UserId),
	SendList			= BlessInfo#bless_info.send_list,
	case lists:keytake({MemId,BlessId}, #bless.key, SendList) of
		{value,Bless,SendListT} ->
			BlessInfo2 	= BlessInfo#bless_info{send_list = SendListT},
			{?ok,Bless,BlessInfo2};
		_ ->
			throw({?error,?TIP_BLESS_NOT_EXIST})
	end.

bless_notice(UserId,Info,Bless) ->
	{MemId,BlessId} 	= Bless#bless.key,
	Bless2				= Bless#bless{key = {UserId,BlessId}},
	case player_api:check_online(MemId) of
		?true ->
			player_api:process_send(MemId, ?MODULE, bless_notice_cb, [UserId,Info,Bless2]);
		_ -> ?ok
	end.		 

bless_notice_cb(Player,[BUserId,BInfo,Bless]) ->
	MemId				= Player#player.user_id,
	{_,BlessId} 		= Bless#bless.key, 
	Info				= Player#player.info,	
	{?ok,BlessInfo} 	= ets_bless_info(MemId),
	RecvList			= BlessInfo#bless_info.recv_list,
	case ets_bless_user(MemId) of
		{?ok,#bless_user{count = Count, flag = Flag}} 
		  when Count + length(RecvList) < ?CONST_RELATIONSHIP_BLESS_TIMES 
			   andalso Flag =:= ?CONST_SYS_FALSE -> 
			case lists:keytake({BUserId,BlessId}, #bless.key, RecvList) of
				?false ->
					RecvListT		= [Bless | RecvList],
					RecvList2		= split_list(RecvListT); 
				{value,_,RecvListT} ->
					RecvList2		= [Bless | RecvListT]
			end,
			BlessInfo2	= BlessInfo#bless_info{recv_list = RecvList2},
			{?ok,Exp}	= get_exp(Info#info.lv),
			Packet14820	= get_bless_msg(?CONST_RELATIONSHIP_BE_BLESS,BUserId,BInfo,BlessId,Bless,Exp),
			insert_bless_info(BlessInfo2),
			misc_packet:send(MemId, Packet14820);
		_ -> ?ok
	end,
	{?ok,Player}.

split_list(RecvList) ->
	if
		length(RecvList) > ?CONST_RELATIONSHIP_BLESS_TIMES ->
			{RecvList2,_}	= lists:split(?CONST_RELATIONSHIP_BLESS_TIMES, RecvList),
			RecvList2;
		?true ->
			RecvList
	end.

get_add_exp(Exp) ->
	if
		Exp > ?CONST_RELATIONSHIP_MAX_BOTTLE_EXP ->
			?CONST_RELATIONSHIP_MAX_BOTTLE_EXP;
		?true ->
			Exp
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bottle_data(UserId) ->
	{?ok,BlessUser} 	= ets_bless_user(UserId),
	Exp					= BlessUser#bless_user.exp,
	Count				= BlessUser#bless_user.count,
	{?ok,Exp,Count}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_bottle_exp(Player = #player{user_id = UserId,info = Info,net_pid = Pid}) ->
	try
		{?ok,BlessUser} = ets_bless_user(UserId),
		?ok				= check_get_exp_lv(Info#info.lv),
		Exp				= BlessUser#bless_user.exp,
		?ok				= check_exp(Exp),
		?ok				= check_exp_flag(BlessUser#bless_user.flag),
		VipLv			= player_api:get_vip_lv(Info), 
		Recent			= player_vip_api:get_exp_bottle_times(VipLv),
		AddExp 			= misc:floor(Exp * Recent/100),
		
		Exp2			= Exp + AddExp,
		Count			= BlessUser#bless_user.count,
		?ok				= check_get_exp(Exp2),
		BlessUser2		= BlessUser#bless_user{exp = 0,flag = ?CONST_SYS_TRUE},
		{?ok,Player2}	= player_api:exp(Player, Exp2),
%% 		Packet14816		= bless_api:msg_sc_battle_data(0,Count),
		Packet14818		= bless_api:msg_battle_info(?CONST_SYS_TRUE,0,Count),
		TipPacket		= message_api:msg_notice(?TIP_BLESS_BOTTLE_EXP, [{?TIP_SYS_COMM,misc:to_list(Exp)}]),
		insert_bless_user(BlessUser2), 
		admin_log_api:log_bless(Player, ?CONST_LOG_BLESS_GET_EXP, ?CONST_SYS_TRUE),
		misc_packet:send(Pid, <<Packet14818/binary,TipPacket/binary>>), 
		{?ok,Player2} 
	catch 
		throw:Return -> 
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

check_exp(Exp) when Exp >= ?CONST_RELATIONSHIP_MAX_BOTTLE_EXP -> ?ok;
check_exp(_) ->
	throw({?error,?TIP_BLESS_EXP_NOT_FULL}).

check_exp_flag(?CONST_SYS_FALSE) -> ?ok;
check_exp_flag(_) -> 
	throw({?error,?TIP_BLESS_HAD_GET_EXP}).
 
check_get_exp_lv(Lv) when Lv < ?CONST_RELATIONSHIP_MIN_LV_GET_EXP ->
	throw({?error,?TIP_BLESS_LV});
check_get_exp_lv(Lv) when Lv >= ?CONST_RELATIONSHIP_MAX_LV_GET_EXP ->
	throw({?error,?TIP_BLESS_MAX_LV});
check_get_exp_lv(_Lv) ->
	?ok.

check_get_exp(0) ->
	throw({?error,?TIP_BLESS_EXP});  
check_get_exp(_) -> ?ok.
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% 广播祝福信息 
broadcast_bless(UserId,Info,Sys, Type, Value) ->
    case Sys < data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP) of
        true ->
            ?ok;
        _ ->
        	case can_bless(Value,Type) of
        		?true ->
        			BValue			= get_bless_value(Value),
        			FList 			= relation_api:list_bilateral_friend(UserId),
        			{?ok,BlessInfo} = ets_bless_info(UserId),
        			BlessId			= BlessInfo#bless_info.count + 1,
        			Bless 			= init_bless(BlessId,UserId,Type,BValue),
        			BlessInfo2		= BlessInfo#bless_info{count = BlessId},
        			Packet14820		= get_bless_msg(?CONST_RELATIONSHIP_BLESS,UserId,Info,BlessId,Bless,0),
        			insert_bless_info(BlessInfo2),
        			broadcast_bless(FList,[Bless,Packet14820]);
        		_ -> 
        			?ok
        	end
    end.

get_bless_value(Value) when is_record(Value,goods) ->
	Value#goods.goods_id;
get_bless_value(Value) when is_record(Value,rec_mind) ->
	Value#rec_mind.mind_id;
get_bless_value(Value) when is_record(Value,partner) ->
	Value#partner.partner_id;
get_bless_value(Value) ->
	Value.

broadcast_bless([],_Arg) ->
	?ok;
broadcast_bless([UserId|FList],Arg) ->
	case player_api:check_online(UserId) of
		?true ->
			player_api:process_send(UserId, ?MODULE, broadcast_bless_cd, Arg);
		_ -> ?ok
	end,		 
	broadcast_bless(FList,Arg).
	
broadcast_bless_cd(Player,[Bless,Packet]) ->
	UserId				= Player#player.user_id,
	{?ok,BlessUser}		= ets_bless_user(UserId), 
	{?ok,BlessInfo} 	= ets_bless_info(UserId),
	SendList			= BlessInfo#bless_info.send_list,
	Count				= BlessUser#bless_user.count + length(SendList),
	if
		Count < ?CONST_RELATIONSHIP_BLESS_TIMES andalso BlessUser#bless_user.flag =:= ?CONST_SYS_FALSE ->
			case lists:keytake(Bless#bless.key,#bless.key, SendList) of
				?false ->
					SendList2	= [Bless|SendList];
				{value,_,SendListT} ->
					SendList2	= [Bless|SendListT]
			end,
			
			BlessInfo2	= BlessInfo#bless_info{send_list = SendList2},
			insert_bless_info(BlessInfo2),
			misc_packet:send(Player#player.net_pid, Packet);
		?true -> 
			?ok
	end,			 
	{?ok,Player}.

get_bless_msg(Type,UserId,Info,BlessId,Bless,Exp) ->
	bless_api:msg_sc_bless_data(Type,
	  							UserId,
								Info#info.user_name,
								Info#info.pro,
								Info#info.sex,
								Info#info.lv,	
								Bless#bless.type,
								BlessId,
								Bless#bless.value,
								Bless#bless.time,
								Exp
								).
  
can_bless(CopyId, ?CONST_RELATIONSHIP_BTYPE_SCOPY) -> 		% 单人副本
    case read_bcopy(CopyId, ?CONST_RELATIONSHIP_BTYPE_SCOPY) of
        ?null -> ?false;
        _     -> ?true
    end;
can_bless(CopyId, ?CONST_RELATIONSHIP_BTYPE_MCOPY) -> 		% 多人副本
    case read_bcopy(CopyId, ?CONST_RELATIONSHIP_BTYPE_MCOPY) of
        ?null -> ?false;
        _     -> ?true
    end;
can_bless(CopyId, ?CONST_RELATIONSHIP_BTYPE_INVASION) -> 	% 异民族
    case read_bcopy(CopyId, ?CONST_RELATIONSHIP_BTYPE_INVASION) of
        ?null -> ?false;
        _     -> ?true
    end;
can_bless(Lv, ?CONST_RELATIONSHIP_BTYPE_LV) -> 				% 人物等级
    (0 =< Lv) andalso (Lv rem 5 =:= 0);
can_bless(Partner, ?CONST_RELATIONSHIP_BTYPE_PARTNER) -> 	% 紫色或者以上武将
    Color = Partner#partner.color,
    (0 < Color) andalso (?CONST_SYS_COLOR_PURPLE =< Color);
can_bless(_Vip, ?CONST_RELATIONSHIP_BTYPE_VIPLV) -> 		% vip等级
    ?true;
can_bless(_GuildName, ?CONST_RELATIONSHIP_BTYPE_GUILD) -> 	% 加入军团
    ?true;
can_bless(Wins, ?CONST_RELATIONSHIP_BTYPE_ARENA) -> 		% 单人竞技场连胜数
    (0 < Wins) andalso (Wins rem 5 =:= 0);
can_bless(RecMind, ?CONST_RELATIONSHIP_BTYPE_MIND) -> 		% 紫色或者以上心法
    Color = RecMind#rec_mind.quality,
    if
        (0 < Color) andalso (?CONST_SYS_COLOR_PURPLE =< Color) ->
            ?true;
        ?true ->
            ?false
    end;
can_bless(Goods, ?CONST_RELATIONSHIP_BTYPE_EQUIP) -> 		% 紫色或者以上装备
    Color = Goods#goods.color,
    if
        (0 < Color) andalso (?CONST_SYS_COLOR_PURPLE =< Color) ->
            ?true;
        ?true ->
            ?false
    end;
can_bless(_, _) ->
    ?false.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read_bcopy(CopyId, Type) ->
    data_bless:get_bcopy({CopyId, Type}).

get_exp(Lv) ->
	case data_bless:get_bless(Lv) of
		?null -> {?ok,0};
		Exp ->
			{?ok,Exp}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
onkey_bless(#player{user_id = UserId,info = Info,net_pid = Pid}) ->
	try
		VipLv			= player_api:get_vip_lv(Info),
		?ok				= check_vip(VipLv),
		{?ok,BlessUser} = ets_bless_user(UserId),
		{?ok,BlessInfo}	= ets_bless_info(UserId),
		SendList		= BlessInfo#bless_info.send_list,
		Count			= BlessUser#bless_user.count,
		case get_bottle_count(Count) of
			{?ok,0} ->
				BlessInfo2		= BlessInfo#bless_info{send_list = []},
				insert_bless_info(BlessInfo2),
				{?error,?TIP_BLESS_COUNT};
			{?ok,LCount} ->
				SendCount		= get_can_send_count(LCount,length(SendList)),
				{?ok,AddExp} 	= get_exp(Info#info.lv),
				AddExp2			= AddExp * SendCount,
				Exp				= get_add_exp(BlessUser#bless_user.exp + AddExp2),
				Count2			= Count + SendCount,
				BlessInfo2		= BlessInfo#bless_info{send_list = []},
				BlessUser2		= BlessUser#bless_user{count 	= Count2,
													   time		= misc:seconds(),
											   		   exp		= Exp},
				Packet14802		= bless_api:msg_sc_bless(?CONST_RELATIONSHIP_BLESS,AddExp2),
				Packet14816		= bless_api:msg_sc_battle_data(Exp,Count2),
				
				onekey_bless(UserId,Info,SendList,SendCount),
				insert_bless_info(BlessInfo2),
				insert_bless_user(BlessUser2),
				misc_packet:send(Pid, <<Packet14802/binary,Packet14816/binary>>)
		end
	catch
		throw:Return -> 
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

check_vip(VipLv) ->
	case player_vip_api:can_onkey_bless(VipLv) of
		?CONST_SYS_TRUE ->
			?ok;
		_ ->
			throw({?error,?TIP_BLESS_ONE_KEY})
	end.

onekey_bless(_UserId,_Info,[],_) -> ?ok;
onekey_bless(_UserId,_Info,_,0) -> ?ok;
onekey_bless(UserId,Info,[Bless|SendList],SendCount) ->
	bless_notice(UserId,Info,Bless),
	onekey_bless(UserId,Info,SendList,SendCount-1).

get_can_send_count(LCount,BCount) ->
	if
		LCount >= BCount ->
			BCount;
		?true ->
			LCount
	end.

check_bless_count(Count) when Count < ?CONST_RELATIONSHIP_BLESS_TIMES ->
	?ok;
check_bless_count(_Count) ->
	throw({?error,?TIP_BLESS_COUNT}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read_bless(#player{user_id = UserId,info = Info,net_pid = Pid}) ->
	try
		{?ok,BlessUser} = ets_bless_user(UserId),
		{?ok,BlessInfo}	= ets_bless_info(UserId),
		RecvList		= BlessInfo#bless_info.recv_list,
		Count			= BlessUser#bless_user.count,
		case get_bottle_count(Count) of
			{?ok,0} ->
				BlessInfo2		= BlessInfo#bless_info{recv_list = []},
				insert_bless_info(BlessInfo2),
				{?error,?TIP_BLESS_COUNT};
			{?ok,LCount} ->
				RecvCount		= get_can_send_count(LCount,length(RecvList)),
				{?ok,AddExp} 	= get_exp(Info#info.lv),
				AddExp2			= AddExp * RecvCount,
				Exp				= get_add_exp(BlessUser#bless_user.exp + AddExp2),
				Count2			= Count + RecvCount,
				BlessInfo2		= BlessInfo#bless_info{recv_list = []},
				BlessUser2		= BlessUser#bless_user{count 	= Count2,
													   time		= misc:seconds(),
											   		   exp		= Exp},
				Packet14802		= bless_api:msg_sc_bless(?CONST_RELATIONSHIP_BE_BLESS,AddExp2),
				Packet14816		= bless_api:msg_sc_battle_data(Exp,Count2),
				insert_bless_info(BlessInfo2),
				insert_bless_user(BlessUser2),
				misc_packet:send(Pid, <<Packet14802/binary,Packet14816/binary>>)
		end
	catch
		throw:Return -> 
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	

get_bottle_count(Count) ->
	LCount	= ?CONST_RELATIONSHIP_BLESS_TIMES - Count,
	if
		LCount > 0 ->
			{?ok,LCount};
		?true ->
			{?ok,0}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ets_bless_user(UserId) -> 
	case ets_api:lookup(?CONST_ETS_BLESS_USER, UserId) of
		?null ->
			BlessUser2 	= init_bless_user(UserId);
		BlessUser ->
			BlessUser2 	= update_bless_user(BlessUser)
	end,
	{?ok,BlessUser2}.

update_bless_user(BlessUser) ->
	Time 	= BlessUser#bless_user.time, 
	Now		= misc:seconds(),
	case misc:is_same_date(Time, Now) of
		?true ->
			BlessUser;
		_ ->
			BlessUser#bless_user{count = 0,time = Now}
	end.

insert_bless_user(BlessUser) -> 
	ets_api:insert(?CONST_ETS_BLESS_USER, BlessUser),
	bless_db_mod:replace_data(BlessUser).

ets_bless_info(UserId) ->
	case ets_api:lookup(?CONST_ETS_BLESS_INFO, UserId) of
		?null ->
			BlessInfo = init_bless_info(UserId);
		BlessInfo -> ?ok
	end,
	{?ok,BlessInfo}.

insert_bless_info(BlessInfo) ->
	ets_api:insert(?CONST_ETS_BLESS_INFO, BlessInfo).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_bless_user(UserId) ->
	#bless_user			{
                         user_id            = UserId,       %% 玩家id
                         count              = 0,            %% 总祝福次数
                         exp                = 0,            %% 祝福经验瓶累积经验
						 time				= 0				%%  祝福时间
                        }.

init_bless(BlessId,UserId,Type,Value) ->
	#bless		 		{
						 key				= {UserId,BlessId},
						 type				= Type,
						 value				= Value,
						 time				= misc:seconds()
                        }.

init_bless_info(UserId) ->
	#bless_info    		{
                         user_id            = UserId,        %% 玩家id
                         count				= 0,		
                         send_list			= [],
						 recv_list			= []
                        }.
