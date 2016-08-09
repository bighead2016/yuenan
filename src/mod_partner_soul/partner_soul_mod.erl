%% Author: Administrator
%% Created: 2014-2-24
%% Description: TODO: Add description to partner_soul_mod
-module(partner_soul_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([
		 get_partner_soul_info/2,
		 upgrade_partner_soul/2,
		 upgrade_partner_soul_star/2,
		 inherit_partner_soul/3,
		 get_partner_soul_attr/3,
		 update_partner_star/2]).
-export([get_init_skill_id/1]).


update_partner_star(UserId,Star) ->
	case player_mod:read_player(UserId) of
			{?ok, ?null} -> void;
			{?ok, Player} -> 
				PartnerSoul		= Player#player.partner_soul,
				% PartnerStarLv	= PartnerSoul#partner_soul.star_lv,
				player_mod:write_player(Player#player{partner_soul = PartnerSoul#partner_soul{star_lv = Star,skill_lv = ((Star + 1) div 10)}},3)
	end.


%%
%% API Functions
%%
%%-------------------------------------------------------------------------------------------------
%% 请求将魂信息
%%-------------------------------------------------------------------------------------------------
get_partner_soul_info(Player, 0) ->
	PartnerSoul		= Player#player.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	PartnerSoulExp  = PartnerSoul#partner_soul.exp,
	PartnerStarLv	= PartnerSoul#partner_soul.star_lv,
	Packet			= partner_soul_api:msg_sc_partner_soul_info(0, PartnerSoulLv, PartnerSoulExp, PartnerStarLv),
	misc_packet:send(Player#player.net_pid, Packet);
get_partner_soul_info(Player, PartnerId) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} -> 
			PartnerSoul		= PartnerInfo#partner.partner_soul,
			PartnerSoulLv	= PartnerSoul#partner_soul.lv,
			PartnerSoulExp  = PartnerSoul#partner_soul.exp,
			PartnerStarLv	= PartnerSoul#partner_soul.star_lv,
			Packet			= partner_soul_api:msg_sc_partner_soul_info(PartnerId, PartnerSoulLv, PartnerSoulExp, PartnerStarLv),
			misc_packet:send(Player#player.net_pid, Packet);
		{?error, ErrorCode} -> 
			TipPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 武将将魂升级
%%-------------------------------------------------------------------------------------------------
upgrade_partner_soul(Player, 0) ->                               %% 将魂升级
	SysId			= Player#player.sys_rank,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	Pro				= Info#info.pro,
	RankId			= data_guide:get_task_rank(?CONST_MODULE_JIANGHUN),
	PartnerSoul		= Player#player.partner_soul,
%% 	io:format("~n PartnerSoul=~p", [PartnerSoul]),
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	PartnerSoulExp  = PartnerSoul#partner_soul.exp,
	try
		?ok				= check_is_open(SysId, RankId),				
		?ok				= check_partner_soul_lv(Lv, PartnerSoulLv, PartnerSoulExp, Pro),
		{?ok, Player1} 	= check_cost_goods(Player),
		{?ok, Player2, SoulLv1, SoulExp1} = upgrade_partner_soul_ext(Player1),
		Packet		   	= partner_soul_api:msg_sc_upgrade_soul(0, SoulLv1, SoulExp1),
		TipPacket	   	= case SoulLv1 =/= PartnerSoulLv of
							  ?true  -> message_api:msg_notice(?TIP_PARTNER_SOUL_LV_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulLv1)}]);
							  ?false -> <<>>
						  end,
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, Player2}
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误	
	end;
upgrade_partner_soul(Player, PartnerId) ->
	try
		{?ok, PartnerInfo} 	= check_partner_exsit(Player, PartnerId),
		{?ok, Player1}		= check_partner_soul(Player, PartnerInfo),
		PartnerSoul			= PartnerInfo#partner.partner_soul,
		PartnerSoulLv		= PartnerSoul#partner_soul.lv,
		{?ok, Player2, SoulLv1, SoulExp1} = upgrade_partner_soul_ext1(Player1, PartnerInfo),
		Packet		   		= partner_soul_api:msg_sc_upgrade_soul(0, SoulLv1, SoulExp1),
		TipPacket	   		= case SoulLv1 =/= PartnerSoulLv of
								  ?true  -> message_api:msg_notice(?TIP_PARTNER_SOUL_LV_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulLv1)}]);
								  ?false -> <<>>
							  end,
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, Player2}
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误																			
	end.

