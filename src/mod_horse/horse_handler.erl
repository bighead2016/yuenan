%% Author: php
%% Created: 2012-08-21 17
%% Description: TODO: Add description to horse_handler
-module(horse_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 坐骑培养数据请求
handler(?MSG_ID_HORSE_CS_DEVELOP, Player, {}) ->
    UserId = Player#player.user_id,
	Packet = horse_stable_api:list_all(Player),
    misc_packet:send(UserId, Packet),
	?ok;

%% 取出
handler(?MSG_ID_HORSE_CS_TAKE_OUT, Player, {Pos}) ->
    UserId = Player#player.user_id,
	case horse_mod:take_out(Player, Pos) of
        {?ok, Player2, Packet} ->
            misc_packet:send(UserId, Packet),
            {?ok, Player2};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;    

%% 坐骑培养
handler(?MSG_ID_HORSE_CS_NORMALDEVE, Player, {_Type}) ->
	case horse_train_api:train(Player) of
        {?ok, Player2, Packet, Packet2} ->
            misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet2/binary>>),
            {?ok, Player2};
        {?error, ErrorCode} -> 
			{?error, ErrorCode}
    end;    

%% 坐骑学习技能
handler(?MSG_ID_HORSE_CS_HORSESKILL, Player, {SkillId}) ->
    case horse_skill_api:learn_from_base(Player, SkillId) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;

%% 清除CD时间
handler(?MSG_ID_HORSE_CS_CLEAR_CD, Player, {Idx}) ->
	case horse_mod:clear_cd(Player, Idx) of
        {?ok, Player2, Packet} ->
            misc_packet:send(Player#player.net_pid, Packet),
            {?ok, Player2};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end;

%% 一键升级
handler(?MSG_ID_HORSE_CS_ONE_KEY, Player, {}) ->
	try
		Player2 = horse_train_api:on_key(Player),
		{?ok, Player2}
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
			?error
	end;

%% 更改皮肤
handler(?MSG_ID_HORSE_CS_REPLACESKIN, Player, {SkinId}) ->
    StyleData = Player#player.style,
    case goods_style_api:is_exist_style(StyleData, SkinId, ?CONST_GOODS_EQUIP_HORSE) of
        ?true ->
            Player2 = goods_style_api:change_skin_style(Player, SkinId, ?CONST_GOODS_EQUIP_HORSE),
            map_api:change_skin_ride(Player2),
            {?ok, Player2};
        ?false ->
            ?error
    end;

%% 坐骑洗练
handler(?MSG_ID_HORSE_CS_REFRESH, Player, {CtnType,PartnerId,Grid,{_Count,List}}) ->
	case horse_mod:refresh(Player,CtnType,PartnerId,Grid,List) of
		{?error,ErrorCode} -> {?error, ErrorCode};
		{?ok, Player2} ->
            schedule_power_api:do_update_horse(Player2),
			{?ok, Player2}
	end;

%% 升级坐骑技能
handler(?MSG_ID_HORSE_CS_LVUPSKILL, Player, {SkillId, Type}) ->
    horse_skill_api:lv_up_skill(Player, SkillId, Type);

%% 皮肤时间到
handler(?MSG_ID_HORSE_CS_TIME_OVER, Player, {SkinId}) ->
    Player2     = goods_style_api:clear_time(Player, SkinId),
    StyleData   = Player2#player.style,
    StyleBag    = StyleData#style_data.bag,
    SkinPacket  = 
        case lists:keyfind(?CONST_GOODS_EQUIP_HORSE, 1, StyleBag) of
            {_, StyleList} ->
                horse_api:pack_horse_skin(StyleList, <<>>);
            _ ->
                <<>>
        end,
    misc_packet:send(Player2#player.user_id, SkinPacket),
    map_api:change_skin_ride(Player2);

%% 请求未保存坐骑洗练属性
handler(?MSG_ID_HORSE_CS_HORSE_ATTR_NOT_SAVE, Player, {CtnType, PartnerId, Grid}) ->
    horse_api:request_not_save_attr(Player, CtnType, PartnerId, Grid),
    {?ok, Player};

handler(?MSG_ID_HORSE_CS_SAVE_ATTR_HORSE, Player, {IsSave, CtnType, PartnerId, Grid}) ->
    horse_api:save_refresh(Player, IsSave, CtnType, PartnerId, Grid);

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
