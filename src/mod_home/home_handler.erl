%% Author: yskj
%% Created: 2012-7-16  家园系统
%% Description: TODO: Add description to home_handler
-module(home_handler).
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

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 家园主系统(7001)
handler(?MSG_ID_HOME_CS_MAIN, Player, {}) ->
	home_mod:get_home_info(Player),
	{?ok, Player};

%% 升级家园(7007)
handler(?MSG_ID_HOME_CS_LVUPHOME, Player, {}) ->
	home_mod:upgrade_home(Player),
	{?ok, Player};

%% 领取封邑日常奖励
handler(?MSG_ID_HOME_CS_DAILY_AWARD, Player, {}) ->
	{?ok, NewPlayer} = home_mod:get_daily_task_award(Player),
	{?ok, NewPlayer};

%% 请求封邑官府任务信息
handler(?MSG_ID_HOME_CS_OFFICE_TASK, Player, {}) ->
	home_mod:get_office_task(Player),
	{?ok, Player};

%% 封邑日常任务刷新
handler(?MSG_ID_HOME_CS_REFRESH_TASK, Player, {Type}) ->
	home_mod:refresh_office_task(Player, Type),
	{?ok, Player};

%% 任务操作请求
handler(?MSG_ID_HOME_CS_TASK_OPERATE, Player, {Type, Grid}) ->
	NewPlayer	= home_mod:office_task_operate(Player, Type, Grid),
	{?ok, NewPlayer};

%% 小黑屋侍女互动(7129)
handler(?MSG_ID_HOME_CS_BLACK_GIRL_PLAY, Player, {Grid,SkillId}) ->
	{?ok, NewPlayer} = home_mod_girl:play_black_girl(Player, Grid, SkillId),
	{?ok, NewPlayer};

%% 主界面仕女互动(7131)
handler(?MSG_ID_HOME_CS_HOMEMAIN_GIRL_PLAY, Player, {SkillId}) ->
	{?ok, NewPlayer} = home_mod_girl:play_main_girl(Player, SkillId),
	{?ok, NewPlayer};

%% 进入别人家园(7405)
handler(?MSG_ID_HOME_CS_OTHERHOME, Player, {UserId}) ->
	home_mod:enter_friend_home(Player, UserId),
	{?ok, Player};

%% 神树种植(7409)
handler(?MSG_ID_HOME_CS_PLANT, Player, {PlantPos, Type}) ->
	{?ok, NewPlayer} = home_mod:plant_coin(Player, PlantPos, Type),
	{?ok, NewPlayer};

%% 神树刷新(7411)
handler(?MSG_ID_HOME_CS_REFRESHPLANT, Player, {_Pos}) ->
%% 	home_mod:refresh_plant_coin(Player, Pos),
	{?ok, Player};

%% 一键刷新(7413)
handler(?MSG_ID_HOME_CS_KEYREFRESH, Player, {_Pos}) ->
%% 	home_mod:refresh_plant_coin_once(Player, Pos),
	{?ok, Player};

%% 请求土地收获信息
handler(?MSG_ID_HOME_CS_PLANT_REWARD, Player, {_}) ->
	{?ok, Player};

%% 请求松土(7617)
handler(?MSG_ID_HOME_CS_LOOSEN, Player, {UserId, PlantPos}) ->
	home_mod:apply_loosen(Player, UserId, PlantPos),
	{?ok, Player};

%% 清除土地种植冷却时间(7417)
handler(?MSG_ID_HOME_CS_CLEARCOLD, Player, {_PlantPos}) ->
%% 	home_mod:clean_plant_cd(Player, PlantPos),
	{?ok, Player};

%% 土地块收获(7424)
handler(?MSG_ID_HOME_CS_HARVEST, Player, {PlantPos}) ->
	NewPlayer  = home_mod:get_plant_reward(Player, PlantPos),
	{?ok, NewPlayer};

%% 请求官府俸禄信息(7609)
handler(?MSG_ID_HOME_CS_OFFICE_AWARD, Player, {}) ->
	home_mod:get_office_reward_info(Player),
	{?ok, Player};

%% 领取俸禄(7611)
handler(?MSG_ID_HOME_CS_GETACTIVES, Player, {Type}) ->
	{?ok, NewPlayer} = home_mod:get_office_reward(Player, Type),
	{?ok, NewPlayer};

%% 请求仕女苑抢夺仇人信息(7101)
handler(?MSG_ID_HOME_CS_GIRL_INFO, Player, {}) ->
	home_mod_girl:get_recommend_list(Player),
	{?ok, Player};

