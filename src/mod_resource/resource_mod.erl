%% @author Administrator
%% @doc @todo Add description to resource_mod2.
-module(resource_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.tip.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.goods.data.hrl").

-include_lib("eunit/include/eunit.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([init_player_resource/0]).
-export([rune_info/1, use_rune/2]).
-export([pray_info/1, use_pray/2]).
-export([rune_chest_info/1, open_rune_chest/2, init_pool/0, pool_info/2,
         clear_cd/1, do_lottery/2, do_gift_lottery/2,calc_lottery_award/2,calc_exp_lottery_award/1,
		 do_exp_lottery/2,get_big_award_info/1]).

%% ====================================================================
%% Internal functions
%% ====================================================================
init_player_resource()	->
	#resource{date			= 0,
			  tot_rune_cnt	= 0,
			  rune_cnt		= 0,
			  rune_tips		= ?true,
			  rune_chest	= init_rune_chest(),
			  pray_cnt		= 0,
              pool_cd       = 0,
			  pool_gift_limit =0
			 }.

init_rune_chest()	->
	ChestIdList	= data_resource:get_rune_chest_list(),
	init_rune_chest(ChestIdList, []).
init_rune_chest([ChestId | ChestIdList], Acc)	->
	NewAcc		= Acc ++ [#chest_data{chest_id	= ChestId,	chest_num	= 0}],
	init_rune_chest(ChestIdList, NewAcc);
init_rune_chest([], Acc)	->	Acc.

rune_info(Player)	->
%% 	NewPlayer	= refresh(Player),
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	VipLv		= player_api:get_vip_lv(Info),
	Resource	= Player#player.resource,
	TotRuneCnt	= Resource#resource.tot_rune_cnt,
	RuneCnt		= Resource#resource.rune_cnt,
	MaxCnt		= player_vip_api:get_grab_times(VipLv),
	CntList		= player_vip_api:get_grab_count(VipLv),
	MoneyList	= rune_gold(Lv, RuneCnt, MaxCnt - RuneCnt, CntList, []),
%% 	?MSG_WARNING("~nLv=~p~nRuneCnt=~p~nAvailableCnt=~p~nCntList=~p~nMoneyList=~p~n",
%% 				 [Lv, RuneCnt, MaxCnt - RuneCnt, CntList, MoneyList]),
	Packet		= resource_api:pack_sc_rune_info(MaxCnt - RuneCnt, TotRuneCnt, MoneyList),
	misc_packet:send(Player#player.net_pid, Packet),
	rune_chest_info(Player),
	{?ok, Player}.

rune_gold(Lv, Used, Available, [Cnt | CntList], Acc)	->
	if
		Cnt =< Available	->
			Cash	= rune_gold(Used, Used + Cnt),
			Gold	= Lv * ?CONST_RESOURCE_BASEGOLD * Cnt,
			NewAcc	= [{Cnt, Cash, Gold} | Acc],
			rune_gold(Lv, Used, Available, CntList, NewAcc);
		?true	->	Acc
	end;
rune_gold(_Lv, _Used, _Available, [], Acc)	->	Acc.

rune_gold(Start, End) when Start < End	->
	data_resource:get_rune_init(End) + rune_gold(Start, End - 1);
rune_gold(_Start, _End)	->	0.

rune_chest_info(Player) ->
	Bag				= Player#player.bag,
	Resource		= Player#player.resource,
	RuneChest		= Resource#resource.rune_chest,
	ChestInfoList	= rune_chest_info(Bag, RuneChest, []),
	Packet			= resource_api:pack_sc_rune_chest_info(ChestInfoList),
	misc_packet:send(Player#player.net_pid, Packet).

rune_chest_info(Container, [Chest | ChestList], Acc)
  when is_record(Chest, chest_data)	->
	ChestId		= Chest#chest_data.chest_id,
	ChestNum	= Chest#chest_data.chest_num,
	case data_resource:get_key_init(ChestId) of
		?null	->
%% 			?MSG_WARNING("~nContainer=~p~nChest=~p~nChestList=~p~nAcc=~p~n", [Container, Chest, ChestList, Acc]),
			NewAcc	= [{ChestId, ChestNum, 0, 0} | Acc],
			rune_chest_info(Container, ChestList, NewAcc);
		KeyId	->
%% 			?MSG_WARNING("~nContainer=~p~nChest=~p~nChestList=~p~nAcc=~p~n",
%% 						 [Container, Chest, ChestList, Acc]),
			KeyNum	= ctn_bag2_api:get_goods_count(Container, KeyId),
			NewAcc	= [{ChestId, ChestNum, KeyId, KeyNum} | Acc],
			rune_chest_info(Container, ChestList, NewAcc)
	end;
rune_chest_info(_Container, [], Acc)	->
%% 	?MSG_WARNING("~nAcc=~p~n", [Acc]),
	Acc.

use_rune(Player, RuneCount)	->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	VipLv		= player_api:get_vip_lv(Info),
	Resource	= Player#player.resource,
	RuneCnt		= Resource#resource.rune_cnt,
	MaxCnt		= player_vip_api:get_grab_times(VipLv),
	CntList		= player_vip_api:get_grab_count(VipLv),
	VipFlag		= check_rune_count(RuneCount, CntList),
	CurCnt		= if
					  MaxCnt >= RuneCnt + RuneCount	->	RuneCount;
					  ?true	->	MaxCnt - RuneCnt
				  end,
	Cash		= rune_gold(RuneCnt, RuneCnt + CurCnt),
	%% Gold		= misc:floor(6000 * (0.8 + 0.2 * Lv) * CurCnt),
	%% CurCnt用于VIP玩家批量收夺次数
	Gold1		= misc:floor(CurCnt * ?FUN_RESOURCE_CSUSERUNE(Lv)),	
	%% 占城军团成员收夺时额外增加20%的收益
	Gold  = get_extra_gold(Player, Gold1),

	{?ok, Money}= player_money_api:read_money(UserId),
	MoneyFlag	= Cash =< Money#money.cash + Money#money.cash_bind + Money#money.cash_bind_2,
	LimitFlag	= ?CONST_SYS_MAX_BGOLD >= Money#money.gold_bind + Gold,
%% 	?MSG_WARNING("~nVipFlag=~p~nMoneyFlag=~p~nLimitFlag=~p~n", [VipFlag, MoneyFlag, LimitFlag]),
	case {VipFlag, MoneyFlag, LimitFlag} of
		{?true, ?true, ?true}	->
			case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_RESOURCE_RUNE) of
				?ok	->
					case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_RESOURCE_REWARD_RUNE) of
						?ok ->
							%% gen_server:cast(guild_pvp_serv, {add_guild_pvp_ex_gold, Player, Gold*0.2}),
							TipPacket		= message_api:msg_notice(?TIP_RESOURCE_GET_GOLD, [{?TIP_SYS_COMM, misc:to_list(Gold)}]),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player1}	= update_rune(Player, CurCnt),
							{?ok, Player2}	= rune_info(Player1),
							use_rune_ext(Player2);
						{?error, _ErrorCode}	->	{?ok, Player}
					end;
				{?error, _ErrorCode}	->	{?ok, Player}
			end;
		{?false, _, _}	->
			TipsPacket	= vip(VipLv),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, ?false, _}	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_CASH_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, _, ?false}	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_TOO_MUCH_BGOLD),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

