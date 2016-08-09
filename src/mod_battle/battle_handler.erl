%% Author: php
%% Created: 2012-09-04 12
%% Description: TODO: Add description to battle_handler
-module(battle_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 开始战斗
handler(?MSG_ID_BATTLE_CS_START, _Player, {?CONST_BATTLE_SINGLE_COPY,_Id}) ->
	?ok;
handler(?MSG_ID_BATTLE_CS_START, _Player, {?CONST_BATTLE_BOSS, _id}) ->
	?ok;
handler(?MSG_ID_BATTLE_CS_START, _Player, {?CONST_BATTLE_TOWER, _id}) ->
	?ok;
handler(?MSG_ID_BATTLE_CS_START, _Player, {?CONST_BATTLE_INVASION_ATTACK, _id}) ->
	?ok;
handler(?MSG_ID_BATTLE_CS_START, _Player, {?CONST_BATTLE_INVASION_GUARD, _id}) ->
	?ok;
handler(?MSG_ID_BATTLE_CS_START, Player, {BattleType,Id}) ->
	case battle_api:start(Player, Id, #param{battle_type = BattleType}) of
        {?ok, Player2} ->
	       {?ok, Player2};
        {?error, _} ->
            ?error
    end;

%% 战斗操作
handler(?MSG_ID_BATTLE_CS_OPERATE, Player, {SkillIdx}) ->
	battle_api:operate(Player, SkillIdx),
	?ok;

%% 请求战报数据
handler(?MSG_ID_BATTLE_CS_REPORT_DATA, Player, {}) ->
    ?ok;

%% 设置自动战斗
handler(?MSG_ID_BATTLE_CS_AUTO, Player, {IsAuto}) ->
	battle_api:auto_battle(Player, IsAuto),
	?ok;

%% 副本战斗测试
handler(?MSG_ID_BATTLE_CS_START_COPY_TEST, Player, {CopyId,Wave}) ->
    copy_single_gm_api:start_battle(Player, CopyId, Wave),
    ?ok;

%% 跳过战斗
handler(?MSG_ID_BATTLE_SC_SKIP, Player, {}) ->
    case battle_skip_api:skip_battle(Player) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, ErrorCode} ->
            UserId = Player#player.user_id,
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            ?error
    end;

%% 请求各类型战报
handler(?MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, Player, {?CONST_BATTLE_TOWER, ReportIdBin}) ->
    ReportId = misc:to_list(ReportIdBin),
    Report = tower_mod_report:get_report_by_id(ReportId),
    UserId = Player#player.user_id,
    misc_packet:send(UserId, Report),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, Player, {?CONST_BATTLE_SINGLE_COPY, ReportIdBin}) ->
    ReportId = misc:to_list(ReportIdBin),
    Report = copy_single_report_api:get_report_by_id(ReportId),
    UserId = Player#player.user_id,
    misc_packet:send(UserId, Report),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, Player, {?CONST_BATTLE_SINGLE_ARENA, ReportIdBin}) ->
    ReportId = misc:to_list(ReportIdBin),
    BinReport = 
        case single_arena_mod:get_report_by_id(ReportId) of
            <<>> ->
                single_arena_api:lookup_campion_report(ReportId);
            R ->
                R
        end,
    misc_packet:send(Player#player.net_pid, BinReport),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, Player, {?CONST_BATTLE_CROSS_ARENA, ReportIdBin}) ->
    ReportId = misc:to_list(ReportIdBin),
    BinReport = cross_arena_mod:get_report_by_id(ReportId),
    misc_packet:send(Player#player.net_pid, BinReport),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, _Player, {_BattleType, _ReportId}) ->
    ?ok;

%% 请求战报列表
handler(?MSG_ID_BATTLE_CS_REPORT_LIST, Player, {?CONST_BATTLE_TOWER, CopyId, Pro}) ->
    UserId = Player#player.user_id,
    Packet = tower_mod_report:list_all(CopyId, Pro),
    misc_packet:send(UserId, Packet),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REPORT_LIST, Player, {?CONST_BATTLE_SINGLE_COPY, CopyId, Pro}) ->
    UserId = Player#player.user_id,
    Packet = copy_single_report_api:list_all(CopyId, Pro),
    misc_packet:send(UserId, Packet),
    ?ok;
handler(?MSG_ID_BATTLE_CS_REPORT_LIST, _Player, {_, _CopyId}) ->
    ?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
