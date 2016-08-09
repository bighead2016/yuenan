%%% 运营活动数据

-module(act_db_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.act.hrl").

%%
%% Exported Functions
%%
-export([sel_db_time/1, ins_db_time/1, sel_db_time/0]).
-export([ins_ets_time/1, sel_ets_time/1, sel_ets_all_time/0, sel_ets_time_key/1]).
-export([ins_ets_act_user/1, sel_ets_act_user/1, sel_ets_act_user_key/1, del_ets_act_user/1,
         upd_ets_time/2, up_ets_act_user/2]).
-export([del_ets_act_temp/1, ins_ets_act_temp/1, sel_ets_act_temp/1]).
-export([ins_db_user/1, ins_ets_user/1]).

%%
%% API Functions
%%

%%===========================================ets=========================================
%% 存到ets
ins_ets_time(Rec) ->
    ets_api:insert(?CONST_ETS_ACT_INFO, Rec).
upd_ets_time(Key, List) ->
    ets_api:update_element(?CONST_ETS_ACT_INFO, Key, List).

%% 读取数据
sel_ets_time(Id) ->
    ets_api:lookup(?CONST_ETS_ACT_INFO, Id).

%% 读取生效数据列表
sel_ets_all_time() ->
    ets:tab2list(?CONST_ETS_ACT_INFO).

%% 读取第一个生效的数据
sel_ets_time_key(?null) ->
    ets:first(?CONST_ETS_ACT_INFO);
sel_ets_time_key(Key) ->
    ets:next(?CONST_ETS_ACT_INFO, Key).

%%
ins_ets_act_user(Rec) ->
    ets_api:insert(?CONST_ETS_ACT_USER, Rec).

%% 
sel_ets_act_user(Key) ->
    ets_api:lookup(?CONST_ETS_ACT_USER, Key).
%% 
up_ets_act_user(Key, List) ->
    ets_api:update_element(?CONST_ETS_ACT_USER, Key, List).

%% 读取第一个生效的数据
sel_ets_act_user_key(?null) ->
    ets:first(?CONST_ETS_ACT_USER);
sel_ets_act_user_key(Key) ->
    ets:next(?CONST_ETS_ACT_USER, Key).

del_ets_act_user(Key) ->
    ets_api:delete(?CONST_ETS_ACT_USER, Key).

%%
%%
ins_ets_act_temp(Rec) ->
    ets_api:insert(?CONST_ETS_ACT_TEMP, Rec).

sel_ets_act_temp(Key) ->
    ets_api:lookup(?CONST_ETS_ACT_TEMP, Key).

del_ets_act_temp(Key) ->
    ets_api:delete(?CONST_ETS_ACT_TEMP, Key).


%%============================================db=========================================

%% desc:从数据库中查询活动时间
%% in:Id::integer() 活动id
%% out:List::list() 原活动列表
sel_db_time(Id) ->
    Sql = <<"select `id`,`start_time`,`stop_time`,`template`,`config_id`,`reset_daily`,",
            "`clear_over` from game_act_time where id='", 
            (misc:to_binary(Id))/binary, "';">>,
    case catch mysql_api:select(Sql) of
        {?ok, List} ->
            List;
        _ ->
            []
    end.

%% desc:从数据库中查询活动时间
%% in:-
%% out:List::list() 原活动列表
sel_db_time() ->
    Sql = <<"select `id`,`start_time`,`stop_time`,`template`,`config_id`,`reset_daily`,",
            "`clear_over` from `game_act_time`;">>,
    case catch mysql_api:select(Sql) of
        {?ok, List} ->
            [erlang:list_to_tuple([ets_act_info|Rec])||Rec<-List];
        _ ->
            []
    end.

%% desc:插入运营活动时间数据到db
%% in:Rec::#ets_act_info{} 活动配置
%% out:-
ins_db_time(Rec) ->
    #ets_act_info{id = Id, clear_over = ClearOver, config_id = ConfigId, start_time = StartTime, 
                stop_time = StopTime, reset_daily = Reset, template = Template
                } = Rec,
    Sql = <<"insert into `game_act_time` ( `id`,`start_time`,`stop_time`,`template`,`config_id`,`reset_daily`,",
            "`clear_over`) values ('", (misc:to_binary(Id))/binary,    "','",
                                       (mysql_api:encode(StartTime))/binary,  " ,'",
                                       (mysql_api:encode(StopTime))/binary,  " ,'",
                                       (misc:to_binary(Template))/binary,  "','",
                                       (misc:to_binary(ConfigId))/binary,  "','",
                                       (misc:to_binary(Reset))/binary,  "','",
                                       (misc:to_binary(ClearOver))/binary, "');">>,
    case catch mysql_api:insert(Sql) of
        {?ok, _, _} ->
            ?ok;
        _ ->
            ?MSG_ERROR("err", [])
    end.

%% @desc 从数据库导出到ets
%% @param Key::{user_id, act_id}
ins_ets_user({UserId, ActId}=Key) ->
	case sel_ets_act_user(Key) of
		?null ->
			case mysql_api:select(["data"], "game_act_user", [{"user_id", UserId}, {"act_id", ActId}]) of
				{ok, [[Bin]]} ->
					UserData = mysql_api:decode(Bin),
					ins_ets_act_user(#ets_act_user{key = {UserId, ActId}, user_id = UserId, act_id =ActId, data = UserData});
				_ ->
					?ok
			end;
		_ ->
			?ok
	end.

%% @desc ets导出到数据库
ins_db_user({UserId, ActId} = Key) ->
	case sel_ets_act_user(Key) of
		?null ->
			?ok;
		Data ->
			Sql = <<"insert into `game_act_user` (`user_id`,`act_id`,`data`) values (",(misc:to_binary(UserId))/binary,",",
					(misc:to_binary(ActId))/binary, " ,  "
					,(mysql_api:encode(Data#ets_act_user.data))/binary," ) ON DUPLICATE KEY UPDATE data= ",(mysql_api:encode(Data#ets_act_user.data))/binary," ;">>,
			mysql_api:execute(Sql)
	end.
%% 
%%
%% Local Functions
%%
