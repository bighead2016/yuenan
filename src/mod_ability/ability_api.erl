%% 内功api
-module(ability_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([
		 refresh_attr/1,
		 create/0,
		 get_ext_value/1,
%% 		 msg_ability_sc_cd/1,
		 msg_ability_sc_ext_info/7,
		 msg_ability_sc_info/2,
		 msg_sc_info/2
		]).

%%
%% API Functions
%%

%% 刷新属性
refresh_attr(AbilityData)
  when is_record(AbilityData, ability_data) ->
	AccAttr		= player_attr_api:record_attr(),
	refresh_attr(AbilityData#ability_data.ability, AccAttr);	
refresh_attr(_AbilityData) ->
	player_attr_api:record_attr().

refresh_attr([Ability|AbilityList], AccAttr) ->
	AccAttr2	= refresh_attr2(Ability, AccAttr),
	refresh_attr(AbilityList, AccAttr2);
refresh_attr([], AccAttr) -> AccAttr.

refresh_attr2(Ability, AccAttr) ->
	RecAbility	= data_ability:get_ability({Ability#ability.ability_id, Ability#ability.lv}),
	Type		= RecAbility#rec_ability.attr_type,
	Value		= RecAbility#rec_ability.attr_value,
	AccAttr2	= player_attr_api:attr_plus(AccAttr, Type, Value),
	Fun			= fun({_ExtId, 0, _Count}, AccExtValue) ->
						  AccExtValue;
					 ({ExtId, N, _Count}, AccExtValue) ->
						  AbilityExt	= data_ability:get_ability_ext(ExtId),
						  lists:nth(N, AbilityExt#rec_ability_ext.value) + AccExtValue
				  end,
	ValueExt	= lists:foldl(Fun, 0, Ability#ability.ability_ext),
	player_attr_api:attr_plus(AccAttr2, Type, ValueExt).

%% 初始化
create() ->
	ability_mod:create().
%% %% 内功总CD
%% msg_ability_sc_cd(Cd) ->
%% 	misc_packet:pack(?MSG_ID_ABILITY_SC_CD, ?MSG_FORMAT_ABILITY_SC_CD, [Cd]).

%% 单条内功信息
msg_ability_sc_info(AbilityList,IsLevel) ->
	msg_ability_sc_info(AbilityList, IsLevel,<<>>).
msg_ability_sc_info([Ability|AbilityList], IsLevel,AccPacket) ->
	Packet	= msg_sc_info(Ability,IsLevel),
	msg_ability_sc_info(AbilityList, IsLevel,<<AccPacket/binary, Packet/binary>>);
msg_ability_sc_info([],_IsLevel, AccPacket) -> AccPacket.

msg_sc_info(Ability,IsLevel) when is_record(Ability, ability) ->
	ExtValue	= get_ext_value(Ability#ability.ability_ext),
	AbilityId	= Ability#ability.ability_id,
	AbilityLv	= Ability#ability.lv,
	misc_packet:pack(?MSG_ID_ABILITY_SC_INFO, ?MSG_FORMAT_ABILITY_SC_INFO, [AbilityId,AbilityLv , ExtValue,IsLevel]);
msg_sc_info(_Ability,_) -> <<>>.

%% 取得八门增加总值
get_ext_value(AbilityExtList) ->
	Fun	= fun({_ExtId, 0, _Count}, AccExtValue) ->
				  AccExtValue;
			 ({ExtId, N, _Count}, AccExtValue) ->
				  AbilityExt	= data_ability:get_ability_ext(ExtId),
				  lists:nth(N, AbilityExt#rec_ability_ext.value) + AccExtValue
		  end,
	lists:foldl(Fun, 0, AbilityExtList).
	

%% 八门信息
msg_ability_sc_ext_info(Nth, Value, Count,Id,Step,Sum,IsRock) ->
	misc_packet:pack(?MSG_ID_ABILITY_SC_EXT_INFO, ?MSG_FORMAT_ABILITY_SC_EXT_INFO, [Nth,Value,Count,Id,Step,Sum,IsRock]).
