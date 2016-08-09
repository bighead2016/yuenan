%% Author: yskj
%% Created: 2012-9-16
%% Description: TODO: Add description to tower_mod_create
-module(tower_mod_create).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.tower.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([get_all_towerpass/2,get_tower_player/1,create_towercamp_init/2,get_tower_pass/1, tower_data_to_record/1]).
%%
%% API Functions
%%
%% 创建闯塔数据
create_tower(UserId) ->
	case tower_db_mod:create_tower(UserId) of
		{?ok, Tower} ->
			insert_ets_tower(Tower),
			tower_data_to_record(Tower);
		{?error, ErrorCode}-> 
			{?error, ErrorCode}
	end.

%%　初始化大阵信息
create_towercamp_init(CampId, CampTuple) ->
	TowerList 	= get_all_towerpass(?CONST_TOWER_PASS_COUNT, []),
	Date		= misc:date_num(),
	F = fun(Pass) ->
				Type 		= Pass#rec_tower_pass.type,
				Id 			= Pass#rec_tower_pass.pass_id,
				#pass{type = Type, id = Id}
		end,
	PassList 	= [F(Pass)||Pass <-TowerList, Pass#rec_tower_pass.camp =:= CampId],
	CampInfo	= #towercamp{max_pass = CampId * 10, id = CampId, pass = PassList, top_pass = ?CONST_SYS_FALSE, 
							 reset_pass = ?CONST_SYS_FALSE, past_list = [], is_award= ?CONST_SYS_FALSE, date = Date},
	erlang:setelement(CampId, CampTuple, CampInfo).

%% 获取玩家闯塔信息
get_tower_player(PlayerId) -> 
	case ets_api:lookup(?CONST_ETS_TOWER_PLAYER, PlayerId) of 
		?null ->
			case tower_db_mod:read_tower_info(PlayerId) of
				{?ok, []} ->
					create_tower(PlayerId);
				{?error, ErrorCode}->
					?MSG_ERROR("~p~n~p~n",[ErrorCode, erlang:get_stacktrace()]);
				Tower ->
%% 					insert_ets_tower(Tower),
%% 					tower_data_to_record(Tower)
					NewTower		= check(Tower),
					insert_ets_tower(Tower),
					NewTower
			end;
		TowerRecord -> check(TowerRecord)
	end.

%% 判断是否要新加入大阵信息
check(Tower) ->
	TowerRecord 	= case is_record(Tower, ets_tower_player) of
						  ?true  -> Tower;
						  ?false -> tower_data_to_record(Tower)
					  end,
	TopPass			= TowerRecord#ets_tower_player.top_score,
	TopPass1		= TopPass + 1,
	Camp			= TowerRecord#ets_tower_player.camp,
	case data_tower:get_towerpass(TopPass + 1) of
		TowerPass when is_record(TowerPass, rec_tower_pass) ->
			CampId		= tower_sweep_api:get_current_camp(misc:to_list(TopPass1)),
			case erlang:element(CampId, Camp) of
				[] -> 
					NewCamp			= create_towercamp_init(CampId, Camp),
					TowerRecord#ets_tower_player{camp = NewCamp};
				Camp1 ->
					case Camp1#towercamp.pass of
						[] ->
							TowerList 	= get_all_towerpass(?CONST_TOWER_PASS_COUNT, []),
							F = fun(Pass) ->
										Type 		= Pass#rec_tower_pass.type,
										Id 			= Pass#rec_tower_pass.pass_id,
										#pass{type = Type, id = Id}
								end,
							PassList 	= [F(Pass)||Pass <-TowerList, Pass#rec_tower_pass.camp =:= CampId],
							Camp1Info	= Camp1#towercamp{pass = PassList},
							NewCamp1	= erlang:setelement(CampId, Camp, Camp1Info),
							TowerRecord#ets_tower_player{camp = NewCamp1};
						_ -> TowerRecord
					end
			end;
		_ -> TowerRecord
	end.
					
%% 获取闯塔信息
get_tower_pass(PassId) -> 
	case ets_api:lookup(?CONST_ETS_TOWER_PASS, PassId) of 
		?null ->
			case tower_db_mod:get_tower_pass_info(PassId) of
				{?ok, []}  ->  ?null;
				{?error, _}->  ?null;
				PassData   ->
					insert_ets_tower_pass(PassData),
					tower_pass_to_record(PassData)
			end;
		PassData ->  PassData 
	end.

%%  args towerdata
insert_ets_tower (Tower) ->
	TowerRecord = tower_data_to_record(Tower),
	ets_api:insert(?CONST_ETS_TOWER_PLAYER, TowerRecord).
%%  towerdata to ets record
tower_data_to_record([TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime]) ->
	tower_data_to_record(TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime);
tower_data_to_record({TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime}) ->
	tower_data_to_record(TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime).

tower_data_to_record(TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, Camp, Sweep, TopTime) ->
	#ets_tower_player{                                                              
					  id			                    = TowerId,			        %% 闯塔id
					  player_id 	                    = PlayerId,			        %% 玩家id
					  top_score		                    = TopScore,			        %% 最高关卡
					  reset_times	                    = ResetTimes,		        %% 重置次数
					  sweep_times	                    = SweepTimes,		        %% 扫荡次数
					  camp			                    = Camp,				        %% 大阵信息
					  sweep			                    = Sweep,			        %% 扫荡信息
					  top_time		                    = TopTime			        %% 通过关卡首次时间
					  }.

insert_ets_tower_pass(TowerPass) ->
	TowerRecord = tower_pass_to_record(TowerPass),
	ets_api:insert(?CONST_ETS_TOWER_PASS, TowerRecord).

tower_pass_to_record(TowerPass) ->
	misc:to_tuple([?CONST_ETS_TOWER_PASS|TowerPass]).

%% 获取基础数据
get_all_towerpass(TotalPass, Acc) when TotalPass > ?CONST_SYS_FALSE ->
	case data_tower:get_towerpass(TotalPass) of
		TowerPass when is_record(TowerPass, rec_tower_pass) ->
			NewAcc		= [TowerPass|Acc],
			get_all_towerpass(TotalPass - 1, NewAcc);
		_ ->
			get_all_towerpass(TotalPass - 1, Acc)
	end;
get_all_towerpass(_, Acc) ->
	Acc.