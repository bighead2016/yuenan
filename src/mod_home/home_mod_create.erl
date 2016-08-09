%% Author: yskj
%% Created: 2012-7-13
%% Description: TODO: Add description to home_mod
-module(home_mod_create).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([get_home/1, create_home/1, get_home1/1]).
-export([set_farm/3, init_farm/1, init_girl/1]).

%%
%% API Functions
%%
%% 获取家园信息
get_home(PlayerId) ->
	case ets_api:lookup(?CONST_ETS_HOME, PlayerId) of 
		?null ->        										%% ets中无家园信息
			case home_db_mod:read_home_info(PlayerId) of
				{?ok, []} ->        							%% 第一次进入家园，需创建家园
					create_home(PlayerId);
				{?error, Error}->
					{?error, Error};
				Home ->              					        %% 从数据库里得到数据，要进行数据格式转换
					insert_ets_home(Home),
					home_data_to_record(Home)
			end;
		HomeRecord -> 
			HomeRecord
	end.

%% 获取家园信息
get_home1(UserId) ->
	ets_api:lookup(?CONST_ETS_HOME, UserId).

%%  创建家园
create_home(PlayerId) ->
	case home_db_mod:create_home_info(PlayerId) of
		{?ok, Home} ->
			insert_ets_home(Home),
			home_data_to_record(Home);
		{?error, Error}-> 
			?MSG_ERROR("~p~n~p~n",[Error, erlang:get_stacktrace()])
	end.

%% 初始化农场
init_farm(PlayerId) ->
	VipLv			= case player_api:get_player_field(PlayerId, #player.info) of
						  {?ok, Info} when is_record(Info, info) -> player_api:get_vip_lv(Info);
						  _ -> ?CONST_SYS_FALSE
					  end,
	HomeData		= data_home:get_base(?CONST_SYS_TRUE),                           %% 1级家园数据
	OpenNum			= if
						  VipLv	=:= 3 -> 
							   HomeData#rec_home_base.farm_vip3;
						  VipLv =:= 5 -> 
							  HomeData#rec_home_base.farm_vip5;
						  ?true -> 
							  HomeData#rec_home_base.farm_vip0
					  end,
	PlantTuple 	  	= erlang:make_tuple(?CONST_HOME_PLANT_MAX_COUNT, ?CONST_SYS_FALSE, []),
	Farm			= #farm{lv = ?CONST_SYS_TRUE, refresh_times = ?CONST_SYS_FALSE, plant = PlantTuple},
	set_farm(OpenNum, ?CONST_SYS_TRUE, Farm).

set_farm(OpenNum, Position, Farm) when Position =< OpenNum ->
	PlantInfo		= Farm#farm.plant,
	Plant 	      	= #plant{land_lv = ?CONST_HOME_LAND_MIN_LV, plant_lv = ?CONST_HOME_PLANT_MIN_LV, position = Position, 
						   state = ?CONST_HOME_PLANT_NULL, state1 = ?CONST_HOME_PLANT_NULL, cd_time = ?CONST_SYS_FALSE},
	NewPlantTuple 	= erlang:setelement(Position, PlantInfo, Plant),
	NewPosition		= Position + 1,
	NewFarm			= Farm#farm{plant = NewPlantTuple},
	set_farm(OpenNum, NewPosition, NewFarm);
set_farm(_, _, Farm) ->
	Farm.
	

%% 初始化仕女苑
init_girl(UserId) ->
	VipList			= home_mod:get_recruit_vip_list(UserId), 											 %% vip侍女列表
	Recruit	   		= [{?CONST_SYS_TRUE}],
	GrabGirl   		= erlang:make_tuple(?CONST_HOME_GRID_MAX, ?CONST_SYS_FALSE, []),
	F	= fun(Num, Acc) ->															                     %%　初始小黑屋数据
				  GrabInfo	= #grab_girl_info{pos = Num, state = 1},
				  erlang:setelement(Num, Acc, GrabInfo)
		  end,
	GrabGirlInfo	= lists:foldl(F, GrabGirl, lists:seq(?CONST_SYS_TRUE, ?CONST_HOME_GRID_MAX)),
	Recommend		= erlang:make_tuple(?CONST_HOME_GRID_MAX, ?CONST_SYS_FALSE, []),					%% 初始推荐列表数据
	F1	= fun(Num1, Acc1)  ->
				  RecInfo	= #recommend_list{pos = Num1, state = 1},
				  erlang:setelement(Num1, Acc1, RecInfo)
		  end,
	RecommendInfo	= lists:foldl(F1, Recommend, lists:seq(?CONST_SYS_TRUE, ?CONST_HOME_GRID_MAX)),
	EnemyList		= erlang:make_tuple(?CONST_HOME_GRID_MAX, ?CONST_SYS_FALSE, []),					%% 初始仇人列表
	F2	= fun(Num2, Acc2) ->
				  Enemy	= #enemy_list{pos = Num2, state = 1},
				  erlang:setelement(Num2, Acc2, Enemy)
		  end,
	EnemyInfo		= lists:foldl(F2, EnemyList, lists:seq(?CONST_SYS_TRUE, ?CONST_HOME_GRID_MAX)),
	IdList			= single_arena_api:get_area_win_top(UserId),
	NewIds			= home_mod_girl:filter_by_lv(IdList, UserId, []),
	RecommedList	= home_mod_girl:init_recommend_list(NewIds, RecommendInfo, ?CONST_SYS_TRUE), 
	#girl{recruit_list = Recruit, grab_num = ?CONST_HOME_GRAB_MAX, grab_girl_info = GrabGirlInfo, recommend_list = RecommedList, 
		  enemy_list = EnemyInfo, recruit_vip_list = VipList, show_girl = ?CONST_SYS_TRUE, source_list = NewIds}.


%%  插入数据到ets
insert_ets_home (Home) ->
	HomeRecord 		= home_data_to_record(Home),
	ets_api:insert(?CONST_ETS_HOME, HomeRecord).

%%  家园数据转换
home_data_to_record(Home) ->
	home_api:record_home(Home).
