%% 任务相关转换
-module(trans_task).

-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.task.hrl").
-include("record.copy_single.hrl").
-include("record.base.data.hrl").

-export([trans_20130926/0]).

%% trans_task:trans_20130926().
trans_20130926() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`,`task`,`copy` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, TaskDataE, CopyDataE], OldCount) ->
                                try
                                    TaskDataD = mysql_api:decode(TaskDataE),
                                    CopyDataD = mysql_api:decode(CopyDataE),
                                    case TaskDataD#task_data.main of
                                        {MainTaskId, _, _, _, _, _} ->
                                            case data_task:get_task(MainTaskId) of
                                                #task{idx = TaskIdx} ->
                                                    Branch    = TaskDataD#task_data.branch,
                                                    AccList   = Branch#branch_task.acceptable,
                                                    CopyBag   = CopyDataD#copy_data.copy_bag,
                                                    {NewAccList, NewCopyBag} = 
                                                        if
                                                            TaskIdx > 126 ->
                                                                Task10414 = data_task:get_task(10414),
                                                                Task10414_2 = Task10414#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
                                                                [Task10414Z] = task_login_mod:zip([Task10414_2], []),
                                                                AccList2 = misc:smart_insert_ignore(10414, Task10414Z, 1, AccList),
                                                                
                                                                CopyBag2 = [#copy_one{id = 20014, flags = #copy_flags{is_2 = 0, is_passed = 0, is_shadowed = 0, is_tasked = 0}}|CopyBag],
                                                                {AccList2, CopyBag2};
                                                            ?true ->
                                                                {AccList, CopyBag}
                                                        end,
                                                    {NewAccList2, NewCopyBag2} = 
                                                        if
                                                            TaskIdx > 129 ->
                                                                Task10415 = data_task:get_task(10415),
                                                                Task10415_2 = Task10415#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
                                                                [Task10415Z] = task_login_mod:zip([Task10415_2], []),
                                                                AccList3 = misc:smart_insert_ignore(10415, Task10415Z, 1, NewAccList),
                                                                
                                                                CopyBag3 = [#copy_one{id = 20015, flags = #copy_flags{is_2 = 0, is_passed = 0, is_shadowed = 0, is_tasked = 0}}|NewCopyBag],
                                                                {AccList3, CopyBag3};
                                                            ?true ->
                                                                {NewAccList, NewCopyBag}
                                                        end,
                                                    Branch2 = Branch#branch_task{acceptable = NewAccList2},
                                                    TaskDataD2 = TaskDataD#task_data{branch = Branch2},
                                                    CopyDataD2 = CopyDataD#copy_data{copy_bag = NewCopyBag2},
                                                    mysql_api:update(<<"update `game_player` set `task`= ", (mysql_api:encode(TaskDataD2))/binary, 
                                                                       ", `copy` = ", (mysql_api:encode(CopyDataD2))/binary,
                                                                     " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>)
                                            end;
                                        XX ->
                                            ?MSG_SYS("s[~p]", [XX])
                                    end,
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end,
    erlang:halt().
%%     ok.
