%% Author: Administrator
%% Created: 2012-10-29
%% Description: TODO: Add description to home_db_mod
-module(home_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([update_home_ground_lv/1, update_home_build/1, update_home_ground_harvast/1, update_home_play_girl/1, update_home_girl/1,
		 update_home/1, read_home_info/1, create_home_info/1]).

%%
%% API Functions
%%
%% 家园信息获取
read_home_info(UserId) ->
	case mysql_api:select_execute(<<"SELECT `user_id`, `lv`, `update_time`, `message`,
											 `farm`, `task_info`, `girl`",
									"FROM `game_home` WHERE `user_id` = ", 
									(misc:to_binary(UserId))/binary, ";">>) of
		{?ok, []} ->        								
			{?ok, []};
		{?ok, [HomeData|_]} ->       	 						%% 从数据库里得到数据，要进行数据格式转换
			read_home_decode(HomeData);
		{?error, Error}->
			?MSG_ERROR("error:~p, Strace:~p~n ", [Error, erlang:get_stacktrace()]),
			{?error, Error}
	end.

read_home_decode([UserId, HomeLv, UpdateTime, MessageTemp, FarmTemp, TaskInfoTemp, GirlTemp]) ->
	Message			= misc:decode(MessageTemp), 
	Farm			= misc:decode(FarmTemp),		   
	TaskInfo		= misc:decode(TaskInfoTemp), 
	Girl			= misc:decode(GirlTemp),
	[UserId, HomeLv, UpdateTime, Message, Farm, TaskInfo, Girl].

%% 创建家园
create_home_info(UserId) ->
	FarmTemp		= home_mod_create:init_farm(UserId),                               %% 初始化农场
	Farm	  		= misc:encode(FarmTemp),
	TaskInfoTemp	= home_mod:init_task(),									   		   %% 初始化官府任务
	TaskInfo		= misc:encode(TaskInfoTemp),
	GirlTemp		= home_mod_create:init_girl(UserId),							   %% 初始化仕女苑
	Girl	   		= misc:encode(GirlTemp),
	MessageTemp		= #message{declare = #declare{}, record = [], note = [], interinfo = []},
	Message	   		= misc:encode(MessageTemp),
	case mysql_api:insert_execute(<<"INSERT INTO `game_home`",
									"(`lv`, `user_id`, `message`, `farm`, `task_info`,",
									"`girl`)",
									"VALUES (",
									" '", (misc:to_binary(1))/binary, "',",
									" '", (misc:to_binary(UserId))/binary, "',",
									" '", (misc:to_binary(Message))/binary, "',",
									" '", (misc:to_binary(Farm))/binary, "',",
									" '", (misc:to_binary(TaskInfo))/binary, "',",
									" '", (misc:to_binary(Girl))/binary, "');">>) of
		{?ok, _Affect, _Id} ->
			Home 	= [UserId, 1, ?CONST_SYS_FALSE, MessageTemp, FarmTemp, TaskInfoTemp, GirlTemp],
			{?ok, Home};
		X -> 
			?MSG_ERROR("X=~p", [X]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.
		
	
%% 土地升级/一键刷新/农场升级
update_home_ground_lv(Home) ->
	Farm			= Home#ets_home.farm,
	PlayerId		= Home#ets_home.user_id,
	case mysql_api:update(game_home,
						  				[{farm,    misc:encode(Farm)}
						  				],[{user_id, PlayerId}]) of
		{?ok, _}  ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 土地块收获/更新种植栏
update_home_ground_harvast(Home) ->
	PlayerId		 = Home#ets_home.user_id,
	Farm			 = Home#ets_home.farm,
	case mysql_api:update(game_home, 
						  				[
										 {farm,      misc:encode(Farm)}
										], [{user_id, PlayerId}]) of
		{?ok, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 升级家园 
update_home_build(Home) ->                            
	PlayerId		 = Home#ets_home.user_id,
	HomeLv			 = Home#ets_home.lv,
	Farm			 = Home#ets_home.farm,
	Now				 = misc:seconds(),
	case mysql_api:update(game_home, 
						  				[{update_time,       Now},
						   				 {lv,         		 HomeLv},
										 {farm,				misc:encode(Farm)}	
										],
						  				[{user_id, PlayerId}]) of
		{?ok, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 侍女情况变动
update_home_girl(Home) ->
	PlayerId		 = Home#ets_home.user_id,
	Girl			 = Home#ets_home.girl,
	case mysql_api:update(game_home, 
						  				[
										 {girl,			misc:encode(Girl)}
						   				 ],
						  				[{user_id, PlayerId}]) of
		{?ok, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 仕女互动
update_home_play_girl(Home) ->
	PlayerId		 = Home#ets_home.user_id,
	Girl			 = Home#ets_home.girl,
	case mysql_api:update(game_home, 
						  				[
										 {girl,			misc:encode(Girl)}
						   				 ],
						  				[{user_id, PlayerId}]) of
		{?ok, _} ->
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 家园更新
update_home(Home) ->
	PlayerId		 = Home#ets_home.user_id,
	Lv				 = Home#ets_home.lv,
	Message			 = Home#ets_home.message,
	Farm			 = Home#ets_home.farm,
	Girl			 = Home#ets_home.girl,
	TaskInfo		 = Home#ets_home.task_info,
	mysql_api:update(game_home, 
					                [{lv,			Lv},
					                 {message,		misc:encode(Message)},
					                 {farm,			misc:encode(Farm)},
					                 {girl,			misc:encode(Girl)},	
									 {task_info,	misc:encode(TaskInfo)}
					                ],
					                [{user_id, PlayerId}]).