%% 检查武将时都存在
check_partner_exsit(Player, PartnerId) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} -> {?ok, PartnerInfo};
		{?error, ErrorCode} -> throw({?error, ErrorCode})
	end.

%% 检查是否能升级
check_partner_soul(Player, PartnerInfo) ->
	Lv				= (Player#player.info)#info.lv,
	SysId			= Player#player.sys_rank,
	RankId			= data_guide:get_task_rank(?CONST_MODULE_JIANGHUN),
	Pro				= PartnerInfo#partner.pro,
	PartnerSoul		= PartnerInfo#partner.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	PartnerSoulExp  = PartnerSoul#partner_soul.exp,
	?ok 			= check_is_open(SysId, RankId),
	?ok				= check_partner_soul_lv(Lv, PartnerSoulLv, PartnerSoulExp, Pro),
	{?ok, Player1}	= check_cost_goods(Player),
	{?ok, Player1}.

%% 检查是否开放将魂(根据任务开放)
check_is_open(SysId, RnakId) when SysId >= RnakId -> ?ok;			             				
check_is_open(_SysId, _RankId) -> throw({?error, ?TIP_PARTNER_SOUL_NOT_OPEN}).

%% 检查将魂等级是否超过人物等级
check_partner_soul_lv(Lv, PartnerSoulLv, _PartnerSoulExp, _Pro) when PartnerSoulLv < Lv -> ?ok;
check_partner_soul_lv(Lv, PartnerSoulLv, PartnerSoulExp, Pro) when PartnerSoulLv =:= Lv -> 
	case data_partner_soul:get_partner_soul({PartnerSoulLv, Pro}) of				
		#rec_partner_soul{exp = NeedExp} when  PartnerSoulExp < NeedExp -> ?ok;
		_ -> throw({?error, ?TIP_PARTNER_SOUL_LV_MAX})
	end;
check_partner_soul_lv(_Lv, _PartnerSoulLv, _PartnerSoulExp, _Pro) -> throw({?error, ?TIP_PARTNER_SOUL_LV_MAX}).

%% 检查消耗物品
check_cost_goods(Player) ->
	UserId		= Player#player.user_id,
	Bag			= Player#player.bag,
	GoodsId		= ?CONST_PARTNER_SOUL_WARE,																
	case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, 1) of
		{?ok, Container2, _GoodsList, Packet1} ->
			 misc_packet:send(UserId, Packet1),
             Player2 = Player#player{bag = Container2},
			 {?ok, Player2};
		{?error, _ErrorCode} ->				%% 魂器不足
			throw({?error, ?TIP_PARTNER_SOUL_WARE_NOT_ENOUGH})
	end.

%% 主角升级将魂后的处理
upgrade_partner_soul_ext(Player) ->
	Info			= Player#player.info,
	Career			= Info#info.pro,
	PartnerSoul		= Player#player.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	PartnerSoulExp  = PartnerSoul#partner_soul.exp,
	?MSG_DEBUG("~n PartnerSoulLv=~p, Career=~p", [PartnerSoulLv, Career]),
	case data_partner_soul:get_partner_soul({PartnerSoulLv + 1, Career}) of
		#rec_partner_soul{exp = NeedExp} when PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP >= NeedExp ->  %% 升级 经验清0
			LeftExp			= (PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP) - NeedExp,
			NewPartnerSoul 	= case PartnerSoulLv + 1 of
								  10 ->
									  SkillId			= get_init_skill_id(Career),
									  PartnerSoul#partner_soul{lv = PartnerSoulLv + 1, exp = LeftExp,
																 skill_id = SkillId};
								  _ ->
									  PartnerSoul#partner_soul{lv = PartnerSoulLv + 1, exp = LeftExp}
							  end,
			Player1  		= Player#player{partner_soul = NewPartnerSoul},
            Player2  		= player_attr_api:refresh_attr_partner_soul(Player1),
			{?ok, Player2, PartnerSoulLv + 1, LeftExp};
		 #rec_partner_soul{exp = NeedExp} when PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP < NeedExp ->	%%没升级 加经验
			NewPartnerSoul  = PartnerSoul#partner_soul{exp = PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP},
			Player1  		= Player#player{partner_soul = NewPartnerSoul},
			{?ok, Player1, PartnerSoulLv, PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP};
		_ ->
			?MSG_DEBUG("~n11111111111111111111111111111111111", []),
			{?ok, Player,PartnerSoulLv, PartnerSoulExp}
	end.

