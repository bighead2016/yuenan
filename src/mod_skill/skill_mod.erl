%% Author: Administrator
%% Created: 2012-7-25
%% Description: TODO: Add description to skill_mod
-module(skill_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([skill_info/1, upgrade_skill/2]).
-export([enable_skill/3, disable_skill/2, exchange_skill_bar/3, reset_skill_point/1, calc_skill_point/1]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
skill_info(Player) ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillList	= SkillData#skill_data.skill,
	PacketSkill	= skill_api:msg_sc_skill_info(Player, SkillList),
	PacketBar	= skill_api:msg_sc_skill_bar_info(SkillBar),
	<<PacketSkill/binary, PacketBar/binary>>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 升级技能
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
upgrade_skill(Player, SkillId) ->
	SkillData	= Player#player.skill,
	SkillList	= SkillData#skill_data.skill,
	{SkillId, SkillLvNext, LvMax, Time} =
		 case lists:keyfind(SkillId, 1, SkillList) of
			 {SkillId, SkillLvOld, TimeLast} ->% 升级技能
				 {SkillId, SkillLvOld + 1, skill_lv_max(SkillId, SkillLvOld), TimeLast};
			 _ ->% 学习技能
				 {SkillId, 1, skill_lv_max(SkillId, 1), 0}
		 end,
	if
		SkillLvNext =< LvMax ->
%% 			?MSG_PRINT("SkillId=~p, SkillLvNext=~p", [SkillId, SkillLvNext]),
			case data_skill:get_skill({SkillId, SkillLvNext}) of
				Skill when is_record(Skill, skill) ->
					Seconds	= misc:seconds(),
					case check(Player, Skill, SkillList, Time, Seconds) of
						?ok ->
							upgrade_skill(Player, Skill, Seconds);
						{?error, ErrorCode} ->
							Packet = message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, Packet),
							{?ok, Player}
					end;
				_ ->% 参数错误
					Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, Player}
			end;
		?true ->% 技能已到最高级
			Packet 		= message_api:msg_notice(?TIP_SKILL_FULL),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

