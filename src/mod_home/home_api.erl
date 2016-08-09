%% Author: yskj
%% Created: 2012-7-13
%% Description: TODO: Add description to home_api
-module(home_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").

%%
%% Exported Functions
%%
-export([init_ets/0, record_home/1]).
-export([msg_sc_girl_info/2, msg_sc_harvest/2,
		 msg_delete_leave_message/1,msg_sc_rescue_list/1,
		 msg_sc_lvuphome/1, msg_sc_main/9, msg_sc_release_girl/1,
		 msg_sc_otherhome/4, msg_sc_plant/2, msg_sc_plant_info/1,
		 msg_sc_office_reward/1, msg_sc_visit_record/1, msg_sc_play_num/4,
		 msg_sc_black_info/1, msg_sc_get_leave_message/1, msg_sc_clean_message/1,
		 msg_sc_declear_info/6, msg_edit_home_declear/1, msg_edit_leave_message/1, 
		 msg_sc_help_loosen/1, msg_recom_enemy_list/4, msg_sc_recruit_success/1, 
		 msg_sc_guide_info/5, msg_sc_office_task/2, msg_sc_refresh_one_task/5, msg_sc_daily_info/1,
		 msg_sc_office_task_times/1, msg_sc_loosen_state/2, msg_sc_invite_friend/5,
		 msg_sc_user_state/2, msg_sc_main_balack/1, msg_sc_inter_info/5,
		 msg_sc_play_success/1, msg_sc_slaver_info/6]).
-export([clean_home_times/0, login_packet/2, logout/1, get_girl_times/1, add_source_list/2]).
%%
%% API Functions
%%
%% 获取仕女互动剩余次数
get_girl_times(Player) ->
	home_mod_girl:get_girl_times(Player).

%% 竞技场增加手下败将
add_source_list(UserId, OtherId) ->
	home_mod_girl:add_source_list(UserId, OtherId).

%%0点定时清理次数
clean_home_times() ->
	try
		home_mod:clean_home_times()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

%% 上线请求俸禄信息
login_packet(Player, Packet) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_HOME) of
		?true ->
			home_mod:refresh_home(Player),
			Position  	= Player#player.position,
			PositionId	= Position#position_data.position,
			Packet1	  	= case PositionId > ?CONST_SYS_TRUE of
							  ?true ->
								  {IsGet, _}= player_position_api:salary_info(Player),
								  msg_sc_office_reward(IsGet);
							  ?false -> <<>>
						  end,
			Packet2		= home_mod:get_home_daily_award(Player),
			{Player, <<Packet/binary, Packet1/binary, Packet2/binary>>};
		?false ->
			{Player, Packet}
	end.

%% 下线写数据库
logout(Player) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_HOME) of
		?true  -> home_mod:logout(Player);
		?false -> ?ok
	end.

%% 初始化家园ets
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_HOME),
	FieldList = [user_id, lv, update_time, message, farm, task_info, girl],
	case mysql_api:select(FieldList, game_home) of
		{?ok, HomeList} ->
			F = fun([UserId, HomeLv, UpdateTime, MessageTemp, FarmTemp, TaskTemp, GirlTemp]) ->
						Message 		= misc:decode(MessageTemp),
						Farm			= misc:decode(FarmTemp),
						Task			= misc:decode(TaskTemp),
						Girl			= misc:decode(GirlTemp),
						record_home([UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl]) 
				end,
			HomeInfoList = [F(HomeTemp) || HomeTemp <- HomeList],
			ets_insert_list(HomeInfoList);
		{?error, _ErrorCode} ->
			?ok
	end.
%% 家园数据转换
record_home([UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl]) ->
	record_home(UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl);
record_home({UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl}) ->
	record_home(UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl).

record_home(UserId, HomeLv, UpdateTime, Message, Farm, Task, Girl) ->
	#ets_home{
			user_id 	                           = UserId,		        %% 玩家id
			lv			                           = HomeLv,		        %% 家园等级
			update_time	                           = UpdateTime,	        %% 升级开始时间
			message		                           = Message,		        %% 留言板
			farm			                       = Farm,		        	%% 农场
			task_info		                       = Task,			        %% 招贤馆
			girl			                       = Girl		        	%% 仕女苑
			 }.
%% 插入到ets
ets_insert_list([HomeInfo|RestList]) ->
	ets_api:insert(?CONST_ETS_HOME, HomeInfo),
	ets_insert_list(RestList);
ets_insert_list([]) ->
	?ok.

%%
%% Local Functions
%%
%% 家园主系统(7002)
msg_sc_main(HomeLv, RemainTime, FriendList, FarmList, ShowGirlId, UserState, BlackList, ContentList,InterCd) ->
	misc_packet:pack(?MSG_ID_HOME_SC_MAIN, ?MSG_FORMAT_HOME_SC_MAIN, 
					 [HomeLv, RemainTime, FriendList, FarmList, ShowGirlId, UserState, BlackList, ContentList, InterCd]).