check_rune_count(RuneCount, [Time | TimesList])	->
	if
		RuneCount =< Time	->	?true;
		?true	->	check_rune_count(RuneCount, TimesList)
	end;
check_rune_count(_RuneCount, [])	->	?false.

update_rune(Player, Cnt)	->
	Resource		= Player#player.resource,
	RuneChest		= Resource#resource.rune_chest,
	TotRuneCnt		= Resource#resource.tot_rune_cnt,
	RuneCnt			= Resource#resource.rune_cnt,
	NewRuneChest	= get_rune_chest(RuneChest, (TotRuneCnt + Cnt) div ?CONST_RESOURCE_BASERUNECHEST),
	NewResource		= Resource#resource{tot_rune_cnt	= (TotRuneCnt + Cnt) rem ?CONST_RESOURCE_BASERUNECHEST,
										rune_cnt		= RuneCnt + Cnt,
										rune_chest		= NewRuneChest},
	NewPlayer		= Player#player{resource = NewResource},
	%% 春节送红包活动
	if Cnt >= 5 ->
		   spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 1 * (Cnt div 5));
	   NewResource#resource.rune_cnt rem 5 =:= 0 ->
		   spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 1);
	   true ->
		   skip
	end,
	{?ok, NewPlayer}.

use_rune_ext(Player)	->
	{?ok, Player1}	= schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_RUNE),
	{?ok, Player2}	= welfare_api:add_pullulation(Player1, ?CONST_WELFARE_RUNE, 0, 1),
	Resource		= Player#player.resource,
	RuneChest		= Resource#resource.rune_chest,
	{?ok, Player3}	= use_rune_ext(Player2, RuneChest),
	achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_SNATCH, 0, 1).