upgrade_skill(Player, Skill, Seconds) ->
	UserId	= Player#player.user_id,
	case deduct_goods(Player, Skill#skill.goods_id, Skill#skill.goods_count) of
		{?ok, Player2, PacketGoods} ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Skill#skill.gold, ?CONST_COST_SKILL_UPGRATE) of
				?ok ->
					case minus_skill_point(Player2, Skill#skill.skill_point) of
						{?ok, Player3} ->
							SkillId		= Skill#skill.skill_id,
							SkillLv		= Skill#skill.lv,
							SkillData	= Player3#player.skill,
							SkillList2	= case lists:keymember(SkillId, 1, SkillData#skill_data.skill) of
											  ?true ->
												  lists:keyreplace(SkillId, 1, SkillData#skill_data.skill, {SkillId, SkillLv, Seconds});
											  ?false ->
												  [{SkillId, SkillLv, Seconds}|SkillData#skill_data.skill]
										  end,
							SkillData2	= SkillData#skill_data{skill = SkillList2},
							PacketSkill	= skill_api:msg_sc_upgrade_skill(SkillId),
							PacketSkillInfo = skill_api:msg_sc_skill_info(Player, SkillList2),
							Packet		= <<PacketGoods/binary, PacketSkill/binary, PacketSkillInfo/binary>>,
							misc_packet:send(Player#player.net_pid, Packet),
                            admin_log_api:log_skill_learn_active(Player3, SkillId, SkillLv, Skill#skill.skill_point),
							{?ok, Player3#player{skill = SkillData2}};
						{?error, ErrorCode} ->
							Packet = message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, Packet),
							{?ok, Player}
					end;
				{?error, ErrorCode} ->
					?MSG_DEBUG("~nErrorCode=~p", [ErrorCode]),
					{?ok, Player}
			end;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

%% 扣除技能点
minus_skill_point(Player, 0) -> {?ok, Player};
minus_skill_point(Player, SkillPoint) ->
	player_api:minus_skill_point(Player, SkillPoint).

%% 扣除物品
deduct_goods(Player, 0, 0) ->
	{?ok, Player, <<>>};
deduct_goods(Player, GoodsId, Count) ->
	case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, GoodsId, Count) of
		{?ok, Container, _GoodsList, Packet} ->
			{?ok, Player#player{bag = Container}, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

check(Player, Skill, SkillList, Time, Seconds) ->
	try
		Info	= Player#player.info,
		?ok 	= check_skill_point(Player, Info#info.skill_point, Skill#skill.skill_point),
		?ok 	= check_prev(Player, Skill#skill.prev_skill, SkillList),
		?ok 	= check_lv(Player, Info#info.lv, Skill#skill.lv_player),
		?ok		= check_time(Player, Seconds, Time, Skill#skill.skill_cd),
		?ok		= check_goods(Player, Player#player.bag, Skill#skill.goods_id, Skill#skill.goods_count),
		?ok
	catch
		throw:Return ->
            Return;
		Type:Error ->
			?MSG_ERROR("~nType:Error---~p~p~n", [Type, Error]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 检查技能点
check_skill_point(_Player, SkillPoint, SkillPointRequest) when SkillPoint >= SkillPointRequest -> ?ok;
check_skill_point(_Player, _SkillPoint, _SkillPointRequest) -> throw({?error, ?TIP_SKILL_POINT_NOT_ENOUGH}).

%% 检查前置技能
check_prev(Player, [{SkillId, Lv}|PrevSkill], SkillList) ->
	case lists:keyfind(SkillId, 1, SkillList) of
		{SkillId, LvNow, _} when LvNow >= Lv ->
			check_prev(Player, PrevSkill, SkillList);
		_ -> throw({?error, ?TIP_SKILL_PRE_NOT_FIT})
	end;
check_prev(_Player, [], _SkillList) -> ?ok.
			
%% 检查物品数量	
check_goods(_Player, _Ctn, 0, 0) -> ?ok;
check_goods(_Player, Ctn, GoodsId, CountRequest) ->
	case ctn_api:get_count(Ctn, GoodsId) of
		Count when Count >= CountRequest -> ?ok;
		_ -> throw({?error, ?TIP_COMMON_GOOD_NOT_ENOUGH})
	end.

%% 检查等级
check_lv(_Player, _Lv, 0) -> ?ok;
check_lv(_Player, Lv, RequestLv) when Lv >= RequestLv -> ?ok;
check_lv(_Player, _Lv, _RequestLv) ->
	throw({?error, ?TIP_COMMON_LEVEL_NOT_ENOUGH}).

%% 检查CD时间
check_time(_Player, _Seconds, _TimeLast, 0) -> ?ok;
check_time(_Player, Seconds, TimeLast, CD) when Seconds >= TimeLast + CD -> ?ok;
check_time(_Player, _Seconds, _TimeLast, _CD) -> 
	throw({?error, ?TIP_SKILL_CD_NOT_ENOUGH}).

%%
%% Local Functions
%%
skill_lv_max(SkillId, SkillLv) ->
	case data_skill:get_skill({SkillId, SkillLv}) of
		Skill when is_record(Skill, skill) ->
			Skill#skill.lv_max;
		_ ->% 参数错误
			0
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 启用技能 | 停用技能
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 启用技能
enable_skill(Player, SkillId, Idx)
  when is_number(Idx) andalso
	   Idx >= 1 andalso Idx =< ?CONST_SKILL_SKILL_BAR_COUNT ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillList	= SkillData#skill_data.skill,
%% 	?MSG_PRINT("SkillBar=~p", [SkillBar]),
%% 	?MSG_PRINT("SkillId=~p, SkillList=~p", [SkillId,SkillList]),
	case lists:keyfind(SkillId, 1, SkillList) of
		{SkillId, Lv, _Time} ->
			Skill = data_skill:get_skill({SkillId, Lv}),
			case Skill#skill.type of
				?CONST_SKILL_TYPE_ACTIVE ->
					case check_repeat(misc:to_list(SkillBar), SkillId) of
						?true ->
							Packet		= message_api:msg_notice(?TIP_SKILL_EXIST),
							misc_packet:send(Player#player.net_pid, Packet),
							{?ok, Player};
						?false ->
							SkillBar2	= setelement(Idx, SkillBar, SkillId),
							SkillData2	= SkillData#skill_data{skill_bar = SkillBar2},
							
							PacketBar	= skill_api:msg_sc_skill_bar_info(SkillBar2),
							misc_packet:send(Player#player.net_pid, PacketBar),

							{?ok, Player#player{skill = SkillData2}}
					end;
				_ ->
					{?ok, Player}
			end;
		_ ->
			Packet = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end;
enable_skill(Player, _SkillId, _Idx) -> % 参数错误
	Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player}.
%% 停用技能
disable_skill(Player, Idx)
  when is_number(Idx) andalso
	   Idx >= 1 andalso Idx =< ?CONST_SKILL_SKILL_BAR_COUNT ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillBar2	= setelement(Idx, SkillBar, 0),
	PacketBar	= skill_api:msg_sc_skill_bar_info(SkillBar2),
	misc_packet:send(Player#player.net_pid, PacketBar),
	SkillData2	= SkillData#skill_data{skill_bar = SkillBar2},
	{?ok, Player#player{skill = SkillData2}};
disable_skill(Player, _Idx) -> % 参数错误
	Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 交换技能栏位置
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exchange_skill_bar(Player, IdxFrom, IdxTo)
  when is_number(IdxFrom) andalso is_number(IdxTo) andalso
	   IdxFrom >= 1 andalso IdxFrom =< ?CONST_SKILL_SKILL_BAR_COUNT andalso
	   IdxTo >= 1 andalso IdxTo =< ?CONST_SKILL_SKILL_BAR_COUNT ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillIdFrom = element(IdxFrom, SkillBar),
	SkillIdTo	= element(IdxTo, SkillBar),
	SkillBar2	= setelement(IdxFrom, SkillBar, SkillIdTo),
	SkillBar3	= setelement(IdxTo, SkillBar2, SkillIdFrom),
	SkillData2	= SkillData#skill_data{skill_bar = SkillBar3},
	PacketBar	= skill_api:msg_sc_skill_bar_info(SkillBar3),
	misc_packet:send(Player#player.net_pid, PacketBar),
	{?ok, Player#player{skill = SkillData2}};
exchange_skill_bar(Player, _IdxFrom, _IdxTo) -> % 参数错误
	Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player}.

check_repeat([SkillId|_SkillBar], SkillId) -> ?true;
check_repeat([_|SkillBar], SkillId) ->
	check_repeat(SkillBar, SkillId);
check_repeat([], _SkillId) -> ?false.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能洗点功能
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reset_skill_point(Player) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	SkillPoint	= Info#info.skill_point,
	Value		= ?CONST_SKILL_POINT_RESET_COST,
	CostSkillPoint		= calc_skill_point(Player),
	case CostSkillPoint =:= ?CONST_SYS_FALSE of
		?false ->           %% 有技能点可洗
			case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Value, ?CONST_COST_SKILL_WASH) of
				?ok ->
					Player1		        = plus_skill_point(Player, CostSkillPoint),
					NewSkillPoint		= SkillPoint + CostSkillPoint,
					?MSG_DEBUG("CostSkillPoint=~p, NewSkillPoint=~p", [CostSkillPoint, NewSkillPoint]),
					SkillBar 			= erlang:make_tuple(?CONST_SKILL_SKILL_BAR_COUNT, 0, []),
					InitSkillList		= [],
					NewPlayer			= Player1#player{skill = #skill_data{skill_bar = SkillBar, skill	= InitSkillList}},
					PacketSkill			= skill_api:msg_sc_skill_info(Player, InitSkillList),
					PacketBar			= skill_api:msg_sc_skill_bar_info(SkillBar),
					
					Packet				= <<PacketSkill/binary, PacketBar/binary>>,
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, NewPlayer};
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
					{?ok, Player}
			end;
		?true ->            %% 无技能点可洗
			Packet		= message_api:msg_notice(?TIP_SKILL_NOT_WASH_POINT),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.
%% 计算用去的技能点
calc_skill_point(Player) ->
	SkillData		= Player#player.skill,
	SkillList		= SkillData#skill_data.skill,
	calc_skill_point1(SkillList, 0).

calc_skill_point1([{SkillId, Lv, _}|SkillList], SkillPoint) when SkillId > 0 ->
	case Lv > 1 of
		?true ->        %% 升级过的技能单独计算
			CostSkillPoint 	= calc_skill_point2(SkillId, Lv, 0),
			NewSkillPoint	= SkillPoint + CostSkillPoint,
			calc_skill_point1(SkillList, NewSkillPoint);
		?false ->       %% 未升级的直接读表获取数据
			SkillData		= data_skill:get_skill({SkillId, Lv}),
			CostSkillPoint	= SkillData#skill.skill_point,
			NewSkillPoint	= SkillPoint + CostSkillPoint,
			calc_skill_point1(SkillList, NewSkillPoint)
	end;
calc_skill_point1([], SkillPoint) ->
	SkillPoint.
		
calc_skill_point2(SkillId, Lv, SkillPoint) when Lv > 0 ->
	SkillData		= data_skill:get_skill({SkillId, Lv}),
	CostSkillPoint	= SkillData#skill.skill_point,
	NewSkillPoint	= SkillPoint + CostSkillPoint,
	calc_skill_point2(SkillId, Lv - 1, NewSkillPoint);
calc_skill_point2(_SkillId, _Lv, SkillPoint) ->
	SkillPoint.
	
%% 加上用去的技能点(洗点)
plus_skill_point(Player, 0) -> Player;
plus_skill_point(Player, SkillPoint) ->
	player_api:plus_skill_point(Player, SkillPoint).
		
		
		
		
		
		
		
		
		
		
		
		
		