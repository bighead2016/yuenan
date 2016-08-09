%% Author: php
%% Created: 2012-08-13 14
%% Description: 心法协议处理  TODO 操作失败不需要返回给前端协议
-module(mind_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 玩家装备心法列表
handler(?MSG_ID_MIND_LIST, Player = #player{net_pid = NetPid}, {Type,UserId,UserType}) ->
	MindUses = 
		case Type of
			1 ->
				MindUse = mind_api:get_user_mind_all(Player, UserType, UserId),
				MindUse#mind_use.mind_use_info;
			2 ->
				mind_api:get_mind_bag_list(Player)
		end,
	
	Fun = fun(X, ReturnList) ->
				  if
					  X#ceil_state.state =:= 1 ->
						  ReturnList ++ [{X#ceil_state.mind_id, X#ceil_state.lv, X#ceil_state.pos, X#ceil_state.lock}];
					  ?true ->
						  ReturnList
				  end
		  end,
	MindList = lists:foldl(Fun, [], MindUses),
	Packet = mind_api:msg_mind_list_return(Type, UserId, UserType, length(MindList), MindList),
	misc_packet:send(NetPid, Packet),
	?ok;

%% 获取参阅状态列表
handler(?MSG_ID_MIND_READ_LIST, Player = #player{net_pid = NetPid}, {}) ->
	{FreeTimes, Pos3Times, Pos4Times, MindLearn} = mind_api:get_mind_learn_list(Player),
	Fun = fun(X) ->
				  {X#secret_state.state, X#secret_state.pos}
		  end,
	MindLearnList = lists:map(Fun, MindLearn),
	Packet = mind_api:msg_mind_read_list_return(FreeTimes, Pos3Times, Pos4Times, MindLearnList),
	misc_packet:send(NetPid, Packet),
	?ok;

%% 心法升级
handler(?MSG_ID_MIND_UPGRADE, Player = #player{net_pid = NetPid}, {UserId,UserType,Type,Pos}) -> 
	case mind_api:mind_upgrade(Player,UserType,UserId,Type,Pos) of
		{?ok, NewLv, SpiritChange, NewPlayer} ->
			mind_api:update_per_mind(NewPlayer, Type, UserType, UserId, Pos),  %%升级成功，通知前端刷新心法格子
			Packet = mind_api:msg_mind_upgrade_return(?CONST_MIND_OK, SpiritChange),
			misc_packet:send(NetPid, Packet),
			{_, Player2} = mind_mod:treat_mind_lv_achievement(NewPlayer, NewLv),
			{?ok, Player2};
		?error ->
			?error
	end;

%% 心法转化(转化灵力)
handler(?MSG_ID_MIND_ABSORB, Player = #player{net_pid = NetPid}, {Type, Pos}) ->
	case mind_api:mind_absorb(Player, Type, Pos) of
		{?ok, _Spirit, _MindId, NewPlayer} ->
			{?ok, NewPlayer2} = achievement_api:add_achievement(NewPlayer, ?CONST_ACHIEVEMENT_TRANSFORM_STAR, 0, 1),
			Packet = mind_api:msg_mind_absorb_return(?CONST_MIND_OK, Type, Pos),
			misc_packet:send(NetPid, Packet),
			{?ok, NewPlayer2};
		?error ->
			?error
	end;
%% 一键转化
handler(?MSG_ID_MIND_ONE_KEY_ABSORB, Player = #player{net_pid = NetPid}, {_Type}) ->
	case mind_api:mind_one_key_absorb(Player, ?CONST_MIND_ABSORB_FORCE) of
		{?ok, Type2, NewPlayer} ->
			{?ok, Player2} = achievement_api:add_achievement(NewPlayer, ?CONST_ACHIEVEMENT_TRANSFORM_STAR, 0, 1),
			Packet = mind_api:msg_mind_one_key_absorb_return(?CONST_MIND_OK, Type2),
			TipPacket = message_api:msg_notice(?TIP_MIND_ALL_ABSORB),
			misc_packet:send(NetPid, <<Packet/binary, TipPacket/binary>>),
			{?ok, Player2};
		?error ->
			?error
	end;

%% 参阅秘籍(自动刷新下一参阅状态)
handler(?MSG_ID_MIND_READ_SECRET, Player = #player{net_pid = NetPid}, {Pos,Type}) ->
	case mind_api:read_secret(Player, Pos, Type) of
		{?ok, MindId, _AddPos, _Ctimes, Cost, NewPlayer} ->
			{_, Player2} 	= achievement_api:add_achievement(NewPlayer, ?CONST_ACHIEVEMENT_PRAY, 0, 1),
			Player3 		= mind_mod:treat_mind_achievement(Player2, [MindId]),
			{?ok, Player4}	= schedule_api:add_guide_times(Player3, ?CONST_SCHEDULE_GUIDE_MIND),
			{_, Player5}	= welfare_api:add_pullulation(Player4, ?CONST_WELFARE_MIND, 0, 1),
			RecMind			= data_mind:get_base_mind(MindId),
			{?ok, Player6}          = new_serv_api:finish_achieve(Player5, ?CONST_NEW_SERV_MIND_GET, RecMind#rec_mind.quality, 1),
			{?ok, Player7}			= achievement_api:add_achievement(Player6, ?CONST_ACHIEVEMENT_GET_ORANGE_STAR, RecMind#rec_mind.quality, 1),
			%%{?ok, Player8_1}		= achievement_api:add_achievement(Player8, ?CONST_ACHIEVEMENT_FIRST_RED_STAR, 0, 1),
			%% 荣誉榜：第一个获得红色星斗的玩家
			{?ok, Player8} = 
				case RecMind#rec_mind.quality =:= ?CONST_SYS_COLOR_RED of
					?true ->
						new_serv_api:add_honor_title(Player7, ?CONST_NEW_SERV_FIRST_RED_STAR, ?CONST_ACHIEVEMENT_FIRST_RED_STAR);
					?false ->
						{?ok, Player7}
				end,
%% 			{?ok, Player9} = new_serv_api:finish_achieve(Player8, ?CONST_NEW_SERV_MIND, 0, 1),
            yunying_activity_mod:activity_unlimitted_award(Player8,RecMind#rec_mind.quality,11),           %运营活动祈天获礼品检测
			if RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_ORANGE ->
				   spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 2);
			   true ->
				   skip
			end,
			Packet 			= mind_api:msg_mind_read_secret_return(?CONST_MIND_OK, MindId, Pos, Cost),
            NewScore        = mind_api:get_score(Player8),
            ScorePacket     = mind_api:msg_sc_update_score(NewScore),
			misc_packet:send(NetPid, <<Packet/binary, ScorePacket/binary>>),
			
			bless_api:send_be_blessed(Player8, ?CONST_RELATIONSHIP_BTYPE_MIND, data_mind:get_base_mind(MindId)),
			{?ok, Player8};
		?error ->
			?error
	end;

%% 一键参阅
handler(?MSG_ID_MIND_ONE_KEY_READ, Player = #player{net_pid = NetPid}, {}) ->
	Pos = mind_mod:high_lv_can_read(Player),
	{?ok, ReturnList, NewPlayer} = mind_api:one_key_read_secret(?CONST_MIND_READ_UNFINISH, Player, Pos, []),
	case (erlang:length(ReturnList) > 0) of
		?true ->
			{_, Player2} 	= achievement_api:add_achievement(NewPlayer, ?CONST_ACHIEVEMENT_PRAY, 0, length(ReturnList)),
			MindList 		= lists:map(fun({MindId, _}) -> MindId end, ReturnList),
			Player3 		= mind_mod:treat_mind_achievement(Player2, MindList),
			{_, Player4}	= welfare_api:add_pullulation(Player3, ?CONST_WELFARE_MIND, 0, 1),
			Packet 		= mind_api:msg_mind_one_key_read_return(?CONST_MIND_OK, ReturnList),
            NewScore        = mind_api:get_score(Player4),
            ScorePacket     = mind_api:msg_sc_update_score(NewScore),
			misc_packet:send(NetPid, <<Packet/binary, ScorePacket/binary>>),
			F = fun({MindId, _Pos}, OP) ->
						RecMind = data_mind:get_base_mind(MindId),
						bless_api:send_be_blessed(Player4, ?CONST_RELATIONSHIP_BTYPE_MIND, RecMind),
						if 
					       RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_RED ->
							   {_, NP} = new_serv_api:add_honor_title(OP, ?CONST_NEW_SERV_FIRST_RED_STAR, ?CONST_ACHIEVEMENT_FIRST_RED_STAR),
                               NP;
                           RecMind#rec_mind.quality >= ?CONST_SYS_COLOR_ORANGE ->
                               spirit_festival_activity_api:receive_redbag(OP#player.user_id, 16, 2),
                               OP;
						   ?true ->
							   OP
						end
				end,
            Player5 = lists:foldl(F, Player4, ReturnList),
			{?ok, Player5};
		?false ->
			{?ok, NewPlayer}
	end;

%% 扩展背包 扩展到第（2+Multiple）行
handler(?MSG_ID_MIND_EXTERN_BAG, Player = #player{net_pid = NetPid}, {Multiple}) ->
	case mind_api:extend_mind_bag(Player, Multiple) of
		{?ok, OpenNum, NewPlayer} ->
			Packet = mind_api:msg_mind_extern_bag_return(?CONST_MIND_OK, OpenNum),
			misc_packet:send(NetPid, Packet),
			{?ok, NewPlayer};
		?error ->
			?error
	end;

%% 获取临时背包
handler(?MSG_ID_MIND_TEMP_BAG_LIST, Player = #player{net_pid = NetPid}, {}) ->
	TempBagMinds = mind_api:get_temp_bag_mind_all(Player),
	Fun = fun(X, ResultList) ->
				  MindId = X#ceil_temp.mind_id,
				  if
					  MindId > 0 ->
						  ResultList ++ [{MindId}];
					  true ->
						  ResultList
				  end
			end,
	MindIdList = lists:foldl(Fun, [], TempBagMinds),
	Packet = mind_api:msg_mind_temp_bag_list_return(MindIdList),
	misc_packet:send(NetPid, Packet),
	?ok;

%% 拾取心法
handler(?MSG_ID_MIND_PICK, Player = #player{net_pid = NetPid}, {TempBagPos, IsConvert}) ->
	case mind_api:mind_pick(Player, TempBagPos, IsConvert) of
		{?ok, BagPos, MindId, NewPlayer} ->
			Packet = mind_api:msg_mind_pick_result(?CONST_MIND_OK, TempBagPos, BagPos, MindId),
			misc_packet:send(NetPid, Packet),
			{?ok, NewPlayer};
		?error ->
			?error
	end;

%% 一键拾取   
handler(?MSG_ID_MIND_ONE_KEY_PICK, Player = #player{net_pid = NetPid}, {Flag}) ->
	case mind_api:one_key_mind_pick(Player, Flag) of
		{?ok, Spirit, ResultList, NewPlayer} ->
			Packet = mind_api:msg_mind_one_key_pick_result(?CONST_MIND_OK, Spirit, ResultList),
			misc_packet:send(NetPid, Packet),
			{?ok, NewPlayer};
		?error ->
			?error
	end;

%% 交换心法位置(包含装备卸载)   
handler(?MSG_ID_MIND_EXCHANGE, Player = #player{net_pid = NetPid}, {Type,UserType,UserId,SourcePos,DestPos}) ->
%% 	?MSG_ERROR("SourcePos ~p, DestPos ~p", [SourcePos,DestPos]),
	case mind_api:mind_exchange(Player, Type, UserType, UserId, SourcePos, DestPos) of
		{?ok, NewPlayer} ->
			Packet = mind_api:msg_mind_exchange_result(?CONST_MIND_OK),
			misc_packet:send(NetPid, Packet),
			{?ok, NewPlayer};
		?error ->
			?error
	end;

%% 更新心法信息(对于单个位置)
handler(?MSG_ID_MIND_GET_MIND_BY_POS, Player, {Type,UserType,UserId,Pos}) ->
	mind_api:update_per_mind(Player, Type, UserType, UserId, Pos),
	?ok;

%% 获取玩家灵力值
handler(?MSG_ID_MIND_GET_SPIRIT, Player = #player{net_pid = NetPid}, {}) ->
	Spirit = mind_api:get_user_spirit(Player),
	Packet = mind_api:msg_update_spirit(Spirit),
	misc_packet:send(NetPid, Packet),
	?ok;

%% 更改背包格子状态
handler(?MSG_ID_MIND_CHANGE_BAG_STATUS, Player, {Type,UserType,UserId,Pos}) ->
	case mind_api:change_ceil_state(Player, Type, UserType, UserId, Pos) of
		{?ok, NewPlayer} ->
			{?ok, NewPlayer};
		?error ->
			?error
	end;

%% 查询祈天积分
handler(?MSG_ID_MIND_CS_GET_SCORE, Player, {}) ->
    MindScore = mind_api:get_score(Player#player.mind),
    Packet = mind_api:msg_sc_update_score(MindScore),
    misc_packet:send(Player#player.user_id, Packet),
    ?ok;

%% 兑换心法
handler(?MSG_ID_MIND_CS_EXCHANGE_SCORE, Player, {MindId}) ->
    Player2 = mind_api:exchange(Player, MindId),
    {?ok, Player2};

%% 不匹配的协议
handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
