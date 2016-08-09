%% Author: Administrator
%% Created: 2012-7-20
%% Description: 心法系统API
-module(mind_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([create_mind/1, clear_mind_by_day/2, login/1, refresh_attr/3,
		 create_partner_mind/2, user_level_up/1, check_partner_mind/2,
         get_score/1, set_score/2, update_mind_score/3, login_packet/2,
         exchange/2]).

-export([get_temp_bag_mind_all/1, get_mind_use_list/1, get_mind_bag_list/1,
		 get_mind_learn_list/1, get_user_mind_all/3, mind_upgrade/5,
		 mind_absorb/3, mind_one_key_absorb/2, read_secret/3,
		 one_key_read_secret/4, extend_mind_bag/2, mind_pick/3,
		 one_key_mind_pick/2, update_per_mind/5, mind_exchange/6, 
		 change_ceil_state/5, get_user_mind_sum/3, check_bag/1]).

-export([get_user_spirit/1,get_spirit_by_id/2,set_spirit/2,get_base_spirit/1]).

-export([
		 msg_mind_list_return/5, msg_mind_read_list_return/4, msg_mind_upgrade_return/2,
		 msg_mind_absorb_return/3, msg_mind_one_key_absorb_return/2, msg_mind_read_secret_return/4, 
		 msg_mind_one_key_read_return/2,msg_mind_extern_bag_return/2, msg_mind_temp_bag_list_return/1,
		 msg_mind_pick_result/4, msg_mind_one_key_pick_result/3, msg_mind_exchange_result/1,
		 msg_mind_get_mind_by_pos_return/7, msg_update_spirit/1, msg_sc_update_score/1]).

%%
%% API Functions
%%
%%玩家心法数据初始化
create_mind(UserId) ->
	#mind_data{
			   last_clear_date = misc:date_num(),
			   mind_uses = [
							#mind_use{
									  type = ?CONST_MIND_TYPE_PLAYER, 
									  user_id = UserId, 
									  index = 1, 
									  mind_use_info = mind_mod:make_ceil(?CONST_MIND_USER_CEIL_MAX, 0)}
						   ],
			   minds = #mind_info{
                                  score = 0,
                                  spirit = 0,
								  daily_free_times = ?CONST_MIND_DAILY_FREE_TIMES,
								  mind_bag = mind_mod:make_ceil(?CONST_MIND_BAG_CEIL_MAX, ?CONST_MIND_BAG_CEIL_DEFAULT),
								  mind_bag_temp = mind_mod:make_temp_ceil(?CONST_MIND_TEMP_BAG_CEIL_MAX),
								  mind_learn = [#secret_state{pos=1, state=1},
												#secret_state{pos=2, state=0},
												#secret_state{pos=3, state=0},
												#secret_state{pos=4, state=0}]}
			  }.