use_rune_ext(Player, [_ChestData = #chest_data{chest_id		= ?CONST_RESOURCE_COPPER_CHEST,
											   chest_num	= ChestNum} | ChestDataList])
  when ChestNum > 0	->
	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_PURPLE_CHEST, 0, 1),
	use_rune_ext(Player1, ChestDataList);
use_rune_ext(Player, [_ChestData = #chest_data{chest_id		= ?CONST_RESOURCE_SILVER_CHEST,
											   chest_num	= ChestNum} | ChestDataList])
  when ChestNum > 0	->
	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_ORANGE_CHEST, 0, 1),
	use_rune_ext(Player1, ChestDataList);
use_rune_ext(Player, [_ChestData = #chest_data{chest_id		= ?CONST_RESOURCE_GOLDEN_CHEST,
											   chest_num	= ChestNum} | ChestDataList])
  when ChestNum > 0	->
	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_RED_CHEST, 0, 1),
	use_rune_ext(Player1, ChestDataList);
use_rune_ext(Player, [_ChestData | ChestDataList])	->	use_rune_ext(Player, ChestDataList);
use_rune_ext(Player, [])	->	{?ok, Player}.

vip(?CONST_SYS_MAX_VIP_LV)	->
%% 	?MSG_WARNING("~nVipLv=~p~n", [?CONST_SYS_MAX_VIP_LV]),
	message_api:msg_notice(?TIP_RESOURCE_RUNE_INSUFFICIENCY);
vip(_VipLv)					->
%% 	?MSG_WARNING("~nVipLv=~p~n", [_VipLv]),
	message_api:msg_notice(?TIP_RESOURCE_VIP_INSUFFICIENCY).

get_rune_chest(RuneChest, Cnt) when Cnt > 0		->
	Chest			= data_resource:get_rune_chest_init(),
	ChestId			= misc_random:odds_one(Chest#chest.list, Chest#chest.sum),
	NewRuneChest	= add_chest(ChestId, RuneChest),
	get_rune_chest(NewRuneChest, Cnt - 1);
get_rune_chest(RuneChest, Cnt) when Cnt =< 0	->
	RuneChest.

pray_info(Player) ->
%% 	NewPlayer	= refresh(Player),
	Resource	= Player#player.resource,
	PrayCnt		= Resource#resource.pray_cnt,
	RemainCnt	= ?CONST_RESOURCE_PRAY_TIMES - PrayCnt,
	Packet		= resource_api:pack_sc_pray_info(RemainCnt),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player}.

