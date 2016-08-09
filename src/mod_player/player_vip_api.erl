%% Author: zero
%% Created: 2012-11-2
%% Description: TODO: Add description to player_vip_api
-module(player_vip_api).

%%
%% Include files
%%
-include("../../include/record.base.data.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.player.hrl").
-include("tencent.hrl").
%%
%% Exported Functions
%%
-export([zero_oclock_refresh/2, login_packet/2, refresh_vip/1, refresh_vip/2, get_gift_vip/2, get_daily_reward/1]).
-export([get_sp_max/1,                  can_commerce_buy_rob_times/1,
         get_friends_max/1,             can_commerce_run/1,
         get_grab_times/1,              can_fast_raid/1,
         get_offline_practice_times/1,  can_furnace_immediately/1,
         get_online_practice_add/1,     can_commerce_2_red/1,
         get_online_practice_time/1,    can_get_flag_reborn/1,
         can_guild_party_auto_join/1,
         can_auto_trans_under_yellow/1, can_home_clear_earth_cd/1,
         can_boss_auto_fight/1,         can_grab_chest_upgrade/1,
         can_boss_encourage/1,          can_home_one_key_fresh/1,
         can_boss_use_scapegoat/1,      can_home_refresh_quality/1,
         can_camp_use_scapegoat/1,      can_mind_one_key/1,
         can_over_fight_auto_sigh/1,    can_mcopy_get_again/1,
         can_commerce_build_market/1,   can_over_fight_super_fight/1,
         can_ability_one_key/1,         can_quick_finish_task/1,
         can_quick_raid/1,              can_raid_4_free/1,
         can_single_arena_clear_cd/1,   can_tower_sweep/1,
         get_elite_copy_reset_times/1,  get_elite_copy_times/1,
         get_exp_bottle_times/1,        get_furnace_queues/1,
         get_grab_count/1,              get_home_girl_max/1,
         get_home_ext_grid_count/1,    get_invasion_ext_buy_times/1,
         get_look_for_buyable_times/1,  get_mind_max_lv/1,
         get_pray_lv/1,                 get_remote_bag_cost/1,
         get_remote_shop_cost/1,        get_single_arena_buyable_times/1,
         get_spring_add/1,              get_tower_but_ext_times/1,
         get_tower_reset_times/1,       get_train_max_lv/1,
         is_boss_no_cd/1,               is_furnace_no_cd/1,
         is_tower_sweep_free/1,      is_vip_mall_opened/1,
         read/1,                        can_boss_reborn/1,
		 can_mind_extend_bag/1,         is_elite_reward/1,
         can_onkey_bless/1,				can_onekey_horse_up/1,			
		 can_cash_recruit/1,			get_party_increace/1,
		 get_spring_auto_flag/1,		get_invasion_auto_flag/1,
		 get_fast_train/1,              get_sp_limit/1,
         is_free_skip/1,                can_one_key_train_horse/1,
		 get_chess_buy_dice/1,			get_world_auto_flag/1,
		 get_follow/1,					get_refit_sign_times/1,
		 is_ok_compose_stone/1,			is_no_arena_cd/1
         ]).

