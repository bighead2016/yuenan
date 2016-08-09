%% Author: php
%% Created: 
%% Description: TODO: Add description to camp_pvp_msg
-module(camp_pvp_msg).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions
%%
%% 进入阵营战成功
%%[Camp]
msg_sc_enter(Camp) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_SC_ENTER, ?MSG_FORMAT_CAMP_PVP_SC_ENTER, [Camp]).
%% 排行榜数据广播
%%[SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,{Name,Score}]
msg_sc_rank(SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,List1) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_SC_RANK, ?MSG_FORMAT_CAMP_PVP_SC_RANK, [SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,List1]).
%% 开始采集资源
%%[Time,Speed]
msg_sc_dig_success(Time,Speed) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_SC_DIG_SUCCESS, ?MSG_FORMAT_CAMP_PVP_SC_DIG_SUCCESS, [Time,Speed]).
%% 活动开始
%%[]
msg_sc_start() ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_SC_START, ?MSG_FORMAT_CAMP_PVP_SC_START, []).
%% 活动结束
%%[{Name1,CampId1,Level1,Career1},IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,Exp,Career,Level,CampId]
msg_sc_end(List1,IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,Exp,Career,Level,CampId) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_END, ?MSG_FORMAT_CAMP_PVP_SC_END, [List1,IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,Exp,Career,Level,CampId]).
%% 加怪物  
%%[MonsterId,PositionX,PositionY,Speed,TargetX,TargetY]
msg_add_monster(MonsterId,PositionX,PositionY,Speed,TargetX,TargetY) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_ADD_MONSTER, ?MSG_FORMAT_CAMP_PVP_ADD_MONSTER, [MonsterId,PositionX,PositionY,Speed,TargetX,TargetY]).
%% 怪物开始移动
%%[MonsterId,TargetX,TargetY,Speed]
msg_monster_move(MonsterId,TargetX,TargetY,Speed) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_MOVE, ?MSG_FORMAT_CAMP_PVP_MONSTER_MOVE, [MonsterId,TargetX,TargetY,Speed]).
%% 怪物被杀死
%%[MonsterId]
msg_monster_killed(MonsterId) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_KILLED, ?MSG_FORMAT_CAMP_PVP_MONSTER_KILLED, [MonsterId]).
%% 怪物攻击buffnpc
%%[MonsterId]
msg_monster_attack(MonsterId) ->
	misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_ATTACK, ?MSG_FORMAT_CAMP_PVP_MONSTER_ATTACK, [MonsterId]).
%%
%% Local Functions
%%
