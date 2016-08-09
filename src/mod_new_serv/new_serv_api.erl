%% Author: Administrator
%% Created: 2013-6-13
%% Description: TODO: Add description to new_serv_api
-module(new_serv_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([init_honor_title_ets/0,
		 read_honor_info/0,
		 init_hero_rank_ets/0,
		 init/0,
		 login/1,
		 refresh/1,
		 flush_offline/2,
		 finish_achieve/4,
		 finish_achieve_cb/2,
		 achieve_info/2,
		 insert_ets_rank/4,
		 get_rank_info/2,
		 get_serv_start_time/0,
		 deposit_award/2,
		 add_honor_title/3,
		 insert_ets_hero_rank/8,
		 get_hero_rank_info/2,
		 get_all_hero_rank_info/0,
		 update_hero_rank/3,
		 get_deposit_single/2,
		 deposit_reward_info/1,
		 deposit_achieve/1,
         reward_rank_end/0,
         save_data_hero/0,
         get_new_serv_end_time/0,
         is_new_serv_1/0,
         is_new_serv/1,
         update_guild_power_hero_rank/3]).

-export([pack_sc_achieve/4,
		 pack_sc_achieve_receive/1,
		 pack_sc_rank/7,
		 pack_sc_storage_info/2,
		 pack_sc_end_time/2,
		 pack_sc_hero_rank/1,
         msg_sc_travell_times/1,
         msg_sc_target/1,
         msg_sc_reply/1,
		 msg_sc_honor_player_info/1,
		 msg_sc_exchange_info/1,
         msg_sc_total_show/1,
		 send_turn_group/2]).

%%
%% API Functions
%%
%% 初始化数据
init() ->
	Today	= misc:date_num(),
	#new_serv{date = Today, turn = #turn{count = 0, times = 0}}.

%% 初始化荣誉榜ETS
init_honor_title_ets() ->
	new_serv_mod:select_data().

%% 初始化英雄榜ETS
init_hero_rank_ets() ->
    EndTime = get_new_serv_end_time(),
    Now = misc:seconds(),
	new_serv_mod:select_data_hero(),
    if
        EndTime < Now ->
            reward_rank_end(),
            ?ok;
        ?true ->
            {{_, M, D}, {H, Mi, _}} = misc:seconds_to_localtime(EndTime),
            crond_api:clock_add('hero_rank_reward_clock', [Mi], [H], [D], [M], [], ?MODULE, reward_rank_end, [])
    end.

%% 新服活动结束时间
get_new_serv_end_time() ->
    StartTime = get_serv_start_time(),
    StartTime + ?CONST_SYS_SEC_DAY*?CONST_NEW_SERV_DAYS.

%% 新服第1天?
is_new_serv_1() ->
    StartTime = get_serv_start_time(),
    Now = misc:seconds(),
    misc:is_same_date(Now, StartTime).
%% 新服第1天?
is_new_serv(N) ->
    StartTime = get_serv_start_time(),
    Now = misc:seconds(),
    {T1, _} = misc:get_midnight_seconds(Now),
    {T2, _} = misc:get_midnight_seconds(StartTime),
    (T1 - T2) / 86400 + 1 =< N.

reward_rank_end() ->
    L = ets:tab2list(?CONST_ETS_HERO_RANK),
    reward_rank(L),
    ets:delete_all_objects(?CONST_ETS_HERO_RANK),
    mysql_api:select(<<"truncate `game_hero_rank`;">>),
    crond_api:clock_del('hero_rank_reward_clock').

reward_rank([{{?CONST_NEW_SERV_TYPE_JTPM = Type, Rank}, GuildId, _Name, _Lv, _Pro, _Sex, _}|Tail]) ->
    try
        case data_new_serv:get_rank_reward({Type, Rank}) of
            #rec_new_serv_rank{reward = GoodsTupleList, main1 = Content, reward2 = GoodsTupleList2, main2 = Content2, top = Title} ->
                GoodsList = make_all_goods(GoodsTupleList, []),
                {?ok, ChiefName} = guild_api:get_guild_chief_name(GuildId),
                send_reward_mail(ChiefName, Type, Title, Content, GoodsList),
                
                GoodsList2 = make_all_goods(GoodsTupleList2, []),
                MemberList = guild_api:get_guild_members(GuildId),
                send_guild_reward_mail(MemberList, Type, Title, Content2, GoodsList2, ChiefName);
            _ ->
                ?ok
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
    reward_rank(Tail);
reward_rank([{{Type, Rank}, _Id, Name, _Lv, _Pro, _Sex, _}|Tail]) ->
    try
        case data_new_serv:get_rank_reward({Type, Rank}) of
            #rec_new_serv_rank{reward = GoodsTupleList, main1 = Content, top = Title} ->
                GoodsList = make_all_goods(GoodsTupleList, []),
                send_reward_mail(Name, Type, Title, Content, GoodsList);
            _ ->
                ?ok
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
    reward_rank(Tail);
reward_rank([]) ->
    ?ok.

make_all_goods([{GoodsId, IsBind, Count}|Tail], L) ->
    case goods_api:make(GoodsId, IsBind, Count) of
        GoodsList when is_list(GoodsList) ->
            make_all_goods(Tail, GoodsList++L);
        _ ->
            make_all_goods(Tail, L)
    end;
make_all_goods([], L) -> L.

send_guild_reward_mail([{_Uid, ChiefName, _Power}|Tail], Type, Title, Content2, GoodsList2, ChiefName) ->
    send_guild_reward_mail(Tail, Type, Title, Content2, GoodsList2, ChiefName);
send_guild_reward_mail([{_Uid, UserName, _Power}|Tail], Type, Title, Content2, GoodsList2, ChiefName) ->
    send_reward_mail(UserName, Type, Title, Content2, GoodsList2),
    send_guild_reward_mail(Tail, Type, Title, Content2, GoodsList2, ChiefName);
send_guild_reward_mail([], _, _, _, _, _) ->
    ?ok.

send_reward_mail(Name, ?CONST_NEW_SERV_TYPE_ZLPM, Title, Content, GoodsList) -> % 战力
    mail_api:send_system_mail_to_one(Name, Title, Content, 0, [], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_P_E);
send_reward_mail(Name, ?CONST_NEW_SERV_TYPE_JTPM, Title, Content, GoodsList) -> % 军团
    mail_api:send_system_mail_to_one(Name, Title, Content, 0, [], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_G_E);
send_reward_mail(Name, ?CONST_NEW_SERV_TYPE_PZPM, Title, Content, GoodsList) -> % 破阵
    mail_api:send_system_mail_to_one(Name, Title, Content, 0, [], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_T_E).

save_data_hero() ->
    new_serv_mod:save_data_hero().
%% 	new_serv_mod:save_exchange_info().
    

%% 登陆刷新数据
login(Player) ->
	{?ok, Player2} = refresh(Player),
    Player3 = new_serv_turn_api:login(Player2),
	Player3.
%% 根据日期刷新数据
refresh(Player) ->
%% 	ReceiveName			= (Player#player.info)#info.user_name,%player_api:get_name(UserId),
	NewServ				= Player#player.new_serv,
	LastDate			= NewServ#new_serv.date,
	LastSeconds			= date_to_seconds(LastDate),
	Today 				= misc:date_num(),
	Now					= misc:seconds(),
	_DiffNum				= misc:get_diff_days(LastSeconds, Now),
	TimeFlag			= check_deposit_reward_validate(?CONST_NEW_SERV_TYPE_ICON),
	case Today =/= LastDate  of
		?true ->
			Player2	= 
				case TimeFlag of
					?true ->
%% 						deposit_award(Player#player.user_id, DiffNum),
						TNewServ	= NewServ#new_serv{date = Today},
						Player#player{new_serv = TNewServ};
					?false ->
						Player
				end,
			NewServ2 = Player2#player.new_serv,
			Achieve	 = NewServ2#new_serv.achieve,
			Achieve2 = refresh_achieve(Achieve, Achieve),
			NewServ3 = NewServ2#new_serv{achieve = Achieve2},
			Player3  = Player2#player{new_serv = NewServ3},
			{?ok, Player3};
		?false ->
			{?ok, Player}
	end.

refresh_achieve([], OldAchieve) -> OldAchieve;
refresh_achieve([#achieve{id = Id}| AchieveList], OldAchieve) ->
	case data_new_serv:get_achieve_by_id(Id) of
		RecAchieve when is_record(RecAchieve, rec_achieve) ->
			Reset 			= RecAchieve#rec_achieve.is_reset,
			Achieve2	= 
				case Reset of
					?CONST_SYS_TRUE -> %% 每日重置
						lists:keydelete(Id, #achieve.id, OldAchieve);
					_ ->
						OldAchieve
				end,
			Achieve3	= 
				case new_serv_mod:check_achieve_validate(RecAchieve) of
					?false -> %% 不在有效期内重置
						lists:keydelete(Id, #achieve.id, OldAchieve);
					?true ->
						Achieve2
				end,
			refresh_achieve(AchieveList, Achieve3);
		_ ->
			refresh_achieve(AchieveList, OldAchieve)
	end;
refresh_achieve([_Achieve| AchieveList], OldAchieve) ->
	refresh_achieve(AchieveList, OldAchieve).
						
			
	
	
%% 检查充值返利有效期
check_deposit_reward_validate(Type) ->
	Now		= misc:seconds(),
	EndTime	= new_serv_mod:end_time(Type),
	Now =< EndTime + 24 * 3600.

%% 充值返利
%% RMB 充值的人民币
%% Cash 充值元宝
deposit_award(UserId, DiffNum) when DiffNum >= 1 ->
	try
		ReceiveName	= player_api:get_name(UserId),
		Deposit 	= get_deposit_single(UserId, DiffNum),
		{AwardCash,GoodsList}	= get_deposit_reward(Deposit),
		DepositList	= [{misc:to_list(Deposit)}],
		AwardList	= [{misc:to_list(AwardCash)}],
		Content		= [{[{ReceiveName}]}] ++ [{DepositList}] ++ [{AwardList}],
		case AwardCash > 0 orelse length(GoodsList) > 0 of
			?true ->
				GoodsList2 =lists:flatten([goods_api:make(GoodsId, Bind, Count)||{GoodsId,Bind,Count}<-GoodsList]), 
				case mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_INTEREST_SEND, Content,
														 GoodsList2, 0, AwardCash, 0, ?CONST_COST_NEW_SERV_DEPOSIT_RETURN) of
					?ok -> ?MSG_ERROR("deposit_award success  UserId：~p  Cash:~p~n", [UserId, AwardCash]), ?ok;
					?true -> ?MSG_ERROR("deposit_award success UserId：~p Cash:~p~n", [UserId, AwardCash]), ?ok;
					{?error, Reason} ->
						?MSG_ERROR("deposit_award error UserId：~p Cash:~p Reason:~p~n", [UserId, AwardCash, Reason]),
						?ok
				end,
				deposit_award(UserId, DiffNum - 1);
			?false ->
				?ok
		end
	catch
		Type:Error ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Type, Error, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end;
deposit_award(_UserId, _DiffNum) -> ?ok.
	

%% 获取充值返利值
get_deposit_reward(Deposit) ->
	Id 			= get_deposit_id(Deposit),
	case data_new_serv:get_deposit_reward(Id) of
		RecDeposit when is_record(RecDeposit, rec_deposit) ->
			{RecDeposit#rec_deposit.reward,RecDeposit#rec_deposit.goods};
		_ ->
			{0,[]}
	end.

%% 获取充值返利区间ID
get_deposit_id(Deposit) ->
	get_deposit_id(Deposit, 1, 0).
get_deposit_id(_Deposit, Id, Id) ->
	Id;
get_deposit_id(Deposit, Id, Acc) ->
	case data_new_serv:get_deposit_reward(Id) of
		RecDeposit when is_record(RecDeposit, rec_deposit) ->
			if
				RecDeposit#rec_deposit.deposit1 =< Deposit andalso RecDeposit#rec_deposit.deposit2 > Deposit ->
					get_deposit_id(Deposit, Id, Id);
				?true ->
					get_deposit_id(Deposit, Id+1, Acc)
			end;
		_ ->
			0
	end.

%% 获得前一日充值总额
get_deposit_single(UserId, DayNum) ->
	Date			= misc:date_num(),
	Seconds 		= date_to_seconds(Date),
	RealSeconds		= Seconds - DayNum * 24 * 3600,
	MatchSpec       = ets:fun2ms(fun({_, _, Cash, Time, Id})  when Id =:= UserId
									  andalso Time >= RealSeconds
									  andalso Time < RealSeconds + 24 * 3600   -> Cash end),
	List			= ets_api:select(?CONST_ETS_PLAYER_DEPOSIT, MatchSpec),
	lists:sum(List).
	
	

%% 日期转化
date_to_seconds(Date) ->
	Y = Date div 10000,
	M = (Date - 10000 * Y) div 100,
	D = (Date - 10000 * Y - 100 * M),
	misc:date_time_to_stamp({Y, M, D, 0, 0, 0}).

%% %% 计算利息
%% calc_interest_last_date(Player, Diff, Now, DrawFlag, Acc) ->
%% 	Seconds		= Now - 24 * 3600 * Diff,
%% 	Interest	= 
%% 		case DrawFlag of
%% 				?false -> %% 前一天未领取的利息
%% 					new_serv_mod:calc_interest(Player, Seconds);
%% 				?true ->  %% 前一天已领取过则不发利息
%% 					0
%% 			end,
%% 	Acc + Interest.
%% 
%% calc_interest(_Player, 0, _Now, Acc) -> Acc;
%% calc_interest(Player, Diff, Now, Acc) when Diff > 0 ->
%% 	Seconds		= Now - 24 * 3600 * Diff,
%% 	Interest	= new_serv_mod:calc_interest(Player, Seconds),
%% 	NewAcc		= Acc + Interest,
%% 	calc_interest(Player, Diff - 1, Now, NewAcc).
%% 					
%% 
%% %% 每日发放未领取元宝
%% refresh_storage_award(_ReceiveName, 0) -> ?ok;
%% refresh_storage_award(ReceiveName, TotalAward) ->
%% 	mail_api:send_interest_mail_to_one2(ReceiveName, <<"生财宝箱存储利息">>, <<"生财宝箱存储利息">>,0,[],
%% 		   							    [], 0, TotalAward, 0, ?CONST_COST_NEW_SERV_DRAW).
%% 
%% 
%% %% 活动结束发放成就奖励
%% refresh_achieve_award(Player, _ReceiveName, []) ->
%% 	{?ok, Player};
%% refresh_achieve_award(Player, ReceiveName, Achieve) ->
%% 	refresh_achieve_award(Player, ReceiveName, Achieve, []),
%% 	NewServ		= Player#player.new_serv,
%% 	NewServ2	= NewServ#new_serv{achieve = []},
%% 	Player2		= Player#player{new_serv = NewServ2},
%% 	{?ok, Player2}.
%% refresh_achieve_award(_Player, ReceiveName, [], Acc) -> 
%% 	case length(Acc) > 0 of
%% 		?true ->
%% 			GoodsIdList		= mail_api:get_goods_id(Acc, []),
%% 			Content			= [{GoodsIdList}],
%% 			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_ACHEIEVEMENT, Content, Acc, 0,
%% 												0, 0, ?CONST_COST_NEW_SERV_ACHIVE_GOODS);
%% 		?false ->
%% 			?ok
%% 	end;
%% refresh_achieve_award(Player, ReceiveName, [#achieve{id = Id, flag = ?true, received = ?CONST_NEW_SERV_UNRECEIVE}|TailList], Acc) -> 
%% 	NewAcc =
%% 		case data_new_serv:get_achieve_goods(Id) of
%% 			RecAchieve when is_record(RecAchieve, rec_achieve)	->
%% 				case new_serv_mod:reward(Player, RecAchieve) of
%% 					{?error, _ErrorCode}			->
%% 						Acc;
%% 					{?ok, _NewPlayer, GoodsList}	->
%% 						Acc ++ GoodsList
%% 				end;
%% 			_Other	->
%% 				?ok
%% 		end,
%% 	refresh_achieve_award(Player, ReceiveName, TailList, NewAcc);
%% refresh_achieve_award(Player, ReceiveName, [_Achieve|TailList], Acc) ->	
%% 	refresh_achieve_award(Player,  ReceiveName, TailList, Acc).
	
%% 捞取离线数据
flush_offline(Player, #achieve_offline{matchdata = MatchData, times = Times, type = Type})->
	finish_achieve(Player#player.user_id, Type, MatchData, Times),
	{?ok, Player};
flush_offline(Player, Data) ->
	?MSG_ERROR("welfare flush_offline data=:~p", [Data]),
	{?ok, Player}.

%% finish_achieve(Player, [])	->	{?ok, Player, <<>>};
%% finish_achieve(Player, AchieveList)	->
%% 	new_serv_mod:finish_achieve(Player, AchieveList, <<>>).

finish_achieve(UserId, Type, MatchData, Times) when is_integer(UserId)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, finish_achieve_cb, [Type, MatchData, Times]);
		_Other	->
			AchieveOffLine	= #achieve_offline{type			= Type,
											   matchdata	= MatchData,
											   times		= Times},
			player_offline_api:offline(?MODULE, UserId, AchieveOffLine)
	end;
finish_achieve(Player, Type, MatchData, Times) when is_record(Player, player)	->
	new_serv_mod:finish_achieve(Player, Type, MatchData, Times).

finish_achieve_cb(Player, [Type, MatchData, Times])	->
	finish_achieve(Player, Type, MatchData, Times).

%% 达成成就信息
achieve_info([#achieve{id = Id, flag = Finished, received = Received, times = Times}|AchieveList], Packet) ->
	Packet1	= pack_sc_achieve(Id, Finished, Received, Times),
	Packet2	= <<Packet/binary, Packet1/binary>>,
	achieve_info(AchieveList, Packet2);
achieve_info([], Packet) -> Packet.
	
%% 插入排名信息
insert_ets_rank(Type, Rank, Num, RankList) ->
	ets_api:insert(?CONST_ETS_NEW_SERV_RANK, {{Type, Rank}, Num, RankList}).

%% 按类型获取排名信息列表
get_rank_info(Type, Rank) ->
	case ets_api:lookup(?CONST_ETS_NEW_SERV_RANK, {Type, Rank}) of
		?null -> {0, []};
		{{Type, Rank}, Num, RankList} -> {Num, RankList}
	end.

%% 获取开服时间
get_serv_start_time() ->
    case config:read_deep([server, release, start_time]) of
        ?null ->
            misc:date_time_to_stamp(misc:seconds());
        Time ->
            misc:date_time_to_stamp(Time)
    end.

%% 充值返利信息
deposit_reward_info(Player) ->
	UserId			= Player#player.user_id,
	Deposit			= get_deposit_single(UserId, 0),
	Packet			= pack_sc_deposit_reward(Deposit),
	misc_packet:send(UserId, Packet),
	{?ok, Player}.

%% 达成成就信息
pack_sc_achieve(Id, Flag, Received, Times)	->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_ACHIEVE,
					 ?MSG_FORMAT_NEW_SERV_SC_ACHIEVE,
					 [Id, Flag, Received, Times]).

%% 成就领取
pack_sc_achieve_receive(Id) ->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_ACHIEVE_RECEIVE, ?MSG_FORMAT_NEW_SERV_SC_ACHIEVE_RECEIVE,[Id]).

%% 排名信息
pack_sc_rank(Type, List1, List2, List3, Num1, Num2, Num3)	->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_RANK,
					 ?MSG_FORMAT_NEW_SERV_SC_RANK,
					 [Type, List1, List2, List3, Num1, Num2, Num3]).

%% 生财宝箱信息
pack_sc_storage_info(Storage, CanDraw)	->
%% 	?MSG_DEBUG("pack_sc_storage_info:~p",[{Storage, CanDraw}]),
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_STORAGE_INFO,
					 ?MSG_FORMAT_NEW_SERV_SC_STORAGE_INFO,
					 [Storage, CanDraw]).

%% 活动剩余时间信息
pack_sc_end_time(Type, TimeStamp)	->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_END_TIME,
					 ?MSG_FORMAT_NEW_SERV_SC_END_TIME,
					 [Type, TimeStamp]).

%% 活动剩余时间信息
pack_sc_deposit_reward(Deposit)	->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_DEPOSIT_REWARD,
					 ?MSG_FORMAT_NEW_SERV_SC_DEPOSIT_REWARD,
					 [Deposit]).

%% 可转次数
%%[Times]
msg_sc_travell_times(Times) ->
    misc_packet:pack(?MSG_ID_NEW_SERV_SC_TRAVELL_TIMES, ?MSG_FORMAT_NEW_SERV_SC_TRAVELL_TIMES, [Times]).
%% 目标
%%[Idx]
msg_sc_target(Idx) ->
    misc_packet:pack(?MSG_ID_NEW_SERV_SC_TARGET, ?MSG_FORMAT_NEW_SERV_SC_TARGET, [Idx]).
%% 到背包
%%[Idx]
msg_sc_reply(Idx) ->
    misc_packet:pack(?MSG_ID_NEW_SERV_SC_REPLY, ?MSG_FORMAT_NEW_SERV_SC_REPLY, [Idx]).

%% 获奖兑换信息
msg_sc_exchange_info(List) ->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_EXCHANGE_INFO, ?MSG_FORMAT_NEW_SERV_SC_EXCHANGE_INFO, [List]).
%%
%% Local Functions
%%

%% ==========================================================
%% 开服活动 -- 荣誉榜
%% ==========================================================
add_honor_title(Player, HonorId, Type) when is_record(Player, player) ->
	new_serv_mod:add_honor_title(Player, HonorId, Type);

add_honor_title(UserId, HonorId, Type) when is_integer(UserId) ->
	new_serv_mod:add_honor_title(UserId, HonorId, Type).

read_honor_info() ->
	case ets:tab2list(?CONST_ETS_HONOR_TITLE) of
		?null ->
			{?ok, []};
		HonorLists ->
			HonorInfo = read_honor_info2(HonorLists, []),
			{?ok, HonorInfo}
	end.

read_honor_info2([Honor | HonorLists], HonorInfo) ->
	
	#rec_honor_title{
					 honor_id = HonorId,		% 荣誉榜ID
					 user_id = UserId,			% 玩家ID
					 user_name = UserName,		% 玩家名称
					 lv = Lv,					% 玩家等级
					 sex = Sex,					% 性别
					 pro = Pro,					% 职业
					 weapon = Weapon,			% 武器ID
					 fashion = Fashion,			% 时装ID
					 armor = Armor				% 衣服ID			
					} = Honor,
	HonorInfo2 = {HonorId, UserId, UserName, Lv, Sex, Pro, Weapon, Fashion, Armor},
	read_honor_info2(HonorLists, [HonorInfo2 | HonorInfo]);
read_honor_info2([], HonorInfo) ->
	HonorInfo.

deposit_achieve(UserId) ->
	CashSum		= player_money_api:read_cash_sum(UserId),
	new_serv_api:deposit_achieve(UserId, ?CONST_NEW_SERV_DEPOSIT, CashSum, 1).
	
msg_sc_honor_player_info(List) ->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_HONOR_PLAYER_INFO, ?MSG_FORMAT_NEW_SERV_SC_HONOR_PLAYER_INFO, [List]).

%% ==========================================================
%% 开服活动 -- 英雄榜
%% ==========================================================
%% 插入英雄榜排名信息
insert_ets_hero_rank(Type, Rank, Id, Name, Lv, Pro, Sex, GuildName) ->
	ets_api:insert(?CONST_ETS_HERO_RANK, {{Type, Rank}, Id, Name, Lv, Pro, Sex, GuildName}).

%% 按类型获取排名信息列表
get_hero_rank_info(Type, Rank) ->
	case ets_api:lookup(?CONST_ETS_HERO_RANK, {Type, Rank}) of
		?null -> {0, 0, 0, 0, 0, 0, 0, <<>>};
		{{Type, Rank}, Id, Name, Lv, Pro, Sex, GuildName} -> 
			{Type, Rank, Id, Name, Lv, Pro, Sex, GuildName}
	end.

get_all_hero_rank_info() ->
		case ets:tab2list(?CONST_ETS_HERO_RANK)  of
		?null -> {?ok, []};
		RankLists -> 
			Fun	= fun({{_Type, _Rank}, 0, <<>>, _Lv, _, _, _}, OldList) ->
				        OldList;
		             ({{Type, Rank}, Id, Name, Lv, Pro, Sex, GuildName}, OldList) ->
				        [{Id, Name, Lv, Rank, Type, Pro, Sex, GuildName}|OldList]
		 			 end,
			NewRankList = lists:foldl(Fun, [], RankLists),
			{?ok, NewRankList}
	end.

update_hero_rank(RankDatas, L, IsSend) ->
    Now = misc:seconds(),
    EndTime = get_new_serv_end_time(),
    if
        Now < EndTime ->
        	new_serv_mod:update_hero_rank(RankDatas, L, IsSend);
        ?true ->
            ?ok
    end.
update_guild_power_hero_rank(RankDatas, L, IsSend) ->
    Now = misc:seconds(),
    EndTime = get_new_serv_end_time(),
    if
        Now < EndTime ->
        	new_serv_mod:update_guild_power_hero_rank(RankDatas, L, IsSend);
        ?true ->
            ?ok
    end.
	
%% 英雄榜前三甲排名信息
pack_sc_hero_rank(RankList)	->
	misc_packet:pack(?MSG_ID_NEW_SERV_SC_HERO_RANK,
					 ?MSG_FORMAT_NEW_SERV_SC_HERO_RANK,
					 [RankList]).

%% 转盘所得
%%[{Idx,Count}]
msg_sc_total_show(List1) ->
    misc_packet:pack(?MSG_ID_NEW_SERV_SC_TOTAL_SHOW, ?MSG_FORMAT_NEW_SERV_SC_TOTAL_SHOW, [List1]).

%% 发送转盘物品的goup id给前端
send_turn_group(UserId, Group) ->
	GroupPacket = misc_packet:pack(?MSG_ID_NEW_SERV_SC_TURN_GROUP_ID, ?MSG_FORMAT_NEW_SERV_SC_TURN_GROUP_ID, [Group]),
	misc_packet:send(UserId, GroupPacket).

