%% 请求招募仕女信息(7109)
handler(?MSG_ID_HOME_CS_RECURIT_INFO, Player, {}) ->
	home_mod:get_recruit_girl_info(Player),
	{?ok, Player};

%% 请求招募仕女(7113)
handler(?MSG_ID_HOME_CS_RECUIT_GIRL, Player, {Id}) ->
	home_mod:recruit_girl(Player, Id),
	{?ok, Player};

%% 反抗(7119)
handler(?MSG_ID_HOME_CS_RESIST, Player, {}) ->
	home_mod_girl:resist_by_self(Player);

%% 抢夺仕女发起战斗(7103)
handler(?MSG_ID_HOME_CS_START_BATTLE, Player, {Type, Grid}) ->
	{?ok, NewPlayer}  = home_mod_girl:grab_girl(Player, Type, Grid),
	{?ok, NewPlayer};

%% 解救好友发起战斗(7105)
handler(?MSG_ID_HOME_CS_RESCUE_BATTLE, Player, {UserId}) ->
	home_mod_girl:rescue_friend(Player, UserId);

%% 请求需解救列表(7135)
handler(?MSG_ID_HOME_CS_RESCUE_LIST, Player, {}) ->
	home_mod_girl:get_rescue_friend(Player),
	{?ok, Player};

%% 邀请好友解救(7137)
handler(?MSG_ID_HOME_CS_INVITE_RESCUE, Player, {UserId}) ->
	home_mod_girl:invite_friend(Player, UserId),
	{?ok, Player};

%% 回复邀请结果(7139)
handler(?MSG_ID_HOME_CS_INVITE_RESULT, Player, {OtherId,Type}) ->
	{?ok, NewPlayer} = home_mod_girl:invite_reply(Player, OtherId, Type),
	{?ok, NewPlayer};

%% 压榨|抽干请求(7141)
handler(?MSG_ID_HOME_CS_PRESS, Player, {Type,Grid}) ->
	{?ok, NewPlayer} = home_mod_girl:press_draw_girl(Player, Type, Grid),
	{?ok, NewPlayer};

%% 献媚(7143)
handler(?MSG_ID_HOME_CS_FAWN, Player, {}) ->
	{?ok, NewPlayer}  = home_mod_girl:fawn_belonger(Player),
	{?ok, NewPlayer};

%% 请求小黑屋仕女信息(7201)
handler(?MSG_ID_HOME_CS_BLACK_GIRLINFO, Player, {}) ->
	home_mod_girl:get_black_info(Player),
	{?ok, Player};

%% 请求展示仕女(7207)
handler(?MSG_ID_HOME_CS_SHOW_GIRL, Player, {Id}) ->
	home_mod_girl:show_girl(Player, Id),
	{?ok, Player};

%% 手动释放侍女(7209)
handler(?MSG_ID_HOME_CS_RELEASE_GIRL, Player, {Grid}) ->
	home_mod_girl:release_girl_self(Player, Grid),
	{?ok, Player};

%% 增加抓捕次数（7119)
handler(?MSG_ID_HOME_CS_ADD_TIMES, Player, {}) ->
	home_mod_girl:increase_grab_times(Player),
	{?ok, Player};

%% 请求清空留言版(7901)
handler(?MSG_ID_HOME_CS_CLEAR_MESSAGE, Player, {}) ->
	home_mod:clean_leave_message(Player),
	{?ok, Player};

%% 请求城池信息(7903)
handler(?MSG_ID_HOME_CS_DECLEAR_INFO, Player, {UserId}) ->
	home_mod:get_owner_declear(Player, UserId),
	{?ok, Player};

%% 编辑城主宣言(7905)
handler(?MSG_ID_HOME_CS_ETDIT_OWNER, Player, {Content}) ->
	home_mod:edit_home_declear(Player, Content),
	{?ok, Player};

%% 玩家留言(7907)
handler(?MSG_ID_HOME_CS_LEAVE_MESSAGE, Player, {UserId,Content}) ->
	home_mod:edit_leave_message(Player, UserId, Content),
	{?ok, Player};

%% 请求玩家留言信息(7909)
handler(?MSG_ID_HOME_CS_APPLY_LEAVE_MESSAGE, Player, {UserId}) ->
	home_mod:get_leave_message(Player, UserId),
	{?ok, Player};

%% 删除留言(7911)
handler(?MSG_ID_HOME_CS_DELETE_MESSAGE, Player, {Id}) ->
	home_mod:delete_leave_message(Player, Id),
	{?ok, Player};

%% 请求访客记录(7913)
handler(?MSG_ID_HOME_CS_VISIT_RECORD, Player, {UserId}) ->
	home_mod:get_visit_record(Player, UserId),
	{?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%