%% 奴隶主信息
msg_sc_slaver_info(UserId, UserName, UserLv, UserPro, UserSex, EndTime) ->
	misc_packet:pack(?MSG_ID_HOME_SC_SLAVER_INFO, ?MSG_FORMAT_HOME_SC_SLAVER_INFO, 
					 [UserId, UserName, UserLv, UserPro, UserSex, EndTime]).

%% 封邑日常任务信息(7010)
msg_sc_daily_info(IsOver) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GET_AWARD, ?MSG_FORMAT_HOME_SC_GET_AWARD, [IsOver]).

%% 官府信息返回(7012)
msg_sc_office_task(TaskList, Time) ->
	misc_packet:pack(?MSG_ID_HOME_SC_OFFICE_TASK, ?MSG_FORMAT_HOME_SC_OFFICE_TASK, [TaskList, Time]).

%% 单个官府任务刷新(7014)
msg_sc_refresh_one_task(Grid, Id, Color, Time, State) ->
	Data		= [Grid, Id, Color, Time, State],
	misc_packet:pack(?MSG_ID_HOME_SC_REFRESH_ONE_TASK, ?MSG_FORMAT_HOME_SC_REFRESH_ONE_TASK, Data).

%%官府任务完成次数(7016)
msg_sc_office_task_times(Times) ->
	misc_packet:pack(?MSG_ID_HOME_SC_TASK_TIMES, ?MSG_FORMAT_HOME_SC_TASK_TIMES, [Times]).

%%　每日引导信息(7100)
msg_sc_guide_info(IsWare,PlayGirlTimes, GrabTimes, PlantTimes, LoosenTimes) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GUIDE_INFO, ?MSG_FORMAT_HOME_SC_GUIDE_INFO, 
					 [IsWare,PlayGirlTimes, GrabTimes, PlantTimes, LoosenTimes]).

%% 返回土地信息(7408)
msg_sc_plant_info(PlantList) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GROUND_INFO, ?MSG_FORMAT_HOME_SC_GROUND_INFO, [PlantList]).

%% 升级家园返回(7008)
msg_sc_lvuphome(Time) ->
	misc_packet:pack(?MSG_ID_HOME_SC_LVUPHOME, ?MSG_FORMAT_HOME_SC_LVUPHOME, [Time]).

%% 进入别人家园返回(7406)
msg_sc_otherhome(FarmList, ShowGirlId, HomeLv, PositionId) ->
	misc_packet:pack(?MSG_ID_HOME_SC_OTHERHOME, ?MSG_FORMAT_HOME_SC_OTHERHOME, [FarmList, ShowGirlId, HomeLv, PositionId]).

%% 神树种植返回(7410)
msg_sc_plant(PlantPos, Type)->
	misc_packet:pack(?MSG_ID_HOME_SC_PLANT, ?MSG_FORMAT_HOME_SC_PLANT, [PlantPos, Type]).

%% 土地块收获返回(7422)
msg_sc_harvest(PlantIndex, Cd) ->
	misc_packet:pack(?MSG_ID_HOME_SC_HARVEST, ?MSG_FORMAT_HOME_SC_HARVEST, [PlantIndex, Cd]).

%% 官府俸禄信息返回(7610)
msg_sc_office_reward(IsGet) ->
	misc_packet:pack(?MSG_ID_HOME_SC_OFFICE_AWARD, ?MSG_FORMAT_HOME_SC_OFFICE_AWARD, [IsGet]).

%% 帮助好友松土返回(7118)
msg_sc_help_loosen(PlantPos) ->
	misc_packet:pack(?MSG_ID_HOME_SC_LOOSEN, ?MSG_FORMAT_HOME_SC_LOOSEN, [PlantPos]).

%% 施肥状态更新(7122)
msg_sc_loosen_state(FriendId, State) ->
	misc_packet:pack(?MSG_ID_HOME_SC_LOOSEN_STATE, ?MSG_FORMAT_HOME_SC_LOOSEN_STATE, [FriendId, State]).

%% 请求小黑屋信息(7202)
msg_sc_black_info(BlackList) ->
	misc_packet:pack(?MSG_ID_HOME_SC_BLACK_GIRLINFO, ?MSG_FORMAT_HOME_SC_BLACK_GIRLINFO, [BlackList]).

%% 推荐和仇人列表(7102)
msg_recom_enemy_list(RecommendList, EnemyList, State, TimeStamp) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GIRL_INFO, ?MSG_FORMAT_HOME_SC_GIRL_INFO, 
					 [RecommendList, EnemyList, State, TimeStamp]).