%%玩家升级刷新心法开启格子(玩家/武将同时刷新) 格子是连续开放的
user_level_up(Player = #player{mind = PlayerMind}) ->
	MindUses = PlayerMind#mind_data.mind_uses,
	Num		 = erlang:length(MindUses),
	user_level_up2(Player, MindUses, Num).
%%刷新每个角色
user_level_up2(Player, _MindUses, 0) ->
	Player;
user_level_up2(Player = #player{info = Info, mind = PlayerMind}, MindUses, Num) ->
	MindUse		= lists:keyfind(Num, #mind_use.index, MindUses),
	#mind_use{type = Type, user_id = UserId} = MindUse,
	MindList 	= mind_mod:get_user_mind_list(Player, Type, UserId),
	Lv		 	= Info#info.lv,
	NewCount 	= mind_mod:get_use_count(Lv),
	MindList2	= user_level_up3(MindList, NewCount),
	MindUses2	= lists:keyreplace(Num, #mind_use.index, MindUses, MindUse#mind_use{mind_use_info = MindList2}),
	PlayerMind2 = PlayerMind#mind_data{mind_uses = MindUses2},
	Player2		= Player#player{mind = PlayerMind2},
	user_level_up2(Player2, MindUses2, Num-1).
%%刷新每位玩家心法列表
user_level_up3(MindList, 0) ->
	MindList;
user_level_up3(MindList, Index) ->
	Ceil		= lists:keyfind(Index, #ceil_state.pos, MindList),
	Ceil2		= Ceil#ceil_state{state = 1},
	MindList2   = lists:keyreplace(Index, #ceil_state.pos, MindList, Ceil2),
	user_level_up3(MindList2, Index-1).
	
%% 新招募武将增加心法背包 提供给武将模块的接口
create_partner_mind(Player = #player{mind = PlayerMind, info = Info}, PartnerId) ->
	MindUses 	= PlayerMind#mind_data.mind_uses,
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, _Partner} ->
			PartnerLv	= Info#info.lv,
			Count		= mind_mod:get_use_count(PartnerLv),
			MindUseNum 	= erlang:length(MindUses),
			MindUse 	= #mind_use{
									type = ?CONST_MIND_TYPE_PARTNER, 
									user_id = PartnerId, 
									index = MindUseNum + 1, 
									mind_use_info = mind_mod:make_ceil(?CONST_MIND_USER_CEIL_MAX, Count)
								   },
			NewMindUses = MindUses ++ [MindUse],				%从后面更新
			NewPlayerMind = PlayerMind#mind_data{mind_uses = NewMindUses},
			Player#player{mind = NewPlayerMind};
		{?error, _Error} ->
			Player
	end.

%% 遣散武将前，检查是否有心法
check_partner_mind(UserId, PartnerId) ->
	case player_api:get_player_field(UserId, #player.mind) of
		{?ok, MindData} ->
			MindUse		= get_user_mind_all(MindData, ?CONST_MIND_TYPE_PARTNER, PartnerId),
			MindList 	= MindUse#mind_use.mind_use_info,
			Fun 		= fun(X, Sum) ->
								  if
									  X#ceil_state.mind_id =/= 0 -> Sum + 1;
									  ?true -> Sum
								  end
						  end,
			Sum2  = lists:foldl(Fun, 0, MindList),
			if
				Sum2 > 0 -> ?true;
				?true -> ?false
			end;
		{?error, _ErrorCode} -> ?false
	end.

%% 心法每天定时清理数据（比如每天免费参阅次数）  在线玩家的处理
clear_mind_by_day(Player = #player{mind = PlayerMind}, _) ->
	try
		LastDate		= PlayerMind#mind_data.last_clear_date,
		Today			= misc:date_num(),
		if	Today =/= LastDate ->
				Minds 			= PlayerMind#mind_data.minds,
				NewMinds 		= Minds#mind_info{daily_free_times = ?CONST_MIND_DAILY_FREE_TIMES},
				NewPlayerMind 	= PlayerMind#mind_data{minds = NewMinds, 
													   last_clear_date 	= Today,
													   today_third_times = 0,
													   today_fourth_times = 0,
													   today_total_times = 0},
				NewPlayer 		= Player#player{mind = NewPlayerMind},
				{?ok, NewPlayer};
			?true ->
				{?ok, Player}
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end;
clear_mind_by_day(Player, _) ->
    ?MSG_ERROR("UserId:~p MindData=[~p]", [Player#player.user_id, Player#player.mind]),
    Player.

%% 玩家上线的心法处理(离线玩家的每日心法更新,在其上线时实现)
login(Player) ->
	{?ok, NewPlayer} = clear_mind_by_day(Player, 0),
	mind_times(Player#player.user_id, ?CONST_MIND_DAILY_FREE_TIMES),
	NewPlayer.

mind_times(UserId, Times) ->
	Packet = msg_update_free_times(Times),
	misc_packet:send(UserId, Packet).

%% 登录包
login_packet(Player, OldPacket) ->
    Score  = get_score(Player),
    Packet = msg_sc_update_score(Score),
    {Player, <<OldPacket/binary, Packet/binary>>}.

%% GM命令使用 未将该变更通知前端
%% mind_api:set_spirit(Player, Spirit).
%% player_api:process_send(75, mind_api, set_spirit, 99999).
set_spirit(Player = #player{mind = PlayerMind}, Spirit) ->
	Minds 			= PlayerMind#mind_data.minds,
	NewMinds 		= Minds#mind_info{spirit = Spirit},
	NewPlayerMind 	= PlayerMind#mind_data{minds = NewMinds},
	{?ok, Player#player{mind = NewPlayerMind}}.

%% 更新心法带来的玩家/武将属性变动
refresh_attr(PlayerMind, ?CONST_MIND_TYPE_PLAYER, _UserId) ->
	refresh_player_attr(PlayerMind);
refresh_attr(PlayerMind, ?CONST_MIND_TYPE_PARTNER, UserId) ->
	refresh_partner_attr(PlayerMind, UserId).

%% 计算心法对主角的加成
refresh_player_attr(PlayerMind) ->
	MindUses 	= PlayerMind#mind_data.mind_uses,
	MindUse 	= lists:keyfind(?CONST_MIND_TYPE_PLAYER, #mind_use.index, MindUses),
	MindUseList = MindUse#mind_use.mind_use_info,
	
	Fun = fun(Ceil, Result) ->
				  MindInfo = data_mind:get_base_mind(Ceil#ceil_state.mind_id),
				  case is_record(MindInfo, rec_mind) of
					  ?true ->
						  #rec_mind{type = Type, grow = MindGrow} = MindInfo,
						  {_, Value}= lists:keyfind(Ceil#ceil_state.lv, 1, MindGrow),
						  [{Type, Value}|Result];
					  ?false ->
						  Result
				  end
		  end,
	AttrList = lists:foldl(Fun, [], MindUseList),
	NullAttr = player_attr_api:record_attr(),
	player_attr_api:attr_plus(NullAttr, AttrList).

%% 计算心法对武将的加成
refresh_partner_attr(PlayerMind, PartnerId) ->
	MindUses 	= PlayerMind#mind_data.mind_uses,
	case lists:filter(fun(X) -> X#mind_use.type =:= ?CONST_MIND_TYPE_PARTNER andalso X#mind_use.user_id =:= PartnerId end, MindUses) of
        [MindUse] ->
        	MindUseList	= MindUse#mind_use.mind_use_info,
        	
        	Fun = fun(Ceil, Result) ->
        				  MindInfo = data_mind:get_base_mind(Ceil#ceil_state.mind_id),
        				  case is_record(MindInfo, rec_mind) of
        					  ?true ->
        						  #rec_mind{type = Type, grow = MindGrow} = MindInfo,
        						  {_, Value} = lists:keyfind(Ceil#ceil_state.lv, 1, MindGrow),
        						  [{Type, Value}|Result];
        					  ?false ->
        						  Result
        				  end
        		  end,
        	AttrList = lists:foldl(Fun, [], MindUseList),
        	NullAttr = player_attr_api:record_attr(),
        	player_attr_api:attr_plus(NullAttr, AttrList);
        _ ->
            NullAttr = player_attr_api:record_attr(),
            NullAttr
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc  心法的各种查询
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%获取临时背包中的心法信息
get_temp_bag_mind_all(Player = #player{mind = PlayerMind}) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	Minds#mind_info.mind_bag_temp.

%% 玩家及武将心法使用列表
get_mind_use_list(Player) ->
	PlayerMind 	= Player#player.mind,
	PlayerMind#mind_data.mind_uses.

%% 玩家心法背包列表
get_mind_bag_list(Player) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	Minds#mind_info.mind_bag.
	
%% 获取参阅状态列表
get_mind_learn_list(Player) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	FreeTimes	= Minds#mind_info.daily_free_times,
	Pos3Times	= PlayerMind#mind_data.today_third_times,
	Pos4Times	= PlayerMind#mind_data.today_fourth_times,
	{FreeTimes, Pos3Times, Pos4Times, Minds#mind_info.mind_learn}.

%%查找玩家或者伙伴装备区心法列表
get_user_mind_all(Player, MindType, _UserId) when is_record(Player, player) ->
	get_user_mind_all(Player#player.mind, MindType, _UserId);
get_user_mind_all(MindData, ?CONST_MIND_TYPE_PLAYER, _UserId) when is_record(MindData, mind_data) ->
	MindUses 	= MindData#mind_data.mind_uses,
	lists:keyfind(1, #mind_use.index, MindUses);
get_user_mind_all(MindData, ?CONST_MIND_TYPE_PARTNER, UserId) when is_record(MindData, mind_data) ->
	MindUses 	= MindData#mind_data.mind_uses,
%% 	?MSG_DEBUG("get_user_mind_all11111111:~p",[MindUses]),
	case lists:filter(fun(X) -> X#mind_use.type =:= ?CONST_MIND_TYPE_PARTNER andalso X#mind_use.user_id =:= UserId end, MindUses) of
		[] -> [];
		[Element2] -> Element2
	end;
get_user_mind_all(_Player, _, _UserId) ->
	[].

%%获取玩家的灵力值
get_user_spirit(Player) ->
	PlayerMind	   = Player#player.mind,
	MindData	   = PlayerMind#mind_data.minds,
	MindData#mind_info.spirit.

%%获取一定等级心法对应的灵力值	
get_spirit_by_id(MindId, MindLv) when MindId =< 0 orelse MindLv =< 0 ->
	0;
get_spirit_by_id(MindId, MindLv) when MindLv =:= 1 ->
	Mind = data_mind:get_base_mind(MindId),
	Mind#rec_mind.base_spirit;
get_spirit_by_id(MindId, MindLv) when MindLv =< ?CONST_MIND_LV_MAX ->
	BaseMindList 		= data_mind:get_base_mind(MindId),
	GrowSpiritList 		= BaseMindList#rec_mind.grow_spirit,
	SpiritNeed			= calc_spirit_by_id(GrowSpiritList, 0, MindLv - 1),
	SpiritNeed + get_spirit_by_id(MindId, 1);
get_spirit_by_id(MindId, _MindLv) ->
	get_spirit_by_id(MindId, ?CONST_MIND_LV_MAX).

%% 计算转化的值
calc_spirit_by_id([{Lv, Value}|SpiritList], Total, MindLv) when Lv >= 1 andalso Lv =< MindLv  ->
	TotalValue			= Total + Value,
	calc_spirit_by_id(SpiritList, TotalValue, MindLv);
calc_spirit_by_id([_|SpiritList], Total, MindLv) ->
	calc_spirit_by_id(SpiritList, Total, MindLv);
calc_spirit_by_id([], Total, _MindLv) -> Total.
	
%%获取心法的基础灵力值
get_base_spirit(MindId) when MindId =< 0 ->
	0;
get_base_spirit(MindId) ->
	Mind = data_mind:get_base_mind(MindId),
	Mind#rec_mind.base_spirit.

%%获取心法升级所需灵力
get_spirit_need(MindId, MindLv) when MindId =< 0 orelse MindLv =< 0 ->
	0;
get_spirit_need(MindId, MindLv) when MindLv =< (?CONST_MIND_LV_MAX - 1) ->
	BaseMindList 		= data_mind:get_base_mind(MindId),
	GrowSpiritList 		= BaseMindList#rec_mind.grow_spirit,
	{_Lv, SpiritNeed} 	= lists:keyfind(MindLv, 1, GrowSpiritList), 
	SpiritNeed;
get_spirit_need(MindId, _MindLv) ->
	get_spirit_need(MindId, (?CONST_MIND_LV_MAX - 1)).

%% 背包区升级
mind_upgrade(Player = #player{net_pid = NetPid}, _UserType, _UserId, ?CONST_MIND_TYPE_BAG, Index) ->
	MindInfo = mind_mod:get_bag_mind_by_index(Player, Index),
	case check_mind_upgrade(MindInfo) of
		?ok ->
			#ceil_state{mind_id = MindId, lv = MindLv} = MindInfo,
			SpiritNeed = get_spirit_need(MindId, MindLv),
			Spirit 	   = get_user_spirit(Player),
			if
				SpiritNeed > Spirit ->     %%灵力不足
					Packet = message_api:msg_notice(?TIP_MIND_SPIRIT_NOT_ENOUGH),
					misc_packet:send(NetPid, Packet),
					?error;
				?true ->
					%% 新服成就
					RecMind 	   = data_mind:get_base_mind(MindId),
%% 					{?ok, Player2}  =
%% 						if RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_PURPLE ->
%% 							   new_serv_api:finish_achieve(Player, ?CONST_NEW_SERV_MIND_UPLEV, MindLv+1, 1);
%% 						   ?true ->
%% 							   {?ok, Player}
%% 						end,
					%%扣除灵力
					{_, NewPlayer} = update_player_spirit(Player, 0 - SpiritNeed),
					%%更新心法等级
					NewMindInfo = MindInfo#ceil_state{lv = MindLv+1},
					NewPlayer2 = mind_mod:update_bag_mind_by_index(NewPlayer, Index, NewMindInfo),
					update_per_mind(NewPlayer2, ?CONST_MIND_TYPE_BAG, 0, 0, Index),
                    if (RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score       = get_score(NewPlayer2),
                            admin_log_api:log_mind(NewPlayer2, MindId, ?CONST_SYS_GOODS_MAKE, MindLv, MindLv+1, Score);
                       ?true ->
                            ?ok
                    end,
					{?ok, MindLv+1, SpiritNeed, NewPlayer2}
			end;
		{?error, Result} ->
			case Result of
				?TIP_MIND_BAD_ARG ->
					Packet = message_api:msg_notice(?TIP_MIND_BAD_ARG),
					misc_packet:send(NetPid, Packet);
				?TIP_MIND_LV_MAX ->
					Packet = message_api:msg_notice(?TIP_MIND_LV_MAX),
					misc_packet:send(NetPid, Packet)
			end,
			?error
	end;
%%装备心法升级
mind_upgrade(Player = #player{net_pid = NetPid, mind = PlayerMind}, UserType, UserId, ?CONST_MIND_TYPE_EQUIP, Index) ->
	Minds = PlayerMind#mind_data.minds,
	MindInfo = mind_mod:get_user_mind_by_index(Player, UserType, UserId, Index),
	case check_mind_upgrade(MindInfo) of
		?ok ->
			#ceil_state{mind_id = MindId, lv = MindLv} = MindInfo,
			SpiritNeed = get_spirit_need(MindId, MindLv),
			if
				SpiritNeed > Minds#mind_info.spirit ->
					Packet = message_api:msg_notice(?TIP_MIND_SPIRIT_NOT_ENOUGH),
					misc_packet:send(NetPid, Packet),
					?error;
				?true ->
					{_, NewPlayer} = update_player_spirit(Player, 0 - SpiritNeed),
					NewPlayer2 = mind_mod:update_player_mind_by_index(NewPlayer, UserType, UserId, Index, MindLv+1),
					%%更新心法升级带来的人物(包括武将)属性变更
					NewPlayer3 = exchange_refresh_attr(NewPlayer2, UserId, UserType),
%% 					NewPlayer3 = player_attr_api:refresh_attr_mind(NewPlayer2),
					update_per_mind(NewPlayer3, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, Index),
					% 刷新人物心力
					{_UserSpirit, NewPlayer4} = mind_mod:send_calc_user_spirit(NewPlayer3, UserId, UserType),
%% 					{?ok, NewPlayer5} = achievement_api:add_achievement(NewPlayer4, ?CONST_ACHIEVEMENT_STAR_FORCE, UserSpirit, 1),
					%% 新服成就
					RecMind 	   = data_mind:get_base_mind(MindId),
                    if (RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score = get_score(NewPlayer4),
                            admin_log_api:log_mind(NewPlayer4, MindId, ?CONST_SYS_GOODS_MAKE, MindLv, MindLv+1, Score);
                       ?true ->
                            ?ok
                    end,
%% 					{?ok, NewPlayer5}  =
%% 						if RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_PURPLE ->
%% 							   new_serv_api:finish_achieve(NewPlayer4, ?CONST_NEW_SERV_MIND_UPLEV, MindLv+1, 1);
%% 						   ?true ->
%% 							   {?ok, NewPlayer4}
%% 						end,
					{?ok, MindLv+1, SpiritNeed, NewPlayer4}
			end;
		{?error, Result} ->
			case Result of
				?TIP_MIND_BAD_ARG ->
					Packet = message_api:msg_notice(?TIP_MIND_BAD_ARG),
					misc_packet:send(NetPid, Packet);
				?TIP_MIND_LV_MAX ->
					Packet = message_api:msg_notice(?TIP_MIND_LV_MAX),
					misc_packet:send(NetPid, Packet)
			end,
			?error
	end;	
mind_upgrade(_Player, _UserType, _UserId, _, _Index) ->
	?error.

%% 检查心法是否可以升级
check_mind_upgrade(MindInfo) when is_record(MindInfo, ceil_state) ->
	 if
		 MindInfo#ceil_state.state =:= 0 ->
			 {?error, ?TIP_MIND_BAD_ARG};
		 MindInfo#ceil_state.lv >= ?CONST_MIND_LV_MAX ->
			 {?error, ?TIP_MIND_LV_MAX};
		 ?true ->
			 ?ok
	end;
check_mind_upgrade(_MindInfo) ->
	{?error, ?TIP_MIND_BAD_ARG}.

%% 心法吸收（转化灵力）
mind_absorb(Player = #player{net_pid = NetPid}, ?CONST_MIND_TYPE_BAG, Index) ->
	MindInfo = mind_mod:get_bag_mind_by_index(Player, Index),
	case is_record(MindInfo, ceil_state) of
		?false ->
			ErrorPacket = message_api:msg_notice(?TIP_MIND_BAD_ARG),
			misc_packet:send(NetPid, ErrorPacket),
			?error;
		?true ->
			case MindInfo#ceil_state.lock of
				?CONST_MIND_UNLOCK ->
					#ceil_state{mind_id = MindId, lv = MindLv} = MindInfo,
					Spirit = get_spirit_by_id(MindId, MindLv),
					{_, NewPlayer} = update_player_spirit(Player, Spirit),
					mind_mod:send_spirit_to_front(Player#player.user_id, Spirit),
					
					NewMindInfo = MindInfo#ceil_state{mind_id = 0, lv = 0},
					Player2 = mind_mod:update_bag_mind_by_index(NewPlayer, MindInfo#ceil_state.pos, NewMindInfo),
                    RecMind = data_mind:get_base_mind(MindId),
					if (RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score = get_score(Player2),
                            admin_log_api:log_mind(Player2, MindId, ?CONST_SYS_GOODS_USE, MindLv, 0, Score);
                       ?true ->
                            ?ok
                    end,
					{?ok, Spirit, MindId, Player2};
				?CONST_MIND_LOCK ->		%锁定位置不能转化
					ErrorPacket = message_api:msg_notice(?TIP_MIND_LOCK),
					misc_packet:send(NetPid, ErrorPacket),
					?error
			end
	end;
mind_absorb(Player = #player{net_pid = NetPid}, ?CONST_MIND_TYPE_TEMP_BAG, Index) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	TempMindBag	= Minds#mind_info.mind_bag_temp,
	MindInfo 	= mind_mod:get_temp_bag_mind_by_index(Player, Index),
	
	case is_record(MindInfo, ceil_temp) of
		?false ->
			ErrorPacket = message_api:msg_notice(?TIP_MIND_BAD_ARG),
			misc_packet:send(NetPid, ErrorPacket),
			?error;
		?true ->
			MindId 		= MindInfo#ceil_temp.mind_id,
			Spirit 		= get_spirit_by_id(MindId, 1),
			TempMindBag2= mind_mod:bag_temp_remove(TempMindBag, Index),
			Minds2		= Minds#mind_info{mind_bag_temp = TempMindBag2},
			PlayerMind2 = PlayerMind#mind_data{minds = Minds2},
			Player2		= Player#player{mind = PlayerMind2},
			{_, Player3} = update_player_spirit(Player2, Spirit),
			mind_mod:send_spirit_to_front(Player#player.user_id, Spirit),
			RecMind = data_mind:get_base_mind(MindId),
            if (RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                    Score = get_score(Player3),
                    admin_log_api:log_mind(Player3, MindId, ?CONST_SYS_GOODS_USE, 1, 0, Score);
               ?true ->
                   ?ok
            end,
			{?ok, Spirit, MindId, Player3}
	end.

%%一键吸收（转化灵力） 只有心法背包可以
mind_one_key_absorb(Player = #player{mind = PlayerMind}, Type) ->
	Minds 		= PlayerMind#mind_data.minds,
	MindBag		= Minds#mind_info.mind_bag,  %%背包格子心法列表
	case mind_mod:check_have_mind(MindBag) of
		?true ->
			{MindBag2, SpiritSum2} = do_one_key_absorb(Player, MindBag, Type, MindBag, 0),
%% 			?MSG_DEBUG("@@@MindBag2 ~p", [lists:sort(MindBag2)]),
			{MindBag3, Packet}	   = sort_one_key_absorb(MindBag2),
			misc_packet:send(Player#player.net_pid, Packet),
			
%% 			?MSG_DEBUG("@@@MindBag3 ~p", [lists:sort(MindBag3)]),
			Minds2 		= Minds#mind_info{mind_bag = MindBag3},
			PlayerMind2 = PlayerMind#mind_data{minds = Minds2},
			Player2 	= Player#player{mind = PlayerMind2},
			{_, Player3}= update_player_spirit(Player2, SpiritSum2),
			mind_mod:send_spirit_to_front(Player#player.user_id, SpiritSum2),
			
			{?ok, get_absorb_type(MindBag2, Type), Player3};
		?false ->
			?error
	end.

do_one_key_absorb(_Player, [], _Type, MindBag, SpiritSum) ->
	{MindBag, SpiritSum};
do_one_key_absorb(Player, [Mind = #ceil_state{mind_id = MindId, lv = MindLv}|T], Type, MindBag, SpiritSum) when MindId =/= 0 ->
	MindInfo = data_mind:get_base_mind(MindId),
	Color	 = MindInfo#rec_mind.quality,
	if	%普通吸收 跳过金色及以上心法
		Type =:= ?CONST_MIND_ABSORB_NORMAL andalso Color >= ?CONST_SYS_COLOR_YELLOW ->
			do_one_key_absorb(Player, T, Type, MindBag, SpiritSum);
		?true ->
			case Mind#ceil_state.lock of
				?CONST_MIND_UNLOCK ->
					Spirit 		= get_spirit_by_id(MindId, MindLv),
					MindInfo2 	= Mind#ceil_state{mind_id = 0, lv = 0},
					MindBag2  	= lists:keyreplace(MindInfo2#ceil_state.pos, #ceil_state.pos, MindBag, MindInfo2),
                    if (Color >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score       = get_score(Player),
                            admin_log_api:log_mind(Player, MindId, ?CONST_SYS_GOODS_USE, MindLv, 0, Score);
                       ?true ->
                            ?ok
                    end,
					do_one_key_absorb(Player, T, Type, MindBag2, SpiritSum+Spirit);
				?CONST_MIND_LOCK ->		%跳过锁定位置
					do_one_key_absorb(Player, T, Type, MindBag, SpiritSum)
			end
	end;
do_one_key_absorb(Player, [_Mind|T], Type, MindBag, SpiritSum) ->
	do_one_key_absorb(Player, T, Type, MindBag, SpiritSum).

%% #5816 一键转化后，要自动把锁定的星斗移动到前面的位置，有多个锁定的话就从第一个开始排序
sort_one_key_absorb(MindBag) ->
	UnlockList = lists:filter(fun(X) -> X#ceil_state.state =:= 1 
				 		andalso X#ceil_state.mind_id =/= 0 
				 		andalso X#ceil_state.lock =:= ?CONST_MIND_UNLOCK 
											 end, MindBag),
	LockList = lists:filter(fun(Y) -> Y#ceil_state.state =:= 1 
				 		andalso Y#ceil_state.mind_id =/= 0 
				 		andalso Y#ceil_state.lock =:= ?CONST_MIND_LOCK 
											 end, MindBag),
	RemainList = lists:filter(fun(Z) -> Z#ceil_state.state =/= 1 
						orelse Z#ceil_state.mind_id =:= 0 end, MindBag),
%% 	?MSG_ERROR("UnlockList ~p, LockList ~p, RemainList ~p", [UnlockList, LockList, RemainList]),
	sort_one_key_absorb(UnlockList, LockList, RemainList).

sort_one_key_absorb(UnlockList, LockList, RemainList) ->
	LockLen = erlang:length(LockList),
	UnlockLen = erlang:length(UnlockList),
	{LockList2, Packet}  = sort_bag_list(LockList, 1, 0, <<>>),
	{UnlockList2, Packet2} = sort_bag_list(UnlockList, LockLen+1, LockLen, Packet),
	{RemainList2, Packet3} = sort_bag_list(RemainList, LockLen+UnlockLen+1, LockLen+UnlockLen, Packet2),
%% 	?MSG_ERROR("UnlockList2 ~p, LockList2 ~p, RemainList2 ~p", [UnlockList2, LockList2, RemainList2]),
	{LockList2 ++ UnlockList2 ++ RemainList2, Packet3}.

sort_bag_list(List, Index, Len, Packet) when (Index - Len) > erlang:length(List) ->
	{List, Packet};
sort_bag_list(List, Index, Len, Packet) ->
%% 	?MSG_ERROR("List ~p, Index ~p, Len ~p", [List, Index, Len]),
	Ceil = lists:nth(Index-Len, List),
	Packet2 =
		case Ceil#ceil_state.state of
			1 ->
				mind_api:msg_mind_get_mind_by_pos_return(?CONST_MIND_TYPE_BAG, 0, 0, Index, 
														 Ceil#ceil_state.mind_id, Ceil#ceil_state.lv, Ceil#ceil_state.lock);
			0 ->
				<<>>
		end,
	List2 = lists:keyreplace(Ceil#ceil_state.pos, #ceil_state.pos, List, Ceil#ceil_state{pos = Index}),
%% 	?MSG_DEBUG("List2 ~p", [List2]),
	sort_bag_list(List2, Index+1, Len, <<Packet/binary, Packet2/binary>>).

%% 参阅秘籍
read_secret(Player = #player{net_pid = NetPid}, Pos, Type) when Type =:= ?CONST_MIND_READ_NORMAL orelse Type =:= ?CONST_MIND_READ_CASH ->
	case check_read_secret(Player, Pos, Type) of
		?ok ->
			read_secret_help(Player, Pos, Type);
		{?error, Reason} ->
			Packet = message_api:msg_notice(Reason),
			misc_packet:send(NetPid, Packet),
			?error
	end;
read_secret(Player, _Pos, _) ->
	Packet = message_api:msg_notice(?TIP_MIND_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	?error.

check_read_secret(#player{info = Info, mind = PlayerMind}, Pos, Type) ->
	Minds 		= PlayerMind#mind_data.minds,
	TempBag		= Minds#mind_info.mind_bag_temp,
	MindLearn 	= Minds#mind_info.mind_learn,
	Secret		= lists:keyfind(Pos, #secret_state.pos, MindLearn),
	VipKey		= get_vip_key(Type, Pos),
	
	try
		?ok		= check_read_secret_vip(VipKey, player_vip_api:get_mind_max_lv(player_api:get_vip_lv(Info))),
		?ok		= check_open_secret(Secret, Type),
		?ok		= check_cash_read_max(PlayerMind, Type, Pos),
		?ok		= check_temp_bag(TempBag)
	catch
		throw:Return ->
			Return;
		_A:_B ->
			{?error, 110}
	end.

%% 获得VIP相关类型 1普通 2地级 3天极
get_vip_key(?CONST_MIND_READ_NORMAL, _Pos) ->
	1;
get_vip_key(?CONST_MIND_READ_CASH, ?CONST_MIND_POS_3) ->
	2;
get_vip_key(?CONST_MIND_READ_CASH, ?CONST_MIND_POS_4) ->
	3.

%% 检查VIP
check_read_secret_vip(VipKey, Type) when Type >= VipKey ->
	?ok;
check_read_secret_vip(_VipKey, _Type) ->
	throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}).

%% 元宝参阅不需要秘籍开启才能参阅
check_open_secret(_Secret, ?CONST_MIND_READ_CASH) ->
	?ok;
check_open_secret(Secret, _Type) when is_record(Secret, secret_state)->
	case Secret#secret_state.state of
		?CONST_MIND_SECRET_OPEN ->
			?ok;
		?CONST_MIND_SECRET_CLOSE ->
			throw({?error, ?TIP_MIND_NOT_OPEN})
	end;
check_open_secret(_Secret, _Type) ->
	throw({?error, ?TIP_MIND_NOT_OPEN}).

%% 检查每日地级/天级元宝参阅上限
check_cash_read_max(PlayerMind, ?CONST_MIND_READ_CASH, ?CONST_MIND_POS_3) ->
	Ctimes = cash_times(PlayerMind, ?CONST_MIND_POS_3),
	case Ctimes > ?CONST_MIND_CASH_READ_MAX_A of
		?true ->
			throw({?error, ?TIP_MIND_READ_LIMIT});
		?false ->
			?ok
	end;
check_cash_read_max(PlayerMind, ?CONST_MIND_READ_CASH, ?CONST_MIND_POS_4) ->
	Ctimes = cash_times(PlayerMind, ?CONST_MIND_POS_4),
	case Ctimes > ?CONST_MIND_CASH_READ_MAX_B of
		?true ->
			throw({?error, ?TIP_MIND_READ_LIMIT});
		?false ->
			?ok
	end;
check_cash_read_max(_PlayerMind, ?CONST_MIND_READ_CASH, _Pos) ->
	throw({?error, ?TIP_COMMON_BAD_ARG});
check_cash_read_max(_PlayerMind, ?CONST_MIND_READ_NORMAL, _Pos) ->
	?ok.

check_temp_bag(TempBag) ->
	case mind_mod:check_bag_temp(TempBag) of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_MIND_TEMP_BAG_CEIL_NOT_ENOUGH})
	end.
			
read_secret_help(Player = #player{user_id = UserId, mind = PlayerMind, info = Info}, Pos, Type) ->
	Minds 			= PlayerMind#mind_data.minds,
	#mind_info{mind_learn = MindLearn, mind_bag_temp = TempBag, daily_free_times = TempFreeTimes} = Minds,
	
	Pos2			= real_pos(Type, Pos),
	MindSecret 		= data_mind:get_base_mind_secret(Pos2),
	#rec_mind_secret{cost = Cost, drop = Drops} = MindSecret,
	Drop 			= mind_mod:get_drop(Drops),
	{Player2, FreeTimes, MindDrop} 		= 
		case PlayerMind#mind_data.guide_finish =:= ?false andalso Type =:= ?CONST_MIND_READ_NORMAL of
			?true ->	%% 心法引导获得心法【地煞】
				GuideList 	 = Player#player.guide,
				[Module|_]	 = data_guide:get_guide(?CONST_MODULE_MIND),
			    NewGuideList = guide_api:finish_module(GuideList, Module),
			    Status 		 = Player#player{guide = NewGuideList},
				{Status, TempFreeTimes + 1, 2};
			?false ->
                Lv = Info#info.lv,
				{Player, TempFreeTimes, mind_mod:trans_drop_to_mind(Drop, Lv)}
		end,
	IsLearn 		= is_learn(MindSecret),
%% 	?MSG_DEBUG("read_secret:~p",[{Pos2, MindSecret, Cost, Drops, MindSecret, Drop, MindDrop, IsLearn}]),
	case (FreeTimes > 0 andalso Type =:= ?CONST_MIND_READ_NORMAL) of
		?true ->
			FreeTimes2 			= FreeTimes - 1,
			{BagTemp2, AddPos}	= mind_mod:bag_temp_add(TempBag, MindDrop),
			MindLearn2 			= mind_mod:set_learn(MindLearn, Pos, IsLearn),
			refresh_learn_list(UserId, PlayerMind, MindLearn2, FreeTimes2),
			Minds2				= Minds#mind_info{mind_bag_temp = BagTemp2, mind_learn = MindLearn2, daily_free_times = FreeTimes2},
			PlayerMind2 		= PlayerMind#mind_data{minds = Minds2, guide_finish = ?true},
			Player3 			= Player2#player{mind = PlayerMind2},
            Player4             = update_mind_score(Player3, Pos, Type),
            % 日志 
            MindDropRec         = data_mind:get_base_mind(MindDrop),
            if (MindDropRec#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                    Score = get_score(Player4),
                    admin_log_api:log_mind(Player4, MindDrop, ?CONST_SYS_GOODS_MAKE, 0, 1, Score);
               ?true ->
                   ?ok
            end,
            
			{?ok, MindDrop, AddPos, cash_times(PlayerMind, Pos), 0,  Player4};
		?false ->
			 % 后台日志的金钱消耗功能点
			case Type of
				?CONST_MIND_READ_NORMAL -> 	
					Point = 1, 
					CostType = ?CONST_SYS_GOLD_BIND, 
					Cost2 = Cost, 
					Ctimes = 0;
				?CONST_MIND_READ_CASH -> 	
					Point = 3, 
					CostType = ?CONST_SYS_CASH, 
					Ctimes = cash_times(PlayerMind, Pos), 
					Cost2 = 
						case Pos of
							?CONST_MIND_POS_3 ->
								Cost + 	?CONST_MIND_READ_CASH_1 * (Ctimes - 1);
							?CONST_MIND_POS_4 ->
								Cost + 	?CONST_MIND_READ_CASH_2 * (Ctimes - 1)
						end
			end,
			case player_money_api:minus_money(UserId, CostType, Cost2, (?CONST_LOG_MIND*100+Pos+Point)) of
				?ok ->
					{BagTemp2, AddPos}	= mind_mod:bag_temp_add(TempBag, MindDrop),
					{MindLearn2, ReturnCost3} 			= 
						case Type of
							?CONST_MIND_READ_NORMAL ->
								{mind_mod:set_learn(MindLearn, Pos, IsLearn), 0};
							?CONST_MIND_READ_CASH ->
								{MindLearn, Cost2}
						end,
					Minds2				= Minds#mind_info{mind_bag_temp = BagTemp2, mind_learn = MindLearn2, daily_free_times = FreeTimes},
					PlayerMind2 		= PlayerMind#mind_data{minds = Minds2, guide_finish = ?true},
					PlayerMind3			= update_player_mind(PlayerMind2, Type, Pos),
					refresh_learn_list(UserId, PlayerMind3, MindLearn2, FreeTimes),
					Player3 			= Player2#player{mind = PlayerMind3},
					read_mind_broadcast(Player3, MindDrop),
                    Player4             = update_mind_score(Player3, Pos, Type),
                    % 日志 
                    MindDropRec         = data_mind:get_base_mind(MindDrop),
                    if (MindDropRec#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score       = get_score(Player4),
                            admin_log_api:log_mind(Player4, MindDrop, ?CONST_SYS_GOODS_MAKE, 0, 1, Score);
                       ?true ->
                           ?ok
                    end,
					{?ok, MindDrop, AddPos, Ctimes, ReturnCost3, Player4};
				_Other ->
					?error
			end
	end.

update_mind_score(Player, Pos, ?CONST_MIND_READ_NORMAL) ->
    case data_mind:get_base_mind_secret(Pos) of
        #rec_mind_secret{score = Score} ->
            {Player2, _NewScore} = delta_score(Player, Score),
            Player2;
        _ ->
            Player
    end;
update_mind_score(Player, ?CONST_MIND_POS_3, ?CONST_MIND_READ_CASH) -> % 元宝星辰
    case data_mind:get_base_mind_secret(5) of
        #rec_mind_secret{score = Score} ->
            {Player2, _NewScore} = delta_score(Player, Score),
            Player2;
        _ ->
            Player
    end;
update_mind_score(Player, ?CONST_MIND_POS_4, ?CONST_MIND_READ_CASH) -> % 元宝元辰
    case data_mind:get_base_mind_secret(6) of
        #rec_mind_secret{score = Score} ->
            {Player2, _NewScore} = delta_score(Player, Score),
            Player2;
        _ ->
            Player
    end;
update_mind_score(Player, X, Y) -> % ?
    ?MSG_ERROR("x=[~p], y=[~p]", [X, Y]),
    Player.
    

cash_times(PlayerMind, ?CONST_MIND_POS_3) ->
	PlayerMind#mind_data.today_third_times + 1;
cash_times(PlayerMind, ?CONST_MIND_POS_4) ->
	PlayerMind#mind_data.today_fourth_times + 1;
cash_times(_, _) ->
	0.

%% 更新元宝祈天次数
update_player_mind(PlayerMind, ?CONST_MIND_READ_NORMAL, _Pos) ->
	PlayerMind;
update_player_mind(PlayerMind, ?CONST_MIND_READ_CASH, ?CONST_MIND_POS_3) ->
	Times = PlayerMind#mind_data.today_third_times,
	PlayerMind#mind_data{today_third_times = (Times + 1)};
update_player_mind(PlayerMind, ?CONST_MIND_READ_CASH, ?CONST_MIND_POS_4) ->
	Times = PlayerMind#mind_data.today_fourth_times,
	PlayerMind#mind_data{today_fourth_times = (Times + 1)}.

%% 真实的POS(用于获取mind_secret表中的KEY)
real_pos(?CONST_MIND_READ_NORMAL, Pos) ->
	Pos;
real_pos(?CONST_MIND_READ_CASH, Pos) ->
	Pos + 2.

%% 一键参阅 相当于替玩家连续点击铜钱参阅
one_key_read_secret(?CONST_MIND_READ_FINISH, Player, _Pos, ReturnList) ->
	{?ok, ReturnList, Player};
one_key_read_secret(?CONST_MIND_READ_UNFINISH, 
					Player = #player{user_id = UserId, info = Info, mind = PlayerMind, net_pid = NetPid}, Pos, ReturnList) ->
	Minds = PlayerMind#mind_data.minds,
	#mind_info{mind_learn = MindLearn, mind_bag_temp = TempBag, daily_free_times = FreeTimes} = Minds,
	case one_key_read_secret_check(player_api:get_vip_lv(Info), TempBag) of
		?ok ->
			Secret 	= data_mind:get_base_mind_secret(Pos),
			#rec_mind_secret{drop = Drops, cost = Cost} = Secret,
			Drop 	= mind_mod:get_drop(Drops),
            Lv      = Info#info.lv,
			MindDrop= mind_mod:trans_drop_to_mind(Drop, Lv),
			IsLearn = is_learn(Secret),
			Pos2 	= mind_mod:secret_add(Pos, IsLearn),
			case (FreeTimes > 0) of
				?true ->
					{BagTemp2, _AddPos} = mind_mod:bag_temp_add(TempBag, MindDrop),
					MindLearn2 			= mind_mod:set_learn(MindLearn, Pos, IsLearn),
					refresh_learn_list(UserId, PlayerMind, MindLearn2, FreeTimes-1),
					
					Minds2 				= Minds#mind_info{mind_bag_temp=BagTemp2, mind_learn = MindLearn2, daily_free_times = FreeTimes-1},
					PlayerMind2 		= PlayerMind#mind_data{minds=Minds2},
					Player2 			= Player#player{mind = PlayerMind2},
					ReturnList2 		= ReturnList ++ [{MindDrop, Pos2}],
					{?ok, Player3}	= schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_MIND),
                    Player4             = update_mind_score(Player3, Pos, ?CONST_MIND_READ_NORMAL),
                     % 日志 
                    MindDropRec         = data_mind:get_base_mind(MindDrop),
                    if (MindDropRec#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                            Score       = get_score(Player4),
                            admin_log_api:log_mind(Player4, MindDrop, ?CONST_SYS_GOODS_MAKE, 0, 1, Score);
                       ?true ->
                            ?ok
                    end,
					{?ok, Player5}      = new_serv_api:finish_achieve(Player4, ?CONST_NEW_SERV_MIND_GET, MindDropRec#rec_mind.quality, 1),
					yunying_activity_mod:activity_unlimitted_award(Player5,MindDropRec#rec_mind.quality,11),           %运营活动祈天获礼品检测
					one_key_read_secret(?CONST_MIND_READ_UNFINISH, Player5, Pos2, ReturnList2);
				?false ->
					case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Cost, (?CONST_LOG_MIND*100+Pos+1)) of
						?ok ->
							{BagTemp2, _AddPos} = mind_mod:bag_temp_add(TempBag, MindDrop),
							MindLearn2 			= mind_mod:set_learn(MindLearn, Pos, IsLearn),
							refresh_learn_list(UserId, PlayerMind, MindLearn2, FreeTimes),
							Minds2 				= Minds#mind_info{mind_bag_temp=BagTemp2, mind_learn = MindLearn2},
							PlayerMind2 		= PlayerMind#mind_data{minds=Minds2},
							Player2 			= Player#player{mind = PlayerMind2},
							ReturnList2 		= ReturnList ++ [{MindDrop, Pos2}], 
							read_mind_broadcast(Player2, MindDrop),
							{?ok, Player3}	= schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_MIND),
                            Player4             = update_mind_score(Player3, Pos, ?CONST_MIND_READ_NORMAL),
                            
                            % 日志 
                            MindDropRec         = data_mind:get_base_mind(MindDrop),
                            if (MindDropRec#rec_mind.quality >= ?CONST_SYS_COLOR_YELLOW) ->
                                    Score       = get_score(Player4),
                                    admin_log_api:log_mind(Player4, MindDrop, ?CONST_SYS_GOODS_MAKE, 0, 1, Score);
                               ?true ->
                                    ?ok
                            end,
                            {?ok, Player5}      = new_serv_api:finish_achieve(Player4, ?CONST_NEW_SERV_MIND_GET, MindDropRec#rec_mind.quality, 1),
							yunying_activity_mod:activity_unlimitted_award(Player5,MindDropRec#rec_mind.quality,11),           %运营活动祈天获礼品检测
							one_key_read_secret(?CONST_MIND_READ_UNFINISH, Player5, Pos2, ReturnList2);
						_Other ->
							one_key_read_secret(?CONST_MIND_READ_FINISH, Player, Pos, ReturnList)
					end
			end;
		{?error, Reason} ->
			case Reason of
				?TIP_COMMON_VIPLEVEL_NOT_ENOUGH ->
					Packet = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
					misc_packet:send(NetPid, Packet);
				?TIP_MIND_TEMP_BAG_CEIL_NOT_ENOUGH ->
					case (erlang:length(ReturnList) > 0) of
						?true ->
							skip;
						?false ->
							Packet = message_api:msg_notice(?TIP_MIND_TEMP_BAG_CEIL_NOT_ENOUGH),
							misc_packet:send(NetPid, Packet)
					end;
				_Other ->
					skip
			end,
			one_key_read_secret(?CONST_MIND_READ_FINISH, Player, Pos, ReturnList)
	end.

%% 一键参阅检查
one_key_read_secret_check(Vip, TempBag) ->
	try
		?ok = check_one_key_read_vip(Vip),
		?ok = check_temp_bag(TempBag)
	catch
		throw:Return ->
			Return;
		_:_ ->
			{?error, 110}
	end.

%% 一键参阅VIP检查
check_one_key_read_vip(Vip) ->
	case  player_vip_api:can_mind_one_key(Vip) of
		0 ->
			throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH});
		1 ->
			?ok
	end.

%% 拾取心法
mind_pick(Player, TempBagPos, IsConvert) ->
	case check_mind_pick(Player, TempBagPos) of
		?ok ->
			{NewPlayer, BagPos, MindId} = handle_mind_pick(Player, TempBagPos, IsConvert), 
			{?ok, BagPos, MindId, NewPlayer};
		{?error, Result} ->
			Packet = message_api:msg_notice(Result),
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end.
check_mind_pick(Player, TempBagPos) ->
	MindTempBag = get_temp_bag_mind_all(Player),
	MindBag = mind_mod:get_bag_mind(Player),
	IsEnoughBag = mind_mod:check_bag(MindBag),
	case mind_mod:get_bag_temp_ceil(MindTempBag, TempBagPos) of
		CeilTemp when is_record(CeilTemp, ceil_temp) ->
			if 
				CeilTemp#ceil_temp.mind_id =< 0 ->		%weird
					{?error, 0};
				IsEnoughBag =:= ?false ->
					{?error, ?TIP_MIND_BAG_CEIL_NOT_ENOUGH};
				?true ->
					?ok
			end
	end.
handle_mind_pick(Player, TempBagPos, ?CONST_MIND_PICK_CONVERT) ->
	MindTempBag 	= get_temp_bag_mind_all(Player),
	MindBag 		= mind_mod:get_bag_mind(Player),
	CeilTemp 		= mind_mod:get_bag_temp_ceil(MindTempBag, TempBagPos),
	MindId			= CeilTemp#ceil_temp.mind_id,
	case check_mind_color(MindId) of
		?true ->
			{NewMindBag, BagPos} = mind_mod:bag_add(MindBag, MindId),
		    NewBagTemp 		= mind_mod:bag_temp_remove(MindTempBag,TempBagPos),
			NewPlayer 		= mind_mod:update_mind_bag(Player, NewMindBag),
			
			NewPlayer2 		= mind_mod:update_mind_temp_bag(NewPlayer, NewBagTemp),
			{NewPlayer2, BagPos, CeilTemp#ceil_temp.mind_id};
		?false -> %金色以下直接转化 
			Spirit = get_spirit_by_id(MindId, 1),
			NewBagTemp 		= mind_mod:bag_temp_remove(MindTempBag, TempBagPos),
			NewPlayer 		= mind_mod:update_mind_temp_bag(Player, NewBagTemp),
			{_, NewPlayer2} = update_player_spirit(NewPlayer, Spirit),
			mind_mod:send_spirit_to_front(Player#player.user_id, Spirit),
			{NewPlayer2, 0, CeilTemp#ceil_temp.mind_id}
	end;
handle_mind_pick(Player, TempBagPos, _) ->
	MindTempBag 	= get_temp_bag_mind_all(Player),
	MindBag 		= mind_mod:get_bag_mind(Player),
	CeilTemp 		= mind_mod:get_bag_temp_ceil(MindTempBag, TempBagPos),
	MindId			= CeilTemp#ceil_temp.mind_id,
	{NewMindBag, BagPos} = mind_mod:bag_add(MindBag, MindId),
	NewBagTemp 		= mind_mod:bag_temp_remove(MindTempBag,TempBagPos),
	NewPlayer 		= mind_mod:update_mind_bag(Player, NewMindBag),
	
	NewPlayer2 		= mind_mod:update_mind_temp_bag(NewPlayer, NewBagTemp),
	{NewPlayer2, BagPos, CeilTemp#ceil_temp.mind_id}.

%%一键拾取心法
one_key_mind_pick(Player = #player{info = Info, mind = PlayerMind, net_pid = NetPid}, IsConvert) ->
	Type 			= player_vip_api:can_auto_trans_under_yellow(player_api:get_vip_lv(Info)),
	MindTempBag 	= get_temp_bag_mind_all(Player),
	MindBag 		= mind_mod:get_bag_mind(Player),
	Minds 			= PlayerMind#mind_data.minds,
	
	EmptyCeil 		= [Ceil || Ceil <- MindBag, Ceil#ceil_state.mind_id =:= 0 andalso Ceil#ceil_state.state =:= 1],
	EmptyCount 		= length(EmptyCeil),
	
	MindListTemp 	= [Ceil || Ceil <- MindTempBag, Ceil#ceil_temp.mind_id =/= 0],
	MindList 		= lists:reverse(MindListTemp),
	MindCount 		= length(MindList),
	MinCount 		= misc:min(EmptyCount, MindCount),
	
	case one_key_mind_pick_check(IsConvert, Type, MinCount, EmptyCount) of
		?ok ->
			{NewMinds, Spirit, ResultList} = one_key_mind_pick_help(Type*IsConvert, Minds, 0, EmptyCount, MindList, []),
			PlayerMind2 = PlayerMind#mind_data{minds = NewMinds},
			Player2 = Player#player{mind = PlayerMind2},
			{_, Player3} = update_player_spirit(Player2, Spirit),		%TODO 通知前端更新心力
			mind_mod:send_spirit_to_front(Player#player.user_id, Spirit),
			{?ok, Spirit, ResultList, Player3};
		{?error, Reason} ->
			Packet = message_api:msg_notice(Reason),
			misc_packet:send(NetPid, Packet),
			?error
	end.

%% 一键拾取心法检查
one_key_mind_pick_check(1, 0, _MinCount, _EmptyCount) ->														%勾选转化 但VIP等级不够
	{?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH};
one_key_mind_pick_check(_IsConvert, _Type, MinCount, EmptyCount) when MinCount =< 0 andalso EmptyCount =< 0 -> 	%临时背包已满
	{?error, ?TIP_MIND_BAG_CEIL_NOT_ENOUGH};
one_key_mind_pick_check(_IsConvert, _Type, MinCount, EmptyCount) when MinCount =< 0 andalso EmptyCount > 0 ->	%临时背包已满
	{?error, ?TIP_MIND_ALREADY_PICK};
one_key_mind_pick_check(_IsConvert, _Type, _MinCount, _EmptyCount) ->
	?ok.

one_key_mind_pick_help(_Type, Minds, Spirit, 0, _, Acc) ->		%背包已满	
	{Minds, Spirit, Acc};
one_key_mind_pick_help(_Type, Minds, Spirit, _, [], Acc) ->		%临时背包已空
	{Minds, Spirit, Acc};
one_key_mind_pick_help(Type, Minds, Spirit, EmptyCount, [CeilTemp|T], Acc) when Type =:= ?CONST_MIND_PICK_CONVERT ->	%勾选同时转化功能
	MindId  = CeilTemp#ceil_temp.mind_id,
	TempPos = CeilTemp#ceil_temp.pos,
	BagTemp = mind_mod:bag_temp_remove(Minds#mind_info.mind_bag_temp, TempPos),
	case check_mind_color(MindId) of
		?true ->		%金色以上心法 放入背包
			{Bag, Pos} = mind_mod:bag_add(Minds#mind_info.mind_bag, MindId),
			one_key_mind_pick_help(Type, Minds#mind_info{mind_bag = Bag, mind_bag_temp = BagTemp}, Spirit, EmptyCount-1, T, Acc++[{MindId, TempPos, Pos}]);
		?false ->		%金色以下心法 直接转化成灵力 
			Spirit2 = get_spirit_by_id(MindId, 1),
			one_key_mind_pick_help(Type, Minds#mind_info{mind_bag_temp = BagTemp}, Spirit+Spirit2, EmptyCount, T, Acc++[{MindId, TempPos, 0}])
	end;
one_key_mind_pick_help(Type, Minds, Spirit, EmptyCount, [CeilTemp|T], Acc) ->
	MindId  = CeilTemp#ceil_temp.mind_id,
	TempPos = CeilTemp#ceil_temp.pos,
	BagTemp = mind_mod:bag_temp_remove(Minds#mind_info.mind_bag_temp, TempPos),
	{Bag, Pos} = mind_mod:bag_add(Minds#mind_info.mind_bag, MindId),
	one_key_mind_pick_help(Type, Minds#mind_info{mind_bag = Bag, mind_bag_temp = BagTemp}, Spirit, EmptyCount-1, T, Acc++[{MindId, TempPos, Pos}]).
	
check_mind_color(MindId) ->
	RecMind = data_mind:get_base_mind(MindId),
	Color	= RecMind#rec_mind.quality,
	if
		Color >= ?CONST_SYS_COLOR_PURPLE -> % 改成紫色了
			?true;
		?true ->
			?false
	end.

%% 更新角色心法
update_player_spirit(Player = #player{mind = PlayerMind, net_pid = NetPid}, Spirit) ->
	case Spirit =/= 0 of
		?true ->
			Minds 		= PlayerMind#mind_data.minds,
			TempSpirit 	= misc:uint(Minds#mind_info.spirit + Spirit),
			NewSpirit   = real_spirit(TempSpirit),
			NewPlayer 	= mind_mod:update_mind_spirit(Player, NewSpirit),
			
			Packet 		= misc_packet:pack(?MSG_ID_MIND_UPDATE_SPIRIT, ?MSG_FORMAT_MIND_UPDATE_SPIRIT, {NewSpirit}),
			case (Spirit >= 0) of
				?true ->
					TipPacket	= message_api:msg_notice(?TIP_MIND_CHANGE_SPIRIT, [{100, misc:to_list(Spirit)}]),
					misc_packet:send(NetPid, <<Packet/binary, TipPacket/binary>>);
				?false ->
					misc_packet:send(NetPid, Packet)
			end,
			{NewSpirit, NewPlayer};
		?false ->
			{Spirit, Player}
	end.

real_spirit(Spirit) when Spirit >= ?CONST_SYS_MAX_SPIRIT ->
	?CONST_SYS_MAX_SPIRIT;
real_spirit(Spirit) ->
	Spirit.

%% 心法交换位置  背包内交换
mind_exchange(Player, ?CONST_MIND_EX_TYPE_INNER, UserType, UserId, SourcePos, DestPos) ->
	{_, Result, NewMindBag} = mind_mod:exchange_mind_bag(Player, SourcePos, DestPos),
	case Result of
		1 ->
			NewPlayer = mind_mod:update_mind_bag(Player, NewMindBag),
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_BAG, UserType, UserId, SourcePos),
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_BAG, UserType, UserId, DestPos),
			{?ok, NewPlayer};
		_Other ->
			?error
	end;
%% 装备区内交换
mind_exchange(Player, ?CONST_MIND_EX_TYPE_EQUIP, UserType, UserId, SourcePos, DestPos) ->
	{_, Result, NewMindUses} = mind_mod:exchange_mind_equip(Player, UserType, UserId, SourcePos, DestPos),
	case Result of
		1 ->
			PlayerMind = Player#player.mind,
			NewPlayerMind = PlayerMind#mind_data{mind_uses = NewMindUses},
			NewPlayer = Player#player{mind = NewPlayerMind},
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, SourcePos),
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, DestPos),
			{?ok, NewPlayer};
		_Other ->
			?error
	end;
%% 背包到装备 装载心法
mind_exchange(Player, ?CONST_MIND_EX_TYPE_BAG2EQUIP, UserType, UserId, SourcePos, DestPos) ->
	{_, Result, NewPlayer} = mind_mod:exchange_bag_to_equip(Player, SourcePos, DestPos, UserId, UserType),
	case Result of
		1 ->
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_BAG, UserType, UserId, SourcePos),
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, DestPos),
			%% 更新心法变动带来的人物属性变动
			NewPlayer2 = exchange_refresh_attr(NewPlayer, UserId, UserType),
			% 刷新人物心力
			{_UserSpirit, NewPlayer3} = mind_mod:send_calc_user_spirit(NewPlayer2, UserId, UserType),
			{?ok, NewPlayer4} = achievement_api:add_achievement(NewPlayer3, ?CONST_ACHIEVEMENT_EQUIP_STAR, 0, 1),
            schedule_power_api:do_change_mind(NewPlayer4, UserType, UserId),
%% 			{?ok, NewPlayer5} = achievement_api:add_achievement(NewPlayer4, ?CONST_ACHIEVEMENT_STAR_FORCE, UserSpirit, 1),
			{?ok, NewPlayer4};
		_Other ->
			?error
	end;
%% 装备到背包 卸载心法
mind_exchange(Player, ?CONST_MIND_EX_TYPE_EQUIP2BAG, UserType, UserId, SourcePos, DestPos) ->
	{_, Result, NewPlayer} = mind_mod:exchange_equip_to_bag(Player, DestPos, SourcePos, UserId, UserType),
	case Result of
		1 ->
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_BAG, UserType, UserId, DestPos),
			update_per_mind(NewPlayer, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, SourcePos),
			%% 更新心法变动带来的人物属性变动
			NewPlayer2 = exchange_refresh_attr(NewPlayer, UserId, UserType),
			% 刷新人物心力
			{_, NewPlayer3} = mind_mod:send_calc_user_spirit(NewPlayer2, UserId, UserType),
            schedule_power_api:do_change_mind(NewPlayer3, UserType, UserId),
			{?ok, NewPlayer3};
		_Other ->
			?error
	end;
%% 干嘛？
mind_exchange(_Player, _, _UserType, _UserId, _SourcePos, _DestPos) ->
	?error.

%% 更新心法变动带来的人物属性变动
exchange_refresh_attr(Player, _UserId, ?CONST_MIND_TYPE_PLAYER) ->
	player_attr_api:refresh_attr_mind(Player);
exchange_refresh_attr(Player, UserId, ?CONST_MIND_TYPE_PARTNER) ->
	partner_api:refresh_attr_mind(Player, UserId);
exchange_refresh_attr(Player, _UserId, _) ->
	Player.

%% 扩展背包
extend_mind_bag(Player = #player{mind = PlayerMind, info = Info}, Multiple) ->
	Minds 		= PlayerMind#mind_data.minds,
	MindBag 	= Minds#mind_info.mind_bag,
	OldOpenNum 	= mind_mod:check_bag_open(MindBag),
	OldRowNum	= OldOpenNum div ?CONST_MIND_PER_EXTEND_NUM,
	case check_extend_mind_bag(MindBag, player_api:get_vip_lv(Info), Multiple, OldRowNum) of
		{?ok, Multiple2} ->
			case handle_extend_mind_bag(Player, MindBag, Multiple2) of
				{?ok, NewPlayer, NewMindBag} ->
					NewOpenNum = mind_mod:check_bag_open(NewMindBag),
					{?ok, NewOpenNum, NewPlayer};
				?error ->
					?error
			end;
		{?error, Result} ->
			Packet = message_api:msg_notice(Result),
			misc_packet:send(Player#player.user_id, Packet),
			?error
	end.

%% 检查扩展背包
check_extend_mind_bag(MindBag, Vip, Multiple, OldRowNum) ->
	try
		?ok = check_vip(Vip),
		?ok = check_empty_ceil(MindBag, Multiple, OldRowNum)
	catch
		throw:Return ->
			Return;
		_:_ ->
			{?error, 110}
	end.

%% 检查VIP
check_vip(Vip) ->
	case player_vip_api:can_mind_extend_bag(Vip) of
		1 ->
			?ok;
		0 ->
			throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH})
	end.

%% 检查背包空间
check_empty_ceil(_MindBag, Multiple, OldRowNum) ->
	if
		Multiple =/= 1 andalso Multiple =/= 2 andalso Multiple =/= 3 ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		OldRowNum >= (Multiple + 2) ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		?true ->
			throw({?ok, Multiple+2-OldRowNum})
	end.
%% 	IsEnoughOpen = mind_mod:check_have_bag_to_open(MindBag),
%% 	case IsEnoughOpen of
%% 		?true ->
%% 			?ok;
%% 		?false ->
%% 			if
%% 				(Multiple + OldRowNum) > 5
%% 			throw({?error, ?TIP_MIND_BAG_CEIL_NOT_ENOUGH})
%% 	end.

%% 执行扩展背包
handle_extend_mind_bag(Player, MindBag, Multiple) ->
	case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, ?CONST_MIND_PER_EXTEND_COST * Multiple, ?CONST_COST_MIND_EXTEND_BAG) of
		?ok ->
			NewMindBag = mind_mod:add_bag_ceil_help(MindBag, Multiple),
			NewPlayer = mind_mod:update_mind_bag(Player, NewMindBag),
			{?ok, NewPlayer, NewMindBag};
		_ ->
			?error
	end.

%% 通知前端更新装备或者背包的心法信息
update_per_mind(Player = #player{net_pid = NetPid}, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, Pos) ->
	case catch mind_mod:get_user_mind_by_index(Player, UserType, UserId, Pos) of
		Ceil when is_record(Ceil, ceil_state) ->
			MindId 	= Ceil#ceil_state.mind_id,
			MindLv 	= Ceil#ceil_state.lv,
			Lock	= Ceil#ceil_state.lock,
			Packet 	= mind_api:msg_mind_get_mind_by_pos_return(?CONST_MIND_TYPE_EQUIP, UserType, UserId, Pos, MindId, MindLv, Lock),
			misc_packet:send(NetPid, Packet),
			?ok;
		Other ->
			?MSG_ERROR("fail with mind equip pos ~p, ceil ~p", [Pos, Other]),
			?ok
	end;
update_per_mind(Player = #player{net_pid = NetPid}, ?CONST_MIND_TYPE_BAG, UserType, UserId, Pos) ->
	case catch mind_mod:get_bag_mind_by_index(Player, Pos) of
		Ceil when is_record(Ceil, ceil_state) ->
			MindId 	= Ceil#ceil_state.mind_id,
			MindLv 	= Ceil#ceil_state.lv,
			Lock	= Ceil#ceil_state.lock,
			Packet 	= mind_api:msg_mind_get_mind_by_pos_return(?CONST_MIND_TYPE_BAG, UserType, UserId, Pos, MindId, MindLv, Lock),
			misc_packet:send(NetPid, Packet),
			?ok;
		Other ->
			?MSG_ERROR("fail with bag pos ~p, ceil ~p", [Pos, Other]),
			?ok
	end.

%% 更改背包格子的锁定状态
change_ceil_state(Player, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, Pos) ->
	PlayerMind = Player#player.mind,
	MindUses = PlayerMind#mind_data.mind_uses,
	[MindUse] = lists:filter(fun(X) -> X#mind_use.type =:= UserType andalso X#mind_use.user_id =:= UserId end, MindUses),
	case is_record(MindUse, mind_use) of
		?true ->
			Ceil = mind_mod:get_user_mind_by_index(Player, UserType, UserId, Pos),
			case is_record(Ceil, ceil_state) of 
				?false ->
%% 					?MSG_DEBUG("@@@@@@@@@@@@  ~p", [Ceil]),
					?error;
				?true ->
					Ceil2		 	= negate(Ceil),
%% 					?MSG_DEBUG("@@@@@@@@@@@@ Ceil ~p, Ceil2 ~p", [Ceil, Ceil2]),
					NewMindUseList 	= lists:keyreplace(Pos, #ceil_state.pos, MindUse#mind_use.mind_use_info, Ceil2),		
					NewMindUse 		= MindUse#mind_use{mind_use_info=NewMindUseList},				%%更新单个角色的心法信息
					
					NewMindUses 	= lists:keyreplace(MindUse#mind_use.index, #mind_use.index, MindUses, NewMindUse),		
					NewPlayerMind 	= PlayerMind#mind_data{mind_uses = NewMindUses},				%%更新所有心法使用的数据结构
					NewPlayer		= Player#player{mind = NewPlayerMind},
					update_per_mind(NewPlayer, ?CONST_MIND_TYPE_EQUIP, UserType, UserId, Pos),
					{?ok, NewPlayer}
			end;
		?false ->
			Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),	%TODO 锁定格子失败
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end;
change_ceil_state(Player, ?CONST_MIND_TYPE_BAG, _UserType, _UserId, Pos) ->
	PlayerMind = Player#player.mind,
	Minds = PlayerMind#mind_data.minds,
	MindBag	= Minds#mind_info.mind_bag,
	case lists:keyfind(Pos, #ceil_state.pos, MindBag) of
		?false ->
			Packet = message_api:msg_notice(0),	%TODO 锁定格子失败
			misc_packet:send(Player#player.net_pid, Packet),
			?error;
		Ceil ->
			Ceil2 = negate(Ceil),
			?MSG_DEBUG("Ceil ~p, Ceil2 ~p", [Ceil , Ceil2]),
			MindBag2 = lists:keyreplace(Ceil2#ceil_state.pos, #ceil_state.pos, MindBag, Ceil2),
			Minds2		= Minds#mind_info{mind_bag = MindBag2},
			PlayerMind2	= PlayerMind#mind_data{minds = Minds2},
			Player2 	= Player#player{mind = PlayerMind2},
			update_per_mind(Player2, ?CONST_MIND_TYPE_BAG, ?CONST_SYS_PLAYER, Player#player.user_id, Pos),
			{?ok, Player2}
	end;
change_ceil_state(Player, _, _UserType, _UserId, _Pos) ->
	Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	?error.

negate(Ceil) when Ceil#ceil_state.lock =:= ?CONST_MIND_LOCK ->
	Ceil#ceil_state{lock = ?CONST_MIND_UNLOCK};
negate(Ceil) when Ceil#ceil_state.lock =:= ?CONST_MIND_UNLOCK ->
	Ceil#ceil_state{lock = ?CONST_MIND_LOCK}.

%% 获取角色装备的心力和
get_user_mind_sum(Player, ?CONST_MIND_TYPE_PLAYER, _UserId) ->
	MindList = mind_mod:get_user_mind_list(Player, ?CONST_MIND_TYPE_PLAYER, 0),
	mind_mod:calc_user_spirit_help(MindList);
get_user_mind_sum(Player, ?CONST_MIND_TYPE_PARTNER, UserId) ->
	MindList = mind_mod:get_user_mind_list(Player, ?CONST_MIND_TYPE_PARTNER, UserId),
	mind_mod:calc_user_spirit_help(MindList).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   协议
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 玩家心法列表返回
%%[Type,UserId,UserType,MindOpenNum,{MindId,MindLv,MindPos}]
msg_mind_list_return(Type,UserId,UserType,MindOpenNum,List1) ->
	misc_packet:pack(?MSG_ID_MIND_LIST_RETURN, ?MSG_FORMAT_MIND_LIST_RETURN, [Type,UserId,UserType,MindOpenNum,List1]).
%% 参阅状态列表返回
%%[FreeTime,Pos3Times,Pos4Times,{MindStatus,MindPos}]
msg_mind_read_list_return(FreeTime,Pos3Times,Pos4Times,List1) ->
	misc_packet:pack(?MSG_ID_MIND_READ_LIST_RETURN, ?MSG_FORMAT_MIND_READ_LIST_RETURN, [FreeTime,Pos3Times,Pos4Times,List1]).
%% 心法升级返回
%%[Result,SpiritChange]
msg_mind_upgrade_return(Result,SpiritChange) ->
	misc_packet:pack(?MSG_ID_MIND_UPGRADE_RETURN, ?MSG_FORMAT_MIND_UPGRADE_RETURN, [Result,SpiritChange]).
%% 心法吸收返回
%%[Result,Spirit,Pos]
msg_mind_absorb_return(Result, Type, Pos) ->
	misc_packet:pack(?MSG_ID_MIND_ABSORB_RETURN, ?MSG_FORMAT_MIND_ABSORB_RETURN, [Result, Type, Pos]).
%% 一键吸收返回
%%[Result,Spirit]
msg_mind_one_key_absorb_return(Result,Type) ->
	misc_packet:pack(?MSG_ID_MIND_ONE_KEY_ABSORB_RETURN, ?MSG_FORMAT_MIND_ONE_KEY_ABSORB_RETURN, [Result,Type]).
%% 参阅秘籍返回
%%[Result,MindId,Pos,Ctimes]
msg_mind_read_secret_return(Result,MindId,Pos, Cost) ->
	misc_packet:pack(?MSG_ID_MIND_READ_SECRET_RETURN, ?MSG_FORMAT_MIND_READ_SECRET_RETURN, [Result,MindId,Pos, Cost]).
%% 一键参阅返回
%%[Result,{MindId,Pos}]
msg_mind_one_key_read_return(Result,List1) ->
	misc_packet:pack(?MSG_ID_MIND_ONE_KEY_READ_RETURN, ?MSG_FORMAT_MIND_ONE_KEY_READ_RETURN, [Result,List1]).
%% 扩展背包返回
%%[Result,NewNum]
msg_mind_extern_bag_return(Result,NewNum) ->
	misc_packet:pack(?MSG_ID_MIND_EXTERN_BAG_RETURN, ?MSG_FORMAT_MIND_EXTERN_BAG_RETURN, [Result,NewNum]).
%% 获取临时背包返回
%%[{MindId}]
msg_mind_temp_bag_list_return(List1) ->
	misc_packet:pack(?MSG_ID_MIND_TEMP_BAG_LIST_RETURN, ?MSG_FORMAT_MIND_TEMP_BAG_LIST_RETURN, [List1]).
%% 拾取心法返回
%%[Result,TempBagPos,BagPos,MindId]
msg_mind_pick_result(Result,TempBagPos,BagPos,MindId) ->
	misc_packet:pack(?MSG_ID_MIND_PICK_RESULT, ?MSG_FORMAT_MIND_PICK_RESULT, [Result,TempBagPos,BagPos,MindId]).
%% 一键拾取返回
%%[Result,{MindId,TempBagPos,BagPos}]
msg_mind_one_key_pick_result(Result,Spirit,List1) ->
	misc_packet:pack(?MSG_ID_MIND_ONE_KEY_PICK_RESULT, ?MSG_FORMAT_MIND_ONE_KEY_PICK_RESULT, [Result,Spirit,List1]).
%% 交换心法位置返回(包含装备卸载)
%%[Result]
msg_mind_exchange_result(Result) ->
	misc_packet:pack(?MSG_ID_MIND_EXCHANGE_RESULT, ?MSG_FORMAT_MIND_EXCHANGE_RESULT, [Result]).
%% 更新心法信息返回
%%[Type,UserType,UserId,Pos,MindId,MindLv]
msg_mind_get_mind_by_pos_return(Type,UserType,UserId,Pos,MindId,MindLv,Lock) ->
	misc_packet:pack(?MSG_ID_MIND_GET_MIND_BY_POS_RETURN, ?MSG_FORMAT_MIND_GET_MIND_BY_POS_RETURN, [Type,UserType,UserId,Pos,MindId,MindLv,Lock]).
%% 更新灵力值
%%[NewSpirit]
msg_update_spirit(NewSpirit) ->
	misc_packet:pack(?MSG_ID_MIND_UPDATE_SPIRIT, ?MSG_FORMAT_MIND_UPDATE_SPIRIT, [NewSpirit]).
	
%% 更新免费参阅次数
%%[NewTimes]
msg_update_free_times(NewTimes) ->
	misc_packet:pack(?MSG_ID_MIND_UPDATE_FREE_TIMES, ?MSG_FORMAT_MIND_UPDATE_FREE_TIMES, [NewTimes]).
%% 更新祈天积分
%%[Score]
msg_sc_update_score(Score) ->
    misc_packet:pack(?MSG_ID_MIND_SC_UPDATE_SCORE, ?MSG_FORMAT_MIND_SC_UPDATE_SCORE, [Score]).


%%
%% Local Functions
%%
read_mind_broadcast(Player, MindId) ->
	Info = Player#player.info,
	RecMind = data_mind:get_base_mind(MindId),
	if 
%% 		RecMind#rec_mind.quality =:= ?CONST_SYS_COLOR_PURPLE ->
%% 		   Packet = message_api:msg_notice(?TIP_MIND_READ_BROADCAST2, [{Player#player.user_id, Info#info.user_name}], [], 
%% 								   [{?TIP_SYS_MIND, misc:to_list(MindId)}, {?TIP_SYS_OPEN_PANEL, misc:to_list("前往祈天")}]),	%TODO前往祈天 待定
%% 		   misc_app:broadcast_world_2(Packet);
	   
	   RecMind#rec_mind.quality > ?CONST_SYS_COLOR_PURPLE ->
		   Packet = message_api:msg_notice(?TIP_MIND_READ_BROADCAST, [{Player#player.user_id, Info#info.user_name}], [], 
								   [{?TIP_SYS_MIND, misc:to_list(MindId)}, {?TIP_SYS_OPEN_PANEL, misc:to_list(<<229,137,141,229,190,128,231,165,136,229,164,169>>)}]),	%TODO前往祈天 待定
		   misc_app:broadcast_world_2(Packet);
	   ?true ->
		   ?ok
	end.

%% 是否可以参阅下级心法
is_learn(MindSecret) ->
	mind_mod:check_rand(MindSecret#rec_mind_secret.rate).

%% 获取一键转化类型 1普通 2强制
get_absorb_type(Bag, Type) ->
	List = List = [Ceil || Ceil <- Bag, Ceil#ceil_state.state =:= 1],											%开启的数量
	List2 = [Ceil || Ceil <- Bag, Ceil#ceil_state.mind_id =:= 0 andalso Ceil#ceil_state.state =:= 1],			%开启&空格子
	List3 = [Ceil || Ceil <- Bag, Ceil#ceil_state.lock =:= 1],													%锁定的心法数量
	
	?MSG_DEBUG("Alll ~p, Null ~p, Lock ~p", [length(List), length(List2), length(List3)]),
	if
		length(List) =< (length(List2) + length(List3)) ->
			?CONST_MIND_ABSORB_FORCE;
		?true ->
			Type
	end.

%% 刷新参阅状态
refresh_learn_list(UserId, PlayerMind, LearnList, Times) ->
	Fun = fun(X) ->
				  {X#secret_state.state, X#secret_state.pos}
		  end,
	LearnList2 	= lists:map(Fun, LearnList),
	Pos3Times	= PlayerMind#mind_data.today_third_times,
	Pos4Times	= PlayerMind#mind_data.today_fourth_times,
	Datas 		= {Times, Pos3Times, Pos4Times, LearnList2},
	Packet 		= misc_packet:pack(?MSG_ID_MIND_READ_LIST_RETURN, ?MSG_FORMAT_MIND_READ_LIST_RETURN, Datas),
	misc_packet:send(UserId, Packet).

%% 读取积分
get_score(#mind_data{minds = #mind_info{score = Score}}) ->
    Score;
get_score(#mind_info{score = Score}) ->
    Score;
get_score(#player{mind = #mind_data{minds = #mind_info{score = Score}}}) ->
    Score;
get_score(X) ->
    ?MSG_ERROR("x=[~p]", [X]),
    0.

%% 设置积分
set_score(MindData, Score) when is_record(MindData, mind_data) ->
    MindInfo  = MindData#mind_data.minds,
    MindInfo2 = 
        if Score < 0 ->
               MindInfo#mind_info{score = 0};
           Score > ?CONST_MIND_MAX_SCORE ->
               MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE};
           ?true ->
               MindInfo#mind_info{score = Score}
        end,
    MindData#mind_data{minds = MindInfo2};
set_score(MindInfo, Score) when is_record(MindInfo, mind_info) ->
    if Score < 0 ->
           MindInfo#mind_info{score = 0};
       Score > ?CONST_MIND_MAX_SCORE ->
           MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE};
       ?true ->
           MindInfo#mind_info{score = Score}
    end;
set_score(Player, Score) when is_record(Player, player) ->
    MindData = Player#player.mind,
    MindInfo = MindData#mind_data.minds,
    MindInfo2 = 
        if Score < 0 ->
               MindInfo#mind_info{score = 0};
           Score > ?CONST_MIND_MAX_SCORE ->
               MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE};
           ?true ->
               MindInfo#mind_info{score = Score}
        end,
    MindData2 = MindData#mind_data{minds = MindInfo2},
    Player#player{mind = MindData2};
set_score(X, Y) ->
    ?MSG_ERROR("x=[~p], y=[~p]", [X, Y]),
    X.

%% 修改积分
delta_score(MindData, Score) when is_record(MindData, mind_data) ->
    MindInfo = MindData#mind_data.minds,
    OldScore = MindInfo#mind_info.score,
    NewScore = OldScore + Score,
    {MindInfo2, NewScore2} = 
        if(NewScore < 0) ->
              {MindInfo#mind_info{score = 0}, 0};
          (NewScore > ?CONST_MIND_MAX_SCORE) ->
              {MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE}, ?CONST_MIND_MAX_SCORE};
          ?true ->
              {MindInfo#mind_info{score = NewScore}, NewScore}
        end,
    {MindData#mind_data{minds = MindInfo2}, NewScore2};
delta_score(MindInfo, Score) when is_record(MindInfo, mind_info) ->
    OldScore = MindInfo#mind_info.score,
    NewScore = OldScore + Score,
    if(NewScore < 0) ->
          {MindInfo#mind_info{score = 0}, 0};
      (NewScore > ?CONST_MIND_MAX_SCORE) ->
              {MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE}, ?CONST_MIND_MAX_SCORE};
      ?true ->
          {MindInfo#mind_info{score = NewScore}, NewScore}
    end;
delta_score(Player, Score) when is_record(Player, player) ->
    MindData = Player#player.mind,
    MindInfo = MindData#mind_data.minds,
    OldScore = MindInfo#mind_info.score,
    NewScore = OldScore + Score,
    {MindInfo2, NewScore2} = 
        if(NewScore < 0) ->
              {MindInfo#mind_info{score = 0}, 0};
          (NewScore > ?CONST_MIND_MAX_SCORE) ->
              {MindInfo#mind_info{score = ?CONST_MIND_MAX_SCORE}, ?CONST_MIND_MAX_SCORE};
          ?true ->
              {MindInfo#mind_info{score = NewScore}, NewScore}
        end,
    MindData2 = MindData#mind_data{minds = MindInfo2},
    {Player#player{mind = MindData2}, NewScore2};
delta_score(X, Y) ->
    ?MSG_ERROR("x=[~p], y=[~p]", [X, Y]),
    {X, 0}.
    
%% 兑换心法
exchange(Player, MindId) ->
    BeforeBuyScore = get_score(Player),
    case data_mind:get_base_mind_shop(MindId) of
        #rec_mind_shop{score = NeedScore} when NeedScore =< BeforeBuyScore ->
            MindBag = mind_mod:get_bag_mind(Player),
            IsEnoughBag = mind_mod:check_bag(MindBag),
            if IsEnoughBag =:= ?false ->
                PacketErr = message_api:msg_notice(?TIP_MIND_BAG_CEIL_NOT_ENOUGH),
                misc_packet:send(Player#player.user_id, PacketErr),
                Player;
            ?true ->
                {Player2, AfterBuyScore} = delta_score(Player, -1*NeedScore),
                ScorePacket              = msg_sc_update_score(AfterBuyScore),
                {NewMindBag, BagPos}     = mind_mod:bag_add(MindBag, MindId),
                Player3                  = mind_mod:update_mind_bag(Player2, NewMindBag),
                admin_log_api:log_mind(Player3, MindId, ?CONST_SYS_GOODS_MAKE, 0, 1, AfterBuyScore),
                Packet = msg_mind_get_mind_by_pos_return(?CONST_MIND_TYPE_BAG,?CONST_SYS_PLAYER,
                                                         Player#player.user_id,BagPos,MindId,1,?CONST_SYS_FALSE),
                OkPacket = message_api:msg_notice(?TIP_MIND_EXCHANGE_OK),
                misc_packet:send(Player#player.net_pid, <<ScorePacket/binary, Packet/binary, OkPacket/binary>>),
                Player3
            end;
        X when is_record(X, rec_mind_shop) ->
            PacketErr = message_api:msg_notice(?TIP_MIND_SCORE_NOT_ENOUGH),
            misc_packet:send(Player#player.user_id, PacketErr),
            Player;
        _ ->
            PacketErr = message_api:msg_notice(?TIP_MIND_MIND_NOT_EXIST),
            misc_packet:send(Player#player.user_id, PacketErr),
            Player
    end.
            
check_bag(MindBag) ->
    mind_mod:check_bag(MindBag).