%% Author: cobain
%% Created: 2012-9-11
%% Description: TODO: Add description to buff_api
-module(buff_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([get_buff/1, get_buff_id/0, decrease_buff/1, insert_buff/2, refresh_attr/2]).
%%
%% API Functions
%%

%% 根据BUFF类型读取BUFF数据
get_buff(BuffType) ->
	data_buff:get_buff(BuffType).

%% 获取BUFF唯一ID
get_buff_id() ->
	buff_serv:make_unique_id_call().

%% BUFF回合递减
decrease_buff(Buff)
  when is_record(Buff, buff) andalso
	   Buff#buff.expend_type =:= ?CONST_BUFF_EXPEND_TYPE_BOUT ->
	Buff#buff{expend_value = Buff#buff.expend_value - 1};
decrease_buff(_Buff) -> ?null.

%% 
insert_buff(Player, Goods) ->
	case goods_convert_buff(Goods) of
		{?ok, Buff} ->
			BuffList	= Player#player.buff,
			case set_buff(Buff, BuffList, [], []) of
				{BuffList2, AccDelete, AccInsert} ->
					F 				= fun(#buff{buff_id = BuffId, buff_type = BuffType}, OldPacket) ->
											  Packet = player_api:msg_sc_buff_delete(BuffId, BuffType),
											  <<OldPacket/binary, Packet/binary>>
									  end,
					PacketDelete 	= lists:foldl(F, <<>>, AccDelete),
					F2 				= fun(#buff{buff_id = BuffId2, buff_type = BuffType2, buff_value = BuffValue2, expend_value = Time2}, OldPacket2) ->
											  Packet2 = player_api:msg_sc_buff_insert(BuffId2, BuffType2, BuffValue2, Time2),
											  <<OldPacket2/binary, Packet2/binary>>
									  end,
                    PacketInsert	= lists:foldl(F2, <<>>, AccInsert),
                    PacketBuff 		= <<PacketDelete/binary, PacketInsert/binary>>,
                    misc_packet:send(Player#player.net_pid, PacketBuff),
                    Player2			= player_attr_api:refresh_buff(Player#player{buff = BuffList2}),% 刷新属性
					{?ok, Player2};
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

goods_convert_buff(Goods) ->
	Exts		= Goods#goods.exts,
	BuffType	= Exts#g_buff.buff_type,
	BuffValue	= Exts#g_buff.buff_value,
	BuffTime	= Exts#g_buff.time,
    Now         = misc:seconds(),
	case get_buff(BuffType) of
		Buff when is_record(Buff, buff) ->
			BuffId	= get_buff_id(),
			Buff2	= Buff#buff{
								buff_id        	= BuffId,          				%% ID
								buff_value      = BuffValue,            		%% 值
								
								source			= ?CONST_BUFF_SOURCE_GOODS,    	%% BUFF来源
								trigger			= ?CONST_BUFF_TRIGGER_NORMAL,	%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_TIME,	%% 消耗类型
								expend_value    = BuffTime + Now       			%% 消耗值
							   },
			{?ok, Buff2};
		_ -> {?error, ?TIP_COMMON_BAD_ARG}
	end.

set_buff(Buff, BuffList, AccDelete, AccInsert) ->
	case lists:keyfind(Buff#buff.buff_type, #buff.buff_type, BuffList) of
		BuffOld when is_record(BuffOld, buff) ->
			case Buff#buff.relation of
				?CONST_BUFF_RELATION_PLUS ->% 同类型BUFF关系--叠加
					Value		= misc:min(BuffOld#buff.buff_value + Buff#buff.buff_value, Buff#buff.limit),
					BuffNew		= Buff#buff{buff_value = Value},
					BuffList2	= lists:delete(BuffOld, BuffList),
					BuffList3	= [BuffNew|BuffList2],
					{BuffList3, [BuffOld|AccDelete], [BuffNew|AccInsert]};
				?CONST_BUFF_RELATION_REPLACE ->% 同类型BUFF关系--替换
					if
						Buff#buff.buff_value >= BuffOld#buff.buff_value ->
							BuffList2	= lists:delete(BuffOld, BuffList),
							BuffList3	= [Buff|BuffList2],
							{BuffList3, [BuffOld|AccDelete], [Buff|AccInsert]};
						?true ->
							{?error, ?TIP_COMMON_BUFF_NOT_REPLACABLE}
					end;
				?CONST_BUFF_RELATION_COEXIST ->% 同类型BUFF关系--共存
					{[Buff|BuffList], AccDelete, [Buff|AccInsert]};
				?CONST_BUFF_RELATION_MUTEX ->% 同类型BUFF关系--互斥
					{?error, ?TIP_COMMON_BUFF_NOT_REPLACABLE}
			end;
		_ ->
			{[Buff|BuffList], AccDelete, [Buff|AccInsert]}
	end.

refresh_attr([#buff{buff_type = Type, buff_value = Value}|Tail], OldList) ->
    BuffType = get_buff_type(Type),
    NewList = [{BuffType, Value, ?CONST_SYS_NUMBER_TEN_THOUSAND}|OldList],
    refresh_attr(Tail, NewList);
refresh_attr([], OldList) ->
    OldList.
    
%%
%% Local Functions
%%

get_buff_type(?CONST_BUFF_TYPE_201) -> ?CONST_PLAYER_ATTR_HP_MAX;
get_buff_type(?CONST_BUFF_TYPE_202) -> ?CONST_PLAYER_ATTR_FORCE_ATTACK;
get_buff_type(?CONST_BUFF_TYPE_203) -> ?CONST_PLAYER_ATTR_MAGIC_ATTACK;
get_buff_type(?CONST_BUFF_TYPE_204) -> ?CONST_PLAYER_ATTR_SPEED;
get_buff_type(?CONST_BUFF_TYPE_205) -> ?CONST_PLAYER_ATTR_E_CRIT;
get_buff_type(?CONST_BUFF_TYPE_206) -> ?CONST_PLAYER_ATTR_E_RESIST;
get_buff_type(?CONST_BUFF_TYPE_207) -> ?CONST_PLAYER_ATTR_E_DODGE;
get_buff_type(BuffType) -> ?MSG_ERROR("ERROR BuffType:~p", [BuffType]), 0.