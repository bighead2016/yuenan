%% Author: php
%% Created: 
%% Description: TODO: Add description to camp_pvp_handler
-module(camp_pvp_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求进入阵营战
handler(?MSG_ID_CAMP_PVP_CS_ENTER, Player, {}) ->
    case camp_pvp_api:enter_camp_map(Player) of
        {?ok, Player2} ->
	       {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 采集资源
handler(?MSG_ID_CAMP_PVP_CS_DIG_RECOURCE, Player, {Type}) ->
    case camp_pvp_api:mining(Player, Type) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 提交资源
handler(?MSG_ID_CAMP_PVP_CS_SUBMIT_RECOURCE, Player, {}) ->
    case camp_pvp_api:submit_resource(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 发起战斗
handler(?MSG_ID_CAMP_PVP_CS_BATTLE, Player, {Type,Id}) ->
    case camp_pvp_api:start_battle(Player, Id, Type) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 退出阵营战
handler(?MSG_ID_CAMP_PVP_CS_EXIT, Player, {}) ->
    case camp_pvp_api:exit_camp(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求阵营战信息
handler(?MSG_ID_CAMP_PVP_CS_CAMP_INFO, Player, {}) ->
    case camp_pvp_api:camp_info_4_client(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

handler(?MSG_ID_CAMP_PVP_CS_CHANGE_STATE, Player, {}) ->
    case camp_pvp_api:player_state_change(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 放弃采集
handler(?MSG_ID_CAMP_PVP_GIVE_UP_MINING, Player, {}) ->
    case camp_pvp_api:give_up_mining(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 地图初始化完成
handler(?MSG_ID_CAMP_PVP_MAP_INIT_FINISH, Player, {MapId}) ->
    case camp_pvp_api:map_init_finish(Player, MapId) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求鼓舞
handler(?MSG_ID_CAMP_PVP_ENCOURAGE, Player, {}) ->
    case camp_pvp_api:encourage(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求打车
handler(?MSG_ID_CAMP_PVP_CS_ATT_CAR, Player, {MonsterId}) ->
    {?ok, Player};

%% 放弃攻击战车
handler(?MSG_ID_CAMP_PVP_GIVE_UP_ATT_CAR, Player, {}) ->
    case camp_pvp_api:give_up_att_car(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求兑换物品
handler(?MSG_ID_CAMP_PVP_BUY_ITEM, Player, {ItemId,Count}) ->
    case camp_pvp_api:buy_item(Player, ItemId, Count) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            ok
    end;
%% 请求积分
handler(?MSG_ID_CAMP_PVP_REQUEST_SCORE, Player, {}) ->
    camp_pvp_mod:send_score(Player),
    {?ok, Player};

%% 创建队伍
handler(?MSG_ID_CAMP_PVP_CREATE_TEAM, Player, {}) ->
    case camp_pvp_api:create_team(Player) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            ok
    end;

%% 离开队伍
handler(?MSG_ID_CAMP_PVP_LEAVE_TEAM, Player, {}) ->
    case camp_pvp_api:leave_team(Player) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            ok
    end;

handler(?MSG_ID_CAMP_PVP_KICK, Player, {UserId}) ->
    case camp_pvp_api:kick(Player, UserId) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            ok
    end;

%% 请求开宝箱
handler(?MSG_ID_CAMP_PVP_OPEN_CASH, Player, {Id}) ->
    case camp_pvp_api:get_box(Player, Id) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 开宝箱结束
handler(?MSG_ID_CAMP_PVP_OPEN_CASH_FINISH, Player, {Id}) ->
    case camp_pvp_api:open_box_end(Player, Id) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            {?ok, Player}
    end;

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
