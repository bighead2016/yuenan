%% Author: Administrator
%% Created: 2013-3-8
%% Description: TODO: Add description to guild_api2
-module(guild_api).

%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl"). 
%%
%% Exported Functions
%%
-export([
		 initial_ets/0,init_create_guild/0,
		 init_guild/1, init_donate_guild/1,
		 refresh_attr/1,login_packet/2,
		 
		 brocast/2,brocast2/2,
		 brocast_handle/2,brocast2_handle/2,
		 
		 clear/0,clear_handle/0,
		 add_guild_goods/2,plus_exploit/3,
		 guild_data/0,guild_member/1,get_online_info/1,
		 login_init/1,logout/1,
		  
		 get_guild_name/1, get_guild_lv/1, get_guild_chief_id/1,
		 get_guild_data/1,get_guild_member/1,get_guild_apply/1,
         
         get_guild_members/1,
		 
		 get_guild_id_by_name/1,
   
         set_timeout/2,
         
         add_guild_pvp_score/2,
		 
		 ets_guild_data/1,insert_guild_data/1,
		 ets_guild_member/1,insert_guild_member/1,
		 ets_guild_apply/1,
         msg_guild_bag_empty/0,
		 
		 error_message/2,error_message2/2,
		 
		 update_guild_power/2,
		 get_task_add/1,get_exp_add/1,
		 get_commerce_add/1,get_arena_add/1,
		 get_surplus_donate_gold/1,
		 get_detail_data/1,
         check_name_use/1,
		 get_skill_lv/2,
         get_guild_rank/1,
         get_guild_chief_name/1
		 ]).

-export([
		 msg_shadow_task/1,msg_unshadow_task/1,
		 msg_change/2,
		  
		 msg_sc_list/1,msg_sc_data/12,
		 msg_sc_member/1,msg_sc_apply_list/1,
		 msg_sc_create/1,msg_sc_invite/4,
		 msg_sc_log/1,msg_sc_apply/2,
		 
		 msg_sc_skill_list/1 ,msg_sc_magic_list/1,
		 msg_sc_skill_learn/1,msg_sc_magic_learn/1,
		 msg_sc_treasure/1,msg_sc_distribute/1,
		 msg_sc_member_info/1,msg_sc_announce/3,
		 msg_sc_member_name/1,msg_sc_on_off/3,
		 msg_sc_cd/1,msg_sc_cd_leave_time/1,
		 msg_sc_mem_detail/6,msg_sc_sup_apply/1
		 ]).

%%
%% API Functions
%%

