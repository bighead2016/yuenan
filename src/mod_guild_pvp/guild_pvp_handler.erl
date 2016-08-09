%% Author: php
%% Created: 
%% Description: TODO: Add description to guild_pvp_handler
-module(guild_pvp_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求进入军团战
handler(?MSG_ID_GUILD_PVP_CS_ENTER, Player, {}) ->
    case guild_pvp_api:enter_guild_pvp(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 发起战斗
handler(?MSG_ID_GUILD_PVP_CS_BATTLE, Player, {Type,Id}) ->
    case guild_pvp_api:start_battle(Player, Id, Type) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 退出军团战
handler(?MSG_ID_GUILD_PVP_CS_EXIT, Player, {}) ->
    case guild_pvp_api:exit_guild_pvp(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求改变状态
handler(?MSG_ID_GUILD_PVP_CS_CHANGE_STATE, Player, {}) ->
    case guild_pvp_api:change_state(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 地图初始化完成
handler(?MSG_ID_GUILD_PVP_CS_INIT_MAP_OK, Player, {MapId}) ->
    case guild_pvp_api:init_map_ok(Player, MapId) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求鼓舞
%% 请求鼓舞
handler(?MSG_ID_GUILD_PVP_CS_ENCOURAGE, Player, {IsUseMoney}) ->
    case guild_pvp_api:encourage(Player, IsUseMoney) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求报名军团战
handler(?MSG_ID_GUILD_PVP_CS_APP, Player, {CampId}) ->
    case guild_pvp_api:app_guild_pvp(Player, CampId) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求军团战报名信息
handler(?MSG_ID_GUILD_PVP_CS_GET_APP_INFO, Player, {}) ->
    case guild_pvp_api:get_guild_pvp_app_info(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 添加防守军团
handler(?MSG_ID_GUILD_PVP_CS_ADD_DEF_GUILD, Player, {GuildId}) ->
    case guild_pvp_api:choose_def(Player, GuildId) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求战车出击
handler(?MSG_ID_GUILD_PVP_CS_CAR_FIRE, Player, {}) ->
    case guild_pvp_api:car_att(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求修复城门
handler(?MSG_ID_GUILD_PVP_CS_FIX_WALL, Player, {}) ->
    case guild_pvp_api:fix_wall(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求浴火重生
handler(?MSG_ID_GUILD_PVP_CS_BRING_BACK, Player, {IsUseMoney}) ->
	case guild_pvp_api:bring_back(Player, IsUseMoney) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求军团列表详细信息
handler(?MSG_ID_GUILD_PVP_CS_APP_LIST, Player, {}) ->
    case guild_pvp_api:get_guild_app_list(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求军团战出战信息
handler(?MSG_ID_GUILD_PVP_CS_GUILD_WALL_INFO, Player, {}) ->
    case guild_pvp_api:get_enter_info(Player) of
        {?ok, Player2} ->
            {ok, Player2};
        _ ->
	       {?ok, Player}
    end;
%% 请求观察进攻城墙玩家列表
handler(?MSG_ID_GUILD_PVP_CS_WALL_LIST, Player, {}) ->
    case guild_pvp_api:water_door(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求进攻城墙
handler(?MSG_ID_GUILD_PVP_CS_ATT_WALL, Player, {}) ->
    case guild_pvp_api:att_wall(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 放弃观察采集城墙列表
handler(?MSG_ID_GUILD_PVP_CS_GIVEUP_WALL, Player, {}) ->
    case guild_pvp_api:give_up_watch(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 进入战场界面
handler(?MSG_ID_GUILD_PVP_ENTER_INFO, Player, {}) ->
    case guild_pvp_api:get_enter_info(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求军团地图城主信息
handler(?MSG_ID_GUILD_PVP_TOWER_OWNER_INFO, Player, {}) ->
    case guild_pvp_api:get_tower_info(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 放弃采集城墙
handler(?MSG_ID_GUILD_PVP_GUILD_UP_ATT_WALL, Player, {}) ->
    case guild_pvp_api:give_up_att_wall(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求购买军团物资
handler(?MSG_ID_GUILD_PVP_REQUEST_BUG_GUILD_ITEMS, Player, {ItemId,Count,IsBuySelf,IdBuyFor,IsBuyForGuild}) ->
    case guild_pvp_api:buy_item(Player, ItemId,Count,IsBuySelf,IdBuyFor,IsBuyForGuild) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求军团成员列表
handler(?MSG_ID_GUILD_PVP_CS_GUILD_MEMBER_LIST, Player, {}) ->
    guild_pvp_api:cs_get_guild_member_list(Player),
    {?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