%%
%% API Functions
%%
%% 零点刷新
zero_oclock_refresh(Player, FlagNotice) ->
	Info	= Player#player.info,
	Vip		= Info#info.vip,
	Date	= Vip#vip.date,
	case misc:date_num() of
		Date -> {?ok, Player};
		Today ->
			Vip2		= Vip#vip{date = Today, daily = ?false},
			Info2		= Info#info{vip = Vip2},
			case FlagNotice of
				?CONST_SYS_TRUE ->
					Packet1506	= player_api:msg_player_sc_vip_daily_info(Vip2),
					misc_packet:send(Player#player.net_pid, Packet1506);
				?CONST_SYS_FALSE -> ?ok
			end,
			{?ok, Player#player{info = Info2}}
	end.

login_packet(Player, AccPacket) ->
	{?ok, Player2}		= zero_oclock_refresh(Player, ?CONST_SYS_FALSE),
	case player_money_api:read_money(Player2#player.user_id) of
		{?ok, #money{cash_sum = CashSum}} ->
			Vip			= (Player2#player.info)#info.vip,
			Packet1026	= player_api:msg_player_sc_vip_info(CashSum, Vip),
			Packet1506	= player_api:msg_player_sc_vip_daily_info(Vip),
			{Player2, <<AccPacket/binary, Packet1026/binary, Packet1506/binary>>};
		_ -> {Player2, AccPacket}
	end.

refresh_vip(UserId) when is_number(UserId) ->
	case player_api:check_online(UserId) of
		?true -> player_api:process_send(UserId, ?MODULE, refresh_vip, ?null);
		?false -> ?ok
	end.
refresh_vip(Player, _) when is_record(Player, player) ->
	UserId	= Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_TENCENT_INFO, Player#player.user_id) of
        ?null ->
            IsYearVip = 0,
            VipLevel = 0;
        TencentInfo ->
            IsYearVip = TencentInfo#ets_tencent_info.is_year_vip,
            VipLevel = TencentInfo#ets_tencent_info.vip_lv
    end,
    case VipLevel >= 0 of
    	true ->
			case player_money_api:read_money(UserId) of
				{?ok, #money{cash_sum = CashSum}} ->
					Info			= Player#player.info,
					Vip				= player_api:get_vip_lv(Info),
					VipLv			= data_player:select_vip(CashSum),
					RecVipDeposit	= data_player:get_vip_deposit(VipLv),
					VipNew			= RecVipDeposit#rec_vip_deposit.vip,
					if
						Vip >= VipNew -> {?ok, Player};
						?true ->% 祝贺[0]VIP等级提升到[10]级，成为尊贵VIP玩家，尊享VIP特权！
							Packet	= message_api:msg_notice(?TIP_PLAYER_VIP_NOTICE,
															 [{UserId, Info#info.user_name}], [],
															 [{?TIP_SYS_COMM, misc:to_list(VipNew)}]),
							misc_app:broadcast_world(Packet),
							player_api:vip(Player, VipNew)
					end;
				{?error, _ErrorCode} -> {?ok, Player}
			end;
		false ->
			{?ok, Player}
	end.


get_gift_vip(Player, VipClient) ->
	Info	= Player#player.info,
	VipLv	= player_api:get_vip_lv(Info),
	if
		VipClient =< VipLv ->
			case lists:member(VipClient, (Info#info.vip)#vip.gift) of
				?true -> {?error, ?TIP_PLAYER_ALREADY_GET_GIFT};% 已领取
				?false -> get_gift_vip2(Player, VipClient)
			end;
		?true -> {?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}% VIP等级不足
	end.

get_gift_vip2(Player, VipClient) ->
	RecVipDeposit	= read_deposit(VipClient),
	case get_gift_vip_goods(Player, RecVipDeposit#rec_vip_deposit.gift_vip, ?CONST_COST_PLAYER_VIP) of
		{?ok, Player2, PacketBag} ->
			Info	= Player2#player.info,
			Vip		= Info#info.vip,
			Vip2	= Vip#vip{gift = [VipClient|Vip#vip.gift]},
			Player3	= Player2#player{info = Info#info{vip = Vip2}},
			get_gift_vip_broadcast(Player3, VipClient),
			{?ok, Player3, PacketBag};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

get_gift_vip_broadcast(#player{user_id = UserId, info = #info{user_name = UserName}}, VipClient) ->
	case get_gift_vip_notice_packet(VipClient) of
		MsgId when is_number(MsgId) ->
			Packet	= message_api:msg_notice(MsgId, [{UserId, UserName}], [], [{?TIP_SYS_VIP, misc:to_list(VipClient)}]),
			misc_app:broadcast_world(Packet);
		_ -> ?ok
	end.

get_gift_vip_notice_packet(_) -> ?TIP_PLAYER_VIP_GIFT_NOTICE_1.
	
get_gift_vip_goods(Player, [], _Point) -> {?ok, Player, <<>>};
get_gift_vip_goods(Player = #player{info = #info{pro = Pro, sex = Sex}}, GoodsData, Point) ->
	Fun			= fun({GoodsId, Bind, Count}, AccGoods) ->
						  GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
						  GoodsTemp ++ AccGoods;
					 ({?CONST_SYS_PRO_NULL, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) ->
						  GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
						  GoodsTemp ++ AccGoods;
					 ({ProTmp, SexTmp, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro andalso SexTmp =:= Sex ->
						  GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
						  GoodsTemp ++ AccGoods;
					 ({?CONST_SYS_PRO_NULL, SexTmp, GoodsId, Bind, Count}, AccGoods) when SexTmp =:= Sex ->
						  GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
						  GoodsTemp ++ AccGoods;
					 ({ProTmp, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro ->
						  GoodsTemp	= goods_api:make(GoodsId, Bind, Count),
						  GoodsTemp ++ AccGoods;
					 (_, AccGoods) -> AccGoods
				  end,
	GoodsList	= lists:foldl(Fun, [], GoodsData),
    case ctn_bag_api:put(Player, GoodsList, Point, 1, 1, 0, 0, 0, 1, []) of
		{?ok, Player2, _, PacketBag} ->
			TipPacket		= msg_notice_goods(GoodsList, <<>>),
			{?ok, Player2, <<PacketBag/binary, TipPacket/binary>>};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

msg_notice_goods([Goods|List], Acc) when is_record(Goods, goods) ->
	GoodsName	= Goods#goods.name,
	GoodsNum	= Goods#goods.count,
	Packet		= message_api:msg_notice(?TIP_PLAYER_VIP_GOODS, [{?TIP_SYS_COMM, GoodsName}, {?TIP_SYS_COMM, misc:to_list(GoodsNum)}]),
	NewAcc		= <<Packet/binary, Acc/binary>>,
	msg_notice_goods(List, NewAcc);
msg_notice_goods([], Acc) ->
	Acc.

get_daily_reward(Player) ->
	Info	= Player#player.info,
	Vip		= Info#info.vip,
	case Vip#vip.daily of
		?false ->
			VipLv		= player_api:get_vip_lv(Info),
			VipDeposit	= read_deposit(VipLv),
			Value		= VipDeposit#rec_vip_deposit.reward_daily,
			case player_money_api:plus_money(Player#player.user_id,
											 ?CONST_SYS_CASH_BIND,
											 Value,
											 ?CONST_COST_PLAYER_VIP) of
				?ok ->
					Vip2		= Vip#vip{daily = ?true},
					TipPacket	= message_api:msg_notice(?TIP_PLAYER_VIP_DAILY_AWARD, [{?TIP_SYS_COMM, misc:to_list(Value)}]),
					{?ok, Player#player{info = Info#info{vip = Vip2}}, TipPacket};
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		?true -> {?error, ?TIP_PLAYER_ALREADY_GET_GIFT}% 已领取
	end.









read_deposit(Vip) ->
	data_player:get_vip_deposit(Vip).
read(VipLv)
  when is_number(VipLv) andalso ?CONST_SYS_MIN_VIP_LV =< VipLv andalso VipLv =< ?CONST_SYS_MAX_VIP_LV ->
	data_player:get_player_vip(VipLv);
read(_) ->
    data_player:get_player_vip(0).

%% 购买体力上限
get_sp_max(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg1.

%% 好友上限增加值
get_friends_max(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg2.

%% 收夺次数
get_grab_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg3.

%% 离线修炼倍数
get_offline_practice_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg5.

%% 修炼增益
get_online_practice_add(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg4.

%% 修炼时长
get_online_practice_time(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg6.

%% 温泉增益
get_spring_add(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg7.

%% 远程背包消耗
get_remote_bag_cost(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg8.

%% 远程道具店消耗
get_remote_shop_cost(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg9.

%% 竞技场可购买次数
get_single_arena_buyable_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg10.

%% 寻访名将购买次数
get_look_for_buyable_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg11.

%% 家园额外开放推荐、小黑屋格子
get_home_ext_grid_count(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg12.

%% 破阵可重置次数
get_tower_reset_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg13.

%% 精英副本可重置次数
get_elite_copy_reset_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg14.

%% 经验瓶倍数
get_exp_bottle_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg15.

%% 作坊强化队列数
get_furnace_queues(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg16.

%% 作坊强化免CD
%% 0:有cd;1:无cd
is_furnace_no_cd(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg17.

%% 妖魔破冷却cd
%% 0:有cd;1:无cd
is_boss_no_cd(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg18.

%% 培养等级
%% 1:普通培养
%% 2:高级培养
%% 3:白金培养
%% 4:至尊培养
get_train_max_lv(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg19.

%% 批量收夺
%% get_grab_count(VipLv)	->
%% 	VipLvList	= lists:seq(?CONST_SYS_MIN_VIP_LV, VipLv),
%% 	get_grab_count(VipLvList, []).
%% get_grab_count([VipLv | VipLvList], Acc)	->
%% 	RecVip	= read(VipLv),
%% 	?MSG_DEBUG("get_grab_count:~p",[RecVip]),
%% 	Arg20	= RecVip#rec_vip.arg20,
%% 	NewAcc	= case lists:member(Arg20, Acc) of
%% 				  ?true		->	Acc;
%% 				  ?false	->	Acc ++ [Arg20]
%% 			  end,
%% 	get_grab_count(VipLvList, NewAcc);
%% get_grab_count([], Acc)	->	Acc.
get_grab_count(VipLv)	->
	VipLvList	= lists:seq(?CONST_SYS_MIN_VIP_LV, 10),
	Fun			= fun(Lv) ->
						 ItemVip	= read(Lv),
						 ItemVip#rec_vip.arg20
				  end,
	List		= lists:map(Fun, VipLvList),
	RecVip	= read(VipLv),
	Arg20	= RecVip#rec_vip.arg20,
	FinalList	= misc:del_repeat_list(List),
	?MSG_DEBUG("get_grab_count:~p",[{List, Arg20, FinalList}]),
	get_grab_count(FinalList, Arg20, []).
get_grab_count([Count | CountList], VipCount, Acc)	->
	?MSG_DEBUG("get_grab_count:~p",[VipCount]),
	NewAcc	= case VipCount < Count of
				  ?true		->	Acc;
				  ?false	->	[Count|Acc]
			  end,
	get_grab_count(CountList, VipCount, NewAcc);
get_grab_count([], _VipCount, Acc)	->	lists:reverse(Acc).

%% 破阵占卜开启
is_tower_sweep_free(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg21.

%% 妖魔破自动参战
can_boss_auto_fight(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg22.

%% 巡城
get_pray_lv(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg23.

%% 扫荡加速
can_quick_raid(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg24.

%% 破阵扫荡
can_tower_sweep(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg25.

%% 任务委托功能
can_quick_finish_task(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg26.

%% 家园刷新作物品质
can_home_refresh_quality(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg27.

%% 家园清除种地CD
can_home_clear_earth_cd(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg28.

%% 商路加速功能
can_commerce_run(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg29.

%% 商路购买拦截次数
can_commerce_buy_rob_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg30.

%% 竞技场挑战冷却时间清除
can_single_arena_clear_cd(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg31.

%% 军团夺旗复活
can_get_flag_reborn(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg32.

%% 开启精英副本次数
get_elite_copy_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg33.

%% 跨服战自动报名
can_over_fight_auto_sigh(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg34.

%% 祈天参阅等级
%% 1:普通参阅
%% 2:地级
%% 3:天级
get_mind_max_lv(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg35.

%% 快速扫荡
can_fast_raid(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg36.

%% VIP商城
is_vip_mall_opened(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg37.

%% 奇门一键升阶
can_ability_one_key(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg38.

%% 商路召唤功能 -- 一键刷红
can_commerce_2_red(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg39.

%% 异民族额外购买次数
get_invasion_ext_buy_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg40.

%% 封邑招募侍女数量
get_home_girl_max(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg41.

%% 军团宴会自动参加
can_guild_party_auto_join(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg42.

%% 妖魔破元宝鼓舞
can_boss_encourage(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg43.

%% 收夺宝箱品质提升
can_grab_chest_upgrade(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg44.

%% 祈天一键参阅
can_mind_one_key(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg45.

%% 妖魔破替身娃娃参战
can_boss_use_scapegoat(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg46.

%% 免费扫荡加速
can_raid_4_free(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg47.

%% 家园一键刷新
can_home_one_key_fresh(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg48.

%% 商路建造市场
can_commerce_build_market(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg49.

%% 阵营战替身娃娃参战
can_camp_use_scapegoat(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg50.

%% 作坊立即锻造
can_furnace_immediately(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg51.

%% 破阵元宝额外开启副本次数
get_tower_but_ext_times(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg52.

%% 跨服战越级挑战
can_over_fight_super_fight(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg53.

%% 祈天拾取时自动转化黄色以下心法
can_auto_trans_under_yellow(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg54.

%% 妖魔破浴火重生
can_boss_reborn(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg55.

%% 心法扩展永久背包
can_mind_extend_bag(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg56.

%% 精英副本翻牌次数
is_elite_reward(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg57.

%% 一键祝福开关
can_onkey_bless(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg58.

%% 团队副本额外翻牌
can_mcopy_get_again(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg59.

%% 坐骑一键升级开关 can_onekey_horse_up/1,
can_onekey_horse_up(VipLv) -> 
	RecVip = read(VipLv),
    RecVip#rec_vip.arg60. 

%% 元宝招募武将
can_cash_recruit(VipLv) ->
	RecVip = read(VipLv),
    RecVip#rec_vip.arg61.

%% 军团宴会经验加成(百分比)
get_party_increace(VipLv) ->
	RecVip = read(VipLv),
    RecVip#rec_vip.arg62. 

%% 温泉自动参加
get_spring_auto_flag(VipLv) ->
	RecVip = read(VipLv),
    RecVip#rec_vip.arg63.  

%% 异民族自动参加
get_invasion_auto_flag(VipLv) ->
	RecVip = read(VipLv),
    RecVip#rec_vip.arg64.  

%% 一键培养
get_fast_train(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg65.

%% 一键培养
get_sp_limit(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg66.

%% 一键培养
is_free_skip(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg67.

%% 批量培养坐骑
can_one_key_train_horse(VipLv) ->
    RecVip = read(VipLv),
    RecVip#rec_vip.arg68.

%% 双陆购买次数
get_chess_buy_dice(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg69.

%% 乱天下自动参加
get_world_auto_flag(VipLv) ->
	RecVip	= read(VipLv),
	RecVip#rec_vip.arg70.

%% 是否允许跟随武将
get_follow(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg71.

%% 补签次数
get_refit_sign_times(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg72.

%% 是否允许一键合成宝石
is_ok_compose_stone(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg73.

%% 一骑讨是否永久清除cd
is_no_arena_cd(VipLv) ->
	RecVip = read(VipLv),
	RecVip#rec_vip.arg74.
%%======================================================================================
    
%%
%% Local Functions
%%