%% 增加军团功德
add_guild_pvp_score(UserId, Score) ->
    case ets:lookup(?CONST_ETS_GUILD_MEMBER, UserId) of
        [] ->
            ok;
        [GuildMember] ->
            OldScore = GuildMember#guild_member.pvp_score,
            NewScore = OldScore + Score,
            ets:update_element(?CONST_ETS_GUILD_MEMBER, UserId, {#guild_member.pvp_score, NewScore}),
            guild_db_mod:update_member(UserId,[{pvp_score, NewScore}])
    end.

%% guild_api:add_guild_goods(GuildId,GoodsList).


add_guild_goods(GuildId,GoodsList) ->
	guild_ctn_mod:set_list(GuildId,GoodsList).

get_guild_rank(GuildId) ->
    case GuildId /= 0 of
        true ->
            NthList = [1,2,3],
            find_rank(GuildId, NthList);
        _ ->
            0
    end.

find_rank(_GuildId, []) -> 0;
find_rank(GuildId, [N|RestList]) ->
    case rank_api:get_max_guild_topn(N) == GuildId of
        true ->
            N;
        _ ->
            find_rank(GuildId, RestList)
    end.

    
    
set_timeout(_, Day) when Day =< 0 ->
    ok;
set_timeout(#player{guild = Guild}, Day) when is_record(Guild,guild)->
    case Guild#guild.guild_pos == ?CONST_GUILD_POSITION_CHIEF of
        true ->
            GuildId = Guild#guild.guild_id,
            ets:update_element(?CONST_ETS_GUILD_DATA, GuildId, {#guild_data.remove_day, Day});
        _ ->
            ok
    end.

%% 开服更新ets
initial_ets() -> 
	guild_db_mod:select_data(),
	guild_db_mod:select_member(),
	guild_db_mod:select_cold_time().

%% 初始化
init_create_guild() ->
	#guild{}.

%% 初始化-个人的术法、当天捐献铜钱 不清除
init_guild(Guild) when is_record(Guild,guild) ->
	Guild#guild{ 
		   guild_id 			= 0,			% 军团id
		   guild_name			= <<"">>,		% 军团名称
		   guild_pos 			= 0 			% 军团职位
		   };
init_guild(_) ->
	#guild{}.

%% 取得军团名
get_guild_name(Guild) when is_record(Guild,guild) ->
	Guild#guild.guild_name;
get_guild_name(GuildId) when is_number(GuildId) ->
	case ets_guild_data(GuildId) of
		#guild_data{guild_name = GuildName} ->
			GuildName;
		_ -> <<"">>
	end;
get_guild_name(_) ->
	<<"">>.

%% 刷新属性
refresh_attr(Guild) when is_record(Guild,guild) ->
	AccAttr		= #attr{attr_second = #attr_second{} ,attr_elite = #attr_elite{}},
	refresh_attr(Guild#guild.guild_magic, AccAttr);
refresh_attr(Guild) -> 
	?MSG_ERROR("bad record~p~n",[Guild]),
	#attr{attr_second = #attr_second{} ,attr_elite = #attr_elite{}}.

refresh_attr([GuildMagic|GuildMagicList], AccAttr) ->
	AccAttr2	= refresh_attr2(GuildMagic, AccAttr),
	refresh_attr(GuildMagicList, AccAttr2);
refresh_attr([], AccAttr) -> AccAttr.

refresh_attr2({MagicId,MagicLv}, AccAttr) ->
	MagicData	= data_guild:get_guild_magic({MagicId,MagicLv}),
	Type		= MagicData#rec_guild_magic.attr_type,
	Value		= MagicData#rec_guild_magic.attr_value,
	player_attr_api:attr_plus(AccAttr, Type, Value);
refresh_attr2(GuildMagic, AccAttr)  ->
	?MSG_ERROR("bad record~p~n",[GuildMagic]),
	AccAttr.

%% 本军团广播 GuildId 军团id
brocast(GuildId, Packet) ->
	guild_serv:brocast_cast(GuildId, Packet).

%% 本军团广播 GuildId 军团id
brocast_handle(GuildId, Packet) ->
	case ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId) of
		?null -> ?ok;
		GuildData ->
			MemberList = GuildData#guild_data.member_online,	%% 在线玩家
			brocast2_handle(MemberList,Packet)
	end.

%% 本军团广播 MemberList 列表
brocast2(MemberList,Packet) ->
	guild_serv:brocast2_cast(MemberList,Packet).

brocast2_handle([],_Packet) -> ?ok;
brocast2_handle(MemberList,Packet) -> 
	if
		length(MemberList) >= 20 ->
			spawn(fun() -> brocast2_handle2(MemberList, Packet) end);
		?true ->
			brocast2_handle2(MemberList, Packet)
	end.

brocast2_handle2([],_Packet) -> ?ok;
brocast2_handle2([UserId|MemberList],Packet) ->
	misc_packet:send(UserId, Packet),
	brocast2_handle2(MemberList,Packet).

%% 玩家登录
login_packet(Player = #player{guild = Guild}, OldPacket) when is_record(Guild,guild)->
	GuildId		= Guild#guild.guild_id,
	{?ok,Lv} 	= get_guild_lv(GuildId),
	Packet		= msg_change(Guild,Lv), 
	{Player,<<OldPacket/binary,Packet/binary>>};
login_packet(Player, OldPacket) ->
	{Player,OldPacket}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 定时清除
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 每天清除
%% guild_api:clear(). 
clear() ->
	guild_serv:clear_cast().

clear_handle() ->
	try
        case ets:first(?CONST_ETS_GUILD_DATA) of
            '$end_of_table' ->
                ok;
            Key ->
                clear_handle_2(Key)
        end,
        case ets:first(?CONST_ETS_GUILD_MEMBER) of
            '$end_of_table' ->
                ok;
            Key2 ->
                claer_member(Key2)
        end
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

clear_handle_2(Key) ->
    case ets_api:lookup(?CONST_ETS_GUILD_DATA, Key) of
        #guild_data{guild_id = GuildId} = GuildData ->
            Invite      = clear_invite(GuildData#guild_data.invite),            %% 清除邀请列表
            GuildData2  = GuildData#guild_data{invite = Invite},
            Add         = guild_skill_mod:default_add(GuildData2),              %% 增加默认技能的进度
            Money       = GuildData2#guild_data.money + Add,
                
            ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.money, Money},
                                                                   {#guild_data.invite, Invite}]),

            guild_db_mod:update_data(GuildId,[{money,Money}]),
            case ets:next(?CONST_ETS_GUILD_DATA, Key) of
                '$end_of_table' ->
                    ok;
                Key2 ->
                    clear_handle_2(Key2)
            end;
        ?null ->
            ok
    end.

%% 成员清除
claer_member(Key) ->
    case ets_api:lookup(?CONST_ETS_GUILD_MEMBER, Key) of
        #guild_member{user_id = UserId} = GuildMember ->
            GuildMember2    = GuildMember#guild_member{donate_today = 0,
                                                       donate_money = 0},
            insert_guild_member(GuildMember2),
            guild_db_mod:update_member(UserId,[{donate_today,0}]),
            case ets:next(?CONST_ETS_GUILD_MEMBER, Key) of
                '$end_of_table' ->
                    ok;
                Key2 ->
                    claer_member(Key2)
            end;
        ?null ->
            ok
    end.
	
%% 清除邀请
clear_invite(Invite) -> 
	F = fun(GuildInvite,Arg) ->
			Time = misc:seconds() - 1800,
			if
				GuildInvite#guild_invite.invite_time =< Time -> Arg;
				?true -> [GuildInvite|Arg]
			end
		end,
	lists:foldl(F, [], Invite).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更新
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更新军团战力
update_guild_power(UserId,Power) ->
	case ets_guild_member(UserId) of
		?null -> ?ok; 
		#guild_member{power = Power} -> ?ok; %% 不更新
		_ ->
			ets_api:update_element(?CONST_ETS_GUILD_MEMBER, UserId,[{#guild_member.power, Power}]),
			guild_db_mod:update_member(UserId,[{power,Power}])
	end.

%% 军团信息 guild_api:guild_data() 
guild_data() ->
	GuildList 	= ets_api:list(?CONST_ETS_GUILD_DATA),
	F = fun(GuildData,Acc) ->
				GuildId = GuildData#guild_data.guild_id,
				D 		= {GuildId},
				[D|Acc]
		end,
	lists:foldl(F, [], GuildList).

%% 军团成员
guild_member(#player{guild = Guild}) ->
	case ets_guild_data(Guild#guild.guild_id) of
		?null -> [];
		#guild_data{member_list = MemberList} ->
			guild_member2(MemberList,[])
	end.


get_guild_members(GuildId) ->
    case ets_guild_data(GuildId) of
        ?null ->[];
        #guild_data{member_list = MemberList} ->
            guild_member3(MemberList, [])
    end.

guild_member3([Uid|MemberList],Acc) ->
    case player_api:get_player_field(Uid, #player.info) of
         {?ok, #info{user_name = UserName, power = Power}} ->
            guild_member3(MemberList,[{Uid, UserName, Power}|Acc]);
        _ -> guild_member3(MemberList,Acc)
    end;
guild_member3([],Acc) -> Acc.

guild_member2([Uid|MemberList],Acc) ->
	case player_api:get_player_field(Uid, #player.info) of
		 {?ok, #info{user_name = UserName, lv = Lv}} ->
			guild_member2(MemberList,[{Uid, UserName, Lv}|Acc]);
		_ -> guild_member2(MemberList,Acc)
	end;
guild_member2([],Acc) -> Acc.

%% 军团等级
get_guild_lv(GuildId) ->
	case ets_guild_data(GuildId) of
		?null -> {?ok,0};
		#guild_data{lv = Lv} -> {?ok,Lv}
	end.

%% 军团长ID
get_guild_chief_id(GuildId) ->
	case ets_guild_data(GuildId) of
		?null -> {?ok,0};
		#guild_data{chief_id = UserId} -> {?ok,UserId}
	end.

%% 军团长名
get_guild_chief_name(GuildId) ->
    case ets_guild_data(GuildId) of
        ?null -> {?ok, <<"">>};
        #guild_data{chief_name = ChiefName} -> {?ok, ChiefName}
    end.

%% 军团ID
get_guild_id_by_name(GuildName) ->
	GuildName2 = misc:to_binary(GuildName),
	case ets:select(?CONST_ETS_GUILD_DATA, [{#guild_data{
														 guild_id			= '$1',            %% 自增ID(帮派ID)
														 guild_name 		= GuildName2,       %% 军团名称	
														 country			= '_',			%% 国家
														 lv 				= '_',            %% 军团等级	
														 exp				= '_',			%% 军团经验
														 num 				= '_',            %% 军团当前人数	
														 num_max 			= '_',            %% 军团人数上限	
														 chief_id 			= '_',            %% 军团团长ID	
														 chief_name 		= '_',       %% 军团团长名字	
														 create_name 		= '_',       %% 军团创建玩家名
														 create_time 		= '_',            %% 军团创建时间
														 bulletin_in	 	= '_',       %% 军团内部公告	
														 bulletin_out 		= '_',       %% 军团外部公告	 	
														 money				= '_',			%% 军团资金	
														 kick_money			= '_',			%% 踢出成员累积资金
														 map_pid			= '_',			%% 地图进程
														 apply 				= '_',			%% 军团邀请
														 invite 			= '_',			%% 军团申请
														 member_online		= '_',			%% 军团成员在线列表	
														 member_list		= '_',			%% 军团成员列表				 
														 pos_list			= '_',			%% 军团职位列表[{Pos,[]},...]
														 skill 				= '_',			%% 军团技能  
														 log 				= '_',			%% 军团日志
														 ctn				= '_',			%% 军团仓库		 
														 guess_win			= '_',			%% 猜拳胜利者
														 rock_win			= '_',			%% 摇色子胜利者
														 remove_day         = '_'             %% 3天未上线的玩家踢出
														},[], ['$$']}]) of
		'$end_of_table' ->
			?false;
		[[Name]] ->
			Name
	end.

%% 在线成员信息
get_online_info(#player{user_id = UserId,guild = Guild}) ->
	case ets_guild_data(Guild#guild.guild_id) of
		?null -> [];
		#guild_data{member_online = MemList} -> %% 在线列表
			MemList2	= lists:delete(UserId, MemList),
			get_online_info2(MemList2,[])
	end.	

get_online_info2([UserId|List],InfoList) ->
	case player_api:get_player_field(UserId, #player.info) of
		 {?ok, #info{user_name = UserName, pro = Pro, sex = Sex, lv = Lv}} -> %% 在线成员 user_id,user_name,pro,sex,lv
			get_online_info2(List,[{UserId,UserName,Pro,Sex,Lv}|InfoList]);
		_ -> get_online_info2(List,InfoList)
	end;
get_online_info2([],InfoList) -> InfoList.

%% 玩家登录
login_init(Player) -> 
	Guild2			= login_init2(Player),
	Guild3			= init_donate_guild(Guild2),	 		%% 更新今天捐献铜钱
	Player2 		= Player#player{guild = Guild3},
	case Guild3#guild.guild_id of 
		0 -> Player2;
		_ ->
			Player3			= task_api:update_guild(Player2),%% 任务
			{?ok,Player4}	= achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_JOIN_GUILD, 0, 1), %% 成就
			Player4
	end.

login_init2(#player{user_id = UserId,guild = Guild,info = Info}) ->
	case ets_guild_member(UserId) of
		?null -> 											%% 不在军团 或 被踢出军团		
			init_guild(Guild);
		#guild_member{guild_id = GuildId,pos = Pos} -> 		%% 军团成员信息（可能被踢出 又 被拉进军团 要更新玩家GuildId 和 Pos）
			case ets_guild_data(GuildId) of
				?null -> 									%% 所在军团已解散 或 不存在
					init_guild(Guild);
				#guild_data{member_online = MemberOnline,guild_name = GuildName} ->%% 军团信息（上线广播）
					MemberOnline2 	= case lists:member(UserId, MemberOnline) of
										  ?false -> [UserId|MemberOnline];
										  _ -> MemberOnline
									  end,
					LoginPacket		= msg_sc_on_off(0,UserId,Info#info.user_name),
					ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.member_online, MemberOnline2}]),
					brocast2(MemberOnline,LoginPacket),		%% 广播
					Guild#guild{guild_id 	= GuildId, 
								guild_name 	= GuildName,
								guild_pos 	= Pos}
			end
	end.
	
%% 更新今天捐献铜钱
init_donate_guild(Guild = #guild{donate_time = Time}) ->
	Now = misc:seconds(),
	case misc:is_same_date(Time, Now) of
		?false ->
			Guild#guild{donate_time = Now,donate_gold = 0};
		_ -> 
			Guild
	end.

%% 玩家下线操作
logout(#player{user_id = UserId,info = Info,guild = Guild}) -> 
	try
		GuildId 		= Guild#guild.guild_id,
		{?ok,GuildData} = get_guild_data(GuildId),
		OnlineL			= GuildData#guild_data.member_online,
		OnlineL2 		= logout_delete(UserId,OnlineL,[]),
		Packet			= msg_sc_on_off(misc:seconds(),UserId,Info#info.user_name),
		ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,[{#guild_data.member_online, OnlineL2}]),
		brocast2(OnlineL2,Packet)		%% 广播
	catch
		_:_ -> ?ok 
	end.

logout_delete(_,[],OnlineL) ->
	OnlineL;
logout_delete(UserId,[H|L],OnlineL) ->
	if
		UserId =:= H ->
			logout_delete(UserId,L,OnlineL);
		?true ->
			logout_delete(UserId,L,[H|OnlineL])
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plus_exploit(Player, Exploit) ->
%% 	plus_exploit(Player, Exploit, 0).
plus_exploit(Player, Exploit, Point) ->
	case ets_guild_member(Player#player.user_id) of
		?null -> ?ok;
		GuildMember ->
			DonateToday			= GuildMember#guild_member.donate_today + Exploit,		%% 更新member信息
			DonateSum			= GuildMember#guild_member.donate_sum + Exploit,
			GuildMember2		= GuildMember#guild_member{donate_today = DonateToday,donate_sum = DonateSum},
			guild_mod:update_member(GuildMember2,[{donate_today,DonateToday},{donate_sum,DonateSum}])  
	end,
	player_api:plus_exploit(Player, Exploit, Point).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能奖励系数
%% return: Rate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 控制军团任务军团贡献奖励系数 
get_task_add(Player) -> 			
	guild_skill_mod:get_skill_add(Player,?CONST_GUILD_SKILL_TYPE_MISSION).
%% 提高玩家副本经验获取系数
get_exp_add(Player) -> 				
	guild_skill_mod:get_skill_add(Player,?CONST_GUILD_SKILL_TYPE_EXP).
%% 提升可以增加商路的收益
get_commerce_add(Player) -> 		
	guild_skill_mod:get_skill_add(Player,?CONST_GUILD_SKILL_TYPE_BUSINESS).
%% 增加一骑讨活动功勋和历练收益加成 
get_arena_add(UserId) -> 
	guild_skill_mod:get_skill_add(UserId).

%% 获取相应技能等级
get_skill_lv(Player, SkillId) ->
	Guild					= Player#player.guild,
	GuildId					= Guild#guild.guild_id,		
	case ets_guild_data(GuildId) of
		?null -> ?CONST_SYS_FALSE; 											%% 没加入军团
		GuildData ->
			SkillList				= GuildData#guild_data.skill,			%% 技能列表
			case lists:keyfind(SkillId, #guild_skill.skill_id, SkillList) of
				?false -> ?CONST_SYS_FALSE;									%% 技能未开放;
				Skill  -> Skill#guild_skill.skill_lv						%% 等级
			end
	end.
		
%% 今日可以捐献铜钱
%% guild_api:get_surplus_donate_gold(Player).
get_surplus_donate_gold(Player) ->
	guild_skill_mod:get_surplus_donate_gold(Player).

%% 任务
msg_shadow_task(TaskData) ->
	task_api:shadow_guild_task(TaskData).

msg_unshadow_task(TaskData) ->
	task_api:unshadow_guild_task(TaskData).

%% 人物信息
msg_change(#guild{guild_id = GuildId,guild_name = GuildName,guild_pos = GuildPos,donate_gold = DonateGold},GuildLv) ->
	PacketUpdata1	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_ID, GuildId),			
	PacketUpdata2   = player_api:msg_player_attr_update_str(?CONST_PLAYER_ATTR_GUILD_NAME, GuildName),			
	PacketUpdata3   = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_POS, GuildPos),	
	PacketUpdata4   = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_LV, GuildLv),	
	PacketUpdata5   = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_DONATE, DonateGold),	
	<<PacketUpdata1/binary,PacketUpdata2/binary,PacketUpdata3/binary,PacketUpdata4/binary,PacketUpdata5/binary>>.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 错误消息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
error_message(Player,ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.

error_message2(Pid,ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Pid, Packet).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% guild_data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% guild_data
get_guild_data(GuildId) ->
	case ets_guild_data(GuildId) of
		?null ->
			throw({?error,?TIP_GUILD_DISBAND}); %% 没加入军团
		GuildData ->
			{?ok,GuildData}
	end.

ets_guild_data(GuildId) ->
	ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId).

insert_guild_data(GuildData) ->
	ets_api:insert(?CONST_ETS_GUILD_DATA, GuildData).

%% ok/{?error, ErrorCode}
check_name_use(GuildName) ->
    try
        guild_mod:check_name_use(GuildName, <<>>)
    catch
        throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _X:_Y ->
            {?error,?TIP_GUILD_CREATE_NAME}
    end.

%% guild_member
get_guild_member(MemId) ->
	case ets_guild_member(MemId) of
		?null ->
			throw({?error,?TIP_GUILD_HAD_NO_JOIN}); %% 对方不在军团
		GuildMember ->
			{?ok,GuildMember}
	end.

ets_guild_member(MemId) ->
	ets_api:lookup(?CONST_ETS_GUILD_MEMBER, MemId).

insert_guild_member(GuildMember) ->
	ets_api:insert(?CONST_ETS_GUILD_MEMBER, GuildMember).

%% guild_apply
get_guild_apply(UserId) ->
	case ets_guild_apply(UserId) of
		?null -> throw({?error,?TIP_GUILD_NOT_IN_APPLY});
		GuildApply ->
			{?ok,GuildApply}
	end.

ets_guild_apply(UserId) ->
	ets_api:lookup(?CONST_ETS_GUILD_APPLY, UserId).

get_detail_data(UserId) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.partner]) of
		{?ok, [Info, Partner]} ->% 玩家在线
			Player	= #player{info = Info, partner = Partner},
			Power	= partner_api:caculate_camp_power(Player),
			List	= partner_api:get_partner_id_list(Player, 0),
			List2	= [{PartnerId} || PartnerId <- List],
			msg_sc_mem_detail(UserId,Info#info.user_name,Info#info.lv,Info#info.pro,Power,List2);
		_ ->
			<<>>
	end.

%%
%% Local Functions
%%

%% 返回军团列表
%%[{GuildId,GuildName,Chief,Lv,Num,NumMax,Announce,State,IsApplyFull}]  
msg_sc_list(List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_LIST, ?MSG_FORMAT_GUILD_SC_LIST, [List1]). 
%% 请求军团详情信息返回
%%[GuildName,Lv,Num,NumMax,CreateName,CreateTime,ChiefName,AnnounceIn,AnnounceOut,Money,KickMoney,KickDay]
msg_sc_data(GuildName,Lv,Num,NumMax,CreateName,CreateTime,ChiefName,AnnounceIn,AnnounceOut,Money,KickMoney,KickDay) ->
    misc_packet:pack(?MSG_ID_GUILD_SC_DATA, ?MSG_FORMAT_GUILD_SC_DATA, [GuildName,Lv,Num,NumMax,CreateName,CreateTime,ChiefName,AnnounceIn,AnnounceOut,Money,KickMoney,KickDay]).

%% 加载成员列表返回
%%[{UserId,UserName,Pos,Lv,Sex,Pro,DonateToday,DonateSum,Introduce,LastTime}]
msg_sc_member(List1) -> 
	misc_packet:pack(?MSG_ID_GUILD_SC_MEMBER, ?MSG_FORMAT_GUILD_SC_MEMBER, [List1]).
%% 军团申请列表返回
%%[{UserId,UserName,Lv,Sex,Pro}]
msg_sc_apply_list(List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_APPLY_LIST, ?MSG_FORMAT_GUILD_SC_APPLY_LIST, [List1]).
%% 军团状态发生变更返回
%%[Res]
%% msg_cs_state_change(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_CS_STATE_CHANGE, ?MSG_FORMAT_GUILD_CS_STATE_CHANGE, [Res]).
%% 创建军团返回
%%[GuildId] 
msg_sc_create(GuildId) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_CREATE, ?MSG_FORMAT_GUILD_SC_CREATE, [GuildId]).
%% 军团申请返回
%%[GuildId,Res]
msg_sc_apply(GuildId,Res) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_APPLY, ?MSG_FORMAT_GUILD_SC_APPLY, [GuildId,Res]).
%% 邀请入团返回
%%[GuildId,GuildName,UserId,UserName]
msg_sc_invite(GuildId,GuildName,UserId,UserName) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_INVITE, ?MSG_FORMAT_GUILD_SC_INVITE, [GuildId,GuildName,UserId,UserName]).
%% 更新我的军功
%%[Exploit]
%% msg_sc_exploit(Exploit) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_SC_EXPLOIT, ?MSG_FORMAT_GUILD_SC_EXPLOIT, [Exploit]).
%% 军团技能列表返回
%%[DefaultId,{SkillId,SkillLv}]
msg_sc_skill_list(List1) -> 
	misc_packet:pack(?MSG_ID_GUILD_SC_SKILL_LIST, ?MSG_FORMAT_GUILD_SC_SKILL_LIST, [List1]).
%% 学习军团技能返回
%%[SkillId]
msg_sc_skill_learn(SkillId) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_SKILL_LEARN, ?MSG_FORMAT_GUILD_SC_SKILL_LEARN, [SkillId]).
%% 学习军团术法返回
%%[MagicId]
msg_sc_magic_learn(MagicId) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_MAGIC_LEARN, ?MSG_FORMAT_GUILD_SC_MAGIC_LEARN, [MagicId]).
%% 术法列表返回
%%[{MagicId,MagicLv}]
msg_sc_magic_list(List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_MAGIC_LIST, ?MSG_FORMAT_GUILD_SC_MAGIC_LIST, [List1]).
%% 军团宝藏信息返回
%%[Lv]
msg_sc_treasure(Lv) -> 
	misc_packet:pack(?MSG_ID_GUILD_SC_TREASURE, ?MSG_FORMAT_GUILD_SC_TREASURE, [Lv]).
%% 军团日志返回
%%[{Time,LogType,{Type,Value}}]
msg_sc_log(List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_LOG, ?MSG_FORMAT_GUILD_SC_LOG, [List1]).
%% 分配仓库物品成功返回
%%[Res]
msg_sc_distribute(Res) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_DISTRIBUTE, ?MSG_FORMAT_GUILD_SC_DISTRIBUTE, [Res]).
%% 军团成员信息返回
%%[{UserId,Name,Pro,Sex,Lv}]
msg_sc_member_info(List1) -> 
	misc_packet:pack(?MSG_ID_GUILD_SC_MEMBER_INFO, ?MSG_FORMAT_GUILD_SC_MEMBER_INFO, [List1]). 
%% 修改军团公告返回
%%[Type,Announce,GuildId]
msg_sc_announce(Type,Announce,GuildId) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_ANNOUNCE, ?MSG_FORMAT_GUILD_SC_ANNOUNCE, [Type,Announce,GuildId]).
%% 成员名字信息
%%[{Name}]
msg_sc_member_name(List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_MEMBER_NAME, ?MSG_FORMAT_GUILD_SC_MEMBER_NAME, [List1]).
%% 成员上下线
%%[Type,UserId,UserName]
msg_sc_on_off(Type,UserId,UserName) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_ON_OFF, ?MSG_FORMAT_GUILD_SC_ON_OFF, [Type,UserId,UserName]).
%% 是否cd时间内
%%[Res]
msg_sc_cd(Res) -> 
	misc_packet:pack(?MSG_ID_GUILD_SC_CD, ?MSG_FORMAT_GUILD_SC_CD, [Res]).
%% CD剩余时间
%%[Time]
msg_sc_cd_leave_time(Time) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_CD_LEAVE_TIME, ?MSG_FORMAT_GUILD_SC_CD_LEAVE_TIME, [Time]).
%% 成员详情信息返回
%%[Name,Lv,Pro,Power,{PartnerId}]
msg_sc_mem_detail(UserId,Name,Lv,Pro,Power,List1) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_MEM_DETAIL, ?MSG_FORMAT_GUILD_SC_MEM_DETAIL, [UserId,Name,Lv,Pro,Power,List1]).
%% 快速邀请返回
%%[Res]
msg_sc_sup_apply(Res) ->
	misc_packet:pack(?MSG_ID_GUILD_SC_SUP_APPLY, ?MSG_FORMAT_GUILD_SC_SUP_APPLY, [Res]).
msg_guild_bag_empty() ->
    misc_packet:pack(?MSG_ID_GUILD_PARTY_GUILD_BAG_EMPTY, ?MSG_FORMAT_GUILD_PARTY_GUILD_BAG_EMPTY, []).