%% 武将升级将魂后的处理
upgrade_partner_soul_ext1(Player, PartnerInfo) ->
	Pro				= PartnerInfo#partner.pro,
	PartnerSoul		= PartnerInfo#partner.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	PartnerSoulExp  = PartnerSoul#partner_soul.exp,
	case data_partner_soul:get_partner_soul({PartnerSoulLv + 1, Pro}) of
		#rec_partner_soul{exp = NeedExp} when PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP >= NeedExp ->  %% 升级 经验清0
			LeftExp			= (PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP) - NeedExp,
			NewPartnerInfo  = case PartnerSoulLv + 1 of
								  10 ->
									  SkillId			= get_init_skill_id(Pro),
									  NewPartnerSoul 	= PartnerSoul#partner_soul{lv = PartnerSoulLv + 1, exp = LeftExp, 
																				   skill_id = SkillId},
									  PartnerInfo#partner{partner_soul = NewPartnerSoul};
								  _ ->
									  NewPartnerSoul 	= PartnerSoul#partner_soul{lv = PartnerSoulLv + 1, exp = LeftExp},
									  PartnerInfo#partner{partner_soul = NewPartnerSoul}
							  end,
			Player1			= partner_mod:update_partner(Player, NewPartnerInfo),
            Player2  		= partner_api:refresh_attr_partner_soul(Player1),
			{?ok, Player2, PartnerSoulLv + 1, LeftExp};
		 #rec_partner_soul{exp = NeedExp} when PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP < NeedExp ->	%%没升级 加经验
			NewPartnerSoul  = PartnerSoul#partner_soul{exp = PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP},
			?MSG_DEBUG("~n11111111111111111111111111111111111", []),
			NewPartnerInfo  = PartnerInfo#partner{partner_soul = NewPartnerSoul},
			Player1			= partner_mod:update_partner(Player, NewPartnerInfo),
			{?ok, Player1, PartnerSoulLv, PartnerSoulExp + ?CONST_PARTNER_SOUL_EXP};
		_ ->
			?MSG_DEBUG("~n11111111111111111111111111111111111", []),
			{?ok, Player, PartnerSoulLv, PartnerSoulExp}
	end.

%%-------------------------------------------------------------------------------------------------
%% 将魂星级升级
%%-------------------------------------------------------------------------------------------------
upgrade_partner_soul_star(Player, 0) ->
	PartnerSoul		= Player#player.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	SoulStarLv		= PartnerSoul#partner_soul.star_lv,
	SkillLv			= PartnerSoul#partner_soul.skill_lv,
	try
		?ok				= check_star_is_open(PartnerSoulLv),
		?ok				= check_star_lv_max(SoulStarLv),
		{?ok, Player1} 	= check_cost_star_stone(Player, SoulStarLv),
		{?ok, Player2}  = upgrade_partner_star_ext(Player1),
		SoulStarLv1		= SoulStarLv + 1,
		map_api:change_star_lv(Player2),
		Packet			= partner_soul_api:msg_sc_upgrade_star(0, SoulStarLv1),
		SkillLv1		= SoulStarLv1 div 10,
		TipPacket		= case SkillLv =/= SkillLv1 of
							  ?true -> 
								  TpPacket1 = message_api:msg_notice(?TIP_PARTNER_SOUL_STAR_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulStarLv1)}]),
								  TpPacket2	= message_api:msg_notice(?TIP_PARTNER_SOUL_SKILL_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SkillLv1)}]),
								  <<TpPacket1/binary, TpPacket2/binary>>;
							  ?false ->
								  message_api:msg_notice(?TIP_PARTNER_SOUL_STAR_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulStarLv1)}])
						  end,
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, Player2}
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误																			
	end;
