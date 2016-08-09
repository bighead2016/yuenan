%% Author: zero
%% Created: 2012-8-18
%% Description: TODO: Add description to ability_mod
-module(ability_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([create/0, ability_info/1, ability_ext_info/3]).
-export([upgrade/2,money_upgrade/2, refresh_ability_ext/3, get_ability/2]).

%% 创建内功数据
create() ->
	#ability_data{
				  ability               = []      		% 内功 #ability{}
				 }.

%% 内功信息  AbilityData [ability,...]
ability_info(#player{ability = AbilityData,net_pid = Pid}) when is_record(AbilityData, ability_data) ->
	PacketInfo	= ability_api:msg_ability_sc_info(AbilityData#ability_data.ability,?CONST_SYS_FALSE),
	misc_packet:send(Pid, PacketInfo);
ability_info(_) -> ?ok.

get_ability_by_id(AbilityId,Ability) ->
	case lists:keyfind(AbilityId, #ability.ability_id, Ability) of %% 根据内功类型取出数据
		AbilityT when is_record(AbilityT, ability) ->
			{?ok,AbilityT};
		_ -> 
			throw({?error,?TIP_COMMON_BAD_ARG})
	end.

%% 内功八门信息
ability_ext_info(#player{ability = AbilityData,net_pid = Pid}, AbilityId, Step)
  when is_record(AbilityData, ability_data) ->
	try
		{?ok,Ability}	= get_ability_by_id(AbilityId,AbilityData#ability_data.ability),%% 根据内功类型取出数据 
		ExtId			= data_ability:get_ability_ext_id({AbilityId, Step}),			%% 取出第几个八门值 	
		Sum				= ability_api:get_ext_value(Ability#ability.ability_ext), 		%% 八门加成总和
		{?ok,N,Count}	= get_ability_ext_by_id(ExtId,Ability#ability.ability_ext),		%% 剩余次数
		ability_ext_info2(Pid,N,ExtId,Count,AbilityId, Step,Sum)
	catch 
		_:_ -> ?ok
	end;
ability_ext_info(_,_,_) -> ?ok.

ability_ext_info2(Pid,0,_ExtId,Count,AbilityId, Step,Sum) -> %% 无八门值
	Packet 			= ability_api:msg_ability_sc_ext_info(0, 0, Count,AbilityId, Step,Sum,?CONST_SYS_FALSE),
	misc_packet:send(Pid, Packet);
ability_ext_info2(Pid,N,ExtId,Count,AbilityId, Step,Sum) ->
	RecAbilityExt	= data_ability:get_ability_ext(ExtId),
	ExtValue 		= lists:nth(N, RecAbilityExt#rec_ability_ext.value),%% 计算八门增加的值
	Packet 			= ability_api:msg_ability_sc_ext_info(N, ExtValue, Count,AbilityId, Step,Sum,?CONST_SYS_FALSE),
	misc_packet:send(Pid, Packet).

%% 根据Id,取出升级等级和ability
get_ability(AbilityId,Ability) ->
	case lists:keyfind(AbilityId, #ability.ability_id, Ability) of
		?false -> % 学习内功
			Lv			= 1,
			AbilityT 	= #ability{ability_id	= AbilityId,lv = Lv,ability_ext	= []};
		Data -> % 升级内功
			Lv			= Data#ability.lv + 1,
			AbilityT	= Data#ability{lv = Lv}
	end,
	{?ok,AbilityT, Lv}.

%% 检查VIP是否一键升阶
check_one_key(VipLv) -> 
	case player_vip_api:can_ability_one_key(VipLv) of
		?CONST_SYS_TRUE -> ?ok;
		_ ->
			throw({?error,?TIP_COMMON_VIPLEVEL_NOT_ENOUGH})
	end.

%% rec_ability数据
get_rec_ability(AbilityId,Lv) ->
	case data_ability:get_ability({AbilityId, Lv}) of
		?null -> %% 内功不存在
			throw({?error, ?TIP_ABILITY_NOT_EXIST});
		RecAbility ->
			{?ok,RecAbility}
	end.

%% 检查元宝升级
check_money_up_cost(0) ->
	throw({?error, ?TIP_ABILITY_NOT_EXIST});
check_money_up_cost(_) -> ?ok.

%% 检查技能的等级 
check_up_lv(Lv,AbilityLv) when AbilityLv > Lv  ->
	throw({?error, ?TIP_ABILITY_LV_NOT_ENOUGH});
check_up_lv(_Lv,_AbilityLv) -> ?ok.

%% 升级花费元宝
upgrade_minus_money(UserId,Cost) ->
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_ABILITY_UPGRADE) of %% 扣取
		?ok -> ?ok;
		_ ->
			throw({?error,?TIP_COMMON_CASH_NOT_ENOUGH})
	end.

%% 元宝升级
money_upgrade(Player = #player{ability = AbilityData,user_id = UserId,info = Info},AbilityId) ->
	try
		{?ok,AbilityT,UpLv} = get_ability(AbilityId,AbilityData#ability_data.ability), 	%% 根据Id,取出升级等级和ability
		?ok					= check_up_lv(Info#info.lv,UpLv),							%% 检查技能等级
		?ok					= check_one_key(player_api:get_vip_lv(Info)),				%% 检查是否一键升阶
		{?ok,RecAbility}	= get_rec_ability(AbilityId,UpLv),							%% rec_ability数据
		?ok					= check_money_up_cost(RecAbility#rec_ability.cost),			%% 检查元宝升级
		{?ok,Player2}		= check_minus_meritorious(Player,RecAbility#rec_ability.meritorious),	%% 检查功勋
		?ok					= upgrade_minus_money(UserId,RecAbility#rec_ability.cost),	%% 升级花费元宝
		upgrade_success(Player2,AbilityId,UpLv,AbilityT,RecAbility,<<>>)				%% 升级成功
	catch
		throw:{?error,?TIP_COMMON_CASH_NOT_ENOUGH} -> %% 元宝不足
			{?ok,Player};
		throw:{?error,?TIP_COMMON_MERITORIOUS_NOT_ENOUGH} ->	%% 功勋不足
			{?ok,Player};
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
	
%% 内功升级
upgrade(Player = #player{ability = AbilityData,info = Info}, AbilityId) ->
	try
		{?ok,AbilityT,UpLv}	= get_ability(AbilityId,AbilityData#ability_data.ability),				%% 根据Id,取出升级等级和ability
		{?ok,RecAbility}	= get_rec_ability(AbilityId,UpLv),										%% rec_ability数据
		?ok					= check_request_lv(Info#info.lv,RecAbility#rec_ability.lv_min),			%% 检查等级要求
		?ok					= cehck_ability_lv(Info#info.lv, RecAbility#rec_ability.lv),			%% 检查技能等级
		{?ok,Player2,Packet}= check_user_goods(Player, RecAbility#rec_ability.goods_id),			%% 检查是否使用物品
		{?ok,Player3}		= check_minus_meritorious(Player2,RecAbility#rec_ability.meritorious),	%% 检查功勋
		{_, Player4}		= welfare_api:add_pullulation(Player3, ?CONST_WELFARE_ABILITY, UpLv, 1),%% 
		upgrade_success(Player4,AbilityId,UpLv,AbilityT,RecAbility,Packet)							%% 升级成功
        
	catch
		throw:{?error,?TIP_COMMON_GOOD_NOT_ENOUGH} -> 			%% 物品不足
			{?ok,Player};
		throw:{?error,?TIP_COMMON_MERITORIOUS_NOT_ENOUGH} ->	%% 功勋不足
			{?ok,Player};
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 升级成功更新属性
upgrade_success(Player,AbilityId,UpLv,AbilityT,RecAbility,Packet) ->
	AbilityData			= Player#player.ability,
	Ability3			= set_ability_ext(AbilityT, RecAbility),
	AbilityList			= case lists:keyfind(Ability3#ability.ability_id, #ability.ability_id, AbilityData#ability_data.ability) of
								?false -> [Ability3|AbilityData#ability_data.ability];
								Temp -> [Ability3|lists:delete(Temp, AbilityData#ability_data.ability)]
						  end,
	UpgradeTimes		= AbilityData#ability_data.upgrade_times + 1,
	AbilityData2		= AbilityData#ability_data{ability 			= AbilityList,
												   upgrade_times 	= UpgradeTimes},
	Player2				= Player#player{ability = AbilityData2},
	PacketInfo			= ability_api:msg_ability_sc_info([Ability3],?CONST_SYS_TRUE),
	Player3				= player_attr_api:refresh_attr_ability(Player2),
	yunying_activity_mod:activity_unlimitted_award(Player3,UpLv,9),           %运营活动奇门获礼品检测
	misc_packet:send(Player3#player.net_pid, <<PacketInfo/binary,Packet/binary>>),
	admin_log_api:log_ability_camp(Player3, ?CONST_LOG_FUN_ABILITY_UPGRADE, AbilityId, UpLv, RecAbility#rec_ability.meritorious),
    schedule_power_api:do_upgrade_ability(Player3),
	if
		AbilityId =:= ?CONST_MERIDIAN_FEED ->
			{?ok,Player4}	= achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_LIFE_LEVELUP, 0, 1),
			welfare_api:add_pullulation(Player4, ?CONST_WELFARE_ABILITY, 0, 1);
		?true -> 
			{?ok,Player3}
	end.

%% 检查功勋
check_minus_meritorious(Player,Meritorious) ->
	case player_api:minus_meritorious(Player, Meritorious, ?CONST_COST_ABILITY_UPGRADE) of %% 扣取功勋
		{?ok, Player2} ->
			{?ok, Player2};
		{?error, _ErrorCode} -> 
			throw({?error,?TIP_COMMON_MERITORIOUS_NOT_ENOUGH})
	end.
	
%% 检查使用物品
check_user_goods(Player, 0) -> %% 不需要使用
	{?ok,Player,<<>>};
check_user_goods(Player, GoodsId) -> %% 需要使用
	case ctn_bag2_api:get_goods_count(Player#player.bag, GoodsId) of
		GoodsNum when GoodsNum < 1 ->
			RecGoods 	= data_goods:get_goods(GoodsId),
			GoodsName 	= RecGoods#goods.name,
			Packet 		= message_api:msg_notice(?TIP_ABILITY_GOODS_NOT_ENOUGH, [{?TIP_SYS_COMM,misc:to_list(GoodsName)}]),%% 提示物品不足
			misc_packet:send(Player#player.net_pid, Packet),
			throw({?error,?TIP_COMMON_GOOD_NOT_ENOUGH});
		_ -> ?ok
	end,
	case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag,GoodsId, 1) of
		{?error, _ErrorCode} ->
			throw({?error,?TIP_COMMON_GOOD_NOT_ENOUGH});
		{?ok, Container2, _, Packet2} ->
            admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_ABILITY_UPGRADE, GoodsId, 1, misc:seconds()),
			{?ok,Player#player{bag = Container2},Packet2}
	end.

%% 设置ability_ext
set_ability_ext(Ability, #rec_ability{ext_id = 0}) -> Ability;
set_ability_ext(Ability, #rec_ability{ext_id = ExtId}) ->
	AbilityExt		= data_ability:get_ability_ext(ExtId),
	case lists:keyfind(ExtId, 1, Ability#ability.ability_ext) of
		?false ->
			AbilityExtList	= [{ExtId, 0, AbilityExt#rec_ability_ext.free}|Ability#ability.ability_ext],
			Ability#ability{ability_ext = AbilityExtList};
		Temp ->
			AbilityExtList	= lists:delete(Temp, Ability#ability.ability_ext),
			AbilityExtList2	= [{ExtId, 0, AbilityExt#rec_ability_ext.free}|AbilityExtList],
			Ability#ability{ability_ext = AbilityExtList2}
	end.

%% 检查等级
check_request_lv(Lv,RequestLv) when Lv >= RequestLv -> ?ok;
check_request_lv(_Lv,_RequestLv) ->
	throw({?error, ?TIP_ABILITY_LV_NOT_OPEN}).				%%人物等级没达到开启该内功条件

cehck_ability_lv(Lv, AbilityLv) when Lv >= AbilityLv -> ?ok;
cehck_ability_lv(_Lv, _AbilityLv) ->
	throw({?error, ?TIP_ABILITY_LV_NOT_ENOUGH}).			%%内功等级不能超过人物等级


%% ability数据
get_refresh_ability(AbilityId,Ability) ->
	case lists:keyfind(AbilityId, #ability.ability_id, Ability) of
		?false ->  %% 内功不存在
			throw({?error, ?TIP_ABILITY_NOT_EXIST});
		AbilityT ->
			{?ok,AbilityT}
	end.
	
%% 刷新八门属性
refresh_ability_ext(Player = #player{ability = AbilityData,net_pid = Pid}, AbilityId, Step) ->
	try
		ExtId				= data_ability:get_ability_ext_id({AbilityId, Step}), 				%% 取出八门ExtId值
		RecAbilityExt		= data_ability:get_ability_ext(ExtId),								%% 根据ExtId取出八门rec数据
		{?ok,Ability}		= get_refresh_ability(AbilityId,AbilityData#ability_data.ability),	%% 取出Ability
		{?ok, NOld, Count} 	= get_ability_ext_by_id(ExtId,Ability#ability.ability_ext),			%% 取出旧的八门值
		{?ok, CountNew, IsFree} = check_count(Player,Count,RecAbilityExt#rec_ability_ext.cost), %% 剩余次数
        Length              = length(RecAbilityExt#rec_ability_ext.value),
        {NNew, Num}         = 
            case IsFree of
                ?CONST_SYS_TRUE ->
                    {1, 1};
                _ ->
            		NumXX	= misc_random:random(Length),	%% 随机八门值
            		XX      = misc:max(NumXX, NOld),% 取最大值
                    {XX, NumXX}
            end,
		
		AbilityExtList 		= lists:keyreplace(ExtId, 1, Ability#ability.ability_ext, {ExtId, NNew, CountNew}), %% 更新新八门值
		Ability2			= Ability#ability{ability_ext = AbilityExtList},					%% 更新八门列表
		AbilityList			= lists:keyreplace(AbilityId, #ability.ability_id, AbilityData#ability_data.ability, Ability2),
		AbilityData2		= AbilityData#ability_data{ability = AbilityList},					%% 更新AbilityData
		Player2				= Player#player{ability = AbilityData2},							%% 更新Player
		
		ExtValue			= lists:nth(NNew, RecAbilityExt#rec_ability_ext.value),	 			%% 当前八门值 
		Sum					= ability_api:get_ext_value(AbilityExtList),						%% 八门总和
		Player3				= player_attr_api:refresh_attr_ability(Player2),					%% 刷新属性
		PacketExtInfo		= ability_api:msg_ability_sc_ext_info(Num, ExtValue, CountNew,AbilityId, Step,Sum,?CONST_SYS_TRUE),
		misc_packet:send(Pid, PacketExtInfo),
		{?ok, Player3}
%% 		if
%% 			Length =:= Num ->
%% 				new_serv_api:finish_achieve(Player3, ?CONST_NEW_SERV_ABILITY, Num, 1),
%%                 {?ok, Player3};
%% 			?true ->
%% 				{?ok, Player3}
%% 		end
	catch
		throw:{?error,?TIP_COMMON_CASH_NOT_ENOUGH} -> 
			{?ok, Player};
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
            {?ok, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查剩余次数
check_count(_Player,Count,_Cost) when Count > 0 ->
	{?ok, Count - 1, ?CONST_SYS_TRUE};
check_count(Player,_Count,Cost) -> %% 剩余次数为0扣取元宝
	 case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST,Cost,?CONST_COST_ABILITY_EXT) of
		 ?ok -> {?ok, 0, ?CONST_SYS_FALSE};
		 {?error, _ErrorCode} -> 
			 throw({?error,?TIP_COMMON_CASH_NOT_ENOUGH})
	 end.

%%　ability_ext 数据
get_ability_ext_by_id(ExtId,AbilityExt) ->	
	case lists:keyfind(ExtId, 1, AbilityExt) of
		{_ExtId, N, Count} ->
			{?ok,N,Count}; 
		_ -> 
			throw({?error, ?TIP_ABILITY_NOT_OPEN})	
	end.


