%%% 排行榜
-module(rank_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").

-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 人物信息
handler(?MSG_ID_RANK_CS_PLAYER, Player, {UserId, 0}) -> % 玩家
    Packet = rank_api:read_info(Player, UserId),
    misc_packet:send(Player#player.user_id, Packet),
	?ok;
handler(?MSG_ID_RANK_CS_PLAYER, Player, {UserId, PartnerId}) -> % 武将
    Packet = rank_api:read_partner_info(Player, UserId, PartnerId),
    misc_packet:send(Player#player.user_id, Packet),
    ?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
