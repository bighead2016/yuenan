%% @author jin
%% @doc @todo Add description to kb_treasure_api.


-module(kb_treasure_api).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([
		 msg_sc_target/1,
		 msg_sc_reply/1,
		 msg_sc_group_result/2,
		 msg_sc_total/1
		]).
%%
%% API Functions
%%
%% 目标
%%[Idx]
msg_sc_target(Idx) ->
	misc_packet:pack(?MSG_ID_KB_TREASURE_SC_TARGET, ?MSG_FORMAT_KB_TREASURE_SC_TARGET, [Idx]).
%% 到背包
%%[Idx]
msg_sc_reply(Idx) ->
	misc_packet:pack(?MSG_ID_KB_TREASURE_SC_REPLY, ?MSG_FORMAT_KB_TREASURE_SC_REPLY, [Idx]).
%% 返回组别
%%[Level,GroupId]
msg_sc_group_result(Level,GroupId) ->
	misc_packet:pack(?MSG_ID_KB_TREASURE_SC_GROUP_RESULT, ?MSG_FORMAT_KB_TREASURE_SC_GROUP_RESULT, [Level,GroupId]).
%% 转盘所得
%%[{Idx,Count}]
msg_sc_total(List1) ->
	misc_packet:pack(?MSG_ID_KB_TREASURE_SC_TOTAL, ?MSG_FORMAT_KB_TREASURE_SC_TOTAL, [List1]).
%%
%% Local Functions
%%
