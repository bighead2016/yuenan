
%%% 教学

-module(teach_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%

%% 请求进度
handler(?MSG_ID_TEACH_CS_PROCESS, Player, {}) ->
    Packet = teach_api:packet_all(Player),
    misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 发起战斗
handler(?MSG_ID_TEACH_CS_BATTLE, Player, {Type, PassId, Pro, Choice}) ->
    teach_api:start_battle(Player, Type, PassId, Pro, Choice);

%% 答题
handler(?MSG_ID_TEACH_CS_ANSWER, Player, {PassId, Answer}) ->
    teach_api:answer(Player, PassId, Answer);

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