use_pray(Player, PrayType) when PrayType =:= ?CONST_RESOURCE_PRAY_XY	->
	Info		= Player#player.info,
	VipLv		= player_api:get_vip_lv(Info),
	VipPrayType	= player_vip_api:get_pray_lv(VipLv),
	RecPray		= data_resource:get_pray_init(PrayType),
	{?ok, Money}= player_money_api:read_money(Player#player.user_id),
	if
		PrayType > VipPrayType	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Money#money.gold_bind < RecPray#rec_pray.coin	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_BIND_GOLD_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		?true	->
			use_pray(Player, ?CONST_SYS_GOLD_BIND, RecPray#rec_pray.coin, RecPray#rec_pray.meritorious)
	end;
use_pray(Player, PrayType)
  when PrayType =:= ?CONST_RESOURCE_PRAY_HX orelse PrayType =:= ?CONST_RESOURCE_PRAY_SW	->
	Info		= Player#player.info,
	VipLv		= player_api:get_vip_lv(Info),
	VipPrayType	= player_vip_api:get_pray_lv(VipLv),
	RecPray		= data_resource:get_pray_init(PrayType),
	{?ok, Money}= player_money_api:read_money(Player#player.user_id),
	if
		PrayType > VipPrayType	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Money#money.cash + Money#money.cash_bind_2 < RecPray#rec_pray.cost	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_CASH_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		?true	->
			use_pray(Player, ?CONST_SYS_CASH, RecPray#rec_pray.cost, RecPray#rec_pray.meritorious)
	end.
use_pray(Player, MinusType, MinusAmount, Meritorious)	->
	Info		= Player#player.info,
	Resource	= Player#player.resource,
	PrayCnt		= Resource#resource.pray_cnt,
	RemainCnt	= ?CONST_RESOURCE_PRAY_TIMES - PrayCnt,
	CountFlag	= RemainCnt > 0 ,
	LimitFlag	= ?CONST_SYS_MAX_MERITORIOUS >= Info#info.meritorious + Meritorious,
	case {CountFlag, LimitFlag} of
		{?true, ?true}	->
			case player_money_api:minus_money(Player#player.user_id, MinusType, MinusAmount, ?CONST_COST_RESOURCE_PRAY) of
				?ok	->
					{?ok, Player1}	= player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_RESOURCE_PRAY_REWARD),
					TipsPacket		= message_api:msg_notice(?TIP_RESOURCE_ADD_MERITORIOUS, [{?TIP_SYS_COMM, misc:to_list(Meritorious)}]),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					admin_log_api:log_patrol(Player1, MinusType, MinusAmount, Meritorious),
					{?ok, Player2}	= update_pray(Player1),
					{?ok, Player3}	= pray_info(Player2),
					use_pray_ext(Player3);
				{?error, _ErrorCode}	->	{?ok, Player}
			end;
		{?false, _}		->
			TipsPacket	= message_api:msg_notice(?TIP_RESOURCE_PRAY_INSUFFICIENCY),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, ?false}		->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_TOO_MUCH_MERITORIOUS),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

update_pray(Player)	->
	Resource	= Player#player.resource,
	PrayCnt		= Resource#resource.pray_cnt,
	NewResource	= Resource#resource{pray_cnt = PrayCnt + 1},
	NewPlayer	= Player#player{resource = NewResource},
	{?ok, NewPlayer}.

use_pray_ext(Player)	->
	{?ok, Player1}	= welfare_api:add_pullulation(Player, ?CONST_WELFARE_PRAY, 0, 1),
	achievement_api:add_achievement(Player1, ?CONST_ACHIEVEMENT_PATROL, 0, 1).

open_rune_chest(Player, ChestId)	->
	Bag			= Player#player.bag,
	Resource	= Player#player.resource,
	RuneChest	= Resource#resource.rune_chest,
	KeyId		= data_resource:get_key_init(ChestId),
	ChestFlag	= chest_num(ChestId, RuneChest) > 0,
	KeyNum		= case KeyId of
					  ?null	->	0;
					  KeyId	->	ctn_bag2_api:get_goods_count(Bag, KeyId)
				  end,
	KeyFlag		= KeyNum > 0,
	BagFlag		= ctn_bag2_api:is_full(Bag),
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	DropId		= data_resource:get_drop_init({ChestId, Lv}),
	GoodsList	= goods_api:goods_drop(DropId),
	case {ChestFlag, KeyFlag, BagFlag} of
		{?true, ?true, ?false}	->
			case ctn_bag2_api:get_by_id(Player#player.user_id, Bag, KeyId, 1) of
				{?ok, DelBag, _GoodsList, Packet}	->
					case del_chest(ChestId, RuneChest) of
						?false	->
							TipsPacket	= message_api:msg_notice(?TIP_RESOURCE_CHEST_INSUFFICIENCY),
							misc_packet:send(Player#player.net_pid, TipsPacket),
							{?ok, Player};
						NewRuneChest	->
							misc_packet:send(Player#player.user_id, Packet),
							admin_log_api:log_goods(Player#player.user_id, 0, ?CONST_COST_OPEN_CHEST, KeyId, 1, misc:seconds()),
							NewResource	= Resource#resource{rune_chest	= NewRuneChest},
							NewPlayer	= Player#player{bag			= DelBag,
														resource	= NewResource},
							case goods_info(NewPlayer, GoodsList) of
								{?ok, NewPlayer2}	->
                                    AddBag          = NewPlayer2#player.bag,
									ChestInfoList	= rune_chest_info(AddBag, NewRuneChest, []),
									ChestPacket		= resource_api:pack_sc_rune_chest_info(ChestInfoList),
									misc_packet:send(NewPlayer#player.net_pid, ChestPacket),
									tips(NewPlayer2, GoodsList),
									{?ok, NewPlayer2};
								{?error, _ErrorCode}	->	{?ok, Player}
							end
					end;
				{?error, _ErrorCode}	->
					TipsPacket	= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player}
			end;
		{?false, _, _}			->
			TipsPacket	= message_api:msg_notice(?TIP_RESOURCE_CHEST_INSUFFICIENCY),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, ?false, _}			->
			TipsPacket	= message_api:msg_notice(?TIP_RESOURCE_KEY_INSUFFICIENCY),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, _, ?true}			->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

tips(Player, [Goods | GoodsList])	->
	GoodsId	= Goods#goods.goods_id,
	Count	= Goods#goods.count,
	Packet	= message_api:msg_notice(?TIP_RESOURCE_OPEN_CHEST,
									 [{?CONST_MESSAGE_NOT_EQUIP, misc:to_list(GoodsId)},
									  {?CONST_MESSAGE_TIP_SYS_COMM, misc:to_list(Count)}]),
	misc_packet:send(Player#player.user_id, Packet),
	tips(Player, GoodsList);
tips(_Player, [])	->	?ignore.

goods_info(Player, GoodsList)	->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_WELFARE_REWARD_GOLD, 1, 1, 0, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag}	->
			{?ok, Player2};
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.

add_chest(ChestId, RuneChest)	->
	case lists:keyfind(ChestId, #chest_data.chest_id, RuneChest) of
		Tuple when is_record(Tuple, chest_data)	->
			NewChestNum	= Tuple#chest_data.chest_num + 1,
			NewTuple	= Tuple#chest_data{chest_num = NewChestNum},
			lists:keyreplace(ChestId, #chest_data.chest_id, RuneChest, NewTuple);
		_Other ->
			Tuple		= #chest_data{chest_id = ChestId, chest_num = 1},
			[Tuple | RuneChest]
	end.

del_chest(ChestId, RuneChest)	->
	case lists:keyfind(ChestId, #chest_data.chest_id, RuneChest) of
		Tuple when is_record(Tuple, chest_data)
		  andalso Tuple#chest_data.chest_num > 0	->
			NewChestNum	= Tuple#chest_data.chest_num - 1,
			NewTuple	= Tuple#chest_data{chest_num = NewChestNum},
			lists:keyreplace(ChestId, #chest_data.chest_id, RuneChest, NewTuple);
		_Other	->	?false
	end.

chest_num(ChestId, RuneChest)	->
	case lists:keyfind(ChestId, #chest_data.chest_id, RuneChest) of
		Tuple when is_record(Tuple, chest_data)	->
			Tuple#chest_data.chest_num;
		_Other	->	0
	end.

get_extra_gold(Player, Gold) ->
	Guild = Player#player.guild,
	GuildId = Guild#guild.guild_id,
	ToweGuildId = guild_pvp_mod:get_tower_owner_id(), 
	if GuildId =:=  ToweGuildId ->
		   round(Gold * (1+0.2));
	   true ->
		   Gold
	end.

%%---------------------------------------------------------------------------------
init_pool() ->
%%     ets:insert(?CONST_ETS_RES_POOL, {bgold, 100000000}),
%%     ets:insert(?CONST_ETS_RES_POOL, {list, []}),
    ok.

pool_info(Player,1) ->
    Res = Player#player.resource,
    PoolCd = Res#resource.pool_cd,
    CdPacket = resource_api:msg_sc_cd(PoolCd),
    BGold = resource_serv:read_bgold(),
    BGoldPacket = resource_api:msg_sc_pool(1,BGold),
    List = resource_serv:read_list(),
    ListPacket = resource_api:msg_sc_winning(List, <<>>),
    misc_packet:send(Player#player.user_id, <<CdPacket/binary, BGoldPacket/binary, ListPacket/binary>>);

pool_info(Player,2) ->
    Res = Player#player.resource,
    FirstCount = Res#resource.pool_gift_limit,
    CdPacket = resource_api:msg_sc_cd(FirstCount),
    BCash = resource_serv:read_bcash(),
    BCashPacket = resource_api:msg_sc_pool(2,BCash),
    List = resource_serv:read_bcash_list(),
    ListPacket = resource_api:msg_sc_winning(List, <<>>),
    misc_packet:send(Player#player.user_id, <<CdPacket/binary, BCashPacket/binary, ListPacket/binary>>);

pool_info(Player,3) ->
	Res = Player#player.resource,
    PoolCd = Res#resource.pool_cd,
    CdPacket = resource_api:msg_sc_cd(PoolCd),
    Exp = resource_serv:read_exp(),
    ExpPacket = resource_api:msg_sc_pool(3,Exp),
    List = resource_serv:read_list_exp(),
    ListPacket = resource_api:msg_sc_winning(List, <<>>),
    misc_packet:send(Player#player.user_id, <<CdPacket/binary, ExpPacket/binary, ListPacket/binary>>);

pool_info(_,_)->
	?error.

clear_cd(Player) ->
    Res = Player#player.resource,
    Cd = Res#resource.pool_cd,
    Cash = calc_cd_cash(Cd),
    case minus_cash(Player, Cash) of
        {?ok, 0} ->
            {?error, ?TIP_RESOURCE_CD_IS_0};
        {?ok, 1} ->
            Res2 = Res#resource{pool_cd = 0},
            CdPacket = resource_api:msg_sc_cd(0),
            misc_packet:send(Player#player.user_id, CdPacket),
            Player#player{resource = Res2};
        _ ->
            ?ok
    end.

calc_cd_cash(Cd) when Cd > 0 -> 
    Now = misc:seconds(),
    Delta = Cd - Now,
    CdMin = round(Delta / 60),
    if
        0 =:= Delta -> 0;
        ?true -> misc:max(CdMin, 1)
    end;
calc_cd_cash(_) -> 0.

minus_cash(_Player, 0) ->
    {?ok, 0};
minus_cash(Player, Cash) ->
    case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_LOTTERY_CLEAR_CD) of
        ?ok -> 
            {?ok, 1};
        {?error, _ErrorCode} ->
            ?error
    end.

%%铜钱抽奖
do_lottery(Player, _Idx) ->
    Res = Player#player.resource,
    Cd = Res#resource.pool_cd,
%%     Now = misc:seconds(),
%%     if
%%         Cd =< Now ->
            case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, ?CONST_GOODS_GOODS_ID_RES_LUCK, 1) of
                {?ok, Bag2, _, BagPacket} ->
                    Info = Player#player.info,
                    VipLv = player_api:get_vip_lv(Player),
                    OldBGold = resource_serv:read_bgold(),
                    Nth = random_win(VipLv, OldBGold, Cd),
                    BGold = calc_lottery_award(Nth, Info#info.lv),
                    case player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, BGold, ?CONST_COST_LOTTERY_DO_LOTTERY) of
                        ?ok ->
%%                             NewCd = Now + ?CONST_RESOURCE_POOL_CD,
%%                             CdPacket = resource_api:msg_sc_cd(NewCd),
                            NewBGold = OldBGold - BGold,
                            PoolPacket = resource_api:msg_sc_pool(1,NewBGold),
							if Nth < 3 -> %% 三等奖不上榜
								   resource_serv:win_cast(Player#player.user_id, Info#info.user_name, BGold),
								   WinPacket = resource_api:msg_sc_winning(Player#player.user_id, Info#info.user_name, BGold,1),
								   misc_app:broadcast_world_2(WinPacket);
							   ?true ->
								   ?ok
							end,
                            
                            WinPacket1 = resource_api:msg_sc_award(1, BGold),
                            misc_packet:send(Player#player.user_id, <<BagPacket/binary, PoolPacket/binary,WinPacket1/binary>>),
                            NewCd = 
                                if
                                    Nth =< 1 ->
                                        TipPacket = message_api:msg_notice(?TIP_RESOURCE_GET_AWARD, [{Player#player.user_id, Info#info.user_name}], [], 
                                                                           [{?TIP_SYS_COMM, misc:to_list(BGold)},
                                                                           {?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_RESOURCE_GET_AWARD)}]),
                                        misc_app:broadcast_world_2(TipPacket),
										BigAwardPacket = resource_api:msg_sc_big_award(Player#player.user_id, Info#info.user_name, BGold,1),
										resource_serv:put_big_award_cast({Player#player.user_id, Info#info.user_name, BGold,1}),
										misc_app:broadcast_world_2(BigAwardPacket),
                                        Cd+1;
                                    ?true ->
                                        Cd
                                end,
                            admin_log_api:log_goods(Player#player.user_id, 0, ?CONST_COST_LOTTERY_DO_LOTTERY, ?CONST_GOODS_GOODS_ID_RES_LUCK, 1, misc:seconds()),
                            Res2 = Res#resource{pool_cd = NewCd},
                            Player#player{bag = Bag2, resource = Res2};
                        _ ->
                            ?error
                    end;
                {?error, _ErrorCode} ->
                    ?error
%%             end;
%%         ?true ->
%%             {?error, ?TIP_RESOURCE_CDING}
    end.

%%礼券抽奖
do_gift_lottery(Player, _Idx) ->
	case resource_api:check_start_server_same_day() of
		true ->
			?error;
		false ->
			Res = Player#player.resource,
			FirstCount = Res#resource.pool_gift_limit,
			case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, ?CONST_GOODS_GOODS_ID_RES_LUCK2, 1) of
				{?ok, Bag2, _, BagPacket} ->
					Info = Player#player.info,
					PlayerLevel = Info#info.lv,
					WorldLevel = 
						case ets:tab2list(?CONST_ETS_RANK_AVG_LV) of
							[{AvgLv}] ->
								AvgLv;
							_ ->
								PlayerLevel
						end,
					OldBcash= resource_serv:read_bcash(),
					AwardCount= random_gift_win(PlayerLevel, WorldLevel, FirstCount),
					case player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH_BIND, AwardCount, ?CONST_COST_LOTTERY_DO_LOTTERY) of
						?ok ->                       
							NewBcash = erlang:max(OldBcash - AwardCount,?CONST_RESOURCE_POOL_BCASH_MIN),
							PoolPacket = resource_api:msg_sc_pool(2,NewBcash),
							case AwardCount > ?CONST_RESOURCE_REAL_BIG_HIT of
								true ->
									resource_serv:win_bcash_cast(Player#player.user_id, Info#info.user_name, AwardCount);
								_ ->
									next
							end,
                            WinPacket = resource_api:msg_sc_award(2, AwardCount),
							misc_packet:send(Player#player.user_id, <<WinPacket/binary,BagPacket/binary, PoolPacket/binary>>),
							NewFirstCount = 
								if
									AwardCount >=?CONST_RESOURCE_REAL_BIG_HIT ->
										TipPacket = message_api:msg_notice(?TIP_RESOURCE_GET_BCASH_AWARD, [{Player#player.user_id, Info#info.user_name}], [], 
																		   [{?TIP_SYS_COMM, misc:to_list(AwardCount)},
																			{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_RESOURCE_GET_AWARD)}]),
										misc_app:broadcast_world_2(TipPacket),
										BigAwardPacket = resource_api:msg_sc_big_award(Player#player.user_id, Info#info.user_name, AwardCount, 2),
										resource_serv:put_big_award_cast({Player#player.user_id, Info#info.user_name, AwardCount,2}),
										misc_app:broadcast_world_2(BigAwardPacket),
										FirstCount+1;
									?true ->
										FirstCount
								end,
							admin_log_api:log_goods(Player#player.user_id, 0, ?CONST_COST_LOTTERY_DO_LOTTERY, ?CONST_GOODS_GOODS_ID_RES_LUCK2, 1, misc:seconds()),
							Res2 = Res#resource{pool_gift_limit = NewFirstCount},
							Player#player{bag = Bag2, resource = Res2};
						_ ->
							?error
					end;
				{?error, _ErrorCode} ->
					?error
			end
	end.

calc_lottery_award(Idx, Lv) when Lv >= ?CONST_RESOURCE_POOL_LV_MIN ->
    Temp = read_idx_award(Idx),
    RandomRate = misc_random:random(80, 120),
    misc:round(Temp * (0.8+0.2*Lv) * (RandomRate / 100));
calc_lottery_award(Idx, _Lv) ->
    calc_lottery_award(Idx, ?CONST_RESOURCE_POOL_LV_MIN).

read_idx_award(1) -> ?CONST_RESOURCE_BGOLD_1ST;
read_idx_award(2) -> ?CONST_RESOURCE_BGOLD_2ND;
read_idx_award(3) -> ?CONST_RESOURCE_BGOLD_3RD;
read_idx_award(_) -> ?CONST_RESOURCE_BGOLD_3RD.

random_win(VipLv, OldBGold, Count) when 0 =< VipLv andalso VipLv =< ?CONST_SYS_MAX_VIP_LV ->
    L = 
        case data_resource:get_random_rate(VipLv) of
            {LR1, R1, HR1, _LR2, _R2, _HR2} when Count < 2 ->
                if
                    OldBGold >= 500000000 ->
                        HR1;
                    OldBGold < 100000000 -> 
                        LR1;
                    ?true ->
                        R1
                end;
            {_LR1, _R1, _HR1, LR2, R2, HR2} ->
                if
                    OldBGold >= 500000000 ->
                        HR2;
                    OldBGold < 100000000 -> 
                        LR2;
                    ?true ->
                        R2
                end;
            _ ->
                {[{1,0},{2,0},{3,100000}],100000}
        end,
    misc_random:odds_one(L);
random_win(_Lv, BGold, Count) ->
    random_win(0, BGold, Count).

random_gift_win(PlayerLevel, WorldLevel,FirstCount)->
	LevelGap = WorldLevel - PlayerLevel,
	[Rate,{Min,Max}] =
	if 
		LevelGap >= 10 ->
			[30,{100,300}];
		LevelGap >= 5 ->
			[10,{100,300}];
		true ->
			[1,{1,15}]
	end,
	Rate2 =
		if LevelGap >=5 andalso FirstCount >=2 -> 0;
		   true -> Rate
		end,
	random_gift_award(Rate2,Min,Max).
	
random_gift_award(Rate,Min,Max)->
	Random = random:uniform(100),
	case Random =< Rate of
		true ->
			random:uniform(Max - Min+1) +Min-1;
		false ->
			0
	end.

do_exp_lottery(Player, _Idx) ->
	case resource_api:check_start_server_same_day() of
		true ->
			?error;
		false ->
			case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, ?CONST_GOODS_GOODS_ID_RES_EXPLUCK, 1) of
				{?ok, Bag2, _, BagPacket} ->
					Info = Player#player.info,
					OldExp = resource_serv:read_exp(),
					{Nth,Exp} = calc_exp_lottery_award(Info#info.lv),
					{?ok, Player2} = player_api:exp(Player, Exp),
					NewExp = OldExp - Exp,
					PoolPacket = resource_api:msg_sc_pool(3,NewExp),
					WinPacket1 = resource_api:msg_sc_award(3, Exp),
					misc_packet:send(Player2#player.user_id, <<BagPacket/binary, PoolPacket/binary,WinPacket1/binary>>),
					if
						Nth =< 2 ->
							WinPacket = resource_api:msg_sc_winning(Player2#player.user_id, Info#info.user_name, Exp, 3),
							misc_app:broadcast_world_2(WinPacket),
							resource_serv:win_exp_cast(Player2#player.user_id, Info#info.user_name, Exp),
							TipPacket = message_api:msg_notice(?TIP_RESOURCE_GET_EXP_AWARD, [{Player2#player.user_id, Info#info.user_name}], [], 
															   [{?TIP_SYS_COMM, misc:to_list(Exp)},
																{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_RESOURCE_GET_AWARD)}]),
							misc_app:broadcast_world_2(TipPacket),
							BigAwardPacket = resource_api:msg_sc_big_award(Player#player.user_id, Info#info.user_name, Exp,3),
							resource_serv:put_big_award_cast({Player#player.user_id, Info#info.user_name, Exp,3}),
							misc_app:broadcast_world_2(BigAwardPacket);
						true ->
							nil
					end,
					admin_log_api:log_goods(Player2#player.user_id, 0, ?CONST_COST_LOTTERY_DO_LOTTERY, ?CONST_GOODS_GOODS_ID_RES_EXPLUCK, 1, misc:seconds()),
					Player2#player{bag = Bag2};
				_ ->
					?error
			end
	end.

calc_exp_lottery_award(Lv) ->
	Random = misc_random:random(100),
	case ets:tab2list(?CONST_ETS_RANK_AVG_LV) of
		[{AvgLv}] ->
			D = AvgLv - Lv,
			if D >= 10 andalso Random =< 30->
				   RandomRate = misc_random:random(80, 120),
				   {1,misc:round(5000 * (0.4+Lv*0.6) * (RandomRate / 100))};
			   D>=5 andalso Random =<10 ->
				   RandomRate = misc_random:random(80, 120),
				   {2,misc:round(5000 * (0.4+Lv*0.6) * (RandomRate / 100))};
			   true ->
				   {3,misc_random:random(100,500)}
			end;
		_ ->
			{3,misc_random:random(100,500)}
	end.			   

get_big_award_info(Player) ->
	resource_serv:get_big_award_cast(Player#player.user_id).