%% 玩法次数返回(7104)
msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, Exp) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GIRL_INFO1, ?MSG_FORMAT_HOME_SC_GIRL_INFO1, 
					 [GrabTimes, PlayTimes, RescueTimes, Exp]).

%% 请求仕女信息返回(7110)
msg_sc_girl_info(UserId, RecruitList) ->
	misc_packet:pack(?MSG_ID_HOME_SC_RECURIT_INFO, ?MSG_FORMAT_HOME_SC_RECURIT_INFO, [UserId, RecruitList]).

%% 招募仕女成功返回(7114)
msg_sc_recruit_success(Id) ->
	misc_packet:pack(?MSG_ID_HOME_SC_RECURIT_GIRL, ?MSG_FORMAT_HOME_SC_RECURIT_GIRL, [Id]).

%% 互动成功返回(7130)
msg_sc_play_success(Type) ->
	misc_packet:pack(?MSG_ID_HOME_SC_GIRL_PLAY, ?MSG_FORMAT_HOME_SC_GIRL_PLAY, [Type]).

%% 需解救列表返回(7136)
msg_sc_rescue_list(List) ->
	misc_packet:pack(?MSG_ID_HOME_SC_RESCUE_LIST, ?MSG_FORMAT_HOME_SC_RESCUE_LIST, [List]).

%% 发送消息给邀请好友(7138)
msg_sc_invite_friend(UserId, UserName, OtherId, OtherName, Power) ->
	misc_packet:pack(?MSG_ID_HOME_SC_INVITE_RESCUE, ?MSG_FORMAT_HOME_SC_INVITE_RESCUE, 
					 [UserId, UserName, OtherId, OtherName, Power]).

%% 人物状态改变(7144)
msg_sc_user_state(UserId, State) ->
	misc_packet:pack(?MSG_ID_HOME_MSG_SC_USER_STATE, ?MSG_FORMAT_HOME_MSG_SC_USER_STATE, [UserId, State]).

%% 互动信息返回(7148) ->
msg_sc_inter_info(Id, UserName, UserName1, SkillId, Value) ->
	misc_packet:pack(?MSG_ID_HOME_SC_INTER_INFO, ?MSG_FORMAT_HOME_SC_INTER_INFO,
					 [Id, UserName, UserName1, SkillId, Value]).

%% 小黑屋侍女信息
msg_sc_main_balack(List) ->
	misc_packet:pack(?MSG_ID_HOME_MSG_SC_MAIN_BLACK, ?MSG_FORMAT_HOME_MSG_SC_MAIN_BLACK, [List]).

%% 手动释放侍女返回(7210)
msg_sc_release_girl(Grid) ->
	misc_packet:pack(?MSG_ID_HOME_SC_RELEASE_GIRL, ?MSG_FORMAT_HOME_SC_RELEASE_GIRL, [Grid]).

%% 清空所有留言(7902)
msg_sc_clean_message(Result) ->
	misc_packet:pack(?MSG_ID_HOME_SC_CLEAR_MESSAGE, ?MSG_FORMAT_HOME_SC_CLEAR_MESSAGE, [Result]).

%% 城主宣言信息返回(7904)
msg_sc_declear_info(GetWareTimes, PlayTimes, GrabTimes, PlantTimes, LoosenTimes, Content) ->
	misc_packet:pack(?MSG_ID_HOME_SC_DECLEAR_INFO, ?MSG_FORMAT_HOME_SC_DECLEAR_INFO, 
					 [GetWareTimes, PlayTimes, GrabTimes, PlantTimes, LoosenTimes, Content]).

%% 编辑城主宣言返回(7906)
msg_edit_home_declear(Result) ->
	misc_packet:pack(?MSG_ID_HOME_SC_EDIT_OWNER, ?MSG_FORMAT_HOME_SC_EDIT_OWNER, [Result]).

%% 编辑留言返回(7908)
msg_edit_leave_message(Id) ->
	misc_packet:pack(?MSG_ID_HOME_SC_EDIT_MESSAGE, ?MSG_FORMAT_HOME_SC_EDIT_MESSAGE, [Id]).

%% 请求玩家所有留言返回(7910)
msg_sc_get_leave_message(MessageList) ->
	misc_packet:pack(?MSG_ID_HOME_SC_LEAVE_MESSAGE, ?MSG_FORMAT_HOME_SC_LEAVE_MESSAGE, [MessageList]).

%% 删除留言返回(7912)
msg_delete_leave_message(Id) ->
	misc_packet:pack(?MSG_ID_HOME_SC_DELETE_MESSAGE, ?MSG_FORMAT_HOME_SC_DELETE_MESSAGE, [Id]).

%% 访客记录返回(7914)
msg_sc_visit_record(MessageList) ->
	misc_packet:pack(?MSG_ID_HOME_SC_VISIT_RECORD, ?MSG_FORMAT_HOME_SC_VISIT_RECORD, [MessageList]).