upgrade_partner_soul_star(Player, PartnerId) ->
	try
		{?ok, PartnerInfo} 	= check_partner_exsit(Player, PartnerId),
		PartnerSoul			= PartnerInfo#partner.partner_soul,
		SoulStarLv			= PartnerSoul#partner_soul.star_lv,
		SkillLv				= PartnerSoul#partner_soul.skill_lv,
		{?ok, Player1}		= check_partner_soul_star(Player, PartnerInfo),
		{?ok, Player2}		= upgrade_partner_star_ext1(Player1, PartnerInfo),
		SoulStarLv1			= SoulStarLv + 1,
		SkillLv1			= SoulStarLv1 div 10,
		TipPacket			= case SkillLv =/= SkillLv1 of
								  ?true -> 
									  TpPacket1 = message_api:msg_notice(?TIP_PARTNER_SOUL_STAR_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulStarLv1)}]),
									  TpPacket2	= message_api:msg_notice(?TIP_PARTNER_SOUL_SKILL_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SkillLv1)}]),
									  <<TpPacket1/binary, TpPacket2/binary>>;
								  ?false ->
									  message_api:msg_notice(?TIP_PARTNER_SOUL_STAR_NOTICE, [{?TIP_SYS_COMM, misc:to_list(SoulStarLv1)}])
							  end,
		Packet				= partner_soul_api:msg_sc_upgrade_star(PartnerId, SoulStarLv1),
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, Player2}
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误																			
	end.

check_partner_soul_star(Player, PartnerInfo) ->
	PartnerSoul		= PartnerInfo#partner.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
	SoulStarLv		= PartnerSoul#partner_soul.star_lv,
	?ok				= check_star_is_open(PartnerSoulLv),
	?ok				= check_star_lv_max(SoulStarLv),
	{?ok, Player1}	= check_cost_star_stone(Player, SoulStarLv),
	{?ok, Player1}.

%% 检查将魂星级是否开启
check_star_is_open(Lv) when Lv >= ?CONST_PARTNER_SOUL_STAR_OPEN_LEVEL -> ?ok;
check_star_is_open(_Lv) -> throw({?error, ?TIP_PARTNER_SOUL_STAR_NOT_OPEN}).

%% 检查将魂星级是否达到最大级
check_star_lv_max(Lv) when Lv < ?CONST_PARTNER_SOUL_STAR_MAX -> ?ok;
check_star_lv_max(_Lv) -> throw({?error, ?TIP_PARTNER_SOUL_STAR_LV_MAX}).

%% 检查将星石是否足够
check_cost_star_stone(Player, StarLv) ->
	UserId			= Player#player.user_id,
	Bag				= Player#player.bag,
	case data_partner_soul:get_partner_star(StarLv + 1) of
		#rec_partner_star{goods = Count} ->
			GoodsId		= ?CONST_PARTNER_SOUL_STONE,									
			case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, Count) of
				{?ok, Container2, _GoodsList, Packet1} ->
					misc_packet:send(UserId, Packet1),
					Player2 = Player#player{bag = Container2},
					{?ok, Player2};
				{?error, _ErrorCode} ->
					throw({?error, ?TIP_PARTNER_SOUL_STONE_NOT_ENOUGH})
			end;
		_ ->
			throw({?error, ?TIP_COMMON_BAD_ARG})
	end.

%% 主角升级将魂星级后的处理
upgrade_partner_star_ext(Player) ->
	PartnerSoul			= Player#player.partner_soul,
	SoulStarLv			= PartnerSoul#partner_soul.star_lv,
	SkillLv				= (SoulStarLv + 1) div 10,
	NewPartnerSoul		= PartnerSoul#partner_soul{star_lv = SoulStarLv + 1, skill_lv = SkillLv},
	Player1				= Player#player{partner_soul = NewPartnerSoul},
	Player2				= player_attr_api:refresh_attr_partner_star(Player1),
	{?ok, Player2}.
%% 武将升级将魂星级后的处理
upgrade_partner_star_ext1(Player, PartnerInfo) ->
	PartnerSoul			= PartnerInfo#partner.partner_soul,
	SoulStarLv			= PartnerSoul#partner_soul.star_lv,
	SkillLv				= (SoulStarLv + 1) div 10,							%% 更新将星技等级和刷新属性
	NewPartnerSoul		= PartnerSoul#partner_soul{star_lv = SoulStarLv + 1, skill_lv = SkillLv},
	NewPartnerInfo		= PartnerInfo#partner{partner_soul =  NewPartnerSoul},
	
	Player2 			= partner_mod:update_partner(Player, NewPartnerInfo),
	Player3  			= partner_api:refresh_attr_partner_star(Player2),
	{?ok, Player3}.
	

