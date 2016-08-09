%% Author: Administrator
%% Created: 2012-11-19
%% Description: TODO: Add description to tower_db_mod
-module(tower_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.tower.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
%% -export([insert_sweep_list/2]).
-export([start_sweep/2, insert_tower_pass/2, update_tower_pass/1, insert_offline_date/4, get_offline_data/1, update_top_score/2,
		 end_sweep/2, update_get_award/2, create_tower/1, read_tower_info/1, get_tower_pass_info/1, update_sweep_info/2,
         save_all_report/1, save_all_report_idx/1]).
%%
%% API Functions
%%
%% 创建破阵数据
create_tower(UserId) ->
	CampTuple		= erlang:make_tuple(?CONST_TOWER_CAMP_COUNT, []),
	?MSG_DEBUG("CampTuple=~p", [CampTuple]),
	CampInit		= tower_mod_create:create_towercamp_init(1, CampTuple),
	CampInfo		= misc:encode(CampInit),
	SweepInit		= #towersweep{id = ?CONST_SYS_FALSE, player_id = ?CONST_SYS_FALSE, current_id = ?CONST_SYS_FALSE, 
								  current_end = ?CONST_SYS_FALSE, reward = ?CONST_SYS_FALSE, begin_time = ?CONST_SYS_FALSE, 
								  end_time = ?CONST_SYS_FALSE, sweep_list = [], interval_time = ?CONST_SYS_FALSE},
	SweepInfo		= misc:encode(SweepInit),
	case mysql_api:insert_execute(<<"INSERT INTO `game_tower_player`",
										"(`player_id`, `camp`, `sweep`)",
										"VALUES ("
										" '", (misc:to_binary(UserId))/binary, "',", 
										" '", (misc:to_binary(CampInfo))/binary, "',",
										" '", (misc:to_binary(SweepInfo))/binary, "');">>) of
		{?ok, _Affect, Id} ->
			Tower		   = [Id, UserId, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, CampInit,
							  SweepInit, ?CONST_SYS_FALSE],
			{?ok, Tower};
		X -> 
			?MSG_ERROR("~p~n~p~n", [X, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 读取破阵数据
read_tower_info(UserId) ->
	case mysql_api:select_execute(<<"SELECT `id`, `player_id`, `top_score`, `reset_times`,
											`sweep_times`, `camp`, `sweep`, `top_time`",
									"FROM game_tower_player WHERE `player_id` = ",
									(misc:to_binary(UserId))/binary ,";">>) of
		{?ok, []} ->
			{?ok, []};
		{?ok, [TowerData|_]} ->
			decode_tower_data(TowerData);
		{?error, ErrorCode} ->
			?MSG_ERROR("error:~p, Strace:~p~n ", [ErrorCode, erlang:get_stacktrace()]),
			{?error, ErrorCode}
	end.

decode_tower_data([TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, CampTemp, SweepTemp, TopTime]) ->
	Camp			= misc:decode(CampTemp),
	Sweep			= misc:decode(SweepTemp),
	[TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime].

%% 获取破阵通关信息
%% tower_db_mod:get_tower_pass_info(1).
get_tower_pass_info(PassId) ->
	case mysql_api:select_execute(<<"SELECT `id`, `pass_type`, `camp_id`, `pass_id`,
											`first_name`, `first_id`, `best_pass`, `best_passid`, `best_score`",
									"FROM game_tower_pass WHERE `pass_id` = ",
									(misc:to_binary(PassId))/binary ,";">>) of
		{?ok, []} ->
			{?ok, []};
		{?ok, [PassData|_]} ->
			PassData;
		{?error, ErrorCode} ->
			?MSG_ERROR("error:~p, Strace:~p~n ", [ErrorCode, erlang:get_stacktrace()]),
			{?error, ErrorCode}
	end.

update_get_award(Player, Tower) ->
	PlayerId		= Player#player.user_id,
	Camp			= Tower#ets_tower_player.camp,
	case mysql_api:update(game_tower_player,[
											{camp, misc:encode(Camp)}
						  					],[{player_id, PlayerId}]) of
		{?ok, _}  ->?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 更新最高记录
update_top_score(Player, Tower) ->
	PlayerId		= Player#player.user_id,
	TopScore		= Tower#ets_tower_player.top_score,
	TopTime			= Tower#ets_tower_player.top_time,
	Camp			= Tower#ets_tower_player.camp,
	case mysql_api:update(game_tower_player,[
						   					{top_score, TopScore},
											{top_time,  TopTime},
											{camp, misc:encode(Camp)}
						  					],[{player_id, PlayerId}]) of
		{?ok, _}  -> ?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 更新重置信息
update_sweep_info(Player, Tower) ->
	PlayerId		= Player#player.user_id,
	ResetTimes		= Tower#ets_tower_player.reset_times,
	SweepTimes		= Tower#ets_tower_player.sweep_times,
	Camp			= Tower#ets_tower_player.camp,
	Sweep			= Tower#ets_tower_player.sweep,
	case mysql_api:update(game_tower_player,
											[{reset_times, ResetTimes},
						   					{sweep_times, SweepTimes}, 
											{camp, misc:encode(Camp)}, 
											{sweep, misc:encode(Sweep)}
											],[{player_id, PlayerId}]) of
		{?ok, _}  -> ?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.
	
%% 开始扫荡
start_sweep(Player, Tower) when is_record(Tower, ets_tower_player) ->
	PlayerId		= Player#player.user_id,
	TopScore		= Tower#ets_tower_player.top_score,
	ResetTimes		= Tower#ets_tower_player.reset_times,
	SweepTimes		= Tower#ets_tower_player.sweep_times,
	Camp			= Tower#ets_tower_player.camp,
	Sweep			= Tower#ets_tower_player.sweep,
	case mysql_api:update(game_tower_player,
						  					[{top_score, TopScore}, 
											{reset_times, ResetTimes},
						   					{sweep_times, SweepTimes}, 
											{camp, misc:encode(Camp)}, 
											{sweep, misc:encode(Sweep)}	
											],[{player_id, PlayerId}]) of
		{?ok, _}  -> ?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 结束扫荡
end_sweep(UserId, Tower) when is_record(Tower, ets_tower_player) ->
	Camp			= Tower#ets_tower_player.camp,
	Sweep			= Tower#ets_tower_player.sweep,
	case mysql_api:update(game_tower_player,[
											{camp, misc:encode(Camp)},
											{sweep, misc:encode(Sweep)}	
											],[{player_id, UserId}]) of
		{?ok, _}  -> ?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 插入首杀以及最佳通关记录
insert_tower_pass(TowerPass, CampId) when is_record(TowerPass, ets_tower_pass) ->
	PassType		= TowerPass#ets_tower_pass.type,
	PassId			= TowerPass#ets_tower_pass.id,
	PlayerId		= TowerPass#ets_tower_pass.first_id,
	PlayerName		= TowerPass#ets_tower_pass.first_name,
	PlayerId1		= TowerPass#ets_tower_pass.best_passid,
	PlayerName1		= TowerPass#ets_tower_pass.best_pass,
	BestScore		= TowerPass#ets_tower_pass.best_score,
	case mysql_api:insert(game_tower_pass,
						  					[
											 {id,			PassId},	
						                     {pass_type, 	PassType}, 
						                     {camp_id, 		CampId},
						                     {pass_id, 		PassId}, 
						                     {first_name, 	PlayerName}, 
						                     {first_id, 	PlayerId},	
						                     {best_pass, 	PlayerName1},
						                     {best_passid,	PlayerId1},
											 {best_score,   BestScore}
						  					]) of
		{?ok, _, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 更新最佳通关
update_tower_pass(TowerPass) when is_record(TowerPass, ets_tower_pass) ->
	PassId			= TowerPass#ets_tower_pass.id,
	PlayerId1		= TowerPass#ets_tower_pass.best_passid,
	PlayerName1		= TowerPass#ets_tower_pass.best_pass,
	BestScore		= TowerPass#ets_tower_pass.best_score,
	case mysql_api:update(game_tower_pass,
						  					[
						                     {best_pass, PlayerName1},
						                     {best_passid,PlayerId1},
											 {best_score,   BestScore}
						  					],[{pass_id, PassId}]) of
		{?ok, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 插入离线数据
insert_offline_date(PlayerId, Module, Data, InitId) ->
	FieldsSql	=	[id, user_id, module, data, time],
	case mysql_api:select(FieldsSql, game_offline, [{user_id, PlayerId}, {module, Module}]) of
		{?ok, []} -> 
			Now				= misc:seconds(),
			InitData		= [{InitId}|Data],
			BinData 		= misc:encode(InitData),
			case mysql_api:insert(game_offline, 
								  				[
												{user_id, PlayerId}, 
												{module,  Module}, 
												{data,    BinData}, 
												{time,    Now}]) of
				{?ok, _, _} -> ?ok;
				{?error, _ErrorCode} ->
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		{?ok, [[_, _, _, BinData1, _]]} ->
			Data1 		= misc:decode(BinData1),
			NewData		= Data1 ++ Data,
%% 			NewData1	= lists:usort(NewData),
			NewBinData	= misc:encode(NewData),
			case mysql_api:update(game_offline,
								  				  [{data,       NewBinData}
								  				   ],[{user_id, PlayerId}, {module, Module}]) of
				{?ok, _} ->  ?ok;
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		{?error, ErrorCode}->
			?MSG_ERROR("~p~n~p~n",[ErrorCode, erlang:get_stacktrace()])
	end.
	
%% 获取离线数据
get_offline_data(Player) ->
	PlayerId		= Player#player.user_id,
    case mysql_api:select_execute(<<"select * from game_tower_offline where user_id = " , (misc:to_binary(PlayerId))/binary, ";">>) of
		{?ok, []} ->
			{?error, ?TIP_COMMON_ERROR_DB};
        {?ok, [[_, _, _, BinData, _]]} ->
            mysql_api:delete(game_tower_offline, "user_id = "++misc:to_list(PlayerId)),
			Data 		= misc:decode(BinData),
            {?ok, Data};
        {?error, ErrorCode}->
			?MSG_ERROR("~p~n~p~n",[ErrorCode, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 下线保存
save_all_report(Report) ->
    case mysql_api:select(<<"insert into `game_tower_report`(`report`)value(", (mysql_api:encode(Report))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 下线保存
save_all_report_idx(ReportIdx) ->
    case mysql_api:select(<<"insert into `game_tower_report_idx`(`record`)value(", (mysql_api:encode(ReportIdx))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

