%% 任务
-module(task_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%

%% 请求任务信息
handler(?MSG_ID_TASK_CS_INFO, Player, {}) ->
    UserId = Player#player.user_id,
	{?ok, Player2, Packet} = task_login_mod:login(Player),
    misc_packet:send(UserId, Packet),
    {?ok, Player2};
%% 接任务
handler(?MSG_ID_TASK_CS_ACCEPT, Player, {TaskId}) ->
	task_mod:accept(Player, TaskId);
%% 交任务
handler(?MSG_ID_TASK_CS_SUBMIT, Player, {TaskId}) ->
	task_mod:submit(Player, TaskId, ?CONST_SYS_FALSE);
%% 放弃任务
handler(?MSG_ID_TASK_CS_ABANDON, Player, {TaskId}) ->
	task_mod:abandon(Player, TaskId);

%% 自动完成任务
handler(?MSG_ID_TASK_CS_AUTO_FINISH, Player, {TaskId}) ->
    case task_mod:auto_finish(Player, TaskId) of
        {?ok, Player2} -> {?ok, Player2};
        {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            misc_packet:send(Player#player.net_pid, PacketError),
            ?error;
        {?error, ErrorCode} ->
			PacketErr = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, PacketErr),
			?error
    end;

%% 测试杀怪任务
handler(?MSG_ID_TASK_CS_TEST_KILL, Player, {MapId,MonsterId}) ->
	{?ok, Player2, _Flag, _GoodsList} = task_api:update_battle(Player, MapId, [MonsterId], 0),
	{?ok, Player2};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	?error.
%%
%% Local Functions
%%