%%-------------------------------------------------------------------------------------------------
%% 继承将魂等级和将魂星级
%%-------------------------------------------------------------------------------------------------
inherit_partner_soul(Player, ToPartnerId, FromPartnerId) ->
	UserId			= Player#player.user_id,
	try
		?ok						= check_from_partner(UserId, FromPartnerId),
		?ok						= check_to_partner(UserId, ToPartnerId),
		{?ok, ToPartnerInfo}	= check_partner_exsit(Player, ToPartnerId),
		{?ok, FromPartnerInfo}  = check_partner_exsit(Player, FromPartnerId),
		?ok						= check_inherit_self(ToPartnerId, FromPartnerId),
		?ok						= check_inherit_partner_soul(ToPartnerInfo, FromPartnerInfo),
		?ok						= check_inherit_cost_coin(Player, FromPartnerInfo),
		{?ok, Player1}			= inherit_partner_soul_ext(Player, ToPartnerInfo, FromPartnerInfo),
		Packet					= partner_soul_api:msg_sc_inherit(ToPartnerId, FromPartnerId),
		misc_packet:send(Player#player.net_pid, Packet),
		{?ok, Player1}
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误																			
	end.

%% 检查是否主角继承
check_to_partner(UserId, ToPartnerId) when UserId =:= ToPartnerId -> throw({?error, ?TIP_PARTNER_SOUL_NOT_INHERIT_HERO});
check_to_partner(_UserId, _ToPartnerId) -> ?ok.

check_from_partner(UserId, FromPartnerId) when UserId =:= FromPartnerId -> throw({?error, ?TIP_PARTNER_SOUL_NOT_INHERIT_HERO});
check_from_partner(_UserId, _FromPartnerId) -> ?ok.

%% 检查是否继承给自己
check_inherit_self(ToPartnerId, FromPartnerId) when ToPartnerId =:= FromPartnerId -> throw({?error, ?TIP_PARTNER_SOUL_NOT_INHERIT_SELF});
check_inherit_self(_ToPartnerId, _FromPartnerId) -> ?ok.

		
%% 检查是否能继承将魂
check_inherit_partner_soul(ToPartnerInfo, FromPartnerInfo) ->
	ToPartnerSoul			= ToPartnerInfo#partner.partner_soul,
	FromPartnerSoul			= FromPartnerInfo#partner.partner_soul,
%% 	?MSG_DEBUG("~n ################################ToPartnerSoul, FromPartnerSoul=~p", [{ToPartnerSoul, FromPartnerSoul}]),
	ToSoulLv				= ToPartnerSoul#partner_soul.lv,
	FromSoulLv				= FromPartnerSoul#partner_soul.lv,
	ToSoulStarLv			= ToPartnerSoul#partner_soul.star_lv,
	FromSoulStarLv			= FromPartnerSoul#partner_soul.star_lv,
	Flag1					= FromSoulLv > ToSoulLv,
	Flag2					= FromSoulStarLv > ToSoulStarLv,
	case Flag1 of
		?false -> throw({?error, ?TIP_PARTNER_SOUL_LV_LOW});
		?true  ->
			case Flag2 of
				?false -> throw({?error, ?TIP_PARTNER_SOUL_STAR_LV_LOW});
				?true -> ?ok
			end
	end.

%% 检查铜钱是否足够
check_inherit_cost_coin(Player, FromPartnerInfo) ->
	UserId					= Player#player.user_id,
	FromPartnerSoul			= FromPartnerInfo#partner.partner_soul,
	FromSoulLv				= FromPartnerSoul#partner_soul.lv,
	FromSoulStarLv			= FromPartnerSoul#partner_soul.star_lv,
	Lv						= case FromSoulStarLv >= FromSoulLv of
								  ?true  -> FromSoulStarLv;
								  ?false -> FromSoulLv
							  end,
	Cost					= Lv * 2000,												%% TODO 按公式计算
	case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Cost, 0) of
		?ok -> ?ok;
		{?error, _ErrorCode} -> {?error, ?TIP_PARTNER_SOUL_COIN_NOT_ENOUGH}
	end.
	

%% 继承后的处理
inherit_partner_soul_ext(Player, ToPartnerInfo, FromPartnerInfo) -> 
	ToPartnerSoul			= ToPartnerInfo#partner.partner_soul,
	FromPartnerSoul			= FromPartnerInfo#partner.partner_soul,
	FromSoulLv				= FromPartnerSoul#partner_soul.lv,
	FromSoulStarLv			= FromPartnerSoul#partner_soul.star_lv,
	FromSoulSkillLv			= FromPartnerSoul#partner_soul.skill_lv,
	NewToPartnerSoul		= ToPartnerSoul#partner_soul{	
														 lv = FromSoulLv,
														 star_lv = FromSoulStarLv,
														 skill_lv = FromSoulSkillLv
														},
	
	NewFromPartnerSoul 		= FromPartnerSoul#partner_soul{ 		
														   lv = 0, 							%% 将魂等级 
														   star_lv = 0,						%% 将魂星级
														   skill_lv = 0						%% 将魂技等级
														  },
	
	NewFromPartnerInfo		= FromPartnerInfo#partner{partner_soul =  NewFromPartnerSoul},
	NewToPartnerInfo		= ToPartnerInfo#partner{partner_soul = NewToPartnerSoul},
	
	Player1					= partner_mod:update_partner(Player, NewFromPartnerInfo),
	Player2					= partner_mod:update_partner(Player1, NewToPartnerInfo),
	
	Player3					= partner_api:refresh_attr_partner_soul(Player2),
	Player4					= partner_api:refresh_attr_partner_star(Player3),
	
	
