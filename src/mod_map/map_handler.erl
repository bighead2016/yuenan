%% Author: cobain
%% Created: 2012-7-12
%% Description: TODO: Add description to player_handler
-module(map_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 请求进入地图
handler(?MSG_ID_MAP_ENTER, Player, {0}) ->
    Info = Player#player.info,
    Step = Info#info.is_newbie,
    if
        0 < Step andalso Step < 10 ->
            copy_single_newbie_api:enter(Player);
        ?true ->
            Player2 = map_api:enter_map(Player, 0),
            {?ok, Player2}
    end;
handler(?MSG_ID_MAP_ENTER, Player, {MapId}) ->
	Player2	= map_api:enter_map(Player, MapId),
	{?ok, Player2};

%% 角色移动
handler(?MSG_ID_MAP_PLAYER_MOVE, Player, {UserId,X,Y}) ->
	Player2	= map_api:move(Player, UserId, X, Y),
	{?ok, Player2};

%% 请求开启地图列表
handler(?MSG_ID_MAP_CS_OPENED_MAP_LIST, Player, {}) ->
    Packet = map_api:msg_sc_opened_map_list(Player#player.maps),
    misc_packet:send(Player#player.user_id, Packet),
    ?ok;

%% NPC功能请求
handler(?MSG_ID_MAP_CS_NPC, Player, {NpcId,Func}) ->
    case npc_api:npc(Player, NpcId, Func) of
        {?ok, NewPlayer} ->
            {?ok, NewPlayer};
        {?error, _ErrorCode} ->
            ?error
    end;
%% 请求瞬移
handler(?MSG_ID_MAP_CS_FLY, Player, {MapId,X,Y}) ->
    map_api:fly(Player, {MapId,X,Y});
%% 采集
handler(?MSG_ID_MAP_SC_COLLECTION, Player, {GatherId}) ->
    MapId = map_api:get_cur_map_id(Player),
    {?ok, NewPlayer} = task_api:update_gather(Player, MapId, GatherId),
    {?ok, NewPlayer};

%% pk邀请
handler(?MSG_ID_MAP_CS_INVITE_PK, Player, {MemId}) ->
	map_mod:request_pk(Player, MemId),
	?ok;

%% 回复pk邀请
handler(?MSG_ID_MAP_CS_REPLY_PK, Player, {Flag, MemId}) ->
	map_mod:reply_pk(Player, MemId, Flag);

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%