%% 	Player3 				= partner_api:refresh_attr_partner_soul(Player2, NewToPartnerInfo),
%% 	Player4					= partner_api:refresh_attr_partner_soul(Player3, NewFromPartnerInfo), 
%% 	Player5					= partner_api:refresh_attr_partner_soul_star(Player4, NewToPartnerInfo),
%% 	Player6					= partner_api:refresh_attr_partner_soul_star(Player5, NewFromPartnerInfo),
	{?ok, Player4}.

%%-------------------------------------------------------------------------------------------------
%% 请求显示将魂属性
%%-------------------------------------------------------------------------------------------------
get_partner_soul_attr(Player, OtherId, PartnerId) ->
	UserId	 		= Player#player.user_id,
	PacketData		= if OtherId =:= 0 orelse OtherId =:= UserId ->
							 partner_soul_attr_ext(Player, PartnerId);
					 ?true ->	%% 如果不是自己
						 case player_api:get_player_first(OtherId) of
								{?ok, ?null, _IsOnline} ->
									<<>>;
								{?ok, OtherPlayer, _IsOnline} ->
									partner_soul_attr_ext(OtherPlayer, PartnerId)
						 end
				  end,
	misc_packet:send(Player#player.net_pid, PacketData).

partner_soul_attr_ext(Player, 0) ->
	UserId				= Player#player.user_id,
	SoulAttr			= partner_soul_api:refresh_attr_partner_soul_player(Player),
	StarAttr			= partner_soul_api:refresh_attr_partner_star_player(Player),
	AttrData			= player_attr_api:attr_plus(SoulAttr, StarAttr),
	SoulAttrDatas		= player_api:msg_attr(AttrData),
	SoulPower			= player_attr_api:caculate_power(SoulAttr),
	StarPower			= player_attr_api:caculate_power(StarAttr),
	PowerData			= SoulPower + StarPower,
	partner_soul_api:msg_sc_soul_attr(UserId, 0, PowerData, SoulAttrDatas);
partner_soul_attr_ext(Player, PartnerId) ->
	UserId				= Player#player.user_id,
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, Partner} ->
			Pro					= Partner#partner.pro,
			SoulAttr			= partner_soul_api:refresh_attr_soul_partner(Pro, Partner),
			StarAttr			= partner_soul_api:refresh_attr_star_partner(Pro, Partner),
			AttrData			= player_attr_api:attr_plus(SoulAttr, StarAttr),
			SoulAttrDatas		= player_api:msg_attr(AttrData),
			
			SoulPower			= player_attr_api:caculate_power(SoulAttr),
			StarPower			= player_attr_api:caculate_power(StarAttr),
			PowerData			= SoulPower + StarPower,
			partner_soul_api:msg_sc_soul_attr(UserId, PartnerId, PowerData, SoulAttrDatas);
		_ ->
			<<>>
	end.
%%
%% Local Functions
%%
%% 根据职业获取初始技能
get_init_skill_id(?CONST_SYS_PRO_XZ) -> ?CONST_PARTNER_SOUL_XZ;
get_init_skill_id(?CONST_SYS_PRO_FJ) -> ?CONST_PARTNER_SOUL_FJ;
get_init_skill_id(?CONST_SYS_PRO_TJ) -> ?CONST_PARTNER_SOUL_TJ;
get_init_skill_id(?CONST_SYS_PRO_GM) -> ?CONST_PARTNER_SOUL_GM;
get_init_skill_id(?CONST_SYS_PRO_KX) -> ?CONST_PARTNER_SOUL_KX;
get_init_skill_id(?CONST_SYS_PRO_JH) -> ?CONST_PARTNER_SOUL_JH;
get_init_skill_id(_) -> 0.
